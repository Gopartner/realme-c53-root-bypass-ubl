# 🔓 Root Realme C53 (RMX3760) via Magisk — Metode Bypass UBL (Tanpa Unlock Bootloader)

> **Tema / metode root:** Magisk patched boot + patched `vbmeta_a` (`AVB_VBMETA_IMAGE_FLAGS_VERIFICATION_DISABLED`)
> — root **tanpa unlock bootloader** (tanpa wipe data), flash via **BROM/spd_dump**.

Root guide & workspace untuk **Realme C53 / RMX3760 / RMX3762** (SoC **Unisoc T612 / UMS9230H**, platform **qogirl6**).

---

## 🏷️ Info Perangkat

| Item | Nilai |
|---|---|
| **Merk / Model** | Realme C53 (RMX3760, RMX3762) |
| **SoC / Platform** | Unisoc T612 (**UMS9230H**, platform `qogirl6`) |
| **CPU** | 2× Cortex-A78 + 6× Cortex-A55 |
| **GPU** | Mali-G57 |
| **RAM / Storage** | 4–8 GB / 64–128 GB eMMC |
| **Slot / A-B** | A/B (aktif: `_a`) |
| **Kernel** | `5.15.178-android13-8` (non-GKI) |

## 🤖 Info Versi Android

| Build | Versi | Catatan |
|---|---|---|
| **Android 14 (saat ini)** | `RMX3760export_14_C.23` | Hasil downgrade A15→A14, basis root |
| Android 15 (sebelumnya) | `RMX3760export_15_*` | Backup `l_fixnv1_a` diambil dari build ini |
| Bootloader | `locked` (`ro.boot.flash.locked=1`) | AVB `enforcing`, verifiedbootstate `green` |
| Magisk | **v30.7** | Patch boot via CLI `boot_patch.sh` |

---

## ⚠️ Peringatan

- Proses ini **berisiko** — dapat membuat device tidak boot jika salah.
- Pastikan IMEI / NV **sudah dibackup** sebelum memulai.
- Kerjakan **di atas meja yang stabil**, colok USB **tidak putus-putus**.
- Hanya untuk **device Anda sendiri**.

---

## 📦 Bahan (Materials)

| Bahan | Lokasi |
|---|---|
| Stock boot `boot_a` A14 (67 MB) | `D:\downloader-firmware\results\pac-bootchain\boot.img` |
| Magisk patched boot (`magisk_patched_boot.img`) | `D:\realme-c53-recovery\03_downgrade_a14\magisk_patched_boot.img` |
| vbmeta_a asli (`verify_vbmeta_a.img`, flags=0) | `root-work\verify\` (cadangan) |
| vbmeta_a patched (`verify_vbmeta_a_new_pad.img`, flags=2) | `root-work\verify\` |
| XML partisi A/B | `D:\downloader-firmware\results\pac-bootchain\ums9230_hulk.xml` |
| Backup A15 NV `l_fixnv1_a.img` (VN wrapper, berisi IMEI) | `D:\realme-c53-recovery\03_downgrade_a14\backup_a15_fresh\` |

## 🛠️ Tools

| Tool | Fungsi |
|---|---|
| **Magisk v30.7 APK** (`Magisk-v30.7.apk`) | Patch stock boot → boot image ber-root |
| **spd_dump.exe** (`spd_tools\spd_dump.exe`) | Akses **BROM** untuk flash `w_force` + read-back |
| **avbtool.py** (`tools\avbtool.py`) | Generate / patch vbmeta (flags `VERIFICATION_DISABLED`) |
| **adb / fastboot** (Platform Tools) | Push file, konfirmasi root |
| **Driver SPRD / OPPO USB** | Agar device terbaca di download mode |
| **Python 3.10+** | Menjalankan `avbtool.py` |

---

## 📖 Tutorial Root (Step-by-Step)

### 0. Persiapan

1. Backup **IMEI/NV** dan data penting.
2. Install **Magisk v30.7** di device (`adb install -r Magisk-v30.7.apk`).
3. Push stock boot ke device:
   ```
   adb push boot.img /data/local/tmp/stock_boot.img
   ```

### 1. Patch Boot dengan Magisk (di device, via CLI)

```
adb shell
cd /data/local/tmp/magisk
./magiskboot unpack stock_boot.img
sh boot_patch.sh stock_boot.img
```
Hasil: `new-boot.img` = boot image ber-root.
Pull ke PC:
```
adb pull /data/local/tmp/magisk/new-boot.img D:\realme-c53-recovery\03_downgrade_a14\magisk_patched_boot.img
```

> **Hash referensi**
> - Stock: `9BB331EC300AD684BF7FB2F28473F523CDD13C02`
> - Patched: `A8BCB42FBD2EBFE5B753C0C4021A6BB11D6BA2BD`

### 2. Patch vbmeta_a (flags=2 → verification disabled)

Dua varian tersedia:

**Varian A — generate ulang dengan avbtool (disarankan):**
```
python tools\avbtool.py make_vbmeta_image ^
  --flags 2 --include_descriptors_from_image verify_vbmeta_a.img ^
  --output verify_vbmeta_a_new.img
```
lalu pad ke 1 MB:
```
python -c "open('verify_vbmeta_a_new_pad.img','wb').write(open('verify_vbmeta_a_new.img','rb').read()+bytes(1048576-15552))"
```

**Varian B — patch in-place (ubah byte flags @ offset 120):**
- Ubah 4 byte `flags` pada offset `120` dari `00 00 00 00` menjadi `02 00 00 00`.
- Hash hasil: `5FA4A6B5603C576974C63D275DE41F1C8A4A0F4D`.

### 3. Flash via BROM (spd_dump) — boot_a + vbmeta_a

1. **Masuk download mode:** matikan device → tahan **Vol+ dan Vol−** → colok USB.
   Tunggu muncul **`OPPO download port`** (`VID_22D9`).
2. Jalankan `flash_root_boot_vbmeta.bat` (isi: `w_force boot_a` patched + `w_force vbmeta_a` patched
   + `read_part` verify + `reboot-fastboot`).

> Tanpa unlock bootloader, ganti vbmeta_a ke flags=2 membuat bootloader boot dalam
> **orange state** — verifiedbootstate berubah dari `green` → `orange`, tapi **tanpa wipe data**.

### 4. Konfirmasi Root

```
adb shell su -c id
```
Harus muncul: `uid=0(root) gid=0(root) ...`

Atau buka aplikasi **Magisk** → status **Installed / All good**.

### 5. Rollback (jika gagal boot)

Flash kembali `vbmeta_a` asli (`verify_vbmeta_a.img`) dan stock boot via BROM.

---

## 🧠 Info Proses (Kenapa Metode Ini)

### Mengapa perlu patch vbmeta?

1. vbmeta_a top-level saat ini: **flags=0** (verification **aktif**), ditandatangani OEM key (`30f6c776...`).
2. Partisi `boot` diverifikasi via **Chain Partition descriptor** (public key `d7fabec6...`).
3. Boot image stock membawa **footer `VBMETA`** (AVB 1.0 `AVBf` + vbmeta embedded `AVB0`, flags=0).
4. Setelah di-patch Magisk, kernel & ramdisk berubah → **digest footer tidak cocok lagi**.
5. Pada bootloader **locked**, boot image yang berubah **ditolak** → perlu `vbmeta_a` dengan
   flag `AVB_VBMETA_IMAGE_FLAGS_VERIFICATION_DISABLED` (nilai `2`).
6. Dengan flags=2, bootloader **skip verifikasi** semua partisi (orange state) tanpa unlock/w ipe.

### Alur Proses

```
Stock boot ──▶ Magisk boot_patch.sh ──▶ magisk_patched_boot.img
                                                        │
vbmeta_a (flags=0) ──▶ avbtool --flags 2 ──▶ vbmeta_a patched
                                                        │
                         ┌──────────────────────────────┤
                         ▼                              ▼
                  w_force boot_a  ◀──────────  w_force vbmeta_a
                         │
                    reboot-fastboot → boot (orange) → su → root ✓
```

---

## 📁 Struktur Folder

```
root-work/
├── README.md                      ← Dokumen ini
├── flash_root_boot_vbmeta.bat     ← Script flash boot+vbmeta via BROM
├── verify/
│   ├── verify_vbmeta_a.img        ← vbmeta_a asli (cadangan)
│   ├── verify_vbmeta_a_new_pad.img← vbmeta patched flags=2 (1 MB, avbtool)
│   └── verify_vbmeta_a_patched.img← vbmeta patched in-place (flags byte)
└── .gitignore                     ← *.img/*.bin/*.log tidak di-commit
```

---

## 📎 Referensi

- [Magisk (topjohnwu)](https://github.com/topjohnwu/Magisk)
- [avbtool (AOSP)](https://android.googlesource.com/platform/external/avb/)
- Unlock exploit SPRD/Unisoc: CVE-2022-38694 (TomKing062)
- Realme C53 kernel source (A13/A14)

---

## ⚖️ Lisensi

Hanya untuk tujuan **edukasi / perangkat sendiri**. Gunakan dengan risiko sendiri.
