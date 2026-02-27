import time
import customtkinter as ctk
from PIL import Image, ImageTk
import cv2

from .config import APP_TITLE, DEFAULT_CONFIG
from .input_module import CameraInput
from .processing_module import PoseProcessor
from .logic_module import compute_baseline, compute_metrics, PostureTimer
from .alert_module import AlertManager


class PostureApp(ctk.CTk):
    def __init__(self, config=DEFAULT_CONFIG):
        super().__init__()
        self.config_data = config
        self.title(APP_TITLE)
        self.geometry("900x700")

        ctk.set_appearance_mode("System")
        ctk.set_default_color_theme("blue")

        self.running = False
        self.pending_calibration = False
        self.baseline = None
        self.timer = PostureTimer()
        self.last_update = time.time()

        self.camera = CameraInput(self.config_data)
        self.processor = PoseProcessor()
        self.alerts = AlertManager(self.config_data)

        self._build_ui()
        self.after(33, self._update_loop)

    def _build_ui(self):
        self.video_label = ctk.CTkLabel(self, text="")
        self.video_label.pack(padx=16, pady=16, fill="both", expand=True)

        self.status_label = ctk.CTkLabel(self, text="Status: idle")
        self.status_label.pack(pady=8)

        button_row = ctk.CTkFrame(self)
        button_row.pack(pady=12)

        self.start_button = ctk.CTkButton(
            button_row, text="Start", command=self._start
        )
        self.start_button.grid(row=0, column=0, padx=8)

        self.stop_button = ctk.CTkButton(button_row, text="Stop", command=self._stop)
        self.stop_button.grid(row=0, column=1, padx=8)

        self.calibrate_button = ctk.CTkButton(
            button_row, text="Calibrate", command=self._calibrate
        )
        self.calibrate_button.grid(row=0, column=2, padx=8)

    def _start(self):
        if not self.running:
            self.camera.open()
            self.running = True
            self.status_label.configure(text="Status: running")

    def _stop(self):
        if self.running:
            self.running = False
            self.camera.release()
            self.timer.reset()
            self.status_label.configure(text="Status: stopped")

    def _calibrate(self):
        self.pending_calibration = True
        self.status_label.configure(text="Status: calibrating")

    def _update_loop(self):
        now = time.time()
        delta = now - self.last_update
        self.last_update = now

        if self.running:
            frame = self.camera.read_frame()
            if frame is not None:
                result = self.processor.process_frame(frame)
                if result.landmarks:
                    if self.pending_calibration:
                        self.baseline = compute_baseline(result.landmarks)
                        self.timer.reset()
                        self.pending_calibration = False
                        self.status_label.configure(text="Status: calibrated")

                    if self.baseline:
                        metrics = compute_metrics(
                            result.landmarks,
                            self.baseline,
                            self.config_data.thresholds,
                        )
                        should_alert = self.timer.update(
                            metrics.is_bad_posture,
                            delta,
                            self.config_data.alert_after_seconds,
                        )
                        if should_alert:
                            self.alerts.trigger(metrics)
                            self.timer.reset()

                        if metrics.is_bad_posture:
                            self.status_label.configure(text="Status: bad posture")
                            cv2.rectangle(
                                frame,
                                (0, 0),
                                (frame.shape[1] - 1, frame.shape[0] - 1),
                                (0, 0, 255),
                                4,
                            )
                        else:
                            self.status_label.configure(text="Status: good posture")

                if self.config_data.draw_skeleton:
                    self.processor.draw_skeleton(frame, result.raw_results)

                frame_rgb = cv2.cvtColor(frame, cv2.COLOR_BGR2RGB)
                image = Image.fromarray(frame_rgb)
                image_tk = ImageTk.PhotoImage(image=image)
                self.video_label.configure(image=image_tk)
                self.video_label.image = image_tk
            else:
                self.status_label.configure(text="Status: camera error")
        else:
            if self.baseline is None:
                self.status_label.configure(text="Status: idle - calibrate before monitoring")

        self.after(33, self._update_loop)
