# KGBox - Warehouse Inventory Management System

KGBox adalah aplikasi manajemen inventaris gudang berbasis Flutter yang dirancang untuk membantu pemilik bisnis dan staf dalam mengelola produk, stok, dan operasi gudang secara efisien.

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

## Teknologi yang Digunakan

- **Flutter**: Framework utama untuk pengembangan aplikasi mobile.
- **Firebase**: Autentikasi, Firestore database, dan Cloud Messaging.
- **Mobile Scanner**: Untuk pemindaian barcode.
- **Provider**: State management.
- **HTTP**: Komunikasi dengan REST API.
- **CSV/Excel/PDF**: Library untuk ekspor laporan.

## Struktur Proyek

```
lib/
├── main.dart                 # Entry point aplikasi
├── models/                   # Model data (Product, User, Order, dll.)
├── pages/                    # UI Pages untuk berbagai fitur
├── providers/                # State management dengan Provider
├── screens/                  # Screen controllers dan logic
├── services/                 # Business logic dan API calls
└── utils/                    # Utility functions
```

## Instalasi dan Setup

1. Pastikan Flutter SDK terinstall.
2. Clone repository ini.
3. Jalankan `flutter pub get` untuk menginstall dependencies.
4. Setup Firebase project dan tambahkan konfigurasi ke `lib/services/firebase_options.dart`.
5. Jalankan aplikasi dengan `flutter run`.

## Kontribusi

Untuk berkontribusi pada proyek ini, silakan buat pull request atau issue di repository GitHub.

## Lisensi

Proyek ini menggunakan lisensi MIT.
