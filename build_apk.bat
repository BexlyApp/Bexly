@echo off
echo Building Bexly APK...
cd /d D:\Projects\DOSafe
set PATH=D:\Dev\flutter\bin;%PATH%
flutter build apk --verbose
echo.
echo Build complete! Check: build\app\outputs\flutter-apk\
pause