# Derma Sense AI

An AI-powered mobile application designed for dermatological assessment, specifically whole-body acne detection. It uses **YOLOv8** to identify and differentiate pimples and scars, assigns a normalized severity score (1-10), and leverages **HuggingFace** models to provide automated, safe skincare guidance.

## Key Features
- **YOLOv8 Object Detection**: Differentiates pimples vs scars.
- **Severity Scoring**: Analyzes total lesions to rank severity (Mild, Moderate, Severe).
- **AI Guidance System**: Provides personalized skincare tips with integrated medical disclaimers ("Patch Test Required", "Consult Dermatologist").
- **GlowGang Community**: Internal community features and FunFact reminders.
- **Backend-as-a-Service**: Powered by Supabase (Auth, Storage, Database).

## Architecture
- `backend/` - Flask Python server hosting AI endpoints (`/analyze`).
- `frontend/` - Flutter mobile application encompassing all UI/UX.
- `dataset/` - Data provisioning and model training code.

## Quick Start
1. **Model Training**: Run the python scripts in `dataset/` to fetch data and train YOLOv8.
2. **Backend**: Install `requirements.txt` in `backend/` and start `app.py`.
3. **Frontend**: Fill in Supabase config in `frontend/` and run `flutter run`.
