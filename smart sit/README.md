# Posture Guard

A desktop posture monitoring app that uses MediaPipe Pose to detect shoulder tilt and forward head posture, then alerts after a sustained bad posture window.

## Requirements

- Python 3.9+ recommended
- Webcam

## Setup

1. Create and activate a virtual environment.
2. Install dependencies:

```bash
pip install -r requirements.txt
```

## Run

```bash
python -m posture_guard.main
```

## Notes

- Use the Calibrate button while sitting upright and looking forward.
- Alerts are logged to `logs/events.csv` and `logs/events.json`.
