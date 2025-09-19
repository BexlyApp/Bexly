@echo off
echo ========================================
echo        BEXLY - Expense Tracker
echo ========================================
echo.
set PATH=%PATH%;D:\Dev\flutter\bin

echo [1] Checking Flutter installation...
flutter --version
echo.

echo [2] Installing dependencies...
flutter pub get
echo.

echo [3] Select run mode:
echo    1. Debug (with hot reload)
echo    2. Profile (performance testing)
echo    3. Release (optimized)
echo.
set /p mode="Enter choice (1-3, default 1): "
if "%mode%"=="" set mode=1

echo.
echo [4] Starting Bexly app...
if "%mode%"=="1" (
    echo Running in DEBUG mode...
    flutter run
) else if "%mode%"=="2" (
    echo Running in PROFILE mode...
    flutter run --profile
) else if "%mode%"=="3" (
    echo Running in RELEASE mode...
    flutter run --release
) else (
    echo Invalid choice, running in DEBUG mode...
    flutter run
)