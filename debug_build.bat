@echo off
echo === BEXLY BUILD DEBUG ===
echo.
echo [1] Checking Flutter...
D:\Dev\flutter\bin\flutter --version
if errorlevel 1 (
    echo ERROR: Flutter not working!
    pause
    exit /b 1
)

echo.
echo [2] Cleaning project...
cd /d D:\Projects\DOSafe
D:\Dev\flutter\bin\flutter clean

echo.
echo [3] Getting packages...
D:\Dev\flutter\bin\flutter pub get
if errorlevel 1 (
    echo ERROR: pub get failed!
    pause
    exit /b 1
)

echo.
echo [4] Building APK...
D:\Dev\flutter\bin\flutter build apk --release --verbose
if errorlevel 1 (
    echo ERROR: Build failed!
    echo Check error above
    pause
    exit /b 1
)

echo.
echo BUILD SUCCESS!
pause