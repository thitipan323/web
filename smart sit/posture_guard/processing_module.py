import cv2
import mediapipe as mp
from mediapipe.tasks import python
from mediapipe.tasks.python import vision
from mediapipe.tasks.python.vision.pose_landmarker import PoseLandmarksConnections
import numpy as np
from dataclasses import dataclass
from pathlib import Path
import urllib.request


@dataclass
class PoseResult:
    landmarks: list | None
    raw_results: object


def download_model_if_needed():
    """Download the pose landmarker model if it doesn't exist."""
    model_path = Path("models/pose_landmarker_lite.task")
    if model_path.exists():
        return str(model_path)
    
    model_path.parent.mkdir(parents=True, exist_ok=True)
    model_url = "https://storage.googleapis.com/mediapipe-models/pose_landmarker/pose_landmarker_lite/float16/latest/pose_landmarker_lite.task"
    
    print(f"Downloading pose model to {model_path}...")
    urllib.request.urlretrieve(model_url, model_path)
    print("Download complete!")
    return str(model_path)


class PoseProcessor:
    def __init__(self, model_complexity=1, smooth_landmarks=True):
        # Download model if needed
        model_path = download_model_if_needed()
        
        # Use the new MediaPipe Tasks API
        base_options = python.BaseOptions(
            model_asset_path=model_path
        )
        options = vision.PoseLandmarkerOptions(
            base_options=base_options,
            running_mode=vision.RunningMode.VIDEO,
            min_pose_detection_confidence=0.5,
            min_pose_presence_confidence=0.5,
            min_tracking_confidence=0.5,
        )
        self.landmarker = vision.PoseLandmarker.create_from_options(options)
        self.frame_timestamp = 0

    def process_frame(self, frame):
        rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
        mp_image = mp.Image(image_format=mp.ImageFormat.SRGB, data=rgb)
        
        # Process with timestamp in milliseconds
        results = self.landmarker.detect_for_video(mp_image, self.frame_timestamp)
        self.frame_timestamp += 33  # ~30 FPS
        
        landmarks = None
        if results.pose_landmarks and len(results.pose_landmarks) > 0:
            landmarks = results.pose_landmarks[0]
        
        return PoseResult(landmarks=landmarks, raw_results=results)

    def draw_skeleton(self, frame, results):
        if results.pose_landmarks and len(results.pose_landmarks) > 0:
            pose_landmarks = results.pose_landmarks[0]
            h, w = frame.shape[:2]
            
            # Draw landmarks
            for landmark in pose_landmarks:
                x = int(landmark.x * w)
                y = int(landmark.y * h)
                cv2.circle(frame, (x, y), 4, (0, 255, 0), -1)
            
            # Draw connections
            for connection in PoseLandmarksConnections.POSE_LANDMARKS:
                start_idx = connection.start
                end_idx = connection.end
                
                start_landmark = pose_landmarks[start_idx]
                end_landmark = pose_landmarks[end_idx]
                
                start_x = int(start_landmark.x * w)
                start_y = int(start_landmark.y * h)
                end_x = int(end_landmark.x * w)
                end_y = int(end_landmark.y * h)
                
                cv2.line(frame, (start_x, start_y), (end_x, end_y), (255, 255, 255), 2)

    def close(self):
        self.landmarker.close()
