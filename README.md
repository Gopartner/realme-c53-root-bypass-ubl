# Root Realme C53 (RMX3760) via Magisk menggunakan BROM/SPD Dump

> **Metode root:** Magisk-patched `boot` + patched `vbmeta` dengan flag `AVB_VBMETA_IMAGE_FLAGS_VERIFICATION_DISABLED`.
>
> **Metode flash:** Unisoc BROM menggunakan `spd_dump`.
>
> **Status bootloader:** Metode ini telah diuji pada perangkat dengan bootloader masih terkunci, tanpa proses unlock bootloader dan tanpa wipe data.
>
> **Status pengujian:** Lihat bagian [Status Pengujian](#status-pengujian) untuk hasil terbaru.

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

# 📊 Status Pengujian

Hasil pengujian metode ini pada perangkat pengujian:

| Tahap                                                        | Hasil                                             |
| ------------------------------------------------------------ | ------------------------------------------------- |
| Patch `boot` dengan Magisk                                   | Berhasil, kernel identik dengan stock             |
| Patch `vbmeta` flag `AVB_VBMETA_IMAGE_FLAGS_VERIFICATION_DISABLED` | Berhasil                                          |
| Flash `boot_a` patched + `vbmeta_a` disabled                 | **Gagal boot**                                    |

Setelah flash, perangkat menampilkan:

```text
no valid os found!!
```

beberapa detik lalu mati. Bootloader dengan status terkunci **menolak** image boot yang sudah dimodifikasi meskipun `vbmeta` sudah dipatch.

> ⚠️ **Kesimpulan sementara:** pada konfigurasi perangkat dan firmware pengujian ini, metode bypass vbmeta **belum berhasil** melewati verifikasi bootloader.
>
> Jika perangkat mengalami gejala di atas, gunakan script restore (lihat bagian [Restore / Rollback](#-restore--rollback)) untuk mengembalikan `boot_a` dan `vbmeta_a` ke kondisi stock.

---

# 🎛️ Penting: Sistem Slot A/B

Perangkat menggunakan sistem **A/B**. Repository ini hanya menyediakan image untuk **slot A**:

```text
boot_a
vbmeta_a
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

Artinya slot aktif adalah **A** — sesuai dengan image yang disediakan.

Jika hasilnya `_b`, jangan langsung flash ke slot B. Image slot B tidak tersedia di repository ini; pastikan slot aktif dikembalikan ke **A** (lihat bagian berikut).

## 2. Pastikan Slot Aktif A di Tool FDL

Saat sudah berada di prompt `FDL2>`, cek daftar partisi:

```text
p
```

Pastikan slot aktif adalah **A**. Jika terlihat slot **B** yang aktif, set ke A:

```text
set_active a
```

> ⚠️ Image di repository ini **hanya untuk slot A** (`boot_a`, `vbmeta_a`).
> Jangan mengganti nama partisi menjadi `boot_b` / `vbmeta_b` — image slot B tidak tersedia.

---

# 📦 File Bahan

| File                    | Lokasi                         | Keterangan                               |
| ----------------------- | ------------------------------ | ---------------------------------------- |
| **Magisk-patched boot** | `boot\magisk_patched_boot.img` | Image boot hasil patch Magisk            |
| **Stock boot**          | `boot\stock_boot.img`          | Backup image boot asli untuk rollback    |
| **vbmeta disabled**     | `vbmeta\vbmeta_a_disabled.img` | `vbmeta_a` dengan verification disabled  |
| **vbmeta original**     | `vbmeta\vbmeta_a_original.img` | Backup `vbmeta_a` asli untuk rollback    |

Hash file:

| File                           | SHA-1                                      |
| ------------------------------ | ------------------------------------------ |
| `boot\magisk_patched_boot.img` | `A8BCB42FBD2EBFE5B753C0C4021A6BB11D6BA2BD` |
| `boot\stock_boot.img`          | `9BB331EC300AD684BF7FB2F28473F523CDD13C02` |
| `vbmeta\vbmeta_a_disabled.img` | `5FA4A6B5603C576974C63D275DE41F1C8A4A0F4D` |
| `vbmeta\vbmeta_a_original.img` | `3D8684BFADEFE8BF1E654D5B2638A86E11A3B93E` |

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

| Metode                       | File                                 | Keterangan                                             |
| ---------------------------- | ------------------------------------ | ------------------------------------------------------ |
| **Flash otomatis**           | `flash_root_boot_vbmeta.bat`         | Flash boot patched + vbmeta disabled otomatis          |
| **Flash manual**             | `brom\start_spd_dump.bat`            | User mengetik perintah satu per satu di prompt `FDL2>` |
| **Restore stock (boot+vbmeta)** | `restore_stock_boot_vbmeta.bat`   | Kembalikan `boot_a` + `vbmeta_a` ke kondisi stock      |
| **Restore stock boot saja**  | `restore_stock_boot_only.bat`        | Kembalikan `boot_a` ke stock (vbmeta tidak disentuh)   |
| **Restore original vbmeta saja** | `restore_stock_vbmeta_only.bat`  | Kembalikan `vbmeta_a` ke original (boot tidak disentuh) |

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

Contoh tampilan saat perangkat terdeteksi di Device Manager:

![Perangkat terdeteksi di Device Manager](brom/image.png)

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
realme-c53-root-bypass-ubl\brom
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

## Pastikan Slot Aktif A

Pastikan slot aktif adalah **A**. Jika terlihat slot **B** yang aktif, salin:

```text
set_active a
```

> ⚠️ Image yang disediakan hanya untuk slot A (`boot_a`, `vbmeta_a`).
> Jangan flash ke `boot_b` / `vbmeta_b`.

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
read_part boot_a 0 67108864 "..\verify_out\verify_root_boot_a.img"
```

File hasil pembacaan akan disimpan sebagai:

```text
verify_out\verify_root_boot_a.img
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
> - Jangan mengubah path `..\boot\...`, `..\vbmeta\...`, atau `..\verify_out\...`.
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

# ↩️ Restore / Rollback

Jika perangkat gagal boot (misalnya menampilkan `no valid os found!!`), kembalikan image stock menggunakan script restore otomatis.

## 1. Restore Otomatis (Disarankan)

Masukkan perangkat ke mode BROM (lihat bagian [Masuk ke Mode BROM](#-masuk-ke-mode-brom)), lalu jalankan salah satu script berikut dari folder utama repository:

| Gejala                                   | Script                             | Yang dikembalikan              |
| ---------------------------------------- | ---------------------------------- | ------------------------------ |
| Gagal boot setelah flash boot + vbmeta   | `restore_stock_boot_vbmeta.bat`    | `boot_a` + `vbmeta_a`          |
| Gagal boot, ingin cek boot saja          | `restore_stock_boot_only.bat`      | `boot_a`                       |
| Ingin mengembalikan vbmeta original saja | `restore_stock_vbmeta_only.bat`    | `vbmeta_a`                     |

Script melakukan:

1. Deteksi otomatis perangkat BROM (`SPRD U2S Diag (COMx)`).
2. `p` + `set_active a`.
3. Menulis image stock ke partisi yang dituju.
4. `reboot-fastboot`.

File yang dikembalikan:

```text
boot\stock_boot.img
```

dan:

```text
vbmeta\vbmeta_a_original.img
```

> ⚠️ Jalankan hanya satu script dalam satu sesi, lalu reboot perangkat dan pastikan hasilnya sebelum menjalankan script lain.

## 2. Restore Manual

Masuk ke mode manual melalui:

```text
brom\start_spd_dump.bat
```

Setelah muncul:

```text
FDL2>
```

jalankan perintah berikut satu per satu.

### Restore Stock Boot

```text
w_force boot_a "..\boot\stock_boot.img"
```

### Restore Original `vbmeta_a`

```text
w_force vbmeta_a "..\vbmeta\vbmeta_a_original.img"
```

### Reboot

```text
reboot-fastboot
```

> ⚠️ Pastikan image rollback sesuai dengan firmware perangkat.
>
> Jangan melakukan rollback ke slot yang berbeda tanpa memahami kondisi sistem A/B perangkat.

---

# 📁 Struktur Folder

```text
realme-c53-root-bypass-ubl/
│
├── README.md
│   └── Dokumentasi utama repository
│
├── flash_root_boot_vbmeta.bat
│   └── Script flash otomatis (boot patched + vbmeta disabled)
│
├── restore_stock_boot_vbmeta.bat
│   └── Script restore otomatis (boot stock + vbmeta original)
│
├── restore_stock_boot_only.bat
│   └── Script restore boot stock saja
│
├── restore_stock_vbmeta_only.bat
│   └── Script restore vbmeta original saja
│
├── boot/
│   │
│   ├── magisk_patched_boot.img
│   │   └── Boot hasil patch Magisk
│   │
│   └── stock_boot.img
│       └── Backup boot asli untuk rollback
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
    ├── image.png
    │   └── Screenshot proses / hasil di Device Manager
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
    ├── pgpt.bin
    │
    └── ums9230_hulk.xml
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
