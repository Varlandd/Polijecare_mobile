# PolijeCare Mobile 📱

**PolijeCare Mobile** adalah aplikasi mobile resmi untuk layanan pengaduan, penanganan kasus kekerasan seksual/perundungan, dan bimbingan konseling yang dikelola oleh **Satgas PPKPT (Pencegahan dan Penanganan Kekerasan di Lingkungan Perguruan Tinggi) Politeknik Negeri Jember**.

Aplikasi ini dibangun menggunakan **Flutter** dan terhubung secara penuh (*1:1 parity*) dengan backend **Laravel 12 REST API** serta versi web **React 18 / Vite**.

---

## 📑 Daftar Isi

- [Fitur Utama](#-fitur-utama)
- [Struktur Arsitektur Project](#-struktur-arsitektur-project)
- [Teknologi yang Digunakan](#-teknologi-yang-digunakan)
- [Prasyarat Sistem](#-prasyarat-sistem)
- [Panduan Instalasi & Menjalankan](#-panduan-instalasi--menjalankan)
  - [1. Menjalankan Backend Laravel](#1-menjalankan-backend-laravel)
  - [2. Setup Project Mobile](#2-setup-project-mobile)
  - [3. Menjalankan di Android Emulator](#3-menjalankan-di-android-emulator)
  - [4. Menjalankan di HP Fisik (Real Device via USB / Wi-Fi)](#4-menjalankan-di-hp-fisik-real-device-via-usb--wi-fi)
- [Akun Pengujian (Testing Accounts)](#-akun-pengujian-testing-accounts)
- [Build APK Rilis](#-build-apk-rilis)

---

## ✨ Fitur Utama

### 🌐 1. Publik (Tanpa Perlu Login)
- **Landing Page Interaktif**: Ringkasan layanan, data statistik kasus, artikel edukasi terkini, dan profil kontak Satgas PPKPT.
- **Lapor Tanpa Login (Umum)**: Formulir pengaduan komprehensif bagi masyarakat umum/tamu dengan validasi KTP, identitas korban & terlapor, usulan jadwal konseling, pemilihan unit/lab Polije, dan unggah bukti pendukung.
- **Kode Akses Rahasia**: Menghasilkan ID Laporan & Tracking Code unik untuk melacak tindak lanjut tanpa membuka identitas pelapor.
- **Integrasi Hotline WhatsApp**: Tombol instan konfirmasi pengaduan dan bantuan darurat 24/7 langsung ke nomor WhatsApp Satgas.

### 👤 2. Mahasiswa / Pelapor (User Portal)
- **Autentikasi Aman**: Login berbasis Token Bearer (Sanctum) dengan verifikasi akun Polije.
- **Dashboard Pelapor**: Ringkasan status laporan (Pending, Diproses, Selesai) dan riwayat aktivitas.
- **Buat Laporan Terverifikasi**: Pengaduan resmi sivitas akademika Polije dengan data terintegrasi.
- **Histori & Detail Kasus**: Pelacakan status investigasi, kronologi penanganan, dan komunikasi dengan konselor.
- **Permohonan Konseling**: Pengajuan jadwal bimbingan konseling bersama tim konselor Satgas.
- **Profil Pengguna**: Manajemen biodata, kontak darurat, dan informasi akademik.

### 🩺 3. Konselor (Satgas PPKPT)
- **Dashboard Konselor**: Monitoring kasus yang ditugaskan, jadwal konseling hari ini, dan metrik penanganan.
- **Manajemen Kasus (Case Management)**: Filter kasus berdasarkan tingkat urgensi, update status tindak lanjut, dan dokumentasi catatan penanganan.
- **Pencatatan Konseling**: Manajemen jadwal konseling serta input data konseling manual/langsung di lapangan.
- **Pusat Materi Edukasi**: Akses dan unduh materi pedoman penanganan kekerasan di lingkungan kampus.

### 🛡️ 4. Super Admin (Operator)
- **Dashboard Eksekutif**: Analisis tren kekerasan tahunan/bulanan, distribusi unit terlapor, dan visualisasi status.
- **Manajemen Seluruh Pengaduan**: Disposisi konselor penanggung jawab, eskalasi urgensi kasus, dan export data.
- **Manajemen Pengguna**: Kontrol akses mahasiswa, konselor, dan operator admin.
- **Manajemen Kategori Kekerasan**: Tambah, edit, dan atur master kategori kekerasan kampus.
- **Manajemen Materi & Artikel**: Publikasi artikel edukasi, berita, dan modul pencegahan kekerasan.

---

## 🏗️ Struktur Arsitektur Project

Proyek ini menggunakan pendekatan **Feature-First / Modular Architecture**:

```
polijecare_mobile/
├── assets/
│   └── images/                     # Aset logo, ilustrasi hero, dan badge
├── lib/
│   ├── app/
│   │   └── routes.dart             # Konfigurasi routing terpusat (AppRoutes)
│   ├── core/
│   │   ├── config/
│   │   │   └── api_config.dart     # Auto-detect Base URL (Emulator, Device, Production)
│   │   ├── constants/
│   │   │   └── polije_data.dart    # Master data Jurusan, Prodi, Lab, Unit Polije
│   │   ├── network/
│   │   │   └── api_client.dart     # Dio HTTP client, Interceptors, Bearer Token
│   │   ├── theme/
│   │   │   ├── app_colors.dart     # Palet warna resmi PolijeCare
│   │   │   └── app_theme.dart      # ThemeData Material 3
│   │   └── utils/
│   │       ├── image_url.dart      # Resolver URL file/gambar backend
│   │       └── launcher.dart       # Helper WhatsApp, Email, Maps, & URL
│   ├── data/
│   │   ├── models/                 # Model data (AppUser, UserComplaint, Article, dll.)
│   │   └── services/               # API service layer & local fallback storage
│   ├── features/
│   │   ├── auth/                   # Halaman Login & Proteksi Route
│   │   ├── common/                 # Placeholder & widget umum
│   │   ├── konselor/               # Semua menu portal Konselor/Satgas
│   │   ├── landing/                # Landing page publik (Navbar, Hero, Footer, dll.)
│   │   ├── operator/               # Semua menu portal Super Admin/Operator
│   │   ├── public/                 # Lapor Tanpa Login & Halaman Publik
│   │   ├── shared/                 # Halaman Profil bersama
│   │   └── user/                   # Semua menu portal Mahasiswa/Pelapor
│   └── main.dart                   # Entry point aplikasi Flutter
└── pubspec.yaml                    # Dependensi dan aset aplikasi
```

---

## 🛠️ Teknologi yang Digunakan

| Komponen | Teknologi |
|---|---|
| **Framework** | [Flutter 3.x](https://flutter.dev) (Dart SDK ^3.10.7) |
| **HTTP & API Client** | `dio: ^5.7.0` |
| **Penyimpanan Lokal** | `shared_preferences: ^2.3.3` (Session cache & fallback offline) |
| **Manajemen Berkas** | `file_picker: ^8.1.4`, `image_picker: ^1.1.2` |
| **Formatting & Tanggal** | `intl: ^0.20.1` |
| **External Launcher** | `url_launcher: ^6.3.1` (WhatsApp Hotline, Google Maps, Telp) |
| **Image Caching** | `cached_network_image: ^3.4.1` |
| **Desain UI** | Material Design 3 diselaraskan dengan TailwindCSS Web PolijeCare |

---

## 📋 Prasyarat Sistem

Sebelum menjalankan aplikasi, pastikan Anda telah menginstal:
1. **Flutter SDK** (versi 3.10.x atau lebih baru) -> Periksa dengan `flutter doctor`
2. **Android Studio** atau **VS Code** dengan ekstensi Flutter & Dart
3. **Android SDK / Emulator** atau Smartphone Android dengan mode **USB Debugging** aktif
4. **Backend Laravel PolijeCare** telah berjalan (default port `8000`)

---

## 🚀 Panduan Instalasi & Menjalankan

### 1. Menjalankan Backend Laravel
Pastikan server backend PolijeCare aktif di terminal terpisah:
```bash
cd D:\Varrel\TA\TA3-POLIJECARE\backend
php artisan serve --host=0.0.0.0 --port=8000
```
> Menggunakan `--host=0.0.0.0` memungkinkan backend diakses tidak hanya oleh `localhost`, tetapi juga oleh emulator dan perangkat HP di jaringan lokal yang sama.

---

### 2. Setup Project Mobile
Buka direktori project mobile di terminal:
```bash
cd D:\Varrel\TA\TA-POLIJECARE-MOBILE\polijecare_mobile
flutter pub get
```

---

### 3. Menjalankan di Android Emulator
Pada Android Emulator, alamat `10.0.2.2` secara otomatis merujuk ke `localhost` komputer:
```bash
flutter run
```
Aplikasi sudah terkonfigurasi secara otomatis mengarahkan ke `http://10.0.2.2:8000/api` saat dijalankan di Android emulator.

---

### 4. Menjalankan di HP Fisik (Real Device via USB / Wi-Fi)

Jika Anda ingin menjalankan aplikasi langsung di HP:

#### Opsi A: Menggunakan `adb reverse` (Koneksi Kabel USB - Paling Direkomendasikan)
Hubungkan HP ke laptop via kabel USB dengan **USB Debugging** aktif, lalu jalankan di terminal:
```bash
adb reverse tcp:8000 tcp:8000
flutter run
```
Dengan perintah ini, HP Anda dapat mengakses backend komputer secara langsung melalui `http://localhost:8000/api`.

#### Opsi B: Menggunakan Alamat IP Wi-Fi Komputer
1. Pastikan laptop dan HP terhubung ke **jaringan Wi-Fi yang sama**.
2. Cek IP lokal laptop Anda di terminal via `ipconfig` (misalnya: `192.168.1.15`).
3. Jalankan Flutter dengan parameter `--dart-define`:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.15:8000/api
```

---

## 👥 Akun Pengujian (Testing Accounts)

Sesuai dengan database seeder bawaan backend Laravel (`DatabaseSeeder.php`):

| Role | Email / Identifier | Password | Hak Akses |
|---|---|---|---|
| **Super Admin** | `admin@polije.ac.id` | `password` | Akses penuh dashboard operator, pengguna, kategori, artikel |
| **Konselor** | `konselor@polije.ac.id` | `password` | Penanganan kasus satgas, rekap konseling, materi |
| **Mahasiswa** | `mhs@polije.ac.id` / `user@polije.ac.id` | `password` | Buat laporan, histori laporan, pengajuan konseling |

> *Catatan:* Anda juga dapat mencoba fitur **Lapor Tanpa Login** langsung dari halaman utama tanpa perlu masuk ke akun terlebih dahulu.

---

## 📦 Build APK Rilis

Untuk menghasilkan file installer `.apk` yang siap di-install di perangkat Android:

```bash
# Build APK standar
flutter build apk --release

# Atau build dengan custom API URL produksi:
flutter build apk --release --dart-define=API_BASE_URL=https://polijecare.my.id/backend/api
```

File output APK akan berada di direktori:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🔒 Kebijakan & Privasi

Aplikasi ini mematuhi amanat **Permendikbudristek No. 55 Tahun 2024 Pasal 30** mengenai perlindungan identitas korban dan saksi dalam pencegahan dan penanganan kekerasan di lingkungan perguruan tinggi. Seluruh data identitas terenkripsi dan hanya dapat diakses oleh anggota Satuan Tugas yang berwenang.

---

**© 2026 Satgas PPKPT Politeknik Negeri Jember. All Rights Reserved.**

## ✨ Fitur Utama

### 🌐 1. Publik (Tanpa Perlu Login)
- **Landing Page Interaktif**: Ringkasan layanan, data statistik kasus, artikel edukasi terkini, dan profil kontak Satgas PPKPT.
- **Lapor Tanpa Login (Umum)**: Formulir pengaduan komprehensif bagi masyarakat umum/tamu dengan validasi KTP, identitas korban & terlapor, usulan jadwal konseling, pemilihan unit/lab Polije, dan unggah bukti pendukung.
- **Kode Akses Rahasia**: Menghasilkan ID Laporan & Tracking Code unik untuk melacak tindak lanjut tanpa membuka identitas pelapor.
- **Integrasi Hotline WhatsApp**: Tombol instan konfirmasi pengaduan dan bantuan darurat 24/7 langsung ke nomor WhatsApp Satgas.

### 👤 2. Mahasiswa / Pelapor (User Portal)
- **Autentikasi Aman**: Login berbasis Token Bearer (Sanctum) dengan verifikasi akun Polije.
- **Dashboard Pelapor**: Ringkasan status laporan (Pending, Diproses, Selesai) dan riwayat aktivitas.
- **Buat Laporan Terverifikasi**: Pengaduan resmi sivitas akademika Polije dengan data terintegrasi.
- **Histori & Detail Kasus**: Pelacakan status investigasi, kronologi penanganan, dan komunikasi dengan konselor.
- **Permohonan Konseling**: Pengajuan jadwal bimbingan konseling bersama tim konselor Satgas.
- **Profil Pengguna**: Manajemen biodata, kontak darurat, dan informasi akademik.

### 🩺 3. Konselor (Satgas PPKPT)
- **Dashboard Konselor**: Monitoring kasus yang ditugaskan, jadwal konseling hari ini, dan metrik penanganan.
- **Manajemen Kasus (Case Management)**: Filter kasus berdasarkan tingkat urgensi, update status tindak lanjut, dan dokumentasi catatan penanganan.
- **Pencatatan Konseling**: Manajemen jadwal konseling serta input data konseling manual/langsung di lapangan.
- **Pusat Materi Edukasi**: Akses dan unduh materi pedoman penanganan kekerasan di lingkungan kampus.

### 🛡️ 4. Super Admin (Operator)
- **Dashboard Eksekutif**: Analisis tren kekerasan tahunan/bulanan, distribusi unit terlapor, dan visualisasi status.
- **Manajemen Seluruh Pengaduan**: Disposisi konselor penanggung jawab, eskalasi urgensi kasus, dan export data.
- **Manajemen Pengguna**: Kontrol akses mahasiswa, konselor, dan operator admin.
- **Manajemen Kategori Kekerasan**: Tambah, edit, dan atur master kategori kekerasan kampus.
- **Manajemen Materi & Artikel**: Publikasi artikel edukasi, berita, dan modul pencegahan kekerasan.

---

## 🏗️ Struktur Arsitektur Project

Proyek ini menggunakan pendekatan **Feature-First / Modular Architecture**:

```
polijecare_mobile/
├── assets/
│   └── images/                     # Aset logo, ilustrasi hero, dan badge
├── lib/
│   ├── app/
│   │   └── routes.dart             # Konfigurasi routing terpusat (AppRoutes)
│   ├── core/
│   │   ├── config/
│   │   │   └── api_config.dart     # Auto-detect Base URL (Emulator, Device, Production)
│   │   ├── constants/
│   │   │   └── polije_data.dart    # Master data Jurusan, Prodi, Lab, Unit Polije
│   │   ├── network/
│   │   │   └── api_client.dart     # Dio HTTP client, Interceptors, Bearer Token
│   │   ├── theme/
│   │   │   ├── app_colors.dart     # Palet warna resmi PolijeCare
│   │   │   └── app_theme.dart      # ThemeData Material 3
│   │   └── utils/
│   │       ├── image_url.dart      # Resolver URL file/gambar backend
│   │       └── launcher.dart       # Helper WhatsApp, Email, Maps, & URL
│   ├── data/
│   │   ├── models/                 # Model data (AppUser, UserComplaint, Article, dll.)
│   │   └── services/               # API service layer & local fallback storage
│   ├── features/
│   │   ├── auth/                   # Halaman Login & Proteksi Route
│   │   ├── common/                 # Placeholder & widget umum
│   │   ├── konselor/               # Semua menu portal Konselor/Satgas
│   │   ├── landing/                # Landing page publik (Navbar, Hero, Footer, dll.)
│   │   ├── operator/               # Semua menu portal Super Admin/Operator
│   │   ├── public/                 # Lapor Tanpa Login & Halaman Publik
│   │   ├── shared/                 # Halaman Profil bersama
│   │   └── user/                   # Semua menu portal Mahasiswa/Pelapor
│   └── main.dart                   # Entry point aplikasi Flutter
└── pubspec.yaml                    # Dependensi dan aset aplikasi
```

---

## 🛠️ Teknologi yang Digunakan

| Komponen | Teknologi |
|---|---|
| **Framework** | [Flutter 3.x](https://flutter.dev) (Dart SDK ^3.10.7) |
| **HTTP & API Client** | `dio: ^5.7.0` |
| **Penyimpanan Lokal** | `shared_preferences: ^2.3.3` (Session cache & fallback offline) |
| **Manajemen Berkas** | `file_picker: ^8.1.4`, `image_picker: ^1.1.2` |
| **Formatting & Tanggal** | `intl: ^0.20.1` |
| **External Launcher** | `url_launcher: ^6.3.1` (WhatsApp Hotline, Google Maps, Telp) |
| **Image Caching** | `cached_network_image: ^3.4.1` |
| **Desain UI** | Material Design 3 diselaraskan dengan TailwindCSS Web PolijeCare |

---

## 📋 Prasyarat Sistem

Sebelum menjalankan aplikasi, pastikan Anda telah menginstal:
1. **Flutter SDK** (versi 3.10.x atau lebih baru) -> Periksa dengan `flutter doctor`
2. **Android Studio** atau **VS Code** dengan ekstensi Flutter & Dart
3. **Android SDK / Emulator** atau Smartphone Android dengan mode **USB Debugging** aktif
4. **Backend Laravel PolijeCare** telah berjalan (default port `8000`)

---

## 🚀 Panduan Instalasi & Menjalankan

### 1. Menjalankan Backend Laravel
Pastikan server backend PolijeCare aktif di terminal terpisah:
```bash
cd D:\Varrel\TA\TA3-POLIJECARE\backend
php artisan serve --host=0.0.0.0 --port=8000
```
> Menggunakan `--host=0.0.0.0` memungkinkan backend diakses tidak hanya oleh `localhost`, tetapi juga oleh emulator dan perangkat HP di jaringan lokal yang sama.

---

### 2. Setup Project Mobile
Buka direktori project mobile di terminal:
```bash
cd D:\Varrel\TA\TA-POLIJECARE-MOBILE\polijecare_mobile
flutter pub get
```

---

### 3. Menjalankan di Android Emulator
Pada Android Emulator, alamat `10.0.2.2` secara otomatis merujuk ke `localhost` komputer:
```bash
flutter run
```
Aplikasi sudah terkonfigurasi secara otomatis mengarahkan ke `http://10.0.2.2:8000/api` saat dijalankan di Android emulator.

---

### 4. Menjalankan di HP Fisik (Real Device via USB / Wi-Fi)

Jika Anda ingin menjalankan aplikasi langsung di HP:

#### Opsi A: Menggunakan `adb reverse` (Koneksi Kabel USB - Paling Direkomendasikan)
Hubungkan HP ke laptop via kabel USB dengan **USB Debugging** aktif, lalu jalankan di terminal:
```bash
adb reverse tcp:8000 tcp:8000
flutter run
```
Dengan perintah ini, HP Anda dapat mengakses backend komputer secara langsung melalui `http://localhost:8000/api`.

#### Opsi B: Menggunakan Alamat IP Wi-Fi Komputer
1. Pastikan laptop dan HP terhubung ke **jaringan Wi-Fi yang sama**.
2. Cek IP lokal laptop Anda di terminal via `ipconfig` (misalnya: `192.168.1.15`).
3. Jalankan Flutter dengan parameter `--dart-define`:
```bash
flutter run --dart-define=API_BASE_URL=http://192.168.1.15:8000/api
```

---

## 👥 Akun Pengujian (Testing Accounts)

Sesuai dengan database seeder bawaan backend Laravel (`DatabaseSeeder.php`):

| Role | Email / Identifier | Password | Hak Akses |
|---|---|---|---|
| **Super Admin** | `admin@polije.ac.id` | `password` | Akses penuh dashboard operator, pengguna, kategori, artikel |
| **Konselor** | `konselor@polije.ac.id` | `password` | Penanganan kasus satgas, rekap konseling, materi |
| **Mahasiswa** | `mhs@polije.ac.id` / `user@polije.ac.id` | `password` | Buat laporan, histori laporan, pengajuan konseling |

> *Catatan:* Anda juga dapat mencoba fitur **Lapor Tanpa Login** langsung dari halaman utama tanpa perlu masuk ke akun terlebih dahulu.

---

## 📦 Build APK Rilis

Untuk menghasilkan file installer `.apk` yang siap di-install di perangkat Android:

```bash
# Build APK standar
flutter build apk --release

# Atau build dengan custom API URL produksi:
flutter build apk --release --dart-define=API_BASE_URL=https://polijecare.my.id/backend/api
```

File output APK akan berada di direktori:
`build/app/outputs/flutter-apk/app-release.apk`

---

## 🔒 Kebijakan & Privasi

Aplikasi ini mematuhi amanat **Permendikbudristek No. 55 Tahun 2024 Pasal 30** mengenai perlindungan identitas korban dan saksi dalam pencegahan dan penanganan kekerasan di lingkungan perguruan tinggi. Seluruh data identitas terenkripsi dan hanya dapat diakses oleh anggota Satuan Tugas yang berwenang.

---

**© 2026 Satgas PPKPT Politeknik Negeri Jember. All Rights Reserved.**

