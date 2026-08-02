@echo off
setlocal EnableExtensions DisableDelayedExpansion
title RESTORE Realme C53 (RMX3760) - Stock Boot Only

REM ============================================================
REM  KONFIGURASI LOKASI FILE
REM ============================================================
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "BROM_DIR=%ROOT%\brom"
set "SPD_DUMP=%BROM_DIR%\spd_dump.exe"
set "FDL1=%BROM_DIR%\fdl1-sign.bin"
set "FDL2=%BROM_DIR%\lk-fdl2-sign.bin"

set "BOOT_IMG=%ROOT%\boot\stock_boot.img"

set "TMPDET=%TEMP%\root_detect.txt"

REM ============================================================
REM  WARNA ANSI
REM ============================================================
for /F %%i in ('echo prompt $E ^| cmd') do set "ESC=%%i"
set "B=%ESC%[1m"
set "DIM=%ESC%[2m"
set "G=%ESC%[32m"
set "Y=%ESC%[33m"
set "R=%ESC%[31m"
set "C=%ESC%[36m"
set "Z=%ESC%[0m"

REM ============================================================
REM  MULAI
REM ============================================================
call :BANNER

call :STEP 1 4 "Memeriksa file yang dibutuhkan"
call :CHECK_FILE "%SPD_DUMP%" "spd_dump.exe"
if errorlevel 1 goto :ERROR
call :CHECK_FILE "%FDL1%" "fdl1-sign.bin"
if errorlevel 1 goto :ERROR
call :CHECK_FILE "%FDL2%" "lk-fdl2-sign.bin"
if errorlevel 1 goto :ERROR
call :CHECK_FILE "%BOOT_IMG%" "stock_boot.img"
if errorlevel 1 goto :ERROR
call :OK "Semua file yang dibutuhkan tersedia."

call :STEP 2 4 "Mendeteksi perangkat BROM"
call :DETECT_DEVICE
if not "%DETECTED%"=="NONE" goto :DEV_OK
call :WARN "Perangkat belum terdeteksi di mode BROM."
echo.
echo   Masukkan HP ke mode download:
echo     %DIM%1. Matikan HP.%Z%
echo     %DIM%2. Tahan Volume + dan Volume - bersamaan.%Z%
echo     %DIM%3. Sambil menahan, colok kabel USB ke PC.%Z%
echo.
echo   Di Device Manager harus muncul:  %B%%G%SPRD U2S Diag (COMx)%Z%
echo.
echo   %B%Menunggu perangkat...%Z%
set /a CNT=0
:WAIT_DEV
set /a CNT+=1
call :DETECT_DEVICE
if not "%DETECTED%"=="NONE" goto :DEV_OK
if %CNT% geq 300 (
  call :ERR "Perangkat tidak terdeteksi setelah 300 detik."
  goto :ERROR
)
ping -n 2 127.0.0.1 >nul
goto :WAIT_DEV
:DEV_OK
call :OK "Perangkat terdeteksi: %DETECTED%"

call :STEP 3 4 "Konfirmasi"
echo.
echo   Akan menimpa partisi berikut:
echo     %B%boot_a%Z%   <--  boot\stock_boot.img
echo.
echo   %Y%vbmeta_a TIDAK diubah oleh script ini.%Z%
echo.
choice /C YN /N /M "   Lanjutkan restore (Y/N)"
if errorlevel 2 goto :ABORT
call :OK "Disetujui, memulai restore."

call :STEP 4 4 "Menjalankan restore via spd_dump"
echo.
echo   %R%%B%JANGAN cabut kabel USB sampai proses selesai!%Z%
echo.

(
  echo p
  echo set_active a
  echo w_force boot_a "%BOOT_IMG%"
  echo reboot-fastboot
) | "%SPD_DUMP%" --wait 300 exec_addr 0x65015f08 fdl "%FDL1%" 0x65000800 fdl "%FDL2%" 0x9EFFFE00 exec

set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
  call :ERR "spd_dump gagal (exit code %EXIT_CODE%)."
  goto :ERROR
)
call :OK "spd_dump selesai tanpa error."

echo.
echo   %G%%B%  RESTORE BOOT BERHASIL%Z%
echo.
echo   Perangkat sudah reboot ke fastboot.
echo   Langkah selanjutnya:
echo     %DIM%1. Boot ke Android (pilih reboot di fastboot)%Z%
echo.
pause
exit /b 0

:ABORT
call :WARN "Dibatalkan oleh pengguna."
pause
exit /b 0

:ERROR
echo.
echo   %R%%B%  PROSES GAGAL%Z%
echo.
pause
exit /b 1

REM ============================================================
REM  FUNGSI
REM ============================================================

:BANNER
cls
echo.
echo   %C%%B%====================================================%Z%
echo   %C%%B%  RESTORE REALME C53 (RMX3760)%Z%
echo   %C%%B%  STOCK BOOT ONLY - VIA BROM%Z%
echo   %C%%B%====================================================%Z%
echo.
echo   Tujuan : kembalikan boot_a ke stock (vbmeta_a tidak disentuh)
echo   Slot   : A
echo.
exit /b 0

:STEP
echo.
echo   %C%%B%[ Langkah %1/%2 ]%Z%  %~3
echo.
exit /b 0

:OK
set "MSG=%*"
set "MSG=%MSG:"=%"
echo   %G%[ OK ]%Z%  %MSG%
exit /b 0

:WARN
set "MSG=%*"
set "MSG=%MSG:"=%"
echo   %Y%[ ! ]%Z%  %MSG%
exit /b 0

:ERR
set "MSG=%*"
set "MSG=%MSG:"=%"
echo   %R%[ X ]%Z%  %MSG%
exit /b 0

:CHECK_FILE
if exist "%~1" (
  call :OK "%~2"
  exit /b 0
)
call :ERR "%~2 tidak ditemukan: %~1"
exit /b 1

:DETECT_DEVICE
set "DETECTED=NONE"
if exist "%TMPDET%" del "%TMPDET%" 2>nul
powershell -NoProfile -Command "$d = Get-CimInstance Win32_PnPEntity -ErrorAction SilentlyContinue | Where-Object { $_.Name -match 'SPRD' } | Select-Object -First 1 -ExpandProperty Name; if ($d) { $d } else { 'NONE' }" > "%TMPDET%" 2>nul
set /p DETECTED= < "%TMPDET%"
if "%DETECTED%"=="" set "DETECTED=NONE"
exit /b 0
