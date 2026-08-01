@echo off
REM ================================================================
REM  SCRIPT: Disable vbmeta (set AVB_VBMETA_IMAGE_FLAGS_VERIFICATION_DISABLED=2)
REM
REM  Cara pakai:
REM    scripts\disable_vbmeta.bat <file_vbmeta_asli> [ukuran_partisi_bytes]
REM
REM  Contoh:
REM    scripts\disable_vbmeta.bat vbmeta\vbmeta_a_original.img
REM    scripts\disable_vbmeta.bat D:\punya_sendiri\vbmeta.img
REM
REM  Hasil: vbmeta_disabled.img di folder yang sama dengan input,
REM  ter-pad ke ukuran partisi (default 1 MB = 1048576).
REM
REM  Bisa dipakai untuk vbmeta milik firmware sendiri atau milik kita.
REM ================================================================
setlocal
set "IN=%~1"
set "SIZE=%~2"
if "%IN%"=="" (
  echo ERROR: tidak ada file vbmeta input.
  echo Pakai: scripts\disable_vbmeta.bat ^<file_vbmeta_asli^> [ukuran]
  exit /b 1
)
if not exist "%IN%" (
  echo ERROR: file tidak ditemukan: "%IN%"
  exit /b 1
)
if "%SIZE%"=="" set "SIZE=1048576"

set "OUT=%~dpn1_disabled%~x1"
set "AVB=D:\porting-custom-rom\root-work\tools\avbtool.py"

echo Input : %IN%
echo Output: %OUT%
echo Size  : %SIZE% bytes
echo.

python "%AVB%" make_vbmeta_image --flags 2 --include_descriptors_from_image "%IN%" --output "%OUT%"
if errorlevel 1 (
  echo.
  echo GAGAL membuat vbmeta disabled.
  exit /b 1
)

echo.
echo Mem-pad ke %SIZE% bytes ...
python -c "import os,sys; s=int(sys.argv[1]); d=open(sys.argv[2],'rb').read(); open(sys.argv[3],'wb').write(d+bytes(max(0,s-len(d))))" "%SIZE%" "%OUT%" "%OUT%"

echo.
echo ================================================================
echo  Selesai. Hash vbmeta disabled:
echo ================================================================
powershell -NoProfile -ExecutionPolicy Bypass -Command "(Get-FileHash '%OUT%' -Algorithm SHA1).Hash; (Get-Item '%OUT%').Length"
echo.
echo Verifikasi struktur:
python "%AVB%" info_image --image "%OUT%"
echo.
echo Sekarang flash bersama boot patched via BROM:
echo   w_force vbmeta_a %OUT%
echo   w_force boot_a  ..\boot\magisk_patched_boot.img
pause
