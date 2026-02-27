# app.py — Entry point สำหรับ PyInstaller (.exe)
# ไฟล์นี้ใช้ absolute imports เพื่อให้ทำงานได้เมื่อ bundle เป็น .exe
from posture_guard.gui import PostureApp


def main():
    app = PostureApp()
    app.mainloop()


if __name__ == "__main__":
    main()
