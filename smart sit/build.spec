# build.spec — PyInstaller spec file สำหรับแพ็ก SmartSit เป็น .exe
# วิธีใช้: pyinstaller build.spec

block_cipher = None

a = Analysis(
    ['app.py'],
    pathex=['.'],
    binaries=[
        ('D:/web/smart sit/.venv/Lib/site-packages/mediapipe/tasks/c/libmediapipe.dll', 'mediapipe/tasks/c'),
    ],
    datas=[
        ('models/pose_landmarker_lite.task', 'models'),
        ('company_config.json', '.'),
        ('D:/web/smart sit/.venv/Lib/site-packages/mediapipe/tasks/c/__init__.py', 'mediapipe/tasks/c'),
    ],
    hiddenimports=[
        'mediapipe',
        'mediapipe.tasks',
        'mediapipe.tasks.c',
        'mediapipe.tasks.python',
        'mediapipe.tasks.python.core',
        'mediapipe.tasks.python.core.mediapipe_c_bindings',
        'mediapipe.tasks.python.core.mediapipe_c_utils',
        'mediapipe.tasks.python.vision',
        'mediapipe.tasks.python.vision.pose_landmarker',
        'customtkinter',
        'PIL._tkinter_finder',
    ],
    hookspath=[],
    hooksconfig={},
    runtime_hooks=[],
    excludes=[],
    win_no_prefer_redirects=False,
    win_private_assemblies=False,
    cipher=block_cipher,
    noarchive=False,
)

pyz = PYZ(a.pure, a.zipped_data, cipher=block_cipher)

exe = EXE(
    pyz,
    a.scripts,
    [],
    exclude_binaries=True,
    name='SmartSit',
    debug=False,
    bootloader_ignore_signals=False,
    strip=False,
    upx=True,
    console=False,          # ไม่แสดง console window
    disable_windowed_traceback=False,
    argv_emulation=False,
    target_arch=None,
    codesign_identity=None,
    entitlements_file=None,
)

coll = COLLECT(
    exe,
    a.binaries,
    a.zipfiles,
    a.datas,
    strip=False,
    upx=True,
    upx_exclude=[],
    name='SmartSit',
)
