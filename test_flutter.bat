@echo off
echo Testing Flutter paths...
echo.

if exist "D:\Dev\flutter\bin\flutter.bat" (
    echo Flutter.bat EXISTS
) else (
    echo Flutter.bat NOT FOUND!
)

if exist "D:\flutter\bin\flutter.bat" (
    echo Found Flutter at D:\flutter\bin\
    D:\flutter\bin\flutter --version
) else if exist "C:\flutter\bin\flutter.bat" (
    echo Found Flutter at C:\flutter\bin\
    C:\flutter\bin\flutter --version
) else if exist "C:\src\flutter\bin\flutter.bat" (
    echo Found Flutter at C:\src\flutter\bin\
    C:\src\flutter\bin\flutter --version
) else (
    echo Flutter not found in common locations!
)

echo.
echo Press any key to exit...
pause > nul