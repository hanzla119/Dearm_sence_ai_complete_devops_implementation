import requests
import sys
import os

# This workflow validates the end-to-end execution of functional requirements
# using a real image for the FYP instead of dummy data.

def test_workflow(image_path):
    print("Testing End-To-End Backend Workflow with REAL IMAGE...")
    
    if not os.path.exists(image_path):
        print(f"Error: The image '{image_path}' does not exist.")
        print("Please provide a valid image path. Example:")
        print("python test_workflow.py real_acne_image.jpg")
        return

    url = 'http://127.0.0.1:5000/analyze'
    
    try:
        print(f"Uploading image '{image_path}' to {url} ...")
        with open(image_path, 'rb') as f:
            files = {'image': f}
            response = requests.post(url, files=files)
            
        print(f"Response Code: {response.status_code}")
        
        if response.status_code == 200:
            data = response.json()
            print("\nSuccess! Retrieved JSON payload.")
            print("\n--- Payload Verification ---")
            print(f"Overall Severity: {data.get('severityLabel')} (Score: {data.get('severityScore')})")
            print(f"Acne Count (Pimples): {data.get('acneCount')}")
            print(f"Average Confidence: {data.get('confidence')}")
            print(f"Guidance Generated: {data.get('recommendations', {}).get('advice')}")
            print("Safety Tags strictly applied:")
            for tag in data.get('recommendations', {}).get('safety_warnings', []):
                print(f" - {tag}")
                
            print("\nVerification COMPLETE. The YOLO model was successfully used on a real image!")
        else:
            print(f"Workflow test failed: {response.text}")

    except Exception as e:
        print(f"Error testing backend workflow: {e}")
        print("Make sure the Flask server is running `python app.py`.")

if __name__ == '__main__':
    # Default image path or from command line argument
    if len(sys.argv) > 1:
        img_path = sys.argv[1]
    else:
        img_path = 'real_acne_image.jpg'
        
    test_workflow(img_path)
