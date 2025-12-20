import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../pages/barcode_scanner_page.dart';
import '../pages/tambah_product_page.dart';
import '../pages/list_product_page.dart';
import '../screens/catat_barang_keluar_screen.dart';
import '../screens/logout_screen.dart';
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
  
  // Cache untuk mencegah terlalu sering fetch
  DateTime? _lastFetchTime;
  static const Duration _refreshInterval = Duration(minutes: 5); // Refresh setiap 5 menit

  // Getters
  List<Map<String, dynamic>> get todaysOut => _todaysOut;

  // Calculations
  int getTotalQuantity() {
    return _todaysOut.fold<int>(0, (s, e) => s + (e['qty'] as int));
  }

  Future<void> fetchTodaysOut(BuildContext context) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';

      final now = DateTime.now();
      final todayKey = '${now.year.toString().padLeft(4, '0')}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      _todaysOut.clear();
      
      // Query orders hari ini (filter by ownerId when available)
      // ignore: unused_local_variable
      dynamic ordersRes;
      if (ownerId.isNotEmpty) {
        ordersRes = await _api.selectWhereLike(token, project, 'order', appid, 'tanggal_order', todayKey + '%');
        // Note: selectWhereLike doesn't support owner filter, so retrieve orders by owner and then filter by date below
        final ownerOrdersRes = await _api.selectWhere(token, project, 'order', appid, 'ownerid', ownerId);
        final ownerOrders = _parseSelectResponse(ownerOrdersRes);
        final dateOrders = _parseSelectResponse(await _api.selectWhereLike(token, project, 'order', appid, 'tanggal_order', todayKey));
        // intersect by order_id
        final ownerOrderIds = ownerOrders.map((o) => (o['order_id'] ?? o['orderId'] ?? '').toString()).toSet();
        final filtered = dateOrders.where((o) => ownerOrderIds.contains((o['order_id'] ?? o['orderId'] ?? '').toString())).toList();
        // use filtered as orders
        final List<dynamic> orders = filtered;
        
        int totalQuantity = 0;
        for (final order in orders) {
          final orderId = (order['order_id'] ?? order['orderId'] ?? '').toString();

          // Query order items untuk order ini
          if (orderId.isNotEmpty) {
            final itemsRes = await _api.selectWhere(token, project, 'order_items', appid, 'order_id', orderId);
            final List<dynamic> items = _parseSelectResponse(itemsRes);

            for (final item in items) {
              final qty = int.tryParse(item['jumlah_produk']?.toString() ?? '0') ?? 0;
              totalQuantity += qty;
            }
          }
        }

        // Simpan sebagai 1 entry untuk hari ini
        if (totalQuantity > 0) {
          _todaysOut.add({
            'name': 'Pengiriman Hari Ini',
            'qty': totalQuantity,
            'note': '${orders.length} transaksi'
          });
        }

        pengirimanCount = orders.length;
        _lastFetchTime = DateTime.now();
        return;
      } else {
        // Query orders hari ini
        final ordersRes = await _api.selectWhereLike(token, project, 'order', appid, 'tanggal_order', todayKey);
        final List<dynamic> orders = _parseSelectResponse(ordersRes);
        
        int totalQuantity = 0;
        for (final order in orders) {
          final orderId = (order['order_id'] ?? order['orderId'] ?? '').toString();

          // Query order items untuk order ini
          if (orderId.isNotEmpty) {
            final itemsRes = await _api.selectWhere(token, project, 'order_items', appid, 'order_id', orderId);
            final List<dynamic> items = _parseSelectResponse(itemsRes);

            for (final item in items) {
              final qty = int.tryParse(item['jumlah_produk']?.toString() ?? '0') ?? 0;
              totalQuantity += qty;
            }
          }
        }

        // Simpan sebagai 1 entry untuk hari ini
        if (totalQuantity > 0) {
          _todaysOut.add({
            'name': 'Pengiriman Hari Ini',
            'qty': totalQuantity,
            'note': '${orders.length} transaksi'
          });
        }

        pengirimanCount = orders.length;
        _lastFetchTime = DateTime.now();
        return;
      }
      
    } catch (e) {
      debugPrint('fetchTodaysOut error: $e');
    }
  }

  Future<void> fetchMetrics(BuildContext context) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';

      // Fetch products untuk low stock dan expired (filter by owner if available)
      dynamic prodRes;
      if (ownerId.isNotEmpty) {
        prodRes = await _api.selectWhere(token, project, 'product', appid, 'ownerid', ownerId);
      } else {
        prodRes = await _api.selectAll(token, project, 'product', appid);
      }
      final List<dynamic> prods = _parseSelectResponse(prodRes);
      
      lowStockCount = 0;
      expiredCount = 0;
      final now = DateTime.now();
      
      for (final p in prods) {
        // Check low stock
        final stok = int.tryParse(p['jumlah_produk']?.toString() ?? p['stok']?.toString() ?? '0') ?? 0;
        if (stok <= 10) lowStockCount++;
        
        // Check expired
        final rawExpired = p['tanggal_expired']?.toString() ?? p['tanggal_expire']?.toString() ?? '';
        if (rawExpired.isNotEmpty) {
          try {
            final expDate = DateTime.parse(rawExpired);
            if (expDate.isBefore(now)) expiredCount++;
          } catch (_) {}
        }
      }

      // Fetch suppliers (filter by owner if possible)
      dynamic supRes;
      if (ownerId.isNotEmpty) {
        supRes = await _api.selectWhere(token, project, 'suppliers', appid, 'ownerid', ownerId);
      } else {
        supRes = await _api.selectAll(token, project, 'suppliers', appid);
      }
      final List<dynamic> sups = _parseSelectResponse(supRes);
      supplierCount = sups.length;

      // Fetch best sellers (produk dengan penjualan terbanyak)
      final oiRes = (ownerId.isNotEmpty)
        ? await _api.selectWhere(token, project, 'order_items', appid, 'ownerid', ownerId)
        : await _api.selectAll(token, project, 'order_items', appid);
      final List<dynamic> ois = _parseSelectResponse(oiRes);
      
      // Hitung frekuensi produk
      final Map<String, int> productFrequency = {};
      for (final item in ois) {
        final productId = (item['id_product'] ?? '').toString();
        if (productId.isNotEmpty) {
          productFrequency[productId] = (productFrequency[productId] ?? 0) + 1;
        }
      }
      
      // Ambil top 10 produk terlaris
      final sortedProducts = productFrequency.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      bestSellerCount = sortedProducts.take(10).length;
      
      _lastFetchTime = DateTime.now();
      
    } catch (e) {
      debugPrint('fetchMetrics error: $e');
    }
  }

  // Smart refresh - hanya refresh jika sudah lewat interval tertentu
  Future<void> smartRefresh(BuildContext context) async {
    final now = DateTime.now();
    if (_lastFetchTime == null || 
        now.difference(_lastFetchTime!) > _refreshInterval) {
      await refreshAll(context);
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
        if (decoded is Map) return [decoded];
      }
      if (res is Map && res.containsKey('data')) return res['data'] as List<dynamic>;
      return [];
    } catch (e) {
      debugPrint('parseSelectResponse error: $e');
      return [];
    }
  }

  /// Refresh all dashboard data
  Future<void> refreshAll(BuildContext context) async {
    await Future.wait([
      fetchTodaysOut(context),
      fetchMetrics(context),
    ]);
  }

  // Helper methods
  String getMonthName(int month) {
    switch (month) {
      case 1: return 'Januari';
      case 2: return 'Februari';
      case 3: return 'Maret';
      case 4: return 'April';
      case 5: return 'Mei';
      case 6: return 'Juni';
      case 7: return 'Juli';
      case 8: return 'Agustus';
      case 9: return 'September';
      case 10: return 'Oktober';
      case 11: return 'November';
      case 12: return 'Desember';
      default: return '';
    }
  }

  // Navigation methods (sama seperti sebelumnya)
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

  void navigateToProductOut(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => const CatatBarangKeluarScreen(),
      ),
    );
  }

  void logout(BuildContext context) {
    handleLogout(context);
  }

  // Alert methods
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