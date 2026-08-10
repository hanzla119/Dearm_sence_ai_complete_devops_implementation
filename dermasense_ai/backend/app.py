import os
import time
import uuid
import torch
import ultralytics.utils.loss
from flask import Flask, request, jsonify, Response
from flask_cors import CORS
from werkzeug.utils import secure_filename
from ultralytics import YOLO
from PIL import Image
from prometheus_client import Counter, Histogram, Gauge, generate_latest, CONTENT_TYPE_LATEST

# Monkey-patch PyTorch 2.6+ to default weights_only=False to allow YOLOv8 custom classes
original_load = torch.load
def safe_load(*args, **kwargs):
    kwargs['weights_only'] = False
    return original_load(*args, **kwargs)
torch.load = safe_load

# Monkey-patch ultralytics DFLoss if missing to prevent AttributeError
if not hasattr(ultralytics.utils.loss, 'DFLoss'):
    class DFLoss:
        def __init__(self, *args, **kwargs):
            pass
    ultralytics.utils.loss.DFLoss = DFLoss

app = Flask(__name__)
CORS(app)

# ----------------------------------------------------
# 1. PROMETHEUS METRICS INSTRUMENTATION
# ----------------------------------------------------
HTTP_REQUESTS_TOTAL = Counter(
    'dermasense_http_requests_total',
    'Total HTTP requests processed by endpoint and status code',
    ['method', 'endpoint', 'status']
)

INFERENCE_REQUESTS_TOTAL = Counter(
    'dermasense_inference_requests_total',
    'Total AI inference requests categorized by acne severity',
    ['severity']
)

INFERENCE_LATENCY_SECONDS = Histogram(
    'dermasense_inference_latency_seconds',
    'Time spent running deep learning computer vision inference in seconds',
    buckets=[0.05, 0.1, 0.25, 0.5, 0.75, 1.0, 2.0, 5.0, 10.0]
)

ACNE_COUNT_HISTOGRAM = Histogram(
    'dermasense_detected_acne_count',
    'Distribution of detected acne lesion counts per image',
    buckets=[0, 1, 5, 10, 15, 20, 30, 50, 100]
)

ACTIVE_INFLIGHT_REQUESTS = Gauge(
    'dermasense_active_inflight_requests',
    'Current number of concurrent active requests'
)

# ----------------------------------------------------
# 2. SETUP ENVIRONMENT & MODELS
# ----------------------------------------------------
UPLOAD_FOLDER = os.path.join(os.path.dirname(__file__), 'uploads')
os.makedirs(UPLOAD_FOLDER, exist_ok=True)
app.config['UPLOAD_FOLDER'] = UPLOAD_FOLDER
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024  # 16 MB max upload limit

MODEL_PATH = os.path.join(os.path.dirname(__file__), 'models', 'best (3).pt')
if not os.path.exists(MODEL_PATH):
    MODEL_PATH = os.path.join(os.path.dirname(__file__), 'models', 'best (2).pt')
if not os.path.exists(MODEL_PATH):
    MODEL_PATH = os.path.join(os.path.dirname(__file__), 'models', 'best.pt')

model_loaded_successfully = False
try:
    if os.path.exists(MODEL_PATH):
        print(f"Loading custom YOLOv8 model from {MODEL_PATH}")
        yolo_model = YOLO(MODEL_PATH)
    else:
        print("Warning: Trained model not found. Falling back to default YOLOv8n.")
        yolo_model = YOLO('yolov8n.pt')
    model_loaded_successfully = True
except Exception as e:
    print(f"Error loading model: {e}")
    yolo_model = None

# Predefined recommendation templates
RECOMMENDATION_TEMPLATES = {
    "Clear": (
        "Your skin is clear! Maintain a basic routine of gentle cleansing, daily hydration, "
        "and sun protection to keep your skin healthy."
    ),
    "Mild": (
        "Wash your face twice daily with a gentle, non-comedogenic cleanser. Use a topical "
        "treatment containing salicylic acid (BHA) to unclog pores. Keep your skin hydrated "
        "with a lightweight, oil-free moisturizer, and apply sunscreen daily."
    ),
    "Moderate": (
        "Cleanse your face twice daily. Apply benzoyl peroxide or salicylic acid to target active spots. "
        "Consider incorporating a topical retinoid (such as adapalene) at night to promote skin cell "
        "turnover. Always use oil-free moisturizer and daily broad-spectrum SPF."
    ),
    "Severe": (
        "Avoid squeezing or popping lesions to prevent scarring and infection. Cleanse gently. "
        "While over-the-counter spot treatments can help, because the condition is severe, "
        "we strongly advise consulting a dermatologist for prescription-strength treatments "
        "(such as oral antibiotics or retinoids)."
    )
}

# ----------------------------------------------------
# 3. HELPER FUNCTIONS
# ----------------------------------------------------
def calculate_severity(acne_count, avg_confidence=0.0, area_ratio=0.0):
    score = 0
    if acne_count == 0:
        score += 0
    elif acne_count <= 5:
        score += 2
    elif acne_count <= 15:
        score += 4
    elif acne_count <= 30:
        score += 6
    else:
        score += 8

    if area_ratio > 0.01:
        score += 1
    if area_ratio > 0.03:
        score += 1

    if avg_confidence > 0.50 and acne_count > 0:
        score += 1

    score = max(1, min(score, 10))

    if score <= 2:
        label = "Clear"
    elif score <= 4:
        label = "Mild"
    elif score <= 7:
        label = "Moderate"
    else:
        label = "Severe"

    return score, label

def generate_skincare_advice(severity_label):
    advice = RECOMMENDATION_TEMPLATES.get(severity_label, RECOMMENDATION_TEMPLATES["Clear"])
    safety_tags = [
        "Patch Test Required",
        "Avoid Harmful Remedies (e.g., toothpaste, baking soda)",
        "Consult Dermatologist"
    ]
    return {
        "advice": advice,
        "safety_warnings": safety_tags
    }

# ----------------------------------------------------
# 4. ENDPOINTS & OBSERVABILITY ROUTES
# ----------------------------------------------------
@app.route('/', methods=['GET'])
def root():
    HTTP_REQUESTS_TOTAL.labels(method='GET', endpoint='/', status='200').inc()
    return jsonify({
        "status": "running",
        "service": "DermaSense AI Backend API",
        "version": "1.0.0",
        "model_loaded": model_loaded_successfully
    }), 200

@app.route('/healthz', methods=['GET'])
def health_check():
    """Kubernetes Liveness & Readiness Probe Endpoint"""
    if not model_loaded_successfully or yolo_model is None:
        HTTP_REQUESTS_TOTAL.labels(method='GET', endpoint='/healthz', status='503').inc()
        return jsonify({"status": "unhealthy", "reason": "model_not_ready"}), 503
    
    HTTP_REQUESTS_TOTAL.labels(method='GET', endpoint='/healthz', status='200').inc()
    return jsonify({
        "status": "healthy",
        "uptime": "operational",
        "model": "YOLOv8-DermaSense"
    }), 200

@app.route('/metrics', methods=['GET'])
def metrics():
    """Prometheus Scrape Endpoint"""
    return Response(generate_latest(), mimetype=CONTENT_TYPE_LATEST)

@app.route('/analyze', methods=['POST'])
def analyze_image():
    ACTIVE_INFLIGHT_REQUESTS.inc()
    filepath = None

    try:
        if 'image' not in request.files:
            HTTP_REQUESTS_TOTAL.labels(method='POST', endpoint='/analyze', status='400').inc()
            return jsonify({"error": "No image part in the request"}), 400
            
        file = request.files['image']
        if file.filename == '':
            HTTP_REQUESTS_TOTAL.labels(method='POST', endpoint='/analyze', status='400').inc()
            return jsonify({"error": "No selected file"}), 400

        filename = secure_filename(file.filename)
        unique_filename = f"{uuid.uuid4()}_{filename}"
        filepath = os.path.join(app.config['UPLOAD_FOLDER'], unique_filename)
        file.save(filepath)

        # Measure Image Size & Area
        with Image.open(filepath) as img:
            img_w, img_h = img.size
            image_area = img_w * img_h
        total_box_area = 0

        # Execute Computer Vision Inference with latency measurement
        inference_start = time.time()
        results = yolo_model(
            filepath,
            conf=0.15,
            iou=0.35,
            imgsz=1280,
            augment=True
        )
        inference_duration = time.time() - inference_start
        INFERENCE_LATENCY_SECONDS.observe(inference_duration)

        # Extract Bounding Box Detections
        pimples = 0
        confidences = []
        boxes_info = []

        if len(results) > 0:
            boxes = results[0].boxes
            for box in boxes:
                conf = float(box.conf[0].item())
                if conf < 0.15:
                    continue
                confidences.append(conf)
                xyxy = box.xyxy[0].tolist()
                
                x1, y1, x2, y2 = xyxy
                box_area = max(0, x2 - x1) * max(0, y2 - y1)
                total_box_area += box_area
                pimples += 1
                
                boxes_info.append({
                    "class": "pimple",
                    "confidence": conf,
                    "bbox": xyxy
                })

        avg_confidence = sum(confidences) / len(confidences) if len(confidences) > 0 else 0.0
        area_ratio = total_box_area / image_area if image_area > 0 else 0.0

        # Calculate Severity & Skincare Guidance
        severity_score, severity_label = calculate_severity(pimples, avg_confidence, area_ratio)
        guidance = generate_skincare_advice(severity_label)

        # Record Prometheus Metrics
        INFERENCE_REQUESTS_TOTAL.labels(severity=severity_label).inc()
        ACNE_COUNT_HISTOGRAM.observe(pimples)
        HTTP_REQUESTS_TOTAL.labels(method='POST', endpoint='/analyze', status='200').inc()

        return jsonify({
            "success": True,
            "acneCount": pimples,
            "severityScore": severity_score,
            "severityLabel": severity_label,
            "confidence": round(avg_confidence, 4),
            "areaRatio": round(area_ratio, 4),
            "inferenceTimeSeconds": round(inference_duration, 4),
            "recommendations": guidance
        }), 200

    except Exception as e:
        HTTP_REQUESTS_TOTAL.labels(method='POST', endpoint='/analyze', status='500').inc()
        return jsonify({"error": f"Internal inference error: {str(e)}"}), 500

    finally:
        ACTIVE_INFLIGHT_REQUESTS.dec()
        if filepath and os.path.exists(filepath):
            try:
                os.remove(filepath)
            except OSError:
                pass
        if __name__ == '__main__':
          host = os.environ.get('HOST', '0.0.0.0')
          port = int(os.environ.get('PORT', 5000))
          app.run(host=host, port=port, debug=False)  # nosec B104
 
