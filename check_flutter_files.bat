@echo off
echo === CHECKING FLUTTER INSTALLATION ===
echo.

echo [1] Flutter.bat size:
for %%A in (D:\Dev\flutter\bin\flutter.bat) do echo Size: %%~zA bytes
echo.

echo [2] Checking critical files...
if exist "D:\Dev\flutter\bin\dart.bat" (
    echo - dart.bat: FOUND
) else (
    echo - dart.bat: MISSING!
)

if exist "D:\Dev\flutter\packages\flutter_tools\bin\flutter_tools.dart" (
    echo - flutter_tools.dart: FOUND
) else (
    echo - flutter_tools.dart: MISSING!
)

if exist "D:\Dev\flutter\bin\cache\dart-sdk\bin\dart.exe" (
    echo - dart.exe: FOUND
    for %%A in (D:\Dev\flutter\bin\cache\dart-sdk\bin\dart.exe) do echo   Size: %%~zA bytes
) else (
    echo - dart.exe: MISSING! Need to download
)

echo.
echo [3] Flutter folder size:
dir D:\Dev\flutter /s | findstr "File(s)"

echo.
echo [4] Try to initialize Flutter...
cd /d D:\Dev\flutter
if exist "D:\Dev\flutter\bin\flutter.bat" (
    echo Running: flutter doctor -v
    call bin\flutter.bat doctor -v
)

echo.
pause