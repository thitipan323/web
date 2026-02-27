import sys
import os

# รองรับทั้งโหมด frozen (.exe) และ development (python -m)
if getattr(sys, 'frozen', False):
    # กำลังรันจาก .exe ที่ PyInstaller สร้าง
    from posture_guard.gui import PostureApp
else:
    # กำลังรันจาก source ปกติ
    from .gui import PostureApp


def main():
    app = PostureApp()
    app.mainloop()


if __name__ == "__main__":
    main()
