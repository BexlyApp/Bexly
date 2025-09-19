@echo off
echo === FLUTTER DIAGNOSIS ===
echo.

echo [1] Flutter.bat content (should be script):
type D:\Dev\flutter\bin\flutter.bat | findstr /n "^" | findstr "1: 2: 3:"
echo.

echo [2] Check if Dart SDK exists:
if exist "D:\Dev\flutter\bin\cache\dart-sdk\bin\dart.exe" (
    echo Dart SDK: FOUND
    D:\Dev\flutter\bin\cache\dart-sdk\bin\dart.exe --version
) else (
    echo Dart SDK: NOT FOUND - Need to run flutter once to download
    echo.
    echo [3] Initializing Flutter (will download Dart SDK)...
    cd /d D:\Dev\flutter
    bin\flutter.bat --version
)

echo.
echo [4] Check environment:
echo FLUTTER_ROOT = %FLUTTER_ROOT%
echo PATH contains Flutter = %PATH% | findstr /i flutter

echo.
echo [5] Try direct execution:
cd /d D:\Projects\DOSafe
call D:\Dev\flutter\bin\flutter.bat doctor -v

echo.
pause