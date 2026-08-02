@echo off
setlocal EnableExtensions DisableDelayedExpansion

REM ============================================================
REM AUTO FLASH BOOT_A + VBMETA_A VIA SPD_DUMP
REM Target:
REM   boot_a   <- boot\magisk_patched_boot.img
REM   vbmeta_a <- vbmeta\vbmeta_a_disabled.img
REM ============================================================

REM Lokasi root project berdasarkan lokasi file BAT
set "ROOT=%~dp0"

REM Hapus backslash terakhir
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

REM ============================================================
REM PATH FOLDER DAN TOOL
REM ============================================================

set "BROM_DIR=%ROOT%\brom"

set "SPD_DUMP=%BROM_DIR%\spd_dump.exe"
set "FDL1=%BROM_DIR%\fdl1-sign.bin"
set "FDL2=%BROM_DIR%\lk-fdl2-sign.bin"

REM ============================================================
REM PATH IMAGE PARTISI
REM ============================================================

set "BOOT_IMG=%ROOT%\boot\magisk_patched_boot.img"
set "VBMETA_IMG=%ROOT%\vbmeta\vbmeta_a_disabled.img"

REM ============================================================
REM INFORMASI
REM ============================================================

echo.
echo ============================================================
echo AUTO FLASH BOOT_A + VBMETA_A VIA SPD_DUMP
echo ============================================================
echo.
echo Project:
echo   "%ROOT%"
echo.
echo Target:
echo   boot_a
echo     "%BOOT_IMG%"
echo.
echo   vbmeta_a
echo     "%VBMETA_IMG%"
echo.

REM ============================================================
REM VALIDASI FILE
REM ============================================================

call :CHECK_FILE "%SPD_DUMP%" "spd_dump.exe"
if errorlevel 1 goto :ERROR

call :CHECK_FILE "%FDL1%" "fdl1-sign.bin"
if errorlevel 1 goto :ERROR

call :CHECK_FILE "%FDL2%" "lk-fdl2-sign.bin"
if errorlevel 1 goto :ERROR

call :CHECK_FILE "%BOOT_IMG%" "magisk_patched_boot.img"
if errorlevel 1 goto :ERROR

call :CHECK_FILE "%VBMETA_IMG%" "vbmeta_a_disabled.img"
if errorlevel 1 goto :ERROR

echo.
echo [OK] Semua file yang diperlukan ditemukan.
echo.

REM ============================================================
REM KONFIRMASI
REM ============================================================

echo ============================================================
echo PERINGATAN
echo ============================================================
echo.
echo Script ini akan menulis:
echo.
echo   boot_a
echo   vbmeta_a
echo.
echo Pastikan:
echo.
echo   1. Perangkat adalah Realme C53 RMX3760.
echo   2. Firmware sesuai dengan image di repository.
echo   3. Target partisi yang benar adalah slot A.
echo   4. Perangkat sudah masuk mode BROM.
echo.
choice /C YN /N /M "Lanjutkan proses flash"

if errorlevel 2 (
    echo.
    echo Proses dibatalkan oleh pengguna.
    exit /b 0
)

echo.
echo ============================================================
echo MENUNGGU DEVICE DALAM MODE BROM
echo ============================================================
echo.
echo Timeout: 300 detik
echo.

REM ============================================================
REM JALANKAN SPD_DUMP DARI FOLDER BROM
REM ============================================================

pushd "%BROM_DIR%"

(
    echo p
    echo set_active a
    echo size_part boot_a
    echo check_part boot_a
    echo check_part vbmeta_a
    echo w_force boot_a "%BOOT_IMG%"
    echo w_force vbmeta_a "%VBMETA_IMG%"
    echo reboot-fastboot
) | "%SPD_DUMP%" --wait 300 exec_addr 0x65015f08 fdl "%FDL1%" 0x65000800 fdl "%FDL2%" 0x9EFFFE00 exec

set "EXIT_CODE=%ERRORLEVEL%"

popd

REM ============================================================
REM HASIL PROSES
REM ============================================================

echo.
echo ============================================================
echo HASIL PROSES
echo ============================================================
echo.
echo Exit code: %EXIT_CODE%
echo.

if not "%EXIT_CODE%"=="0" (
    echo [ERROR] SPD_DUMP mengembalikan exit code bukan 0.
    goto :ERROR
)

echo [SUCCESS] SPD_DUMP selesai tanpa error pada exit code.
echo.
echo Periksa log di atas dan pastikan:
echo.
echo   - boot_a berhasil ditulis
echo   - vbmeta_a berhasil ditulis
echo   - reboot-fastboot berhasil dijalankan
echo.

pause
exit /b 0

REM ============================================================
REM FUNCTION: VALIDASI FILE
REM ============================================================

:CHECK_FILE
if exist "%~1" (
    echo [OK] %~2
    exit /b 0
)

echo.
echo [ERROR] %~2 tidak ditemukan:
echo "%~1"
exit /b 1

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