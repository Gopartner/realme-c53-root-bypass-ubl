@echo off
setlocal EnableExtensions DisableDelayedExpansion
title RESTORE ALL - Realme C53 (RMX3760) - Stock boot/vbmeta/init_boot

REM ============================================================
REM  KONFIGURASI LOKASI (JANGAN DIUBAH)
REM ============================================================
set "ROOT=%~dp0"
if "%ROOT:~-1%"=="\" set "ROOT=%ROOT:~0,-1%"

set "BROM_DIR=%ROOT%\brom"
set "SPD_DUMP=%BROM_DIR%\spd_dump.exe"
set "FDL1=%BROM_DIR%\fdl1-sign.bin"
set "FDL2=%BROM_DIR%\lk-fdl2-sign.bin"
set "VER_DIR=%ROOT%\verify_out"
set "TMPDET=%TEMP%\root_detect.txt"

REM  --- Bahan stock untuk restore (semua) ---
set "BOOT_IMG=%ROOT%\boot\stock_boot.img"
set "VBMETA_IMG=%ROOT%\vbmeta\vbmeta_a_original.img"
set "INITBOOT_IMG=%ROOT%\boot\init_boot_a.img"

for /F %%i in ('echo prompt $E ^| cmd') do set "ESC=%%i"
set "B=%ESC%[1m"
set "DIM=%ESC%[2m"
set "G=%ESC%[32m"
set "Y=%ESC%[33m"
set "R=%ESC%[31m"
set "C=%ESC%[36m"
set "Z=%ESC%[0m"

call :BANNER

call :STEP 1 5 "Memeriksa file yang dibutuhkan"
call :CHECK_FILE "%SPD_DUMP%" "spd_dump.exe"
if errorlevel 1 goto :ERROR
call :CHECK_FILE "%FDL1%" "fdl1-sign.bin"
if errorlevel 1 goto :ERROR
call :CHECK_FILE "%FDL2%" "lk-fdl2-sign.bin"
if errorlevel 1 goto :ERROR
call :CHECK_FILE "%BOOT_IMG%" "stock boot"
if errorlevel 1 goto :ERROR
call :CHECK_FILE "%VBMETA_IMG%" "stock vbmeta"
if errorlevel 1 goto :ERROR
call :CHECK_FILE "%INITBOOT_IMG%" "stock init_boot"
if errorlevel 1 goto :ERROR
call :OK "Semua file stock tersedia."

call :STEP 2 5 "Mendeteksi perangkat BROM"
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

call :STEP 3 5 "Konfirmasi"
echo.
echo   Akan menimpa partisi berikut (SEMUA ke stock):
echo     %B%boot_a%Z%        ^<--  boot\stock_boot.img
echo     %B%vbmeta_a%Z%      ^<--  vbmeta\vbmeta_a_original.img
echo     %B%init_boot_a%Z%   ^<--  boot\init_boot_a.img
echo.
choice /C YN /N /M "   Lanjutkan restore semua (Y/N)"
if errorlevel 2 goto :ABORT
call :OK "Disetujui, memulai restore."

call :STEP 4 5 "Menjalankan restore via spd_dump"
echo.
echo   %R%%B%JANGAN cabut kabel USB sampai proses selesai!%Z%
echo.
if not exist "%VER_DIR%" mkdir "%VER_DIR%"

for %%F in ("%BOOT_IMG%")     do set "BOOT_SIZE=%%~zF"
for %%F in ("%INITBOOT_IMG%") do set "INITBOOT_SIZE=%%~zF"

(
  echo p
  echo set_active a
  echo size_part boot_a
  echo check_part boot_a
  echo w_force boot_a "%BOOT_IMG%"
  echo read_part boot_a 0 %BOOT_SIZE% "%VER_DIR%\verify_boot_a.img"
  echo check_part vbmeta_a
  echo w_force vbmeta_a "%VBMETA_IMG%"
  echo read_part vbmeta_a 0 1048576 "%VER_DIR%\verify_vbmeta_a.img"
  echo check_part init_boot_a
  echo w_force init_boot_a "%INITBOOT_IMG%"
  echo read_part init_boot_a 0 %INITBOOT_SIZE% "%VER_DIR%\verify_init_boot_a.img"
  echo reboot-fastboot
) | "%SPD_DUMP%" --wait 300 exec_addr 0x65015f08 fdl "%FDL1%" 0x65000800 fdl "%FDL2%" 0x9EFFFE00 exec

set "EXIT_CODE=%ERRORLEVEL%"
if not "%EXIT_CODE%"=="0" (
  call :ERR "spd_dump gagal (exit code %EXIT_CODE%)."
  goto :ERROR
)
call :OK "spd_dump selesai tanpa error."

call :STEP 5 5 "Memverifikasi hasil restore (read-back)"
call :VERIFY_IMG "%VER_DIR%\verify_boot_a.img" "%BOOT_IMG%" "boot_a"
call :VERIFY_IMG "%VER_DIR%\verify_vbmeta_a.img" "%VBMETA_IMG%" "vbmeta_a"
call :VERIFY_IMG "%VER_DIR%\verify_init_boot_a.img" "%INITBOOT_IMG%" "init_boot_a"

echo.
echo   %G%%B%  RESTORE ALL BERHASIL%Z%
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

:BANNER
cls
echo.
echo   %C%%B%====================================================%Z%
echo   %C%%B%  RESTORE ALL - REALME C53 (RMX3760)%Z%
echo   %C%%B%  Kembalikan boot + vbmeta + init_boot ke stock%Z%
echo   %C%%B%====================================================%Z%
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
