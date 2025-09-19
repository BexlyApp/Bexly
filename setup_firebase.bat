@echo off
echo ===================================
echo    FIREBASE SETUP FOR POCKAW
echo ===================================
echo.

REM Check Flutter installation
echo [1] Checking Flutter installation...
D:\Dev\flutter\bin\flutter --version
if %errorlevel% neq 0 (
    echo ERROR: Flutter not found!
    pause
    exit /b 1
)

echo.
echo [2] Installing Firebase dependencies...
D:\Dev\flutter\bin\flutter pub get
if %errorlevel% neq 0 (
    echo ERROR: Failed to install dependencies!
    pause
    exit /b 1
)

echo.
echo [3] Activating FlutterFire CLI...
D:\Dev\flutter\bin\dart pub global activate flutterfire_cli
if %errorlevel% neq 0 (
    echo ERROR: Failed to activate FlutterFire CLI!
    pause
    exit /b 1
)

echo.
echo [4] Running FlutterFire configure...
echo.
echo NOTE: You'll need to:
echo - Login to Firebase (if not already)
echo - Select or create a Firebase project
echo - Select platforms (Android, iOS, Web)
echo.
pause

REM Run FlutterFire configure
C:\Users\%USERNAME%\AppData\Local\Pub\Cache\bin\flutterfire configure ^
    --project=pockaw-app ^
    --platforms=android,ios,web ^
    --android-package-name=com.pockaw.app

if %errorlevel% neq 0 (
    echo.
    echo If FlutterFire is not found, try running:
    echo flutterfire configure --project=pockaw-app --platforms=android,ios,web
    echo.
    echo Or without project specification:
    echo flutterfire configure
)

echo.
echo [5] Building app to test...
D:\Dev\flutter\bin\flutter build apk --debug

echo.
echo ===================================
echo    SETUP COMPLETE!
echo ===================================
echo.
echo Next steps:
echo 1. Check firebase_options.dart was created
echo 2. Run the app to test Firebase connection
echo 3. Test backup/restore features
echo.
pause