@echo off
echo === SEARCHING FOR FLUTTER INSTALLATIONS ===
echo.

echo [1] Checking common Flutter locations...
echo.

if exist "C:\flutter\bin\flutter.bat" (
    echo Found at C:\flutter
    C:\flutter\bin\flutter --version
)

if exist "C:\src\flutter\bin\flutter.bat" (
    echo Found at C:\src\flutter
    C:\src\flutter\bin\flutter --version
)

if exist "C:\tools\flutter\bin\flutter.bat" (
    echo Found at C:\tools\flutter
    C:\tools\flutter\bin\flutter --version
)

if exist "%USERPROFILE%\flutter\bin\flutter.bat" (
    echo Found at %USERPROFILE%\flutter
    %USERPROFILE%\flutter\bin\flutter --version
)

if exist "C:\Program Files\flutter\bin\flutter.bat" (
    echo Found at Program Files
    "C:\Program Files\flutter\bin\flutter" --version
)

echo.
echo [2] Checking Android Studio Flutter...
if exist "%USERPROFILE%\AppData\Local\Android\flutter\bin\flutter.bat" (
    echo Found Android Studio Flutter
    %USERPROFILE%\AppData\Local\Android\flutter\bin\flutter --version
)

echo.
echo [3] Checking if Flutter in PATH...
where flutter 2>nul
if %errorlevel% == 0 (
    echo Flutter found in PATH!
    flutter --version
) else (
    echo Flutter not in PATH
)

echo.
pause