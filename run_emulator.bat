@echo off
echo === FLUTTER EMULATOR LAUNCHER ===
echo.

echo [1] Checking available emulators...
flutter emulators
echo.

echo [2] Checking connected devices...
flutter devices
echo.

echo If you see emulators above, run:
echo flutter emulators --launch [emulator_name]
echo.
echo Or create new emulator in Android Studio:
echo - Open Android Studio
echo - Tools -^> AVD Manager
echo - Create Virtual Device
echo.

echo [3] Run app directly (will auto-launch emulator if available):
set /p run="Run app now? (y/n): "
if /i "%run%"=="y" (
    echo Starting Flutter run...
    flutter run --release
)

pause