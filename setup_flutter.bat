@echo off
echo === FLUTTER 3.35.4 SETUP ===
echo.

echo [1] Downloading Flutter SDK...
cd /d D:\
powershell -Command "Invoke-WebRequest -Uri 'https://storage.googleapis.com/flutter_infra_release/releases/stable/windows/flutter_windows_3.35.4-stable.zip' -OutFile 'flutter_new.zip'"

echo.
echo [2] Removing old Flutter...
if exist "D:\Dev\flutter" (
    echo Removing old installation...
    rmdir /s /q "D:\Dev\flutter"
)

echo.
echo [3] Extracting new Flutter...
powershell -Command "Expand-Archive -Path 'D:\flutter_new.zip' -DestinationPath 'D:\Dev' -Force"

echo.
echo [4] Verifying installation...
if exist "D:\Dev\flutter\bin\flutter.bat" (
    echo Flutter extracted successfully!
    for %%A in (D:\Dev\flutter\bin\flutter.bat) do echo Flutter.bat size: %%~zA bytes
) else (
    echo ERROR: Flutter not extracted properly!
    pause
    exit /b 1
)

echo.
echo [5] Running Flutter doctor...
call D:\Dev\flutter\bin\flutter.bat doctor

echo.
echo [6] Cleaning up...
del D:\flutter_new.zip

echo.
echo Flutter 3.35.4 installed successfully!
echo Now you can build your app with:
echo D:\Dev\flutter\bin\flutter build apk
echo.
pause