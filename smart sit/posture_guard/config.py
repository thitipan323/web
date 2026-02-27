from dataclasses import dataclass
from pathlib import Path

APP_TITLE = "Posture Guard"


@dataclass(frozen=True)
class Thresholds:
    shoulder_tilt: float = 0.04
    distance_ratio: float = 0.8


@dataclass(frozen=True)
class AppConfig:
    camera_index: int = 0
    frame_width: int = 640
    frame_height: int = 480
    alert_after_seconds: float = 10.0
    thresholds: Thresholds = Thresholds()
    log_dir: Path = Path("logs")
    csv_log: Path = log_dir / "events.csv"
    json_log: Path = log_dir / "events.json"
    sound_enabled: bool = True
    draw_skeleton: bool = True


DEFAULT_CONFIG = AppConfig()
