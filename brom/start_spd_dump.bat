@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM ============================================================
REM START SPD_DUMP - MANUAL FDL2 MODE
REM ============================================================

REM Selalu jalankan dari folder tempat file BAT ini berada
cd /d "%~dp0"

REM ============================================================
REM PATH FILE
REM ============================================================

set "SPD_DUMP=%CD%\spd_dump.exe"
set "FDL1=%CD%\fdl1-sign.bin"
set "FDL2=%CD%\lk-fdl2-sign.bin"

REM ============================================================
REM INFORMASI
REM ============================================================

echo.
echo ============================================================
echo MENJALANKAN SPD_DUMP - MODE MANUAL FDL2
echo ============================================================
echo.
echo Folder BROM:
echo   "%CD%"
echo.
echo Timeout:
echo   300 detik
echo.

REM ============================================================
REM VALIDASI FILE
REM ============================================================

if not exist "%SPD_DUMP%" (
    echo [ERROR] spd_dump.exe tidak ditemukan:
    echo   "%SPD_DUMP%"
    goto :ERROR
)

if not exist "%FDL1%" (
    echo [ERROR] fdl1-sign.bin tidak ditemukan:
    echo   "%FDL1%"
    goto :ERROR
)

if not exist "%FDL2%" (
    echo [ERROR] lk-fdl2-sign.bin tidak ditemukan:
    echo   "%FDL2%"
    goto :ERROR
)

echo [OK] spd_dump.exe ditemukan.
echo [OK] fdl1-sign.bin ditemukan.
echo [OK] lk-fdl2-sign.bin ditemukan.
echo.

REM ============================================================
REM JALANKAN SPD_DUMP
REM ============================================================

echo ============================================================
echo MENUNGGU DEVICE DALAM MODE BROM
echo ============================================================
echo.
echo Pastikan perangkat sudah:
echo.
echo   1. Dalam keadaan mati.
echo   2. Menekan Volume Up + Volume Down.
echo   3. Terhubung ke komputer melalui USB.
echo.
echo Tunggu sampai prompt berikut muncul:
echo.
echo   FDL2^>
echo.
echo Setelah muncul FDL2^>, ketik atau paste perintah manual
echo dari README.md.
echo.

"%SPD_DUMP%" --wait 300 exec_addr 0x65015f08 fdl "%FDL1%" 0x65000800 fdl "%FDL2%" 0x9EFFFE00 exec

set "EXIT_CODE=%ERRORLEVEL%"

REM ============================================================
REM HASIL PROSES
REM ============================================================

echo.
echo ============================================================
echo PROSES SPD_DUMP SELESAI
echo ============================================================
echo.
echo Exit code: %EXIT_CODE%
echo.

if not "%EXIT_CODE%"=="0" (
    echo [ERROR] SPD_DUMP berhenti dengan exit code bukan 0.
    goto :ERROR
)

echo [SUCCESS] SPD_DUMP selesai tanpa error pada exit code.
echo.

pause
exit /b 0

REM ============================================================
REM ERROR HANDLER
REM ============================================================

:ERROR
echo.
echo ============================================================
echo PROSES GAGAL
echo ============================================================
echo.
pause
exit /b 1