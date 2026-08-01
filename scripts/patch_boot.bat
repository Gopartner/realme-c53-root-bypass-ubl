@echo off
REM ================================================================
REM  SCRIPT: Patch stock boot dengan Magisk (metode CLI, tanpa buka app)
REM
REM  Cara pakai:
REM    scripts\patch_boot.bat <boot.img> [Magisk.apk]
REM
REM  Contoh:
REM    scripts\patch_boot.bat boot\stock_boot.img
REM    scripts\patch_boot.bat D:\punya_sendiri\boot.img C:\Downloads\Magisk.apk
REM
REM  Prasyarat:
REM    - Device terhubung adb (adb devices harus muncul)
REM    - Boot image sesuai build/device yang sama
REM    - (opsional) path Magisk APK; default: D:\realme-c53-recovery\01_alat\Magisk-v30.7.apk
REM
REM  Hasil: new-boot.img (boot patched) ditarik ke folder yang sama dengan boot input.
REM ================================================================
setlocal
set "BOOT=%~1"
set "APK=%~2"
if "%BOOT%"=="" (
  echo ERROR: tidak ada boot image input.
  echo Pakai: scripts\patch_boot.bat ^<boot.img^> [Magisk.apk]
  exit /b 1
)
if not exist "%BOOT%" (
  echo ERROR: boot image tidak ditemukan: "%BOOT%"
  exit /b 1
)
if "%APK%"=="" set "APK=D:\realme-c53-recovery\01_alat\Magisk-v30.7.apk"
if not exist "%APK%" (
  echo ERROR: Magisk APK tidak ditemukan: "%APK%"
  exit /b 1
)

echo Cek koneksi adb ...
adb get-state >nul 2>&1
if errorlevel 1 (
  echo ERROR: device tidak terhubung adb. Aktifkan USB debugging dulu.
  exit /b 1
)

set "TMP=C:\Users\Rafka\AppData\Local\Temp\opencode\magisk_patch"
set "DEV=/data/local/tmp/magisk"

echo.
echo [1/6] Ekstrak Magisk APK ...
if exist "%TMP%" rmdir /s /q "%TMP%"
python -c "import zipfile; zipfile.ZipFile(r'%APK%').extractall(r'%TMP%')"
if errorlevel 1 exit /b 1

echo [2/6] Push stock boot ke device ...
adb push "%BOOT%" /data/local/tmp/stock_boot.img
if errorlevel 1 exit /b 1

echo [3/6] Push binary Magisk ke device ...
adb shell rm -rf %DEV%
adb shell mkdir -p %DEV%
adb push "%TMP%\assets\boot_patch.sh" %DEV%/
adb push "%TMP%\assets\util_functions.sh" %DEV%/
adb push "%TMP%\assets\stub.apk" %DEV%/
adb push "%TMP%\lib\arm64-v8a\libmagiskboot.so" %DEV%/magiskboot
adb push "%TMP%\lib\arm64-v8a\libmagiskinit.so" %DEV%/magiskinit
adb push "%TMP%\lib\arm64-v8a\libmagisk32.so" %DEV%/magisk32
adb push "%TMP%\lib\arm64-v8a\libmagisk64.so" %DEV%/magisk64
adb push "%TMP%\lib\arm64-v8a\libmagiskpolicy.so" %DEV%/magiskpolicy
adb push "%TMP%\lib\arm64-v8a\libinit-ld.so" %DEV%/init-ld
adb shell chmod 755 %DEV%/boot_patch.sh %DEV%/magiskboot %DEV%/magiskinit %DEV%/magisk32 %DEV%/magisk64 %DEV%/magiskpolicy %DEV%/init-ld

echo [4/6] Jalankan boot_patch.sh di device ...
adb shell "cd %DEV% && ./boot_patch.sh /data/local/tmp/stock_boot.img"
if errorlevel 1 exit /b 1

echo [5/6] Tarik hasil new-boot.img ...
adb shell ls -la %DEV%/new-boot.img
adb pull %DEV%/new-boot.img "%~dpn1_magisk.img"
if errorlevel 1 exit /b 1

echo.
echo ================================================================
echo  Selesai. Boot patched:
echo    "%~dpn1_magisk.img"
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-FileHash '%~dpn1_magisk.img' -Algorithm SHA1).Hash; (Get-Item '%~dpn1_magisk.img').Length"
echo.
echo Hasil siap di-flash ke boot_a via BROM:
echo   w_force boot_a "%~dpn1_magisk.img"
pause
