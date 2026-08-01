# Flash Manual Interaktif via BROM (FDL2> prompt)

Dua cara untuk flash root: **script `.bat` otomatis** atau **ketik perintah manual**.
Panduan ini untuk cara manual — cocok untuk user yang mau kontrol penuh dan
ketik partisi satu-persatu.

---

## 🎛️ Penting: Slot A/B

Device memakai sistem **A/B (VAB)** — partisi ada dua salinan: `boot_a`/`boot_b`,
`vbmeta_a`/`vbmeta_b`, `l_fixnv1_a`/`l_fixnv1_b`, dst.

**Yang harus di-flash = slot yang aktif.** Cek slot aktif:

```
adb shell getprop ro.boot.slot_suffix
```

- `_a` → flash `boot_a`, `vbmeta_a` (sama seperti contoh di repo ini)
- `_b` → flash `boot_b`, `vbmeta_b`

Contoh di panduan ini memakai slot **`_a`** (slot aktif device uji).
Jika slot aktif Anda `_b`, ganti `boot_a`→`boot_b` dan `vbmeta_a`→`vbmeta_b`.

Di prompt FDL2>, slot aktif bisa dicek / diubah:
```
FDL2> p                       REM lihat daftar partisi (boot_a & boot_b)
FDL2> set_active a            REM paksa slot A aktif
FDL2> set_active b            REM paksa slot B aktif
```

---

## Persiapan

1. Buka **Command Prompt** di folder `brom\` repo ini:
   ```
   cd /d D:\porting-custom-rom\root-work\brom
   ```
2. Masukkan device ke **download mode** (BROM):
   - Matikan device (power off).
   - Tahan **Volume + dan Volume −** bersamaan.
   - Sambil menahan, colokkan kabel USB ke PC.
   - Tunggu muncul **`OPPO download port`** (`VID_22D9`) di Device Manager.

---

## Masuk ke Prompt FDL2>

Jalankan spd_dump dengan opsi FDL1 + FDL2 + `exec`, TANPA perintah flash:

```
spd_dump.exe --wait 300 exec_addr 0x65015f08 fdl fdl1-sign.bin 0x65000800 fdl lk-fdl2-sign.bin 0x9EFFFE00 exec
```

Setelah koneksi sukses, prompt berubah menjadi:

```
FDL2>
```

Dari sini Anda bisa ketik perintah satu-persatu (lihat daftar di bawah).

---

## Perintah Interaktif (FDL2>)

### 1. Lihat daftar partisi

```
p
```

Contoh output: daftar nama partisi + ukuran.

### 2. Flash partisi `boot_a` (boot patched Magisk)

```
w_force boot_a ..\boot\magisk_patched_boot.img
```

> ⚠️ `w_force` dipakai agar bisa menulis partisi yang terkunci/protected
> (seperti boot) di slot A/B. Script `flash_root_boot_vbmeta.bat` juga memakai
> `w_force`.

### 3. Flash partisi `vbmeta_a` (vbmeta disabled flags=2)

```
w_force vbmeta_a ..\vbmeta\vbmeta_a_disabled.img
```

### 4. (Opsional) Flash partisi lain satu-persatu

Contoh umum:

```
w_force boot_b ..\boot\magisk_patched_boot.img   REM flash slot B juga
w_force vbmeta_b ..\vbmeta\vbmeta_a_disabled.img REM vbmeta slot B
read_part boot_a 0 67108864 ..\verify_out\cek_boot_a.img
read_part vbmeta_a 0 1048576 ..\verify_out\cek_vbmeta_a.img
size_part boot_a
check_part vbmeta_a
```

### 5. Reboot

```
reboot-fastboot
```
atau
```
reset
```
atau
```
poweroff
```

---

## Catatan Path

Karena prompt dijalankan dari folder `brom\`, file bahan ada di folder induk:

| File | Path relatif dari `brom\` |
|---|---|
| Boot patched Magisk | `..\boot\magisk_patched_boot.img` |
| vbmeta disabled flags=2 | `..\vbmeta\vbmeta_a_disabled.img` |
| vbmeta asli (cadangan) | `..\vbmeta\vbmeta_a_original.img` |

Hasil read-back disarankan disimpan di `..\verify_out\` (folder dibuat otomatis oleh script `.bat`).

---

## Referensi Perintah Lengkap

Perintah runtime yang didukung `spd_dump.exe` (dari `spd_dump -h`):

| Perintah | Fungsi |
|---|---|
| `p` | Print daftar partisi |
| `read_part <name> <off> <size> <file>` | Baca partisi ke file |
| `w_force <name> <file>` | Tulis partisi (bypass protected) |
| `w` / `write_part <name> <file>` | Tulis partisi |
| `e` / `erase_part <name>` | Hapus partisi |
| `size_part <name>` | Lihat ukuran partisi |
| `check_part <name>` | Cek partisi ada/tidak |
| `set_active {a,b}` | Set slot aktif (VAB) |
| `verity {0,1}` | Atur dm-verity (Android 10+) |
| `r all_lite` | Backup penuh (tanpa slot inaktif/cache/userdata) |
| `path <dir>` | Ubah folder simpan hasil |
| `reboot-fastboot` | Reboot ke fastboot |
| `reset` | Reboot device |
| `poweroff` | Matikan device |
