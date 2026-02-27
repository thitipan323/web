from dataclasses import dataclass
from mediapipe.tasks.python.vision.pose_landmarker import PoseLandmark


@dataclass
class BaselineData:
    shoulder_y: float
    eye_y: float
    distance: float


@dataclass
class Metrics:
    shoulder_tilt: float
    eye_shoulder_distance: float
    is_bad_posture: bool


class PostureTimer:
    def __init__(self):
        self.bad_elapsed = 0.0

    def reset(self):
        self.bad_elapsed = 0.0

    def update(self, is_bad, delta_seconds, alert_after_seconds):
        if is_bad:
            self.bad_elapsed += delta_seconds
        else:
            self.bad_elapsed = 0.0
        return self.bad_elapsed >= alert_after_seconds


def compute_baseline(landmarks):
    left_shoulder = landmarks[PoseLandmark.LEFT_SHOULDER]
    right_shoulder = landmarks[PoseLandmark.RIGHT_SHOULDER]
    left_eye = landmarks[PoseLandmark.LEFT_EYE]
    right_eye = landmarks[PoseLandmark.RIGHT_EYE]

    shoulder_y = (left_shoulder.y + right_shoulder.y) / 2.0
    eye_y = (left_eye.y + right_eye.y) / 2.0
    distance = shoulder_y - eye_y
    return BaselineData(shoulder_y=shoulder_y, eye_y=eye_y, distance=distance)


def compute_metrics(landmarks, baseline, thresholds):
    left_shoulder = landmarks[PoseLandmark.LEFT_SHOULDER]
    right_shoulder = landmarks[PoseLandmark.RIGHT_SHOULDER]
    left_eye = landmarks[PoseLandmark.LEFT_EYE]
    right_eye = landmarks[PoseLandmark.RIGHT_EYE]

    shoulder_tilt = abs(left_shoulder.y - right_shoulder.y)
    shoulder_y = (left_shoulder.y + right_shoulder.y) / 2.0
    eye_y = (left_eye.y + right_eye.y) / 2.0
    distance = shoulder_y - eye_y

    bad_tilt = shoulder_tilt > thresholds.shoulder_tilt
    bad_distance = distance < (baseline.distance * thresholds.distance_ratio)
    is_bad = bad_tilt or bad_distance
    return Metrics(
        shoulder_tilt=shoulder_tilt,
        eye_shoulder_distance=distance,
        is_bad_posture=is_bad,
    )
