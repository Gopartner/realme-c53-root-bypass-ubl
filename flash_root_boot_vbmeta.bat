@echo off
setlocal EnableExtensions

REM ============================================================
REM AUTO FLASH BOOT_A + VBMETA_A VIA SPD_DUMP
REM ============================================================

REM Lokasi folder project berdasarkan lokasi file BAT
set "ROOT=%~dp0"

REM Hapus backslash terakhir
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

REM ============================================================
REM PATH TOOL BROM
REM ============================================================

set "BROM_DIR=%ROOT%\brom"

set "SPD_DUMP=%BROM_DIR%\spd_dump.exe"
set "FDL1=%BROM_DIR%\fdl1-sign.bin"
set "FDL2=%BROM_DIR%\lk-fdl2-sign.bin"

REM ============================================================
REM PATH FILE PARTISI
REM ============================================================

set "BOOT_IMG=%ROOT%\boot\magisk_patched_boot.img"
set "VBMETA_IMG=%ROOT%\vbmeta\vbmeta_a_disabled.img"

REM ============================================================
REM INFORMASI
REM ============================================================

echo ============================================================
echo AUTO FLASH BOOT_A + VBMETA_A
echo ============================================================
echo.
echo Project:
echo "%ROOT%"
echo.
echo Target:
echo.
echo BOOT_A:
echo "%BOOT_IMG%"
echo.
echo VBMETA_A:
echo "%VBMETA_IMG%"
echo.

REM ============================================================
REM VALIDASI TOOL
REM ============================================================

if not exist "%SPD_DUMP%" (
    echo [ERROR] spd_dump.exe tidak ditemukan:
    echo "%SPD_DUMP%"
    goto :ERROR
)

if not exist "%FDL1%" (
    echo [ERROR] fdl1-sign.bin tidak ditemukan:
    echo "%FDL1%"
    goto :ERROR
)

if not exist "%FDL2%" (
    echo [ERROR] lk-fdl2-sign.bin tidak ditemukan:
    echo "%FDL2%"
    goto :ERROR
)

REM ============================================================
REM VALIDASI IMAGE
REM ============================================================

if not exist "%BOOT_IMG%" (
    echo [ERROR] magisk_patched_boot.img tidak ditemukan:
    echo "%BOOT_IMG%"
    goto :ERROR
)

if not exist "%VBMETA_IMG%" (
    echo [ERROR] vbmeta_a_disabled.img tidak ditemukan:
    echo "%VBMETA_IMG%"
    goto :ERROR
)

echo [OK] Semua file ditemukan.
echo.

echo ============================================================
echo MENUNGGU DEVICE DALAM MODE BROM
echo ============================================================
echo.
echo Timeout: 300 detik
echo.

REM ============================================================
REM KIRIM PERINTAH KE FDL2
REM ============================================================

(
    REM Tampilkan daftar partisi
    echo p

    REM Cek ukuran boot_a
    echo size_part boot_a

    REM Pastikan vbmeta_a tersedia
    echo check_part vbmeta_a

    REM Aktifkan slot A
    echo set_active a

    REM Flash boot hasil Magisk
    echo w_force boot_a "%BOOT_IMG%"

    REM Flash vbmeta disabled
    echo w_force vbmeta_a "%VBMETA_IMG%"

    REM Reboot ke fastboot
    echo reboot-fastboot

) | "%SPD_DUMP%" --wait 300 exec_addr 0x65015f08 fdl "%FDL1%" 0x65000800 fdl "%FDL2%" 0x9EFFFE00 exec

set "EXIT_CODE=%ERRORLEVEL%"

echo.
echo ============================================================
echo PROSES SELESAI
echo ============================================================
echo Exit code: %EXIT_CODE%
echo.

if not "%EXIT_CODE%"=="0" (
    echo [ERROR] SPD_DUMP mengembalikan error.
    goto :ERROR
)

echo [SUCCESS] Perintah flash telah dikirim.
echo.
echo Periksa output di atas untuk memastikan:
echo.
echo   - boot_a berhasil ditulis
echo   - vbmeta_a berhasil ditulis
echo   - reboot-fastboot berhasil dijalankan
echo.

pause
exit /b 0


:ERROR
echo.
echo ============================================================
echo PROSES GAGAL
echo ============================================================
echo.
pause
exit /b 1