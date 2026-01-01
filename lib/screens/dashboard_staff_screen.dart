import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:kgbox/screens/notifications_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';
import '../pages/barcode_scanner_page.dart';
import '../pages/tambah_product_page.dart';
import '../pages/list_product_page.dart';
import '../screens/catat_barang_keluar_screen.dart';
import '../screens/logout_screen.dart';
import '../services/restapi.dart';
import '../services/config.dart';

class DashboardStaffScreen extends ChangeNotifier {
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
        ordersRes = await _api.selectWhereLike(token, project, 'order', appid, 'tanggal_order', '$todayKey%');
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
        notifyListeners();
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
        notifyListeners();
                _lastFetchTime = DateTime.now();
                notifyListeners();
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
      // Prefer Firestore for expired count (more reliable). Fall back to REST if Firestore unavailable.
      lowStockCount = 0;
      expiredCount = 0;
      final now = DateTime.now();

      try {
        final firestore = FirebaseFirestore.instance;

        QuerySnapshot<Map<String, dynamic>> snap;
        if (ownerId.isNotEmpty) {
          // Try both common owner field variants and use whichever returns docs
          final qLower = await firestore.collection('products').where('ownerid', isEqualTo: ownerId).get();
          if (qLower.docs.isNotEmpty) {
            snap = qLower;
          } else {
            snap = await firestore.collection('products').where('ownerId', isEqualTo: ownerId).get();
          }
        } else {
          snap = await firestore.collection('products').get();
        }

        int fsExpired = 0;
        for (final doc in snap.docs) {
          final dataObj = doc.data();
          // lowStock: try common fields
          try {
            final stokVal = dataObj['jumlah_produk'] ?? dataObj['stok'] ?? dataObj['stock'];
            final stok = int.tryParse(stokVal?.toString() ?? '0') ?? 0;
            if (stok <= 10) lowStockCount++;
          } catch (_) {}

          // parse possible expiry fields
          DateTime? expDate;
          final candidates = ['tanggal_expired', 'tanggal_expire', 'expiredDate', 'expired_at', 'expired_date', 'expired'];
          for (final f in candidates) {
            if (dataObj.containsKey(f) && expDate == null) {
              final raw = dataObj[f];
              if (raw is Timestamp) {
                expDate = raw.toDate();
              } else if (raw is int) {
                // handle seconds or milliseconds
                if (raw > 1000000000000) {
                  expDate = DateTime.fromMillisecondsSinceEpoch(raw);
                } else {
                  expDate = DateTime.fromMillisecondsSinceEpoch(raw * 1000);
                }
              } else if (raw is String) {
                try {
                  expDate = DateTime.parse(raw);
                } catch (_) {
                  // try yyyy-MM-dd fallback
                  try {
                    expDate = DateTime.parse(raw.replaceAll('/', '-'));
                  } catch (_) {}
                }
              }
            }
          }

          if (expDate != null && expDate.isBefore(now)) fsExpired++;
        }

        expiredCount = fsExpired;
          // Create or update a summary notification for expired products for this owner
          try {
            if (ownerId.isNotEmpty) {
              final notifRef = FirebaseFirestore.instance.collection('notifications').doc('expired_summary_$ownerId');
              if (expiredCount > 0) {
                final title = expiredCount == 1 ? 'Produk kedaluwarsa' : 'Produk kedaluwarsa: $expiredCount';
                final body = expiredCount == 1
                    ? 'Ada 1 produk yang telah kedaluwarsa. Periksa daftar Produk Kedaluwarsa.'
                    : 'Ada $expiredCount produk yang telah kedaluwarsa. Periksa daftar Produk Kedaluwarsa.';
                await notifRef.set({
                  'ownerid': ownerId,
                  'type': 'expired_summary',
                  'title': title,
                  'body': body,
                  'timestamp': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
              } else {
                // remove previous summary notification if none expired
                await notifRef.delete().catchError((_) {});
              }
            }
          } catch (_) {}
      } catch (e) {
        // Firestore attempt failed; fall back to REST parsing of 'product' table
        dynamic prodRes;
        if (ownerId.isNotEmpty) {
          prodRes = await _api.selectWhere(token, project, 'product', appid, 'ownerid', ownerId);
        } else {
          prodRes = await _api.selectAll(token, project, 'product', appid);
        }
        final List<dynamic> prods = _parseSelectResponse(prodRes);

        lowStockCount = 0;
        expiredCount = 0;
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
      }

      // Fetch suppliers count from Firestore when possible (preferred)
      try {
        final firestore = FirebaseFirestore.instance;
        Query q = firestore.collection('suppliers');
        if (ownerId.isNotEmpty) q = q.where('ownerid', isEqualTo: ownerId);
        final snap = await q.get();
        supplierCount = snap.size;
      } catch (_) {
        // fallback to existing REST logic
        dynamic supRes;
        if (ownerId.isNotEmpty) {
          supRes = await _api.selectWhere(token, project, 'suppliers', appid, 'ownerid', ownerId);
        } else {
          supRes = await _api.selectAll(token, project, 'suppliers', appid);
        }
        final List<dynamic> sups = _parseSelectResponse(supRes);
        supplierCount = sups.length;
      }

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
      notifyListeners();
      
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
      if (result != null) {
        String? barcodeArg;
        if (result is String && result.isNotEmpty) {
          barcodeArg = result;
        } else if (result is Map && result.isNotEmpty) {
          try {
            final keys = result.keys.map((k) => k.toString()).where((s) => s.isNotEmpty).toList();
            if (keys.isNotEmpty) barcodeArg = keys.join(',');
          } catch (_) {
            barcodeArg = null;
          }
        }

        if (barcodeArg != null && barcodeArg.isNotEmpty) {
          final auth = Provider.of<AuthProvider>(context, listen: false);
          final user = auth.currentUser;
          final ownerId = user?.ownerId ?? user?.id ?? '';

          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => AddProductPage(
                userRole: '',
                barcode: barcodeArg,
                ownerId: ownerId,
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
      MaterialPageRoute(builder: (context) => const NotificationsScreen()),
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