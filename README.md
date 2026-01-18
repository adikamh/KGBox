# KGBox - Warehouse Inventory Management System

KGBox adalah aplikasi manajemen inventaris gudang berbasis Flutter yang dirancang untuk membantu pemilik bisnis dan staf dalam mengelola produk, stok, dan operasi gudang secara efisien.

## Instalasi dan Setup Awal

### Prasyarat
- **Flutter SDK**: Versi 3.9.2 atau lebih tinggi
- **Dart SDK**: Versi yang sesuai dengan Flutter SDK
- **Android Studio** atau **Xcode** untuk emulator
- **Git**: Untuk clone repository
- **Akun Firebase**: Untuk konfigurasi authentication dan Firestore

### Langkah-Langkah Instalasi

#### 1. Clone Repository
```bash
git clone https://github.com/yourusername/KGBox.git
cd KGBox
```

#### 2. Install Dependencies
```bash
flutter pub get
```

#### 3. Konfigurasi Firebase
1. Buat project baru di [Firebase Console](https://console.firebase.google.com)
2. Aktifkan authentication dengan Email/Password
3. Setup Firestore Database dengan security rules yang sesuai
4. Aktifkan Cloud Messaging untuk notifikasi
5. Download `google-services.json` untuk Android dan letakkan di `android/app/`
6. Update konfigurasi Firebase di `lib/services/firebase_options.dart`

#### 4. Konfigurasi REST API (Opsional)
Jika menggunakan REST API untuk data order dan customer:
1. Setup backend server dengan endpoint API
2. Konfigurasi `lib/services/config.dart` dengan API URL dan credentials

#### 5. Jalankan Aplikasi
```bash
# Untuk Android
flutter run -d android

# Untuk iOS
flutter run -d ios

# Untuk Web
flutter run -d chrome
```

## Panduan Penggunaan Aplikasi

### A. Untuk Pemilik Bisnis (Owner)

#### Saat Pertama Kali Membuka Aplikasi
1. **Splash Screen**: Tunggu 5 detik pada layar pembuka dengan logo KGBox
2. **Login atau Registrasi**: 
   - Jika sudah punya akun, masukkan email dan password Anda
   - Jika belum punya akun, klik "Registrasi" dan isi form pendaftaran
   - Untuk lupa password, klik "Reset Password" dan ikuti instruksi

#### Dashboard Owner - Menu Utama
Setelah login, Anda akan masuk ke **Dashboard Owner** dengan menu-menu berikut:

**1. Statistik Ringkas**
   - Total Produk: Jumlah semua produk di inventaris
   - Barang Masuk: Produk yang diterima minggu ini
   - Barang Keluar: Produk yang telah dijual/dikeluarkan
   - Lihat chart visual untuk melihat tren 12 bulan terakhir

**2. Manajemen Produk**
   - **Lihat Produk**: Tap menu "Produk" untuk melihat daftar semua produk
   - **Tambah Produk**: Klik tombol "Tambah" dan isi detail produk (nama, harga, jumlah stok, tanggal kadaluarsa, dll)
   - **Edit Produk**: Dari daftar produk, tap produk untuk edit informasinya
   - **Cari Produk**: Gunakan fitur search untuk menemukan produk dengan cepat

**3. Monitoring Stok**
   - **Stok Keseluruhan**: Lihat jumlah stok semua produk di halaman "Stok"
   - **Permintaan Stok**: Kelola permintaan stok dari staff di bagian "Manajemen Stok"
   - **Persetujuan/Penolakan**: Approve atau reject permintaan stok berdasarkan kebutuhan

**4. Manajemen Staff**
   - **Lihat Daftar Staff**: Tap menu "Kelola Staff"
   - **Tambah Staff**: Klik "Tambah Staff" dan isi informasi (nama, email, phone, role)
   - **Edit Staff**: Tap staff untuk mengubah data atau role
   - **Hapus Staff**: Tap staff dan pilih delete (staff tidak bisa login setelah dihapus)

**5. Manajemen Supplier**
   - **Lihat Supplier**: Buka menu "Supplier"
   - **Tambah Supplier**: Klik tombol tambah dan isi info supplier (nama, contact, address)
   - **Edit Supplier**: Tap supplier untuk mengubah informasi

**6. Pengiriman & Order**
   - **Lihat Order**: Buka menu "Pengiriman" untuk melihat daftar order
   - **Tracking**: Lihat status pengiriman setiap order (Pending, Dalam Proses, Terkirim)
   - **Update Status**: Update status pengiriman saat ada perubahan

**7. Laporan & Analitik**
   - **Produk Kadaluarsa**: Lihat produk yang sudah melewati tanggal kadaluarsa
   - **Best Seller**: Lihat produk yang paling laris terjual
   - **Laporan Produk**: Generate laporan produk tersedia dalam format CSV/PDF/Excel
   - **Laporan Kadaluarsa**: Generate laporan produk kadaluarsa
   - **Laporan Order**: Generate laporan pengiriman dan order

**8. Notifikasi**
   - **Notifikasi Real-time**: Terima notifikasi push otomatis untuk:
     - Produk yang akan kadaluarsa
     - Permintaan stok dari staff
     - Order baru yang masuk
   - **Pusat Notifikasi**: Tap icon bell untuk melihat semua notifikasi
   - **Tandai sebagai Dibaca**: Tap notifikasi untuk menandainya sebagai dibaca

---

### B. Untuk Staf Gudang (Staff)

#### Saat Pertama Kali Login
1. Masukkan email dan password yang diberikan oleh owner
2. Setelah login sukses, Anda akan masuk ke **Dashboard Staff**

#### Dashboard Staff - Tugas Harian

**1. Pencatatan Barang Keluar**
   - **Tap Menu "Catat Barang Keluar"**
   - **Scan Barcode**: Gunakan scanner untuk scan barcode produk
   - **Masukkan Jumlah**: Berapa banyak produk yang keluar
   - **Konfirmasi**: Tap "Simpan" untuk mencatat barang keluar
   - Sistem otomatis mengurangi stok produk

**2. Lihat Stok Produk**
   - **Tap Menu "Stok Produk"**
   - Lihat daftar semua produk dan stok saat ini
   - Gunakan search untuk cari produk tertentu
   - Tap produk untuk lihat detail (harga, exp date, supplier)

**3. Penerimaan Barang Masuk**
   - Informasi barang masuk akan dikirim melalui notifikasi
   - Scan barcode menggunakan fitur **Barcode Scanner**
   - Catat jumlah barang yang diterima
   - Sistem otomatis menambah stok

**4. Lihat Produk Best Seller**
   - **Tap Menu "Best Seller"**
   - Lihat produk apa yang paling banyak terjual
   - Berguna untuk planning stok yang lebih baik

**5. Pantau Produk Kadaluarsa**
   - **Tap Menu "Produk Kadaluarsa"**
   - Lihat daftar produk yang sudah atau hampir kadaluarsa
   - Laporkan kepada owner untuk tindakan lanjut

**6. Notifikasi & Komunikasi**
   - Terima notifikasi untuk tugas/permintaan dari owner
   - **Tap Icon Bell** untuk lihat semua notifikasi
   - Tandai notifikasi sebagai dibaca setelah menyelesaikan tugas

---

### C. Fitur Umum untuk Semua User

#### 1. Barcode Scanner
```
Lokasi: Tersedia di beberapa halaman untuk scan produk cepat
Cara Menggunakan:
- Tap icon scanner di dashboard
- Arahkan kamera ke barcode produk
- Sistem otomatis membaca dan menampilkan data produk
- Tap add untuk menambahkan ke list
```

#### 2. Export Laporan
```
Lokasi: Dashboard Owner → Menu Export Report
Format: CSV, PDF, atau Excel
Jenis Laporan:
- Laporan Produk Tersedia
- Laporan Produk Kadaluarsa
- Laporan Order/Pengiriman
- Laporan Transaksi

Cara:
1. Pilih jenis laporan
2. Pilih format export (CSV/PDF/Excel)
3. Tap "Export"
4. File otomatis tersimpan atau bisa di-share
```

#### 3. Search & Filter
```
Fitur: Tersedia di List Produk, Staff, Supplier, Order
Cara:
- Tap kolom search di halaman
- Ketik nama produk/staff/supplier yang dicari
- Hasil otomatis ter-filter saat ketik
- Gunakan clear untuk reset search
```

#### 4. Logout
```
Lokasi: Menu Settings / Profile
Cara:
- Tap menu hamburger atau icon profile
- Pilih "Logout"
- Konfirmasi logout
- Akan kembali ke halaman login
```

---

### D. Tips & Best Practices

1. **Atur Notifikasi**
   - Izinkan notifikasi push agar mendapat update real-time
   - Check notifikasi secara berkala untuk tidak melewatkan informasi penting

2. **Backup Data**
   - Data tersimpan di Firebase Firestore secara otomatis
   - Pastikan koneksi internet stabil saat melakukan operasi penting

3. **Keamanan Password**
   - Gunakan password yang kuat untuk akun owner
   - Jangan share password dengan siapapun
   - Jika lupa password, gunakan fitur "Reset Password"

4. **Efisiensi Operasional**
   - Gunakan barcode scanner untuk input data lebih cepat
   - Check dashboard setiap hari untuk monitoring stok
   - Gunakan laporan untuk decision making yang lebih baik

5. **Maintenance**
   - Hapus notifikasi lama yang sudah tidak relevan
   - Update data produk jika ada perubahan harga/supplier
   - Review laporan kadaluarsa secara berkala

## Fitur Utama

### 1. Autentikasi Pengguna

- **[Login](lib/screens/login_screen.dart)**: Sistem login dengan autentikasi Firebase untuk owner dan staff.
- **[Registrasi](lib/screens/register_screen.dart)**: Pendaftaran akun baru untuk pengguna baru.
- **[Reset Password](lib/screens/reset_password_screen.dart)**: Fitur lupa password untuk pemulihan akun.

### 2. Dashboard

- **[Dashboard Owner](lib/pages/dashboard_owner_page.dart)**: Tampilan utama untuk pemilik dengan ringkasan produk, barang masuk/keluar, dan performa tahunan.
- **[Dashboard Staff](lib/pages/dashboard_staff_page.dart)**: Dashboard khusus untuk staf dengan akses terbatas sesuai peran.

### 3. Manajemen Produk

- **[Tambah Produk](lib/pages/tambah_product_page.dart)**: Menambahkan produk baru ke inventaris dengan detail lengkap.
- **[Edit Produk](lib/pages/edit_product_page.dart)**: Mengubah informasi produk yang sudah ada.
- **[List Produk](lib/pages/list_product_page.dart)**: Menampilkan daftar semua produk dengan fitur pencarian.
- **[Detail Produk](lib/pages/detail_product_page.dart)**: Melihat informasi detail produk tertentu.
- **[Scan Barcode](lib/pages/barcode_scanner_page.dart)**: Pemindaian multiplebarcode untuk identifikasi produk cepat.

### 4. Manajemen Stok

- **[Stok Owner](lib/pages/stok_owner_page.dart)**: Monitoring stok keseluruhan untuk pemilik.
- **[Stok Produk](lib/pages/stok_produk_page.dart)**: Pengelolaan stok per produk individual.

### 5. Manajemen Staff

- **[Kelola Staff](lib/pages/kelola_staff_page.dart)**: Mengelola daftar staf, menambah, mengedit, dan menghapus staf.
- **[Tambah Staff](lib/pages/tambah_staff_page.dart)**: Menambahkan staf baru ke sistem.
- **[Edit Staff](lib/pages/edit_staff_page.dart)**: Mengubah informasi staf yang sudah ada.

### 6. Manajemen Supplier

- **[Supplier](lib/pages/supplier_page.dart)**: Mengelola daftar supplier dan informasi terkait.

### 7. Manajemen Pesanan dan Pengiriman

- **[Pengiriman](lib/pages/pengiriman_page.dart)**: Mengelola pesanan dan proses pengiriman barang.

### 8. Monitoring Produk

- **[Produk Kadaluarsa](lib/pages/expired_page.dart)**: Melacak produk yang sudah kadaluarsa.
- **[Best Seller](lib/pages/bestseller_page.dart)**: Menampilkan produk terlaris berdasarkan penjualan.
- **[Catat Barang Keluar](lib/pages/catat_barang_keluar_page.dart)**: Mencatat pengeluaran barang dari gudang.

### 9. Notifikasi

- **[Notifikasi](lib/pages/notifications_page.dart)**: Sistem notifikasi push menggunakan Firebase Cloud Messaging (FCM).
- **[Service Notifikasi](lib/services/notifications_service.dart)**: Layanan untuk menangani notifikasi lokal dan push.

### 10. Laporan dan Ekspor

- **[Export Report](lib/pages/export_report_page.dart)**: Mengekspor laporan dalam format CSV, PDF, dan Excel.
- **[Service Export](lib/services/export_service.dart)**: Layanan untuk menangani ekspor data ke berbagai format.

### 11. Analitik dan Chart

- **Product Flow Chart**: Visualisasi alur produk masuk dan keluar (terintegrasi di [Dashboard Owner](lib/pages/dashboard_owner_page.dart)).
- **Financial Overview**: Ringkasan performa keuangan dengan chart transaksi bulanan (terintegrasi di [Dashboard Owner](lib/pages/dashboard_owner_page.dart)).
- **Chart Owner Screen**: Layar khusus untuk menampilkan chart alur produk dengan data dinamis 12 bulan terakhir dari data Firestore dan REST API.

### 12. Splash Screen

- **[Splash Screen](lib/screens/splash_screen.dart)**: Layar pembuka aplikasi yang menampilkan logo/brand selama 5 detik sebelum mengarahkan ke halaman login. Menggunakan custom asset image untuk branding yang lebih baik.

### 13. Notifikasi Owner

- **[Notifikasi Owner Page](lib/pages/notifikasi_owner_page.dart)**: Dashboard notifikasi khusus untuk owner dengan fitur pencarian notifikasi real-time.
- **[Notifikasi Owner Screen](lib/screens/notifikasi_owner_screen.dart)**: Service controller untuk mengelola notifikasi owner termasuk mark as read, delete, dan stream notifications.
- **[Notification Owner Service](lib/services/notification_owner_service.dart)**: Service backend untuk menangani operasi notifikasi di Firestore.

### 14. Integrasi REST API

- **Advanced Export Service**: Service untuk mengekspor berbagai jenis laporan (produk tersedia, produk kadaluarsa, order pengiriman, staff, supplier, transaksi, barang keluar/masuk) ke format CSV dan JSON.
- **Integrasi API Dinamis**: Dashboard dan chart menggunakan REST API untuk data order dan customer real-time, dengan caching dan polling otomatis.

## Penjelasan pubspec.yaml

File `pubspec.yaml` adalah konfigurasi utama project Flutter yang mendefinisikan metadata, dependencies, dan asset aplikasi.

### Metadata Aplikasi
```yaml
name: KGbox                    # Nama aplikasi
description: "A new Flutter project."  # Deskripsi
version: 1.0.0+3             # Versi: 1.0.0 (version code) + 3 (build number)
publish_to: 'none'           # Private package (tidak dipublikasikan ke pub.dev)
```

### Environment & SDK
```yaml
environment:
  sdk: ^3.9.2                # Kompatibel dengan Dart SDK 3.9.2 atau lebih tinggi
```

### Dependencies (Library Eksternal)

#### **Authentication & Backend**
- **`firebase_auth: ^5.7.0`** - Firebase Authentication untuk login/registrasi user
- **`google_sign_in: ^6.0.0`** - Google Sign-In (opsional untuk integrasi Google)
- **`cloud_firestore: ^5.6.12`** - Firestore database untuk menyimpan data (produk, staff, order, dll)
- **`firebase_messaging: ^15.2.10`** - Firebase Cloud Messaging untuk notifikasi push

#### **Networking & API**
- **`http: ^0.13.6`** - HTTP client untuk komunikasi REST API

#### **Barcode & Scanner**
- **`mobile_scanner: ^7.1.4`** - Library untuk scan barcode menggunakan kamera

#### **UI & UX**
- **`cupertino_icons: ^1.0.8`** - iOS-style icons
- **`device_preview: ^1.1.1`** - Preview aplikasi di berbagai ukuran device (development)
- **`intl: ^0.20.2`** - Internationalization untuk format tanggal, bilangan (ID/EN)
- **`provider: ^6.1.5+1`** - State management (replace old provider pattern)

#### **Share & File Handling**
- **`share_plus: ^12.0.1`** - Share file/data dengan aplikasi lain
- **`path_provider: ^2.0.15`** - Akses direktori lokal untuk menyimpan file

#### **Notifikasi Lokal**
- **`flutter_local_notifications: ^18.0.1`** - Menampilkan notifikasi lokal di device
- **`flutter_native_timezone: ^2.0.0`** - Timezone native untuk scheduling notifikasi
- **`timezone: ^0.9.4`** - Menangani timezone untuk notifikasi

#### **Export Laporan**
- **`csv: ^6.0.0`** - Generate file CSV (Excel format)
- **`excel: ^2.0.0`** - Generate file Excel (.xlsx)
- **`pdf: ^3.8.1`** - Generate file PDF dengan data

#### **URL Launcher**
- **`url_launcher: ^6.3.2`** - Membuka URL eksternal (browser, email, phone call)

### Dev Dependencies (Library untuk Development)
```yaml
dev_dependencies:
  flutter_test:           # Testing framework untuk Flutter
    sdk: flutter
  flutter_lints: ^5.0.0   # Linting rules untuk kode berkualitas
  flutter_launcher_icons: ^0.13.1  # Generate app icon otomatis
```

### Launcher Icons Configuration
```yaml
flutter_launcher_icons:
  android: "launcher_icon"              # Nama asset icon untuk Android
  ios: true                             # Generate icon untuk iOS
  image_path: "lib/assets/Logo_aplikasi.png"  # Path image source
  min_sdk_android: 21                   # Min SDK untuk Android
```

### Flutter Assets Configuration
```yaml
flutter:
  uses-material-design: true    # Gunakan Material Design icons
  
  assets:                       # Asset image yang digunakan
    - lib/assets/splash_screen.png
    - lib/assets/Logo_aplikasi.png
```

### Cara Menambah Dependencies Baru

#### Option 1: Edit pubspec.yaml Langsung
```yaml
dependencies:
  nama_package: ^version
```
Lalu jalankan `flutter pub get`

#### Option 2: Command Line
```bash
flutter pub add nama_package
```

### Cara Update Dependencies
```bash
# Update semua packages ke versi terbaru
flutter pub upgrade

# Update major version juga
flutter pub upgrade --major-versions

# Lihat versi outdated
flutter pub outdated
```

### Dependency Version Notation

| Notation  | Penjelasan 
|-----------|------------
| `^1.0.0`  | Kompatibel dengan versi 1.x (1.0.0 - <2.0.0) 
| `~1.0.0`  | Kompatibel dengan 1.0.x (1.0.0 - <1.1.0) 
| `1.0.0`   | Versi spesifik (lock ke 1.0.0 only) 
| `>=1.0.0` | Versi 1.0.0 atau lebih tinggi 
| `<=2.0.0` | Versi 2.0.0 atau lebih rendah 

## Teknologi yang Digunakan

- **Flutter**: Framework utama untuk pengembangan aplikasi mobile.
- **Firebase**: Autentikasi, Firestore database, dan Cloud Messaging (FCM).
- **Mobile Scanner**: Untuk pemindaian barcode.
- **Provider**: State management untuk manajemen state aplikasi.
- **HTTP/REST API**: Komunikasi dengan REST API backend untuk data order dan customer.
- **CSV/Excel/PDF**: Library untuk ekspor laporan dalam berbagai format.
- **Firebase Cloud Messaging (FCM)**: Sistem notifikasi push real-time.
- **Intl**: Internasionalisasi untuk format tanggal dan bilangan.
- **Share Plus**: Fitur untuk membagikan file laporan.

## Struktur Proyek

```
lib/
├── main.dart                          # Entry point aplikasi, routing setup, Firebase init
├── assets/                            # Asset files (images, icons)
│   ├── Logo_aplikasi.png              # Logo KGBox
│   └── splash_screen.png              # Splash screen image
│
├── models/                            # Model data classes
│   ├── product_model.dart             # Model untuk data produk
│   ├── user_model.dart                # Model untuk data user (owner/staff)
│   ├── supplier_model.dart            # Model untuk data supplier
│   ├── order_model.dart               # Model untuk data order/pesanan
│   ├── order_items_model.dart         # Model untuk item dalam order
│   ├── customer_model.dart            # Model untuk data customer
│   └── permintaan_stok_model.dart     # Model untuk permintaan stok
│
├── pages/                             # UI Pages (presentasi layer)
│   ├── login_page.dart                # Login page UI
│   ├── dashboard_owner_page.dart      # Owner dashboard UI
│   ├── dashboard_staff_page.dart      # Staff dashboard UI
│   ├── list_product_page.dart         # Product list page
│   ├── detail_product_page.dart       # Product detail page
│   ├── tambah_product_page.dart       # Add product page
│   ├── edit_product_page.dart         # Edit product page
│   ├── barcode_scanner_page.dart      # Barcode scanner page
│   ├── stok_owner_page.dart           # Stock owner monitoring page
│   ├── stok_produk_page.dart          # Product stock page
│   ├── kelola_staff_page.dart         # Staff management page
│   ├── tambah_staff_page.dart         # Add staff page
│   ├── edit_staff_page.dart           # Edit staff page
│   ├── supplier_page.dart             # Supplier management page
│   ├── pengiriman_page.dart           # Delivery management page
│   ├── expired_page.dart              # Expired products page
│   ├── bestseller_page.dart           # Best seller products page
│   ├── catat_barang_keluar_page.dart  # Record outgoing items page
│   ├── notifications_page.dart        # Notifications page
│   ├── notifikasi_owner_page.dart     # Owner notifications page
│   ├── export_report_page.dart        # Export report page
│   └── [other UI pages]
│
├── screens/                           # Screen controllers & business logic
│   ├── login_screen.dart              # Login logic & validation
│   ├── register_screen.dart           # Registration logic
│   ├── reset_password_screen.dart     # Password reset logic
│   ├── dashboard_owner_screen.dart    # Owner dashboard controller
│   ├── dashboard_staff_screen.dart    # Staff dashboard controller
│   ├── list_product_screen.dart       # Product list controller
│   ├── splash_screen.dart             # Splash screen controller
│   ├── chart_owner_screen.dart        # Chart & analytics controller
│   ├── export_report_screen.dart      # Export report controller
│   ├── notifikasi_owner_screen.dart   # Owner notifications controller
│   ├── catat_barang_keluar_screen.dart # Outgoing items controller
│   ├── notifications_screen.dart      # Notifications controller
│   ├── logout_screen.dart             # Logout handler
│   ├── [other screen controllers]
│   └── [platform-specific implementations]
│
├── services/                          # Business logic & API integration
│   ├── restapi.dart                   # REST API client for backend
│   ├── config.dart                    # Configuration & constants
│   ├── firebase_options.dart          # Firebase initialization config
│   ├── notifications_service.dart     # Push notifications service
│   ├── notification_owner_service.dart # Owner-specific notifications
│   ├── fcm_service.dart               # Firebase Cloud Messaging service
│   ├── export_service.dart            # Cross-platform file export
│   ├── export_impl_io.dart            # File export implementation (mobile)
│   ├── export_impl_web.dart           # File export implementation (web)
│   ├── advanced_export_service.dart   # Advanced reporting & export
│   └── username_service.dart          # Username/user data service
│
├── providers/                         # State management (Provider pattern)
│   └── auth_provider.dart             # Authentication state & user data
│
└── utils/                             # Utility functions & helpers
    ├── file_saver.dart                # Platform-agnostic file saver interface
    ├── file_saver_io.dart             # File saver for mobile (Android/iOS)
    └── file_saver_web.dart            # File saver for web
```

### Penjelasan Struktur:

**models/** - Berisi data models yang merepresentasikan struktur data aplikasi. Digunakan untuk type safety dan data serialization/deserialization dari API dan Firestore.

**pages/** - Berisi pure UI widgets yang hanya menampilkan data. Pages menerima data dari screens via constructor atau provider.

**screens/** - Berisi business logic, API calls, dan state management. Screens menghubungkan pages dengan services dan data.

**services/** - Berisi logika backend, integrasi API, Firebase operations, dan utility functions untuk digunakan di seluruh aplikasi.

**providers/** - State management menggunakan Provider pattern untuk global state seperti authentication dan user info.

**utils/** - Helper functions, constants, dan cross-platform utilities yang digunakan di berbagai bagian aplikasi.

**assets/** - Static files seperti images dan icons yang di-bundle dengan aplikasi.

## Database Schema

Aplikasi menggunakan dua sumber database:
- **Firebase Firestore**: Untuk data produk, user, notifikasi, dan internal system
- **Gocloud (REST API)**: Untuk data order, order_items, dan customer

### 🔥 Firebase Firestore Collections

#### 1. Collection: `users`
Menyimpan data user (owner dan staff).

```json
{
  "uid": "string (document ID)",
  "email": "string (unique)",
  "nama": "string",
  "phone": "string",
  "role": "string (owner/staff)",
  "ownerId": "string (reference ke owner)",
  "company": "string (nama perusahaan)",
  "address": "string (alamat)",
  "created_at": "timestamp",
  "updated_at": "timestamp",
  "is_active": "boolean"
}
```

#### 2. Collection: `products`
Menyimpan data produk.

```json
{
  "id": "string (document ID)",
  "nama_produk": "string",
  "harga_product": "number",
  "kategori": "string",
  "deskripsi": "string",
  "gambar": "string (URL/path)",
  "barcodes": "array of strings (barcode list)",
  "ownerId": "string (reference ke owner)",
  "supplier_id": "string (reference ke supplier)",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

#### 3. Collection: `product_barcodes`
Menyimpan detail barcode dan tracking stok per barcode.

```json
{
  "id": "string (document ID)",
  "productId": "string (reference ke products)",
  "barcode": "string (unique)",
  "ownerId": "string",
  "tanggal_kadaluarsa": "timestamp/string (YYYY-MM-DD)",
  "supplier": "string",
  "harga_beli": "number",
  "scannedAt": "timestamp",
  "status": "string (tersedia/terjual/rusak/kadaluarsa)",
  "keterangan": "string",
  "created_at": "timestamp"
}
```

#### 4. Collection: `suppliers`
Menyimpan data supplier.

```json
{
  "id": "string (document ID)",
  "nama_supplier": "string",
  "contact_person": "string",
  "phone": "string",
  "email": "string",
  "alamat": "string",
  "kota": "string",
  "provinsi": "string",
  "ownerId": "string (reference ke owner)",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

#### 5. Collection: `stock_requests`
Menyimpan permintaan stok dari staff.

```json
{
  "id": "string (document ID)",
  "product_id": "string (reference ke products)",
  "product_name": "string",
  "jumlah_permintaan": "number",
  "staff_id": "string (reference ke staff)",
  "nama_staff": "string",
  "ownerId": "string",
  "status": "string (pending/approved/rejected)",
  "supplier_id": "string (reference ke suppliers)",
  "supplier_agent": "string",
  "supplier_company": "string",
  "catatan": "string",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

#### 6. Collection: `notifications`
Menyimpan notifikasi sistem untuk user.

```json
{
  "id": "string (document ID)",
  "userId": "string (reference ke users)",
  "ownerId": "string",
  "title": "string",
  "body": "string",
  "type": "string (expired_product/low_stock/order/delivery/stock_request)",
  "is_read": "boolean",
  "data": "map (additional data)",
  "created_at": "timestamp"
}
```

#### 7. Collection: `device_tokens`
Menyimpan FCM device tokens untuk push notifications.

```json
{
  "id": "string (document ID)",
  "userId": "string (reference ke users)",
  "token": "string (FCM token)",
  "device_name": "string",
  "platform": "string (android/ios/web)",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### ☁️ Gocloud Database Collections (via REST API)

#### 1. Collection: `order` / `orders`
Menyimpan data pesanan/order.

```json
{
  "id": "string (unique identifier)",
  "ownerid": "string (reference ke owner di Firebase)",
  "customer_id": "string (reference ke customer)",
  "order_date": "string (YYYY-MM-DD)",
  "total_amount": "number",
  "status": "string (pending/processing/shipped/delivered/cancelled)",
  "shipping_address": "string",
  "payment_method": "string",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

#### 2. Collection: `order_items`
Menyimpan item detail dalam setiap order.

```json
{
  "id": "string (unique identifier)",
  "order_id": "string (reference ke order)",
  "product_id": "string (reference ke products di Firebase)",
  "product_name": "string",
  "quantity": "number",
  "unit_price": "number",
  "subtotal": "number",
  "created_at": "timestamp"
}
```

#### 3. Collection: `customer` / `customers`
Menyimpan data customer.

```json
{
  "id": "string (unique identifier)",
  "name": "string",
  "email": "string",
  "phone": "string",
  "address": "string",
  "city": "string",
  "province": "string",
  "zip_code": "string",
  "created_at": "timestamp",
  "updated_at": "timestamp"
}
```

### 🔗 Integrasi Database

**Alur Data:**
1. **Product Management**: Data disimpan di Firebase (`products`, `product_barcodes`)
2. **Order Processing**: Order dibuat di Gocloud, reference ke products di Firebase
3. **Real-time Sync**: Dashboard menggunakan Firestore listener + REST API polling untuk data terbaru
4. **Notifications**: Dikirim melalui Firebase untuk update real-time

**REST API Configuration:**
```dart
// lib/services/config.dart
const String API_BASE_URL = 'https://api.gocloud.com/v5';
const String PROJECT_ID = 'your_project_id';
const String APP_ID = 'your_app_id';
const String API_TOKEN = 'your_api_token';
```

### Firestore Indexes & Rules

**Security Rules:**
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // User hanya bisa akses data mereka sendiri
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Owner bisa akses semua data mereka
    match /products/{document=**} {
      allow read, write: if request.auth.uid != null && 
        get(/databases/$(database)/documents/users/$(request.auth.uid)).data.ownerId == resource.data.ownerId;
    }
    
    match /suppliers/{document=**} {
      allow read, write: if request.auth.uid != null;
    }
    
    match /stock_requests/{document=**} {
      allow read, write: if request.auth.uid != null;
    }
    
    match /notifications/{document=**} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
    
    match /device_tokens/{document=**} {
      allow read, write: if request.auth.uid == resource.data.userId;
    }
  }
}
```

**Recommended Indexes:**
- `products`: Composite index pada `ownerId`, `created_at`
- `product_barcodes`: Composite index pada `ownerId`, `scannedAt`
- `stock_requests`: Composite index pada `ownerId`, `status`, `created_at`
- `notifications`: Composite index pada `userId`, `is_read`, `created_at`

## Kontribusi

Untuk berkontribusi pada proyek ini, silakan buat pull request atau issue di repository GitHub.

## Lisensi

Proyek ini menggunakan lisensi MIT.
