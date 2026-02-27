import time
import customtkinter as ctk
from PIL import Image, ImageTk
import cv2

from .config import APP_TITLE, DEFAULT_CONFIG
from .input_module import CameraInput
from .processing_module import PoseProcessor
from .logic_module import compute_baseline, compute_metrics, PostureTimer
from .alert_module import AlertManager
from .user_profile import save_baseline, load_baseline, get_username


class PostureApp(ctk.CTk):
    def __init__(self, config=DEFAULT_CONFIG):
        super().__init__()
        self.config_data = config
        self._username = get_username()
        self.title(f"{APP_TITLE}  —  {self._username}")
        self.geometry("900x740")

        ctk.set_appearance_mode("System")
        ctk.set_default_color_theme("blue")

        self.running = False
        self.pending_calibration = False
        self.timer = PostureTimer()
        self.last_update = time.time()

        self.camera = CameraInput(self.config_data)
        self.processor = PoseProcessor()
        self.alerts = AlertManager(self.config_data)

        # โหลด Calibration ที่บันทึกไว้ก่อนหน้านี้
        self.baseline = load_baseline()

        self._build_ui()

        if self.baseline:
            self.status_label.configure(
                text=f"Status: calibration loaded for {self._username} — ready to Start"
            )

        self.after(33, self._update_loop)

    # ------------------------------------------------------------------
    def _build_ui(self):
        # แถบบนสุด: username + log path
        top_bar = ctk.CTkFrame(self, fg_color="transparent")
        top_bar.pack(fill="x", padx=16, pady=(10, 0))
        ctk.CTkLabel(
            top_bar,
            text=f"User: {self._username}",
            font=ctk.CTkFont(size=12),
        ).pack(side="left")
        ctk.CTkLabel(
            top_bar,
            text=f"Log: {self.config_data.log_dir}",
            font=ctk.CTkFont(size=11),
            text_color="gray",
        ).pack(side="right")

        # ภาพกล้อง
        self.video_label = ctk.CTkLabel(self, text="")
        self.video_label.pack(padx=16, pady=8, fill="both", expand=True)

        # Status
        self.status_label = ctk.CTkLabel(self, text="Status: idle")
        self.status_label.pack(pady=4)

        # ปุ่มหลัก
        button_row = ctk.CTkFrame(self)
        button_row.pack(pady=8)

        self.start_button = ctk.CTkButton(
            button_row, text="▶  Start", width=110, command=self._start
        )
        self.start_button.grid(row=0, column=0, padx=8)

        self.stop_button = ctk.CTkButton(
            button_row, text="■  Stop", width=110, command=self._stop
        )
        self.stop_button.grid(row=0, column=1, padx=8)

        self.calibrate_button = ctk.CTkButton(
            button_row, text="🎯  Calibrate", width=130, command=self._calibrate
        )
        self.calibrate_button.grid(row=0, column=2, padx=8)

        self.settings_button = ctk.CTkButton(
            button_row, text="⚙  Settings", width=110,
            fg_color="gray40", hover_color="gray30",
            command=self._open_settings,
        )
        self.settings_button.grid(row=0, column=3, padx=8)

    # ------------------------------------------------------------------
    def _start(self):
        if not self.running:
            self.camera.open()
            self.running = True
            if self.baseline:
                self.status_label.configure(text="Status: monitoring")
            else:
                self.status_label.configure(
                    text="Status: running — please Calibrate first"
                )

    def _stop(self):
        if self.running:
            self.running = False
            self.camera.release()
            self.timer.reset()
            self.status_label.configure(text="Status: stopped")

    def _calibrate(self):
        self.pending_calibration = True
        self.status_label.configure(
            text="Status: sit upright, look forward, then hold still…"
        )

    # ------------------------------------------------------------------
    def _open_settings(self):
        win = ctk.CTkToplevel(self)
        win.title("Settings")
        win.geometry("360x260")
        win.grab_set()

        ctk.CTkLabel(win, text="Alert after (seconds):").pack(padx=20, pady=(20, 2), anchor="w")
        alert_var = ctk.StringVar(value=str(self.config_data.alert_after_seconds))
        ctk.CTkEntry(win, textvariable=alert_var).pack(padx=20, fill="x")

        ctk.CTkLabel(win, text="Shoulder tilt threshold (0–1):").pack(padx=20, pady=(12, 2), anchor="w")
        tilt_var = ctk.StringVar(value=str(self.config_data.thresholds.shoulder_tilt))
        ctk.CTkEntry(win, textvariable=tilt_var).pack(padx=20, fill="x")

        ctk.CTkLabel(win, text="Distance ratio threshold (0–1):").pack(padx=20, pady=(12, 2), anchor="w")
        dist_var = ctk.StringVar(value=str(self.config_data.thresholds.distance_ratio))
        ctk.CTkEntry(win, textvariable=dist_var).pack(padx=20, fill="x")

        def _save():
            try:
                from .config import Thresholds
                self.config_data.alert_after_seconds = float(alert_var.get())
                self.config_data.thresholds = Thresholds(
                    shoulder_tilt=float(tilt_var.get()),
                    distance_ratio=float(dist_var.get()),
                )
                self.status_label.configure(text="Settings saved for this session")
            except ValueError:
                self.status_label.configure(text="Invalid settings value")
            win.destroy()

        ctk.CTkButton(win, text="Save", command=_save).pack(pady=16)

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
                        save_baseline(self.baseline)  # บันทึกลง profile ผู้ใช้
                        self.timer.reset()
                        self.pending_calibration = False
                        self.status_label.configure(
                            text=f"Status: calibrated ✓  (saved for {self._username})"
                        )

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
                            self.status_label.configure(text="Status: ⚠ bad posture")
                            cv2.rectangle(
                                frame,
                                (0, 0),
                                (frame.shape[1] - 1, frame.shape[0] - 1),
                                (0, 0, 255),
                                4,
                            )
                        else:
                            self.status_label.configure(text="Status: ✓ good posture")

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
                self.status_label.configure(
                    text="Status: idle — sit upright then press Calibrate"
                )

        self.after(33, self._update_loop)
