# Root Realme C53 (RMX3760) via Magisk menggunakan BROM/SPD Dump

> **Metode root:** Magisk-patched `boot` + patched `vbmeta` dengan flag `AVB_VBMETA_IMAGE_FLAGS_VERIFICATION_DISABLED`.
>
> **Metode flash:** Unisoc BROM menggunakan `spd_dump`.
>
> **Status bootloader:** Metode ini telah diuji pada perangkat dengan bootloader masih terkunci, tanpa proses unlock bootloader dan tanpa wipe data.

---

## ⚠️ Peringatan Penting

Repository ini berisi image partisi yang dibuat dan diuji untuk firmware tertentu.

Sebelum melakukan flash, pastikan:

- Model perangkat adalah **Realme C53 (RMX3760)**.
- Firmware aktif sesuai dengan build yang disebutkan pada bagian kompatibilitas.
- Slot aktif perangkat sudah diketahui.
- File `boot` dan `vbmeta` sesuai dengan firmware perangkat.
- Baterai perangkat cukup.
- Kabel USB dan koneksi BROM stabil.
- Anda memahami risiko proses flash partisi.

Flash image yang tidak sesuai dapat menyebabkan:

- Bootloop.
- Gagal masuk Android.
- Slot gagal melakukan boot.
- Sistem tidak dapat berjalan.
- Kehilangan data jika pemulihan memerlukan flash firmware penuh.

Gunakan repository ini hanya pada perangkat sendiri dan dengan risiko sendiri.

---

# 🧪 Perangkat dan Firmware yang Sudah Diuji

| Informasi                     | Nilai                              |
| ----------------------------- | ---------------------------------- |
| **Model**                     | Realme C53 (RMX3760)               |
| **SoC / Platform**            | Unisoc T612 (`UMS9230H`)           |
| **Board**                     | `ums9230_hulk`                     |
| **Platform**                  | `qogirl6`                          |
| **Kondisi awal**              | Android 15(downgrade ke versi 14)  |
| **Firmware pengujian root**   | Android 14 `RMX3760export_14_C.23` |
| **Bootloader saat pengujian** | Locked                             |
| **AVB sebelum patch**         | Enforcing                          |
| **Root**                      | Magisk v30.7                       |
| **Metode patch**              | Magisk-patched boot                |

> ⚠️ File `boot` dan `vbmeta` dalam repository ini dibuat dari firmware:
>
> ```text
> RMX3760export_14_C.23
> ```
>
> Jangan flash file tersebut pada firmware atau build lain sebelum memastikan kecocokan image dan ukuran partisinya.

---

# 🎛️ Penting: Sistem Slot A/B

Perangkat menggunakan sistem **A/B**. Beberapa partisi memiliki dua slot:

```text
boot_a
boot_b

vbmeta_a
vbmeta_b
```

Image harus ditulis ke partisi yang sesuai dengan slot target.

## 1. Cek Slot Aktif dari Android

Sebelum masuk ke mode BROM, jalankan:

```bash
adb shell getprop ro.boot.slot_suffix
```

Contoh hasil:

```text
_a
```

Artinya slot aktif adalah **A**.

Jika hasilnya:

```text
_b
```

artinya slot aktif adalah **B**.

> Repository ini saat ini menyediakan image dan perintah flash untuk **slot A**:
>
> ```text
> boot_a
> vbmeta_a
> ```
>
> Jika perangkat menggunakan slot B, jangan hanya mengganti nama partisi menjadi `boot_b` atau `vbmeta_b`. Pastikan image yang digunakan benar dan sesuai dengan firmware serta slot target.

---

# 📦 File Bahan

| File                    | Lokasi                         | Keterangan                               |
| ----------------------- | ------------------------------ | ---------------------------------------- |
| **Magisk-patched boot** | `boot\magisk_patched_boot.img` | Image boot hasil patch Magisk            |
| **Stock boot**          | `boot\stock_boot.img`          | Backup image boot asli untuk rollback    |
| **Read-back boot**      | `boot\verify_boot_a.img`       | Hasil pembacaan kembali partisi `boot_a` |
| **vbmeta disabled**     | `vbmeta\vbmeta_a_disabled.img` | `vbmeta_a` dengan verification disabled  |
| **vbmeta original**     | `vbmeta\vbmeta_a_original.img` | Backup `vbmeta_a` asli untuk rollback    |

Hash file:

| File                           | SHA-1                                      |
| ------------------------------ | ------------------------------------------ |
| `boot\magisk_patched_boot.img` | `A8BCB42FBD2EBFE5B753C0C4021A6BB11D6BA2BD` |
| `vbmeta\vbmeta_a_disabled.img` | `7C79BBFCF485822582B30DBE45B8B1DDAA6332B4` |

---

# 📥 Clone Repository

Clone repository:

```bash
git clone <URL_REPOSITORY>
```

Masuk ke folder repository:

```bash
cd root-work
```

Setelah repository berhasil di-clone, pilih salah satu metode berikut:

| Metode       | File                         | Keterangan                                             |
| ------------ | ---------------------------- | ------------------------------------------------------ |
| **Otomatis** | `flash_root_boot_vbmeta.bat` | Proses flash dijalankan otomatis                       |
| **Manual**   | `brom\start_spd_dump.bat`    | User mengetik perintah satu per satu di prompt `FDL2>` |

---

# 🔥 Masuk ke Mode BROM

1. Matikan perangkat.
2. Tekan dan tahan **Volume Up + Volume Down** secara bersamaan.
3. Sambil tetap menekan kedua tombol, hubungkan kabel USB ke komputer.
4. Periksa **Windows Device Manager**.

Perangkat biasanya akan muncul sebagai:

```text
SPRD U2S Diag (COMx)
```

Contoh:

```text
SPRD U2S Diag (COM4)
```

Nama perangkat dan nomor COM dapat berbeda tergantung driver serta komputer yang digunakan.

---

# 🚀 Cara A — Flash Otomatis

Gunakan metode ini jika ingin menjalankan proses flash secara otomatis.

## 1. Masuk ke Mode BROM

Ikuti langkah pada bagian:

```text
Masuk ke Mode BROM
```

Pastikan perangkat terdeteksi sebagai:

```text
SPRD U2S Diag (COMx)
```

## 2. Jalankan Script

Dari folder utama repository, klik dua kali:

```text
flash_root_boot_vbmeta.bat
```

Atau jalankan melalui Command Prompt:

```cmd
flash_root_boot_vbmeta.bat
```

Script akan menggunakan file berikut:

```text
brom\spd_dump.exe

brom\fdl1-sign.bin

brom\lk-fdl2-sign.bin

boot\magisk_patched_boot.img

vbmeta\vbmeta_a_disabled.img
```

Path tidak perlu diubah secara manual.

Script menggunakan lokasi file `flash_root_boot_vbmeta.bat` sebagai root project, sehingga repository dapat di-clone ke drive atau folder mana pun.

Contoh lokasi yang tetap dapat digunakan:

```text
D:\root-work
```

```text
D:\porting-custom-rom\root-work
```

```text
C:\Users\User\Documents\root-work
```

> ⚠️ Script otomatis pada repository ini ditujukan untuk:
>
> ```text
> boot_a
> vbmeta_a
> ```
>
> Pastikan slot dan image yang digunakan sesuai sebelum menjalankan script.

---

# ⌨️ Cara B — Flash Manual melalui `FDL2>`

Gunakan metode ini jika ingin mengetik dan menjalankan setiap perintah secara manual.

## 1. Buka Folder `brom`

Masuk ke folder:

```text
root-work\brom
```

## 2. Jalankan `start_spd_dump.bat`

Klik dua kali:

```text
start_spd_dump.bat
```

Script akan menjalankan:

```text
spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl .\fdl1-sign.bin 0x65000800 fdl .\lk-fdl2-sign.bin 0x9EFFFE00 exec
```

Tunggu sampai FDL1 dan FDL2 berhasil dimuat.

Jika berhasil, akan muncul:

```text
FDL2>
```

## 3. Jalankan Perintah Satu per Satu

Setelah muncul prompt:

```text
FDL2>
```

salin setiap perintah dari README menggunakan tombol **Copy**, lalu paste ke prompt `FDL2>`.

Jalankan perintah **satu per satu** dan tunggu proses sebelumnya selesai sebelum melanjutkan.

---

## Periksa Daftar Partisi

Salin:

```text
p
```

---

## Periksa Ukuran `boot_a`

Salin:

```text
size_part boot_a
```

Pada perangkat pengujian, ukuran `boot_a` adalah:

```text
67108864
```

atau sekitar **64 MiB**.

---

## Periksa Partisi `boot_a`

Salin:

```text
check_part boot_a
```

---

## Periksa Partisi `vbmeta_a`

Salin:

```text
check_part vbmeta_a
```

---

## Flash Magisk-Patched Boot ke `boot_a`

Salin:

```text
w_force boot_a "..\boot\magisk_patched_boot.img"
```

Perintah tersebut menulis:

```text
boot\magisk_patched_boot.img
```

ke partisi:

```text
boot_a
```

---

## Flash `vbmeta_a` Disabled

Salin:

```text
w_force vbmeta_a "..\vbmeta\vbmeta_a_disabled.img"
```

Perintah tersebut menulis:

```text
vbmeta\vbmeta_a_disabled.img
```

ke partisi:

```text
vbmeta_a
```

---

## Read-Back `boot_a`

Salin:

```text
read_part boot_a 0 67108864 "..\boot\verify_boot_a.img"
```

File hasil pembacaan akan disimpan sebagai:

```text
boot\verify_boot_a.img
```

---

## Reboot ke Fastboot

Setelah semua proses selesai, salin:

```text
reboot-fastboot
```

Perangkat akan reboot ke mode Fastboot.

> **Catatan:**
>
> - Semua perintah di atas ditujukan untuk **slot A**.
> - Jalankan setiap perintah satu per satu.
> - Jangan mengubah path `..\boot\...` atau `..\vbmeta\...`.
> - Path tersebut sudah sesuai dengan struktur repository dan tetap dapat digunakan setelah repository di-clone ke lokasi lain.
> - Jangan mengganti `boot_a` menjadi `boot_b` atau `vbmeta_a` menjadi `vbmeta_b` tanpa memastikan image dan slot target benar.

---

# ✅ Verifikasi Root

Setelah perangkat berhasil boot ke Android dan Magisk aktif, jalankan:

```bash
adb shell su -c id
```

Output yang diharapkan:

```text
uid=0(root) gid=0(root) ...
```

Alternatif:

1. Buka aplikasi **Magisk**.
2. Periksa status instalasi.
3. Pastikan Magisk menampilkan status:

```text
Installed
```

atau:

```text
All good
```

---

# ↩️ Rollback

Jika perangkat gagal boot, flash kembali image asli yang tersedia di repository.

File rollback:

```text
boot\stock_boot.img
```

dan:

```text
vbmeta\vbmeta_a_original.img
```

Masuk kembali ke mode manual melalui:

```text
brom\start_spd_dump.bat
```

Setelah muncul:

```text
FDL2>
```

jalankan perintah berikut satu per satu.

## Restore Stock Boot

```text
w_force boot_a "..\boot\stock_boot.img"
```

## Restore Original `vbmeta_a`

```text
w_force vbmeta_a "..\vbmeta\vbmeta_a_original.img"
```

## Reboot

```text
reboot-fastboot
```

> ⚠️ Pastikan image rollback sesuai dengan firmware perangkat.
>
> Jangan melakukan rollback ke slot yang berbeda tanpa memahami kondisi sistem A/B perangkat.

---

# 📁 Struktur Folder

```text
root-work/
│
├── README.md
│   └── Dokumentasi utama repository
│
├── flash_root_boot_vbmeta.bat
│   └── Script flash otomatis
│
├── boot/
│   │
│   ├── magisk_patched_boot.img
│   │   └── Boot hasil patch Magisk
│   │
│   ├── stock_boot.img
│   │   └── Backup boot asli untuk rollback
│   │
│   └── verify_boot_a.img
│       └── Hasil read-back partisi boot_a
│
├── vbmeta/
│   │
│   ├── vbmeta_a_disabled.img
│   │   └── vbmeta_a dengan verification disabled
│   │
│   └── vbmeta_a_original.img
│       └── Backup vbmeta_a asli untuk rollback
│
└── brom/
    │
    ├── spd_dump.exe
    │   └── Tool komunikasi Unisoc BROM/FDL
    │
    ├── start_spd_dump.bat
    │   └── Menjalankan spd_dump sampai muncul prompt FDL2>
    │
    ├── fdl1-sign.bin
    │   └── FDL1 signed
    │
    ├── lk-fdl2-sign.bin
    │   └── FDL2 signed
    │
    ├── Channel.ini
    │
    ├── Channel9.dll
    │
    ├── partition_1785558533.xml
    │
    ├── partition_1785558921.xml
    │
    ├── pgpt.bin
    │
    ├── ums9230_hulk.xml
    │
    └── perintah-fdl1-fdl2.txt
        └── Catatan perintah manual FDL1 dan FDL2
```

---

# ℹ️ Catatan AVB dan Orange State

Patch `vbmeta` dengan flag verification disabled dapat menyebabkan status Verified Boot berubah dari:

```text
green
```

menjadi:

```text
orange
```

Hal tersebut menunjukkan bahwa rantai verifikasi boot telah dimodifikasi.

Pada konfigurasi perangkat yang diuji, metode ini tidak melakukan proses unlock bootloader dan tidak melakukan wipe data. Hasil dapat berbeda pada firmware, build, atau konfigurasi perangkat lain.

---

# ⚖️ Lisensi dan Penafian

Repository ini disediakan untuk:

- Edukasi.
- Penelitian.
- Pengujian pada perangkat sendiri.

Gunakan dengan risiko sendiri.

Penulis repository tidak bertanggung jawab atas:

- Bootloop.
- Kehilangan data.
- Kerusakan sistem.
- Kegagalan boot.
- Kegagalan flash.
- Penggunaan file pada firmware atau perangkat yang tidak sesuai.
