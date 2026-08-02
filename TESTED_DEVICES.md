# TESTED DEVICES — Registry Status Pengujian

Daftar status hasil pengujian metode repository ini (BROM/SPD flash) pada
berbagai perangkat Android. Setiap **merek + model** yang sedang/sudah diuji
dicatat di sini sehingga status `tested` / `belum` selalu jelas.

> **Bagi pengembang:** tambahkan satu baris baru saat menguji perangkat baru
> atau memperbarui hasil. Jangan hapus riwayat baris lama — tulis baris baru
> dengan tanggal terbaru.

---

## Legenda Status

| Status      | Arti                                                            |
| ----------- | --------------------------------------------------------------- |
| ✅ Tested OK     | Booting + root terbukti berhasil di perangkat ini.          |
| ⚠️ Sebagian      | Flash/beberapa tahap berhasil, tapi root belum jalan / masih riset. |
| 🚧 Dalam uji     | Sedang diuji saat ini (riset aktif).                         |
| ❌ Gagal         | Metode terbukti gagal total di perangkat ini.               |
| ⬜ Belum diuji   | Terdaftar sebagai kandidat, belum ada hasil.                |

---

## Daftar Perangkat

| Status | Merek | Model | SoC / Board | Android | Metode root | Tanggal | Catatan |
| ------ | ----- | ----- | ----------- | ------- | ----------- | ------- | ------- |
| 🚧 Dalam uji | Realme | C53 (RMX3760) | Unisoc T612 (`UMS9230H`) / board `ums9230_hulk` | 14 (`RMX3760export_14_C.23`) | Magisk-patched `boot` + `vbmeta` disable, via BROM | 2026-08-02 | Bootloader **locked**, tanpa unlock. Boot patched Magisk (`VENDORBOOT=false` & `=true`) → **bootloop**; `init_boot` patched → tanpa efek; arsitektur: ramdisk `boot` = init asli (PID 1), init_boot/vendor_boot tidak dipakai. Re-encoded stock (eksperimen A) belum diuji. |

---

## Cara Menambah Perangkat Baru

1. Salin baris tabel di atas, ubah: `Status`, `Merek`, `Model`, `SoC/Board`,
   `Android`, `Metode root`, `Tanggal`, `Catatan`.
2. Pastikan bahan (`boot` / `vbmeta`) di folder `boot\` / `vbmeta\` sesuai
   firmware perangkat tersebut — **jangan** memakai bahan milik perangkat lain.
3. Perbarui juga bagian kompatibilitas di `README.md` bila perlu.

> ⚠️ File image (`boot`, `vbmeta`, `init_boot`) di repository ini dibuat dari
> firmware **RMX3760export_14_C.23 (Realme C53)** dan **tidak kompatibel**
> dengan perangkat lain tanpa bahan masing-masing.
