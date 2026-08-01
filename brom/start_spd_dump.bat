@echo off
setlocal

echo ==========================================
echo Menjalankan SPD Dump
echo ==========================================
echo.

.\spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl .\fdl1-sign.bin 0x65000800 fdl .\lk-fdl2-sign.bin 0x9EFFFE00 exec

echo.
echo ==========================================
echo Proses selesai
echo Exit code: %ERRORLEVEL%
echo ==========================================
echo.

pause
endlocal