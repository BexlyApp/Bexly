@echo off
echo ===================================
echo    FLUTTER COMMANDS RUNNER
echo ===================================
echo.

if "%1"=="" (
    echo Usage: run_commands.bat [command]
    echo.
    echo Available commands:
    echo   pub-get       - Install dependencies
    echo   build-apk     - Build APK
    echo   build-runner  - Run code generation
    echo   analyze       - Analyze code
    echo   test          - Run tests
    echo   clean         - Clean project
    echo   doctor        - Check Flutter setup
    echo   run           - Run app
    echo   firebase      - Setup Firebase
    echo.
    exit /b 0
)

set FLUTTER_PATH=D:\Dev\flutter\bin\flutter.bat

if "%1"=="pub-get" (
    echo Running: flutter pub get
    %FLUTTER_PATH% pub get
    exit /b %errorlevel%
)

if "%1"=="build-apk" (
    echo Running: flutter build apk
    %FLUTTER_PATH% build apk
    exit /b %errorlevel%
)

if "%1"=="build-runner" (
    echo Running: dart run build_runner build
    D:\Dev\flutter\bin\dart run build_runner build --delete-conflicting-outputs
    exit /b %errorlevel%
)

if "%1"=="analyze" (
    echo Running: flutter analyze
    %FLUTTER_PATH% analyze
    exit /b %errorlevel%
)

if "%1"=="test" (
    echo Running: flutter test
    %FLUTTER_PATH% test
    exit /b %errorlevel%
)

if "%1"=="clean" (
    echo Running: flutter clean
    %FLUTTER_PATH% clean
    exit /b %errorlevel%
)

if "%1"=="doctor" (
    echo Running: flutter doctor
    %FLUTTER_PATH% doctor -v
    exit /b %errorlevel%
)

if "%1"=="run" (
    echo Running: flutter run
    %FLUTTER_PATH% run
    exit /b %errorlevel%
)

if "%1"=="firebase" (
    echo Running Firebase setup...
    call setup_firebase.bat
    exit /b %errorlevel%
)

echo Unknown command: %1
exit /b 1