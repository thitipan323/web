# Posture Guard

A desktop posture monitoring app that uses MediaPipe Pose to detect shoulder tilt and forward head posture, then alerts after a sustained bad posture window.

## Requirements

- Python 3.9+ recommended
- Webcam

## Setup

1. Create and activate a virtual environment.
2. Install dependencies:

```bash
pip install -r requirements.txt
```

## Run (Development)

```bash
python -m posture_guard.main
```

## Build as .exe (Company Deployment — Option 1)

```bash
# ติดตั้ง PyInstaller (ถ้ายังไม่ได้ติดตั้ง)
pip install pyinstaller

# Build
pyinstaller build.spec
```

ไฟล์ `.exe` จะอยู่ที่ `dist/SmartSit/SmartSit.exe`

### แจกให้พนักงาน

1. คัดลอกโฟลเดอร์ `dist/SmartSit/` ทั้งโฟลเดอร์
2. แก้ไข `company_config.json` ในโฟลเดอร์นั้นก่อนแจก (ตั้งค่า threshold / เวลาเตือนตามนโยบายบริษัท)
3. พนักงานแต่ละคนรัน `SmartSit.exe` ได้เลย ไม่ต้องติดตั้ง Python

## Notes

- กด **Calibrate** ครั้งแรกขณะนั่งตัวตรง ระบบจะจำค่าอ้างอิงของผู้ใช้คนนั้น
- ค่า Calibration ถูกบันทึกในเครื่อง (`AppData/SmartSit/`) ไม่ต้อง Calibrate ใหม่ทุกครั้ง
- Log บันทึกไว้ที่ `AppData/SmartSit/logs/events.csv` และ `events.json` ของผู้ใช้แต่ละคน
- IT สามารถกำหนดค่าเริ่มต้นผ่าน `company_config.json` ในโฟลเดอร์เดียวกับ `.exe`
