# Root RMX3760 — Work Folder

Proyek kerja root Realme C53 (RMX3760, UMS9230H) — **tanpa unlock bootloader** (metode bypass UBL).

## Tujuan

Mendapatkan akses root (Magisk) untuk mendiagnosis jalur boot CP/modem
(baseband `Unknown,Unknown` setelah downgrade A15→A14).

## Ringkasan Strategi

| Item | Nilai |
|------|-------|
| Boot image | Stock A14 `boot_a` (sha1 `9BB331EC...`, 67108864 B) |
| Magisk | v30.7, patch via CLI `boot_patch.sh` |
| Patched boot | `magisk_patched_boot.img` (sha1 `A8BCB42F...`) — TIDAK di-commit (64MB), ada di `D:\realme-c53-recovery\03_downgrade_a14\` |
| vbmeta_a asli | `verify\verify_vbmeta_a.img` (flags=0, AVB enforcing, chain descriptor boot key `d7fabec6...`) |
| vbmeta_a patched | `verify\verify_vbmeta_a_new_pad.img` (avbtool `--flags 2` = `VERIFICATION_DISABLED`, algorithm NONE, sha1 `7C79BBFC...`) |
| vbmeta_a patched (in-place) | `verify\verify_vbmeta_a_patched.img` (ubah byte flags @120 → 2, sha1 `5FA4A6B5...`) |
| Flash script | `flash_root_boot_vbmeta.bat` (via BROM/spd_dump `w_force`) |

## Analisis AVB

- vbmeta_a top-level: flags=0 (verification **aktif**), ditandatangani OEM key (`30f6c776...`).
- `boot` diverifikasi via **chain descriptor** (public key `d7fabec6...`) → bootloader locked
  memvalidasi footer `VBMETA` (AVB 1.0 `AVBf` + vbmeta embedded) di dalam boot image.
- Magisk patched boot mengubah kernel/ramdisk → digest footer vbmeta **tidak cocok** →
  akan ditolak bootloader locked tanpa vbmeta flags=2.
- Solusi: flash `vbmeta_a` dengan `AVB_VBMETA_IMAGE_FLAGS_VERIFICATION_DISABLED` (2) →
  bootloader boot dalam **orange state** tanpa wipe data (metode komunitas Realme bypass UBL).

## Langkah Eksekusi

1. Masuk download mode: power off → tahan **Vol+ dan Vol−** → colok USB (muncul `OPPO download port`, `VID_22D9`).
2. Jalankan `flash_root_boot_vbmeta.bat` → flash `boot_a` + `vbmeta_a` via BROM, verify read-back, `reboot-fastboot`.
3. Boot normal → cek `adb shell su -c id` → harus `uid=0(root)`.
4. Jika boot ditolak/diblock bootloader: flash kembali vbmeta_a asli (recovery via BROM).

## File Referensi (tidak di-copy, lokasi asli)
- Stock boot: `D:\downloader-firmware\results\pac-bootchain\boot.img`
- Magisk patched boot: `D:\realme-c53-recovery\03_downgrade_a14\magisk_patched_boot.img`
- Tools: `D:\realme-c53-recovery\01_alat\spd_tools\spd_dump.exe`
- avbtool: `D:\realme-c53-recovery\tools\avbtool.py`
- XML partisi: `D:\downloader-firmware\results\pac-bootchain\ums9230_hulk.xml`
