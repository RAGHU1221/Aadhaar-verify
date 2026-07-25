@echo off
REM ================================================================
REM  Textile Billing Software - build_exe.bat
REM  Indha file ah Windows PC la double-click pannunga (or run in
REM  Command Prompt) - adhu automatic-ah .exe file ah create pannidum.
REM ================================================================

echo Cleaning any old build files (so nothing old gets mixed in)...
if exist build rmdir /s /q build
if exist dist rmdir /s /q dist
if exist TextileBilling.spec del /q TextileBilling.spec

echo.
echo Installing required libraries (only needed once)...
pip install -r requirements.txt
pip install pyinstaller

echo.
echo Building the EXE file... please wait, this can take a few minutes
echo because of the camera/QR libraries...
pyinstaller --onefile --windowed --name "TextileBilling" --add-data "fonts;fonts" app.py

echo.
echo ================================================================
echo  DONE! Unga .exe file inga irukku:
echo  dist\TextileBilling.exe
echo ================================================================
pause
