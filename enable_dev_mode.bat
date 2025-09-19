@echo off
echo === ENABLE DEVELOPER MODE ===
echo.
echo Opening Windows Developer Settings...
start ms-settings:developers
echo.
echo Please:
echo 1. Toggle "Developer Mode" to ON
echo 2. Wait for it to enable
echo 3. Then come back and press any key
echo.
pause
echo.
echo Now building APK...
cd /d D:\Projects\DOSafe
flutter build apk --release
pause