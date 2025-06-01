# Panduan Pengujian Manual - Fitur Pencarian Tempat Ibadah

## Persiapan
1. Pastikan aplikasi sudah ter-install
2. Pastikan lokasi (GPS) perangkat aktif
3. Pastikan terhubung ke internet

## Skenario Pengujian

### 1. Pengujian Izin Lokasi
- [ ] Buka aplikasi dan masuk ke halaman Peta
- [ ] Verifikasi aplikasi meminta izin akses lokasi
- [ ] Terima izin lokasi dan pastikan koordinat pengguna muncul
- [ ] Verifikasi status "AKTIF" muncul saat lokasi tersedia

### 2. Pengujian Pencarian Tempat Ibadah
- [ ] Klik tombol ikon gereja di app bar
- [ ] Verifikasi loading indicator muncul
- [ ] Tunggu hingga marker tempat ibadah muncul di peta
- [ ] Pastikan marker menggunakan ikon yang berbeda (ungu)
- [ ] Verifikasi label "Tempat Ibadah" muncul di atas marker

### 3. Pengujian Detail Tempat Ibadah
- [ ] Klik salah satu marker tempat ibadah
- [ ] Verifikasi dialog detail muncul
- [ ] Pastikan informasi berikut ditampilkan:
  - Nama/alamat tempat ibadah
  - Koordinat (latitude & longitude)
  - Tombol Tutup dan Navigasi

### 4. Pengujian Radius Pencarian
- [ ] Geser slider radius pencarian
- [ ] Verifikasi nilai radius berubah (dalam meter)
- [ ] Klik tombol pencarian tempat ibadah
- [ ] Pastikan hasil pencarian sesuai dengan radius yang dipilih

### 5. Pengujian Navigasi
- [ ] Klik marker tempat ibadah
- [ ] Klik tombol "Navigasi" pada dialog detail
- [ ] Verifikasi aplikasi membuka Google Maps
- [ ] Pastikan rute dari lokasi pengguna ke tempat ibadah ditampilkan

### 6. Pengujian Error Handling
- [ ] Matikan internet
- [ ] Coba lakukan pencarian
- [ ] Verifikasi pesan error muncul
- [ ] Nyalakan internet dan coba lagi
- [ ] Matikan GPS
- [ ] Verifikasi pesan error lokasi muncul

## Hasil yang Diharapkan
- Aplikasi dapat menampilkan tempat ibadah terdekat
- Marker tempat ibadah tampil dengan jelas dan informatif
- Dialog detail menampilkan informasi yang akurat
- Navigasi ke tempat ibadah berfungsi dengan baik
- Error handling berjalan sesuai ekspektasi

## Catatan Tambahan
- Catat jika ada lag/delay saat pencarian
- Catat jika ada crash atau error tidak terduga
- Catat jika ada masalah UI/UX
- Dokumentasikan semua bug yang ditemukan

## Status Pengujian
- [ ] Semua test case berhasil
- [ ] Ada bug minor
- [ ] Ada bug major
- [ ] Gagal/Perlu perbaikan

## Bug Report Template
```
Judul Bug:
Severity: (Critical/Major/Minor)
Langkah Reproduksi:
1. 
2. 
3. 

Hasil Aktual:
Hasil yang Diharapkan:
Screenshot (jika ada):
