from dataclasses import dataclass
from datetime import datetime
import csv
import json

try:
    import winsound
except ImportError:
    winsound = None


@dataclass
class AlertEvent:
    timestamp: str
    reason: str
    shoulder_tilt: float
    eye_shoulder_distance: float


class AlertManager:
    def __init__(self, config):
        self.config = config
        self._prepare_logs()

    def _prepare_logs(self):
        self.config.log_dir.mkdir(parents=True, exist_ok=True)
        if not self.config.csv_log.exists():
            with self.config.csv_log.open("w", newline="", encoding="utf-8") as handle:
                writer = csv.writer(handle)
                writer.writerow(
                    ["timestamp", "reason", "shoulder_tilt", "eye_shoulder_distance"]
                )
        if not self.config.json_log.exists():
            self.config.json_log.write_text("", encoding="utf-8")

    def trigger(self, metrics, reason="bad_posture"):
        event = AlertEvent(
            timestamp=datetime.utcnow().isoformat(),
            reason=reason,
            shoulder_tilt=metrics.shoulder_tilt,
            eye_shoulder_distance=metrics.eye_shoulder_distance,
        )
        self._beep()
        self._log_event(event)

    def _beep(self):
        if not self.config.sound_enabled:
            return
        if winsound:
            winsound.Beep(1500, 300)
        else:
            print("Beep")

    def _log_event(self, event):
        with self.config.csv_log.open("a", newline="", encoding="utf-8") as handle:
            writer = csv.writer(handle)
            writer.writerow(
                [
                    event.timestamp,
                    event.reason,
                    event.shoulder_tilt,
                    event.eye_shoulder_distance,
                ]
            )
        with self.config.json_log.open("a", encoding="utf-8") as handle:
            handle.write(json.dumps(event.__dict__) + "\n")
