# Testing Guide - Export Laporan Feature

## 🧪 Quick Start Testing

### Prerequisites
- Sudah login sebagai owner
- Data tersedia di collections yang sesuai
- Device/Emulator dengan storage yang cukup

### Test Case 1: Export Laporan Produk Tersedia (CSV)

**Steps:**
1. Buka Dashboard Owner
2. Klik tombol **Export** (hijau, pojok kanan bawah)
3. Dari dialog pertama, pilih **📦 Laporan Keseluruhan Produk Tersedia**
4. Dari dialog kedua, pilih **📋 CSV (.csv)**
5. Tunggu loading selesai

**Expected Results:**
- ✅ Loading dialog muncul dengan spinner
- ✅ File berhasil diekspor ke Downloads folder
- ✅ SnackBar muncul: "Laporan berhasil diexport: [file path]"
- ✅ Tombol **Bagikan** tersedia di SnackBar

**Verification:**
```bash
# Windows: Buka folder
C:\Users\[Username]\Downloads

# Cek file yang dibuat:
laporan_Laporan_Keseluruhan_Produk_Tersedia_*.csv
```

**File Content Check:**
- Header row: ID,Nama Produk,Kategori,Harga,Stok,Satuan
- Data rows sesuai dengan produk yang tersimpan
- Tidak ada karakter aneh atau corrupted data

---

### Test Case 2: Export Laporan Produk Kadaluarsa (JSON)

**Steps:**
1. Klik Export
2. Pilih **⏰ Laporan Keseluruhan Produk Kadaluarsa**
3. Pilih **📊 JSON (.json)**

**Expected Results:**
- ✅ JSON file dibuat dengan struktur yang benar
- ✅ Hanya produk yang expired (tanggal < hari ini) ditampilkan
- ✅ Metadata (type, timestamp, totalRecords) ada

**File Content Verification:**
```json
{
  "type": "Laporan Keseluruhan Produk Kadaluarsa",
  "timestamp": "2026-01-10T...",
  "totalRecords": N,
  "data": [...]
}
```

---

### Test Case 3: Export Laporan Order Pengiriman (CSV)

**Steps:**
1. Klik Export
2. Pilih **🚚 Laporan Order Pengiriman**
3. Pilih **📋 CSV (.csv)**

**Expected Results:**
- ✅ CSV file dengan kolom: No Order, Tgl Order, Customer, Status, Total, Alamat Pengiriman
- ✅ Hanya order milik owner yang login
- ✅ Data sesuai dengan order yang ada di database

---

### Test Case 4: Export Laporan Staff (JSON)

**Steps:**
1. Klik Export
2. Pilih **👥 Laporan Keseluruhan Staff**
3. Pilih **📊 JSON (.json)**

**Expected Results:**
- ✅ JSON file berisi data staff dari Firebase collection
- ✅ Hanya staff yang terdaftar untuk owner tersebut
- ✅ Kolom: Nama, Email, Posisi, Telepon, Tanggal Bergabung, Status

---

### Test Case 5: Export Laporan Supplier

**Steps:**
1. Klik Export
2. Pilih **🏭 Laporan Keseluruhan Suppliers**
3. Pilih format pilihan (CSV atau JSON)

**Expected Results:**
- ✅ Data supplier milik owner
- ✅ Kolom: Nama Supplier, Alamat, Telepon, Email, Kontak Person, Kategori Barang

---

### Test Case 6: Export Laporan Transaksi

**Steps:**
1. Klik Export
2. Pilih **💰 Laporan Transaksi**
3. Pilih format pilihan

**Expected Results:**
- ✅ Data transaksi milik owner
- ✅ Kolom: No Transaksi, Tanggal, Customer, Total, Metode Pembayaran, Status

---

### Test Case 7: Export Laporan Barang Keluar

**Steps:**
1. Klik Export
2. Pilih **📤 Laporan Barang Keluar**
3. Pilih format pilihan

**Expected Results:**
- ✅ Data order_items dari REST API
- ✅ Hanya barang yang keluar untuk owner tersebut
- ✅ Kolom: ID Produk, Nama Produk, Jumlah, Tanggal Keluar, Tujuan, Status

---

### Test Case 8: Export Laporan Barang Masuk

**Steps:**
1. Klik Export
2. Pilih **📥 Laporan Barang Masuk**
3. Pilih format pilihan

**Expected Results:**
- ✅ Data dari Firebase product_barcodes
- ✅ Hanya barcode yang milik owner
- ✅ Kolom: Barcode, ID Produk, Nama Produk, Jumlah, Tanggal Masuk, Supplier

---

## 🔍 Error Handling Tests

### Test Case 9: Tanpa Data (Empty Result)

**Setup:**
- Login sebagai owner yang tidak punya produk

**Steps:**
1. Klik Export
2. Pilih laporan apapun

**Expected Results:**
- ✅ Loading dialog tetap muncul
- ✅ File tetap dibuat (dengan data kosong atau hanya header)
- ✅ SnackBar menunjukkan file berhasil dibuat

---

### Test Case 10: Network Error

**Setup:**
- Disconnect dari internet
- Atau REST API server down

**Steps:**
1. Klik Export
2. Pilih laporan dari REST API (misal: Produk Tersedia)

**Expected Results:**
- ✅ Loading dialog ditampilkan
- ✅ Error SnackBar muncul dengan pesan error
- ✅ File tidak dibuat
- ✅ Tidak ada crash, aplikasi tetap responsif

---

### Test Case 11: Cancel Export

**Steps:**
1. Klik Export
2. Dialog pilihan laporan muncul
3. Klik **[Batal]**

**Expected Results:**
- ✅ Dialog tertutup
- ✅ Tidak ada proses export
- ✅ Aplikasi kembali normal

---

### Test Case 12: Cancel Format Selection

**Steps:**
1. Klik Export
2. Pilih laporan apapun
3. Dialog format muncul
4. Klik **[Batal]**

**Expected Results:**
- ✅ Dialog tertutup
- ✅ Tidak ada export dijalankan
- ✅ User kembali ke dashboard

---

## 📊 Per-Owner Filtering Tests

### Test Case 13: Multi-Owner Data Isolation

**Setup:**
- Buat 2 owner berbeda dengan data produk
- Login sebagai Owner A

**Steps:**
1. Klik Export
2. Export Laporan Produk Tersedia

**Expected Results:**
- ✅ CSV/JSON hanya menampilkan produk milik Owner A
- ✅ Produk dari Owner B tidak muncul
- ✅ Filter berdasarkan field: ownerid/ownerId/owner/owner_id

---

## 🚀 Feature Integration Tests

### Test Case 14: Share File Function

**Steps:**
1. Export file berhasil
2. SnackBar muncul dengan tombol **[Bagikan]**
3. Klik tombol **[Bagikan]**

**Expected Results:**
- ✅ Share dialog atau file manager terbuka
- ✅ File dapat dikirim melalui email, messaging apps, dll
- ✅ File tersimpan dengan benar di penerima

---

### Test Case 15: Multiple Exports

**Steps:**
1. Export laporan A (CSV)
2. Tunggu selesai
3. Export laporan B (JSON)
4. Tunggu selesai
5. Export laporan C (CSV)

**Expected Results:**
- ✅ Semua file berhasil dibuat
- ✅ File naming berbeda-beda (timestamp)
- ✅ Tidak ada conflict atau overwrite
- ✅ Semua file valid dan dapat dibuka

---

## 📋 CSV Format Validation Tests

### Test Case 16: CSV Escaping

**Validation:**
Buka file CSV dengan Excel/LibreOffice Calc

**Check:**
- ✅ Semua data terbaca dengan benar
- ✅ Komma di dalam value di-escape dengan quotes
- ✅ Newline character di-escape dengan benar
- ✅ Quote character di-escape dengan double quotes

**Example:**
```
"Nama, Produk A","Kategori ""Premium"""
```

---

### Test Case 17: CSV Special Characters

**Setup:**
- Data dengan karakter spesial: ñ, é, ü, ü, 中文, emoji, etc

**Steps:**
1. Export ke CSV
2. Buka dengan text editor dan dengan Excel

**Expected Results:**
- ✅ Text editor: Encoding UTF-8 terbaca
- ✅ Excel: Karakter spesial ditampilkan dengan benar
- ✅ Tidak ada corrupted characters

---

## 🔧 Platform-Specific Tests

### Test Case 18: Windows File Save

**Platform:** Windows

**Steps:**
1. Export file
2. Buka Explorer ke: `C:\Users\[Username]\Downloads`

**Expected Results:**
- ✅ File muncul di folder Downloads
- ✅ File dapat di-double-click untuk buka
- ✅ Path benar: `C:\Users\...\Downloads\laporan_*.csv`

---

### Test Case 19: Android File Save

**Platform:** Android (Emulator atau Device)

**Steps:**
1. Export file
2. Buka Files/Storage app

**Expected Results:**
- ✅ File tersimpan di `/storage/emulated/0/Download`
- ✅ File dapat di-share ke apps lain
- ✅ Path benar dan accessible

---

### Test Case 20: macOS/Linux File Save

**Platform:** macOS atau Linux

**Steps:**
1. Export file
2. Buka file manager, navigate ke `~/Downloads`

**Expected Results:**
- ✅ File muncul di folder Downloads
- ✅ File dapat dibuka dengan aplikasi default
- ✅ Path benar: `~/Downloads/laporan_*.csv`

---

## 📝 Logging & Debug Tests

### Test Case 21: Debug Output

**Setup:**
- Run aplikasi dengan debug console terbuka

**Steps:**
1. Klik Export
2. Amati console output

**Expected Debug Messages:**
```
I/flutter: _performExport: Fetching data for report: available_products
I/flutter: fetchAvailableProductsReport: Fetching products from REST API
I/flutter: fetchAvailableProductsReport: Found 5 products for owner ABC123
I/flutter: exportToCSV: Converting to CSV format
I/flutter: _saveFile: File saved to: C:\Users\...\Downloads\laporan_*.csv
```

---

## ✅ Test Summary Checklist

### Functionality
- [ ] Semua 8 jenis laporan dapat dipilih
- [ ] CSV format export bekerja
- [ ] JSON format export bekerja
- [ ] File tersimpan di lokasi yang benar
- [ ] File dapat dibuka dan dibaca

### UI/UX
- [ ] Dialog pilihan laporan user-friendly
- [ ] Dialog format selection user-friendly
- [ ] Loading indicator ditampilkan
- [ ] Success/Error messages jelas
- [ ] Tombol batal berfungsi

### Data Integrity
- [ ] Per-owner filtering bekerja
- [ ] Data tidak corrupt
- [ ] Header row benar
- [ ] Data lengkap dan sesuai database

### Error Handling
- [ ] Network error handled gracefully
- [ ] Empty data handled
- [ ] Invalid owner handled
- [ ] File save error handled

### Platform
- [ ] Windows: File tersimpan di Downloads
- [ ] macOS: File tersimpan di Downloads
- [ ] Linux: File tersimpan di Downloads
- [ ] Android: File tersimpan di Download folder
- [ ] iOS: File tersimpan di Documents

---

## 🐛 Troubleshooting

### Issue: File tidak tersimpan
**Solution:**
1. Cek storage permission
2. Cek disk space
3. Cek folder Downloads exists
4. Cek debug logs untuk error message

### Issue: Data kosong di report
**Solution:**
1. Verifikasi data ada di database
2. Cek owner ID filter
3. Verifikasi collection names
4. Cek koneksi ke REST API/Firebase

### Issue: Character corrupted
**Solution:**
1. Cek UTF-8 encoding
2. Cek field mapping
3. Verifikasi data di source

### Issue: Aplikasi crash
**Solution:**
1. Cek error logs
2. Verifikasi null safety
3. Test dengan data minimal
4. Check memory usage

