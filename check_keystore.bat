@echo off
echo === CHECKING KEYSTORE ALIASES ===
echo.
echo Listing all aliases in DOS-key.jks...
echo Password: DOSLabs
echo.
keytool -list -keystore "C:\Users\JOY\DOS-key.jks" -storepass DOSLabs
echo.
echo If you see the alias list above, update keystore.properties with the correct alias name.
pause