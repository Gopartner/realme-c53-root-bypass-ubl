@echo off
setlocal EnableExtensions DisableDelayedExpansion
title ROOT Realme C53 (RMX3760) - Flash via BROM

REM ============================================================
REM  KONFIGURASI LOKASI FILE
REM ============================================================
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "BROM_DIR=%ROOT%\brom"
set "SPD_DUMP=%BROM_DIR%\spd_dump.exe"
set "FDL1=%BROM_DIR%\fdl1-sign.bin"
set "FDL2=%BROM_DIR%\lk-fdl2-sign.bin"

set "BOOT_IMG=%ROOT%\boot\magisk_patched_boot.img"
set "VBMETA_IMG=%ROOT%\vbmeta\vbmeta_a_disabled.img"
set "VER_DIR=%ROOT%\verify_out"

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

call :STEP 1 6 "Memeriksa file yang dibutuhkan"
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
call :OK "Semua file yang dibutuhkan tersedia."

call :STEP 2 6 "Mendeteksi perangkat BROM"
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

call :STEP 3 6 "Konfirmasi"
echo.
echo   Akan menimpa partisi berikut:
echo     %B%boot_a%Z%   <--  boot\magisk_patched_boot.img
echo     %B%vbmeta_a%Z% <--  vbmeta\vbmeta_a_disabled.img
echo.
choice /C YN /N /M "   Lanjutkan flash sekarang (Y/N)"
if errorlevel 2 goto :ABORT
call :OK "Disetujui, memulai flash."

call :STEP 4 6 "Menjalankan flash via spd_dump"
echo.
echo   %DIM%Urutan: BROM > FDL1 > FDL2 > set_active a >%Z%
echo   %DIM%          w_force boot_a + vbmeta_a > read-back > reboot-fastboot%Z%
echo.
echo   %R%%B%JANGAN cabut kabel USB sampai proses selesai!%Z%
echo.
if not exist "%VER_DIR%" mkdir "%VER_DIR%"

(
  echo p
  echo set_active a
  echo size_part boot_a
  echo check_part boot_a
  echo check_part vbmeta_a
  echo w_force boot_a "%BOOT_IMG%"
  echo w_force vbmeta_a "%VBMETA_IMG%"
  echo read_part boot_a 0 67108864 "%VER_DIR%\verify_root_boot_a.img"
  echo read_part vbmeta_a 0 1048576 "%VER_DIR%\verify_root_vbmeta_a.img"
  echo reboot-fastboot
) | "%SPD_DUMP%" --wait 300 exec_addr 0x65015f08 fdl "%FDL1%" 0x65000800 fdl "%FDL2%" 0x9EFFFE00 exec

set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
  call :ERR "spd_dump gagal (exit code %EXIT_CODE%)."
  goto :ERROR
)
call :OK "spd_dump selesai tanpa error."

call :STEP 5 6 "Memverifikasi hasil flash (read-back)"
call :VERIFY_IMG "%VER_DIR%\verify_root_boot_a.img" "%BOOT_IMG%" "boot_a"
call :VERIFY_IMG "%VER_DIR%\verify_root_vbmeta_a.img" "%VBMETA_IMG%" "vbmeta_a"

call :STEP 6 6 "Selesai"
echo.
echo   %G%%B%  FLASH BERHASIL%Z%
echo.
echo   Perangkat sudah reboot ke fastboot.
echo   Langkah selanjutnya:
echo     %DIM%1. Boot ke Android (pilih reboot di fastboot)%Z%
echo     %DIM%2. Buka aplikasi Magisk - status harus Installed%Z%
echo     %DIM%3. Verifikasi root: adb shell su -c id  ->  uid=0(root)%Z%
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
echo   %C%%B%  ROOT REALME C53 (RMX3760) - FLASH VIA BROM%Z%
echo   %C%%B%====================================================%Z%
echo.
echo   Metode : bypass UBL (tanpa unlock bootloader)
echo   Slot   : A
echo   Root   : Magisk patched boot
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

:VERIFY_IMG
set "VF=%~1"
set "TF=%~2"
set "PN=%~3"
if not exist "%VF%" (
  call :WARN "%PN%: file verify tidak ada (%VF%)"
  exit /b 0
)
if exist "%TMPDET%" del "%TMPDET%" 2>nul
powershell -NoProfile -Command "$a=(Get-FileHash '%VF%' -Algorithm SHA1).Hash; $b=(Get-FileHash '%TF%' -Algorithm SHA1).Hash; if($a -eq $b){'MATCH'}else{'DIFF'}" > "%TMPDET%" 2>nul
set /p HRES= < "%TMPDET%"
if /i "%HRES%"=="MATCH" (
  call :OK "%PN% cocok dengan file bahan."
) else (
  call :WARN "%PN% BERBEDA dengan file bahan - periksa!"
)
exit /b 0
