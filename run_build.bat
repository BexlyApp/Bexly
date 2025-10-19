@echo off
cd /d D:\Projects\Bexly
D:\Dev\flutter\bin\flutter.bat pub run build_runner build --delete-conflicting-outputs
pause
