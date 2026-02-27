"""
user_profile.py
บันทึกและโหลดข้อมูล Calibration Baseline ต่อผู้ใช้แต่ละคน
เก็บในโฟลเดอร์ AppData ของผู้ใช้ เพื่อให้ไม่ต้อง Calibrate ใหม่ทุกครั้ง
"""

import json
import getpass
from pathlib import Path
from .config import _get_app_dir
from .logic_module import BaselineData


def _profile_path() -> Path:
    username = getpass.getuser()
    return _get_app_dir() / f"profile_{username}.json"


def save_baseline(baseline: BaselineData) -> None:
    """บันทึกค่า Baseline ลงไฟล์ของผู้ใช้คนนี้"""
    data = {
        "shoulder_y": baseline.shoulder_y,
        "eye_y": baseline.eye_y,
        "distance": baseline.distance,
    }
    _profile_path().write_text(json.dumps(data, indent=2), encoding="utf-8")


def load_baseline() -> BaselineData | None:
    """โหลดค่า Baseline ของผู้ใช้คนนี้ คืน None ถ้ายังไม่เคย Calibrate"""
    path = _profile_path()
    if not path.exists():
        return None
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
        return BaselineData(
            shoulder_y=float(data["shoulder_y"]),
            eye_y=float(data["eye_y"]),
            distance=float(data["distance"]),
        )
    except Exception:
        return None


def get_username() -> str:
    """คืนชื่อผู้ใช้ปัจจุบัน"""
    return getpass.getuser()
