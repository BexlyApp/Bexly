@echo off
echo === FLUTTER DIRECT TEST ===
echo.

echo [1] Testing with CALL command...
call D:\Dev\flutter\bin\flutter.bat --version
echo Exit code: %errorlevel%

echo.
echo [2] Testing dart.exe directly...
if exist "D:\Dev\flutter\bin\cache\dart-sdk\bin\dart.exe" (
    D:\Dev\flutter\bin\cache\dart-sdk\bin\dart.exe --version
) else (
    echo Dart.exe not found in cache!
)

echo.
echo [3] Checking Flutter structure...
dir D:\Dev\flutter\bin\*.bat
echo.
dir D:\Dev\flutter\bin\cache\

echo.
echo [4] Try running with full path and extension...
"D:\Dev\flutter\bin\flutter.bat" doctor

echo.
pause