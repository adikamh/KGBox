# Export Laporan - Fitur Dokumentasi

## Overview
Fitur export yang ditingkatkan memungkinkan owner untuk mengekspor berbagai jenis laporan bisnis dalam format CSV atau JSON.

## Fitur-Fitur Laporan

### 1. 📦 Laporan Keseluruhan Produk Tersedia
- **Deskripsi**: Menampilkan semua produk yang tersedia milik owner
- **Kolom**: ID, Nama Produk, Kategori, Harga, Stok, Satuan
- **Sumber Data**: REST API `product` collection

### 2. ⏰ Laporan Keseluruhan Produk Kadaluarsa
- **Deskripsi**: Menampilkan produk yang sudah kadaluarsa
- **Kolom**: ID, Nama Produk, Tanggal Kadaluarsa, Stok, Kategori
- **Sumber Data**: REST API `product` collection (filter by expiry date)

### 3. 🚚 Laporan Order Pengiriman
- **Deskripsi**: Menampilkan semua order pengiriman
- **Kolom**: No Order, Tgl Order, Customer, Status, Total, Alamat Pengiriman
- **Sumber Data**: REST API `order` collection

### 4. 👥 Laporan Keseluruhan Staff
- **Deskripsi**: Menampilkan semua staff yang bekerja untuk owner
- **Kolom**: Nama, Email, Posisi, Telepon, Tanggal Bergabung, Status
- **Sumber Data**: Firebase Firestore `staff` collection

### 5. 🏭 Laporan Keseluruhan Suppliers
- **Deskripsi**: Menampilkan semua supplier yang terdaftar
- **Kolom**: Nama Supplier, Alamat, Telepon, Email, Kontak Person, Kategori Barang
- **Sumber Data**: REST API `supplier` collection

### 6. 💰 Laporan Transaksi
- **Deskripsi**: Menampilkan semua transaksi penjualan
- **Kolom**: No Transaksi, Tanggal, Customer, Total, Metode Pembayaran, Status
- **Sumber Data**: REST API `order` collection

### 7. 📤 Laporan Barang Keluar
- **Deskripsi**: Menampilkan barang yang keluar dari gudang
- **Kolom**: ID Produk, Nama Produk, Jumlah, Tanggal Keluar, Tujuan, Status
- **Sumber Data**: REST API `order_items` collection

### 8. 📥 Laporan Barang Masuk
- **Deskripsi**: Menampilkan barang yang masuk ke gudang
- **Kolom**: Barcode, ID Produk, Nama Produk, Jumlah, Tanggal Masuk, Supplier
- **Sumber Data**: Firebase Firestore `product_barcodes` collection

## Format Export

### CSV (.csv)
- Format: Comma-Separated Values
- Ideal untuk: Import ke Excel, Google Sheets, atau database
- File naming: `laporan_<jenis>_<timestamp>.csv`

### JSON (.json)
- Format: JavaScript Object Notation
- Ideal untuk: Integrasi dengan sistem lain, backup data
- File naming: `laporan_<jenis>_<timestamp>.json`
- Struktur:
  ```json
  {
    "type": "Laporan Keseluruhan Produk Tersedia",
    "timestamp": "2026-01-10T15:30:00.000",
    "totalRecords": 25,
    "data": [...]
  }
  ```

## Cara Menggunakan

1. **Klik tombol Export** (floating action button) di dashboard owner
2. **Pilih jenis laporan** dari list yang muncul
3. **Pilih format file** (CSV atau JSON)
4. **Tunggu proses loading** selesai
5. **File akan otomatis disimpan** ke folder Downloads
6. **Share atau gunakan file** sesuai kebutuhan

## Fitur Keamanan & Filtering

✅ **Per-Owner Filtering**
- Setiap laporan hanya menampilkan data milik owner yang login
- Filter berdasarkan field: `ownerid`, `owner_id`, `ownerId`, `owner`

✅ **Error Handling**
- Handle berbagai variasi nama field
- Safe parsing untuk data yang tidak konsisten
- Fallback values untuk data yang hilang

## Lokasi File Tersimpan

| Platform | Lokasi Default |
|----------|-----------------|
| Windows  | `C:\Users\[Username]\Downloads` |
| macOS    | `~/Downloads` |
| Linux    | `~/Downloads` |
| Android  | `/storage/emulated/0/Download` |
| iOS      | Documents folder |

## Struktur Kode

### File-File Terkait:
- `lib/pages/dashboard_owner_page.dart` - UI dialog dan handler
- `lib/screens/dashboard_owner_screen.dart` - Business logic dan export methods
- `lib/services/advanced_export_service.dart` - Service helper (optional)

### Method Utama:
- `fetchAvailableProductsReport(ownerId)` - Ambil data laporan produk tersedia
- `fetchExpiredProductsReport(ownerId)` - Ambil data laporan produk kadaluarsa
- `fetchDeliveryOrderReport(ownerId)` - Ambil data laporan order pengiriman
- `fetchStaffReport(ownerId)` - Ambil data laporan staff
- `fetchSuppliersReport(ownerId)` - Ambil data laporan supplier
- `fetchTransactionsReport(ownerId)` - Ambil data laporan transaksi
- `fetchOutgoingItemsReport(ownerId)` - Ambil data laporan barang keluar
- `fetchIncomingItemsReport(ownerId)` - Ambil data laporan barang masuk
- `exportToCSV(reportData)` - Export ke format CSV
- `exportToJSON(reportData)` - Export ke format JSON

## Future Enhancements

Fitur-fitur yang bisa ditambahkan di masa depan:
- ✅ Support format PDF (memerlukan package `pdf`)
- ✅ Support format Excel/XLSX (memerlukan package `excel`)
- ✅ Support format Word (.docx)
- ✅ Email laporan langsung dari aplikasi
- ✅ Schedule export otomatis
- ✅ Custom template laporan
- ✅ Chart dan visualisasi di laporan PDF
- ✅ Digital signature untuk laporan resmi

