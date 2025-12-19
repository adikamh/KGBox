// lib/screens/dashboard_staff_screen.dart
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/barcode_scanner_page.dart';
import '../pages/tambah_product_page.dart';
import '../pages/list_product_page.dart';
import '../screens/catat_barang_keluar_screen.dart';
import '../services/restapi.dart';
import '../services/config.dart';

class DashboardStaffScreen {
  // Data management
  final List<Map<String, dynamic>> _todaysOut = [];
  final DataService _api = DataService();
  int lowStockCount = 0;
  int bestSellerCount = 0;
  int expiredCount = 0;
  int supplierCount = 0;
  int pengirimanCount = 0;

  // Getters
  List<Map<String, dynamic>> get todaysOut => _todaysOut;

  // Calculations
  int getTotalQuantity() {
    return _todaysOut.fold<int>(0, (s, e) => s + (e['qty'] as int));
  }

  Future<void> fetchTodaysOut() async {
    try {
      _todaysOut.clear();
      final now = DateTime.now();
      final dateKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      // find orders whose tanggal_order contains today's date
      final ordersRes = await _api.selectWhereLike(token, project, 'order', appid, 'tanggal_order', dateKey);
      final List<dynamic> orders = _parseSelectResponse(ordersRes);

      for (final o in orders) {
        try {
          final orderId = (o['order_id'] ?? o['orderId'] ?? '').toString();
          final toko = o['nama_toko'] ?? o['customer_name'] ?? '';
          final alamat = o['alamat_toko'] ?? '';

          // sum order_items for this order
          final itemsRes = await _api.selectWhere(token, project, 'order_items', appid, 'order_id', orderId);
          final Map<String, dynamic> itemsJson = itemsRes is String ? (itemsRes.isNotEmpty ? (Map<String, dynamic>.from(jsonDecode(itemsRes))) : {}) : Map<String, dynamic>.from(itemsRes);
          final List<dynamic> items = (itemsJson['data'] ?? []);
          int qtySum = 0;
          for (final it in items) {
            qtySum += int.tryParse(it['jumlah_produk']?.toString() ?? '0') ?? 0;
          }

          if (qtySum > 0) {
            _todaysOut.add({'name': toko ?? orderId, 'qty': qtySum, 'note': alamat});
          }
        } catch (_) {}
      }
      // set pengirimanCount
      pengirimanCount = _todaysOut.length;
    } catch (e) {
      debugPrint('fetchTodaysOut error: $e');
    }
  }

  Future<void> fetchMetrics() async {
    try {
      // products
      lowStockCount = 0;
      expiredCount = 0;
      final prodRes = await _api.selectAll(token, project, 'product', appid);
      final List<dynamic> prods = _parseSelectResponse(prodRes);
      final now = DateTime.now();
      final threshold = DateTime(now.year, now.month + 2, now.day);
      for (final p in prods) {
        final stok = int.tryParse(p['jumlah_produk']?.toString() ?? p['stok']?.toString() ?? '0') ?? 0;
        if (stok <= 10) lowStockCount++;
        final raw = p['tanggal_expired']?.toString() ?? p['tanggal_expire']?.toString() ?? '';
        try {
          final dt = DateTime.parse(raw);
          if (dt.isBefore(now) || dt.isBefore(threshold)) expiredCount++;
        } catch (_) {}
      }

      // suppliers
      final supRes = await _api.selectAll(token, project, 'supplier', appid);
      final List<dynamic> sups = _parseSelectResponse(supRes);
      supplierCount = sups.length;

      // bestsellers: distinct products that have outgoing qty
      final oiRes = await _api.selectAll(token, project, 'order_items', appid);
      final List<dynamic> ois = _parseSelectResponse(oiRes);
      final Set<String> distinct = {};
      for (final it in ois) {
        final id = (it['id_product'] ?? '').toString();
        if (id.isNotEmpty) distinct.add(id);
      }
      bestSellerCount = distinct.length;
    } catch (e) {
      debugPrint('fetchMetrics error: $e');
    }
  }

  List<dynamic> _parseSelectResponse(dynamic res) {
    try {
      if (res == null) return [];
      if (res is List) return res;
      if (res is String) {
        if (res.trim().isEmpty) return [];
        final decoded = jsonDecode(res);
        if (decoded is List) return decoded;
        if (decoded is Map && decoded.containsKey('data')) return decoded['data'] as List<dynamic>;
        // If API returns plain object representing a single item, wrap it
        if (decoded is Map) return [decoded];
      }
      if (res is Map && res.containsKey('data')) return res['data'] as List<dynamic>;
      return [];
    } catch (e) {
      debugPrint('parseSelectResponse error: $e');
      return [];
    }
  }

  /// Refresh all dashboard data (todays out + metrics)
  Future<void> refreshAll() async {
    await Future.wait([fetchTodaysOut(), fetchMetrics()]);
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
     ).then((result) {
       // If scanner returned a barcode, navigate to AddProductPage with that barcode and ownerId
       if (result != null && result is String && result.isNotEmpty) {
         try {
           final auth = Provider.of<AuthProvider>(context, listen: false);
           final user = auth.currentUser;
           final ownerId = user?.ownerId ?? user?.id ?? '';

           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (_) => AddProductPage(
                 userRole: '',
                 barcode: result,
                 ownerId: ownerId,
               ),
             ),
           );
         } catch (e) {
           // Fallback: open without ownerId
           Navigator.push(
             context,
             MaterialPageRoute(
               builder: (_) => AddProductPage(
                 userRole: '',
                 barcode: result,
               ),
             ),
           );
         }
       }
     });
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
         builder: (_) => const CatatBarangKeluarScreen(),
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