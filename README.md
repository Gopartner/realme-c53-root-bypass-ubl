# 🔓 Root Realme C53 (RMX3760) via Magisk — Metode Bypass UBL (Tanpa Unlock Bootloader)

> **Metode root:** Magisk patched boot + patched `vbmeta_a` (`AVB_VBMETA_IMAGE_FLAGS_VERIFICATION_DISABLED`)
> — root **tanpa unlock bootloader** (tanpa wipe data), flash via **BROM/spd_dump**.

Repo ini menyediakan **alat + bahan** untuk root Realme C53 / RMX3760 / RMX3762
(SoC **Unisoc T612 / UMS9230H**, platform **qogirl6**).

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

> ⚠️ **Bahan boot/vbmeta di repo ini dibuat dari build `RMX3760export_14_C.23` (A14).**
> Bahan tersebut **hanya cocok** jika firmware aktif di HP Anda adalah build yang sama.

---

## 🎛️ Penting: Partisi Slot A/B

Device ini memakai sistem **A/B (VAB)** — semua partisi boot/modem/NV punya dua salinan:
`boot_a` / `boot_b`, `vbmeta_a` / `vbmeta_b`, `l_fixnv1_a` / `l_fixnv1_b`, dst.

Yang **harus di-flash adalah slot yang sedang aktif (active slot)**, bukan keduanya
secara asal — jika Anda flash ke slot non-aktif, perubahan tidak akan dipakai saat boot.

**Cara cek slot aktif:**

```
adb shell getprop ro.boot.slot_suffix
```
- Output `_a` → slot aktif = **A** → flash ke `boot_a`, `vbmeta_a`
- Output `_b` → slot aktif = **B** → flash ke `boot_b`, `vbmeta_b`

> ℹ️ Pada perangkat uji (device ini), slot aktif = **`_a`**, sehingga semua contoh di
> repo ini (script & panduan manual) memakai `boot_a` / `vbmeta_a`.
>
> ⚠️ Jika slot aktif HP Anda `_b`, gunakan nama partisi **`_b`**:
> ```
> w_force boot_b ..\boot\magisk_patched_boot.img
> w_force vbmeta_b ..\vbmeta\vbmeta_a_disabled.img
> ```
> (atau ubah `boot_a`→`boot_b`, `vbmeta_a`→`vbmeta_b` di `flash_root_boot_vbmeta.bat`)

**Cara cek slot lewat BROM (mode download):**

```
FDL2> p
```
Output menampilkan daftar partisi (perhatikan apakah `boot_a` & `boot_b` ada).
Partisi aktif bisa dicek dengan `set_active`:
```
FDL2> set_active a
```
Perintah `set_active a` / `set_active b` memaksa slot tertentu sebagai slot aktif.

---

## 🧭 Langkah 0 — Cek Firmware Aktif di HP Anda

Hubungkan HP (aktifkan **USB debugging**), lalu jalankan:

```
adb shell getprop ro.build.display.id
adb shell getprop ro.build.version.incremental
adb shell getprop ro.product.model
adb shell getprop ro.build.fingerprint
```

Bandingkan dengan bahan yang kita pakai:

| Properti | Nilai bahan di repo ini |
|---|---|
| `ro.build.display.id` | `RMX3760export_14_C.23` |
| `ro.build.version.incremental` | `C.23` |
| `ro.product.model` | `RMX3760` atau `RMX3762` |
| `ro.build.fingerprint` | berakhiran `...:14/RKQ1...` (Android 14) |

**Hasil cek → dua kemungkinan:**

- ✅ **COCOK** → Anda bisa langsung pakai bahan milik kita (`boot\magisk_patched_boot.img` + `vbmeta\vbmeta_a_disabled.img`), lanjut ke [Langkah 3](#langkah-3--flash).
- ❌ **TIDAK cocok / build beda** → ambil boot milik Anda sendiri dan patch sendiri ([Langkah 1a](#langkah-1a--patch-boot-milik-sendiri)), lalu disable vbmeta ([Langkah 1b](#langkah-1b--disable-vbmeta-milik-sendiri)).

---

## Langkah 1a — Patch Boot Milik Sendiri (jika build beda)

> **Cara A — Script otomatis (disarankan):**
```
scripts\patch_boot.bat boot\stock_boot.img
```
atau dengan boot milik sendiri:
```
scripts\patch_boot.bat D:\punya_sendiri\boot.img
```
Script akan: ekstrak Magisk APK → push binary → jalankan `boot_patch.sh` → tarik hasil `xxx_magisk.img`.

> **Cara B — Manual via aplikasi Magisk:**
> 1. Install Magisk di HP.
> 2. Buka Magisk → **Install → Select and Patch a File** → pilih `boot.img`.
> 3. Hasil `magisk_patched_boot.img` tersimpan di Download.

> **Dapatkan `boot.img` milik sendiri** dari firmware build Anda (extract dari PAC/ROM),
> atau baca dari partisi device via BROM: `read_part boot_a 0 67108864 boot.img`.

**Hasil:** boot patched (mis. `stock_boot_magisk.img`).

---

## Langkah 1b — Disable VBMeta Milik Sendiri

> **Script otomatis:**
```
scripts\disable_vbmeta.bat vbmeta\vbmeta_a_original.img
```
atau pakai vbmeta milik firmware Anda sendiri:
```
scripts\disable_vbmeta.bat D:\punya_sendiri\vbmeta.img
```
Script akan: generate vbmeta baru dengan flags=2 → pad ke 1 MB → tampilkan hash + info.
Hasil: `vbmeta_a_disabled.img` (atau `xxx_disabled.img` di samping input).

> ℹ️ Anda **boleh** pakai vbmeta disabled dari repo ini (`vbmeta\vbmeta_a_disabled.img`)
> jika firmware Anda build A14 C.23 — atau buat sendiri dari vbmeta firmware Anda
> dengan script di atas. Keduanya sama-sama valid untuk metode bypass UBL.

---

## Langkah 3 — Flash via BROM (boot_a + vbmeta_a)

1. **Masuk download mode:** matikan device → tahan **Vol+ dan Vol−** → colok USB.
   Tunggu muncul **`OPPO download port`** (`VID_22D9`).

Dua cara flash — pilih salah satu:

**Cara A — Script otomatis (1 klik):**
```
flash_root_boot_vbmeta.bat
```
Isi script: `w_force boot_a` (patched) + `w_force vbmeta_a` (disabled) + `read_part` verify + `reboot-fastboot`.

**Cara B — Manual interaktif (ketik partisi satu-persatu di prompt FDL2>):**
```
cd /d D:\porting-custom-rom\root-work\brom
spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-sign.bin 0x65000800 fdl lk-fdl2-sign.bin 0x9EFFFE00 exec
```
lalu ketik di `FDL2>`:
```
w_force boot_a ..\boot\magisk_patched_boot.img
w_force vbmeta_a ..\vbmeta\vbmeta_a_disabled.img
read_part boot_a 0 67108864 ..\verify_out\cek_boot_a.img
read_part vbmeta_a 0 1048576 ..\verify_out\cek_vbmeta_a.img
reboot-fastboot
```

> 📖 Panduan manual lengkap: **[FLASH_MANUAL_INTERAKTIF.md](FLASH_MANUAL_INTERAKTIF.md)**

> ℹ️ Tanpa unlock bootloader, ganti vbmeta_a ke flags=2 membuat bootloader boot dalam
> **orange state** — verifiedbootstate berubah dari `green` → `orange`, tapi **tanpa wipe data**.

---

## Langkah 4 — Konfirmasi Root

```
adb shell su -c id
```
Harus muncul: `uid=0(root) gid=0(root) ...`

Atau buka aplikasi **Magisk** → status **Installed / All good**.

---

## Langkah 5 — Rollback (jika gagal boot)

Flash kembali `vbmeta_a` asli (`vbmeta\vbmeta_a_original.img`) dan stock boot via BROM.

---

## 🛠️ Alat yang Disediakan

| Alat | Lokasi | Fungsi |
|---|---|---|
| **spd_dump.exe** | `brom\spd_dump.exe` | Akses BROM, flash `w_force`, read-back |
| **fdl1-sign.bin** | `brom\` | FDL1 stage boot (BROM) |
| **lk-fdl2-sign.bin** | `brom\` | FDL2 stage (u-boot/lk) |
| **ums9230_hulk.xml / partition_*.xml** | `brom\` | Layout partisi A/B |
| **pgpt.bin** | `brom\` | Primary GPT |
| **Channel.ini / Channel9.dll** | `brom\` | Konfigurasi & library spd_dump |
| **avbtool.py** | `tools\avbtool.py` | Generate/patch vbmeta (flags=2) |
| **patch_boot.bat** | `scripts\` | Patch boot milik sendiri dengan Magisk |
| **disable_vbmeta.bat** | `scripts\` | Disable vbmeta milik sendiri |

> ℹ️ **Semua alat self-contained** di repo ini — script tidak butuh tool eksternal.

## 📦 Bahan yang Disediakan

| Bahan | Lokasi | Catatan |
|---|---|---|
| **Stock boot A14 C.23** | `boot\stock_boot.img` | Hasil extract PAC A14 (sha1 `9BB331EC...`) |
| **Boot patched Magisk** | `boot\magisk_patched_boot.img` | Siap flash (sha1 `A8BCB42F...`) |
| **Verify boot read-back** | `boot\verify_boot_a.img` | Baca dari device saat uji |
| **vbmeta_a asli (flags=0)** | `vbmeta\vbmeta_a_original.img` | Cadangan / bahan disable |
| **vbmeta_a disabled (flags=2)** | `vbmeta\vbmeta_a_disabled.img` | Siap flash (sha1 `7C79BBFC...`) |

---

## 📁 Struktur Folder

```
root-work/
├── README.md                      ← Dokumen ini
├── FLASH_MANUAL_INTERAKTIF.md     ← Panduan flash manual (prompt FDL2>)
├── flash_root_boot_vbmeta.bat     ← Script flash 1-klik (self-contained)
├── boot/
│   ├── stock_boot.img             ← Stock boot A14 (67 MB)
│   ├── magisk_patched_boot.img    ← Boot patched Magisk (67 MB)
│   └── verify_boot_a.img          ← Read-back boot_a dari device
├── vbmeta/
│   ├── vbmeta_a_original.img      ← vbmeta_a asli (cadangan, flags=0)
│   └── vbmeta_a_disabled.img      ← vbmeta patched flags=2 (1 MB, avbtool)
├── brom/                          ← Alat BROM (flash)
│   ├── spd_dump.exe
│   ├── fdl1-sign.bin / lk-fdl2-sign.bin
│   ├── ums9230_hulk.xml / partition_*.xml / pgpt.bin
│   ├── Channel.ini / Channel9.dll
│   └── perintah-fdl1-fdl2.txt
├── scripts/
│   ├── patch_boot.bat             ← Patch boot milik sendiri (Magisk CLI)
│   └── disable_vbmeta.bat         ← Disable vbmeta milik sendiri (avbtool)
├── tools/
│   └── avbtool.py                 ← Generator/patch vbmeta
└── .gitignore                     ← *.log, backup NV/IMEI tidak di-commit
```

---

## 🔢 Hash Bahan (untuk verifikasi)

| File | SHA1 |
|---|---|
| `boot\stock_boot.img` | `9BB331EC300AD684BF7FB2F28473F523CDD13C02` |
| `boot\magisk_patched_boot.img` | `A8BCB42FBD2EBFE5B753C0C4021A6BB11D6BA2BD` |
| `vbmeta\vbmeta_a_disabled.img` | `7C79BBFCF485822582B30DBE45B8B1DDAA6332B4` |

---

## 🧠 Info Proses (Kenapa Metode Ini)

1. vbmeta_a top-level: **flags=0** (verification aktif), ditandatangani OEM key (`30f6c776...`).
2. Partisi `boot` diverifikasi via **Chain Partition descriptor** (public key `d7fabec6...`).
3. Boot image stock membawa **footer `VBMETA`** (AVB 1.0 `AVBf` + vbmeta embedded `AVB0`, flags=0).
4. Setelah di-patch Magisk, kernel & ramdisk berubah → **digest footer tidak cocok**.
5. Pada bootloader **locked**, boot image yang berubah **ditolak** → perlu `vbmeta_a` dengan
   flag `AVB_VBMETA_IMAGE_FLAGS_VERIFICATION_DISABLED` (nilai `2`).
6. Dengan flags=2, bootloader **skip verifikasi** semua partisi (orange state) tanpa unlock/wipe.

```
Stock boot ──▶ Magisk boot_patch.sh ──▶ boot patched
vbmeta (flags=0) ──▶ avbtool --flags 2 ──▶ vbmeta disabled
                   BROM w_force boot_a + vbmeta_a
                       │
              reboot-fastboot → boot (orange) → su → root ✓
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
