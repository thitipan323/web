from dataclasses import dataclass, field
from pathlib import Path
import json
import os
import sys

APP_TITLE = "Posture Guard"
APP_NAME = "SmartSit"


def _get_app_dir() -> Path:
    """Return per-user data directory (AppData on Windows, ~/.smartsit otherwise)."""
    if sys.platform == "win32":
        base = Path(os.environ.get("APPDATA", Path.home()))
    else:
        base = Path.home()
    app_dir = base / APP_NAME
    app_dir.mkdir(parents=True, exist_ok=True)
    return app_dir


def _get_app_root() -> Path:
    """Return directory where the exe or script lives (for company_config.json)."""
    if getattr(sys, "frozen", False):
        return Path(sys.executable).parent
    return Path(__file__).parent.parent


@dataclass
class Thresholds:
    shoulder_tilt: float = 0.04
    distance_ratio: float = 0.8


@dataclass
class AppConfig:
    camera_index: int = 0
    frame_width: int = 640
    frame_height: int = 480
    alert_after_seconds: float = 10.0
    thresholds: Thresholds = field(default_factory=Thresholds)
    log_dir: Path = field(default_factory=lambda: _get_app_dir() / "logs")
    sound_enabled: bool = True
    draw_skeleton: bool = True

    @property
    def csv_log(self) -> Path:
        return self.log_dir / "events.csv"

    @property
    def json_log(self) -> Path:
        return self.log_dir / "events.json"


def load_config() -> AppConfig:
    """Load defaults then overlay company_config.json if present next to the exe."""
    cfg = AppConfig()
    company_cfg_path = _get_app_root() / "company_config.json"
    if company_cfg_path.exists():
        try:
            data = json.loads(company_cfg_path.read_text(encoding="utf-8"))
            if "alert_after_seconds" in data:
                cfg.alert_after_seconds = float(data["alert_after_seconds"])
            if "sound_enabled" in data:
                cfg.sound_enabled = bool(data["sound_enabled"])
            if "draw_skeleton" in data:
                cfg.draw_skeleton = bool(data["draw_skeleton"])
            if "camera_index" in data:
                cfg.camera_index = int(data["camera_index"])
            thresholds = data.get("thresholds", {})
            if thresholds:
                cfg.thresholds = Thresholds(
                    shoulder_tilt=float(thresholds.get("shoulder_tilt", cfg.thresholds.shoulder_tilt)),
                    distance_ratio=float(thresholds.get("distance_ratio", cfg.thresholds.distance_ratio)),
                )
        except Exception:
            pass  # Fall back to defaults silently
    return cfg


DEFAULT_CONFIG = load_config()
