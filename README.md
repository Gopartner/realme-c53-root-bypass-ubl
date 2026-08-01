# 🔓 Root Realme C53 (RMX3760) via Magisk — Metode Bypass UBL (Tanpa Unlock Bootloader)

> **Metode root:** Magisk patched boot + patched `vbmeta_a` (`AVB_VBMETA_IMAGE_FLAGS_VERIFICATION_DISABLED`)
> — root **tanpa unlock bootloader** (tanpa wipe data).
>
> **Cara flash:** **hanya via BROM/spd_dump (spd_tools)** — dua pilihan:
> script `.bat` otomatis atau ketik partisi satu-satu di prompt `FDL2>`.

---

## 🧪 HP yang Sudah Teruji

| Info | Nilai |
|---|---|
| **Model** | Realme C53 (RMX3760 / RMX3762) |
| **SoC / Platform** | Unisoc T612 (**UMS9230H**, platform `qogirl6`) |
| **Kondisi awal** | Android 15 (build `export_15_*`) |
| **Downgrade** | A15 → **Android 14** (`RMX3760export_14_C.23`) |
| **Versi yang diuji root** | **Android 14** `RMX3760export_14_C.23` |
| **Bootloader** | `locked`, AVB `enforcing` |
| **Root yang dipakai** | Magisk v30.7 (patch boot via CLI) |

> ⚠️ Bahan di repo ini dibuat dari build `RMX3760export_14_C.23` (A14) —
> pastikan firmware aktif HP Anda build yang sama sebelum flash.

---

## 🎛️ Penting: Slot A/B

Device memakai sistem **A/B (VAB)** — partisi punya dua salinan: `boot_a`/`boot_b`,
`vbmeta_a`/`vbmeta_b`, dst. **Yang harus di-flash = slot yang aktif.**

- Cek slot aktif (dari HP / mode fastboot):
  ```
  adb shell getprop ro.boot.slot_suffix
  ```
- Output `_a` → flash `boot_a`, `vbmeta_a` (contoh di repo ini)
- Output `_b` → flash `boot_b`, `vbmeta_b`

Cek / paksa slot lewat BROM di prompt `FDL2>`:
```
FDL2> p                       REM lihat daftar partisi
FDL2> set_active a            REM paksa slot A aktif
FDL2> set_active b            REM paksa slot B aktif
```

---

## 📦 Bahan (Siap Flash)

| Bahan | Lokasi | Catatan |
|---|---|---|
| **Boot patched Magisk** | `boot\magisk_patched_boot.img` | sha1 `A8BCB42FBD2EBFE5B753C0C4021A6BB11D6BA2BD` |
| **vbmeta_a disabled (flags=2)** | `vbmeta\vbmeta_a_disabled.img` | sha1 `7C79BBFCF485822582B30DBE45B8B1DDAA6332B4` |

Tambahan (opsional): `boot\stock_boot.img` (stock asli, sha1 `9BB331EC...`),
`boot\verify_boot_a.img` (read-back dari device), `vbmeta\vbmeta_a_original.img`
(vbmeta asli untuk rollback).

---

## 🔥 Flash via BROM — Pilih Salah Satu

1. **Masuk download mode (BROM):** matikan device → tahan **Vol+ dan Vol−**
   bersamaan → colok USB. Tunggu muncul **`OPPO download port`** (`VID_22D9`).

### Cara A — Script otomatis (mengarah ke folder bahan)

Buka **Command Prompt** di folder repo, lalu jalankan:
```
flash_root_boot_vbmeta.bat
```
Script otomatis: masuk BROM (`brom\spd_dump.exe` + `fdl1-sign.bin` +
`lk-fdl2-sign.bin`) → flash `boot_a` dari `boot\magisk_patched_boot.img` →
flash `vbmeta_a` dari `vbmeta\vbmeta_a_disabled.img` → verify read-back +
tampilkan hash → `reboot-fastboot`.

### Cara B — Manual (ketik partisi satu-satu di prompt FDL2>)

```
cd /d D:\porting-custom-rom\root-work\brom
spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-sign.bin 0x65000800 fdl lk-fdl2-sign.bin 0x9EFFFE00 exec
```
Lalu ketik di `FDL2>`:
```
w_force boot_a ..\boot\magisk_patched_boot.img
w_force vbmeta_a ..\vbmeta\vbmeta_a_disabled.img
read_part boot_a 0 67108864 ..\verify_out\cek_boot_a.img
read_part vbmeta_a 0 1048576 ..\verify_out\cek_vbmeta_a.img
reboot-fastboot
```

> 📖 Panduan manual lengkap: **[FLASH_MANUAL_INTERAKTIF.md](FLASH_MANUAL_INTERAKTIF.md)**

> ℹ️ Tanpa unlock bootloader, vbmeta_a flags=2 membuat bootloader boot dalam
> **orange state** — verifiedbootstate `green` → `orange`, tapi **tanpa wipe data**.

---

## ✅ Konfirmasi Root

```
adb shell su -c id
```
Harus muncul: `uid=0(root) gid=0(root) ...`
Atau buka aplikasi **Magisk** → status **Installed / All good**.

---

## ↩️ Rollback (jika gagal boot)

Flash kembali vbmeta asli (`vbmeta\vbmeta_a_original.img`) dan stock boot
(`boot\stock_boot.img`) via BROM dengan cara yang sama.

---

## 📁 Struktur Folder

```
root-work/
├── README.md                      ← Dokumen ini
├── FLASH_MANUAL_INTERAKTIF.md     ← Panduan manual (prompt FDL2>)
├── flash_root_boot_vbmeta.bat     ← Script flash otomatis (mengarah ke folder bahan)
├── boot/
│   ├── stock_boot.img             ← Stock boot A14 (67 MB)
│   ├── magisk_patched_boot.img    ← Boot patched Magisk (siap flash)
│   └── verify_boot_a.img          ← Read-back boot_a dari device
├── vbmeta/
│   ├── vbmeta_a_original.img      ← vbmeta_a asli (rollback, flags=0)
│   └── vbmeta_a_disabled.img      ← vbmeta patched flags=2 (siap flash)
└── brom/                          ← Alat BROM/spd_dump (self-contained)
    ├── spd_dump.exe
    ├── fdl1-sign.bin / lk-fdl2-sign.bin
    ├── ums9230_hulk.xml / partition_*.xml / pgpt.bin
    ├── Channel.ini / Channel9.dll
    └── perintah-fdl1-fdl2.txt
```

> ℹ️ **Semua alat & bahan self-contained** di repo ini — tidak butuh tool eksternal.

---

## ⚖️ Lisensi

Hanya untuk tujuan **edukasi / perangkat sendiri**. Gunakan dengan risiko sendiri.
