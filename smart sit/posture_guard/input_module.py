import cv2


class CameraInput:
    def __init__(self, config):
        self.config = config
        self.capture = None

    def open(self):
        if self.capture is None:
            self.capture = cv2.VideoCapture(self.config.camera_index)
            self.capture.set(cv2.CAP_PROP_FRAME_WIDTH, self.config.frame_width)
            self.capture.set(cv2.CAP_PROP_FRAME_HEIGHT, self.config.frame_height)

    def read_frame(self):
        if self.capture is None:
            return None
        ok, frame = self.capture.read()
        if not ok:
            return None
        if self.config.frame_width and self.config.frame_height:
            frame = cv2.resize(frame, (self.config.frame_width, self.config.frame_height))
        return frame

    def release(self):
        if self.capture is not None:
            self.capture.release()
            self.capture = None
