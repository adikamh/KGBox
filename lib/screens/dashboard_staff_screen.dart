// lib/screens/dashboard_staff_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/barcode_scanner_page.dart';
import '../pages/tambah_product_page.dart';
import '../pages/list_product_page.dart';
import '../pages/catat_barang_keluar_page.dart';

class DashboardStaffScreen {
  // Data management
  final List<Map<String, dynamic>> _todaysOut = [
    {"name": "Produk A", "qty": 3, "note": "Penjualan"},
    {"name": "Produk B", "qty": 1, "note": "Retur"},
    {"name": "Produk C", "qty": 5, "note": "Pengiriman"},
  ];

  // Getters
  List<Map<String, dynamic>> get todaysOut => _todaysOut;

  // Calculations
  int getTotalQuantity() {
    return _todaysOut.fold<int>(0, (s, e) => s + (e['qty'] as int));
  }

  // Helper methods
  String getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return '';
    }
  }

  // Navigation methods
  void navigateToAddProduct(BuildContext context, String userRole) {
     final auth = Provider.of<AuthProvider>(context, listen: false);
     final user = auth.currentUser;
     final ownerId = user?.ownerId ?? user?.id ?? '';

     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (_) => AddProductPage(userRole: userRole, ownerId: ownerId),
       ),
     );
  }

  void navigateToBarcodeScanner(BuildContext context) {
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (_) => const BarcodeScannerPage(userRole: ''),
       ),
     );
  }

  void navigateToViewProducts(BuildContext context) {
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (_) => ListProductPage(),
       ),
     );
  }

  void navigateToNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => Scaffold(
          appBar: AppBar(title: const Text('Notifications')),
          body: const Center(child: Text('No notifications')),
        ),
      ),
    );
  }

  void navigateToStoreHistory(BuildContext context) {
    // Import RiwayatTokoModel
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(
    //     builder: (_) => const RiwayatTokoPage(),
    //   ),
    // );
  }

  void navigateToProductOut(BuildContext context) {
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (_) => CatatBarangKeluarPage(
           namaTokoController: TextEditingController(),
           alamatTokoController: TextEditingController(),
           namaPemilikController: TextEditingController(),
           scannedProducts: [],
           total: 0,
           onScanPressed: () {},
           onSubmitPressed: () {},
           onQuantityChanged: (index, quantity) {},
         ),
       ),
     );
  }

  void logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/');
  }

  void showStockAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Stok Produk - Segera diupdate')),
    );
  }

  void showBestSellersAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk Terlaris - Segera diupdate')),
    );
  }

  void showExpiredAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Produk Kadaluarsa - Segera diupdate')),
    );
  }

  void showSupplierAlert(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data Suplier - Segera diupdate')),
    );
  }
}