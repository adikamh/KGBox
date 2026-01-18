import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:KGbox/screens/notifications_screen.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/notifications_service.dart';
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
  int nearExpiredCount = 0;
  int productInToday = 0;
  int todayOrderItemsCount = 0;
  int supplierCount = 0;
  int pengirimanCount = 0;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _ordersSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _orderItemsSub;
  Timer? _ordersPollTimer;
  
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
      
      // Query order_items langsung dengan filter tanggal hari ini
      try {
        final api = DataService();
        
        // Fetch all order_items (REST API doesn't support complex date filtering)
        final itemsRes = await api.selectAll(token, project, 'order_items', appid).timeout(const Duration(seconds: 15));
        final List<dynamic> allItems = _parseSelectResponse(itemsRes);
        
        // Filter by owner if available
        List<dynamic> ownerItems = allItems;
        if (ownerId.isNotEmpty) {
          ownerItems = allItems.where((item) {
            final itemOwner = (item['ownerid'] ?? item['ownerid'] ?? '').toString();
            return itemOwner == ownerId;
          }).toList();
        }
        
        // Filter by tanggal_order_items (today)
        int totalQty = 0;
        final Set<String> uniqueProductIds = {};
        
        for (final item in ownerItems) {
          final rawDate = item['tanggal_order_items'] ?? item['tanggal_order'] ?? item['created_at'];
          if (rawDate != null) {
            DateTime? d;
            if (rawDate is String) {
              try {
                d = DateTime.parse(rawDate.toString().trim());
              } catch (_) {
                try {
                  final sub = rawDate.toString().trim().split(' ').first;
                  d = DateTime.parse(sub);
                } catch (_) {
                  d = null;
                }
              }
            }
            
            // Only include if date is today
            if (d != null && (d.year == now.year && d.month == now.month && d.day == now.day)) {
              // Track unique product id
              final productId = (item['id_product'] ?? '').toString();
              if (productId.isNotEmpty) {
                uniqueProductIds.add(productId);
              }
              
              // Sum quantities
              final qty = int.tryParse(item['jumlah_produk']?.toString() ?? '0') ?? 0;
              totalQty += qty;
            }
          }
        }
        
        // Simpan sebagai 1 entry untuk hari ini
        if (uniqueProductIds.isNotEmpty) {
          _todaysOut.add({
            'name': 'Produk Keluar Hari Ini',
            'qty': uniqueProductIds.length,
            'note': '$totalQty unit'
          });
        }
        
        pengirimanCount = uniqueProductIds.length;
        
        // also compute productInToday via Firestore 'product_in' collection if available
        try {
          productInToday = 0;
          final firestore = FirebaseFirestore.instance;
          final q = await firestore.collection('product_in')
            .where('tanggal', isGreaterThanOrEqualTo: '$todayKey 00:00:00')
            .where('tanggal', isLessThanOrEqualTo: '$todayKey 23:59:59')
            .get();
          if (q.docs.isNotEmpty) {
            for (final d in q.docs) {
              final data = d.data();
              final qty = int.tryParse((data['qty'] ?? data['jumlah'] ?? data['jumlah_produk'] ?? '0').toString()) ?? 0;
              productInToday += qty;
            }
          }
        } catch (_) {
          productInToday = 0;
        }
        _lastFetchTime = DateTime.now();
        notifyListeners();
        return;
      } catch (e) {
        debugPrint('Error fetching todays out: $e');
      }
      
      _lastFetchTime = DateTime.now();
      notifyListeners();
      return;
        // compute productInToday for non-owner id path as well
    } catch (e) {
      debugPrint('fetchTodaysOut error: $e');
    }
  }

  /// Fetch total orders count from REST API (owner filter when available)
  Future<void> fetchAllOrdersCount(BuildContext context) async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';

      dynamic res;
      if (ownerId.isNotEmpty) {
        res = await _api.selectWhere(token, project, 'order', appid, 'ownerid', ownerId);
      } else {
        res = await _api.selectAll(token, project, 'order', appid);
      }
      final List<dynamic> list = _parseSelectResponse(res);
      pengirimanCount = list.length;
      notifyListeners();
    } catch (e) {
      debugPrint('fetchAllOrdersCount error: $e');
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
        int fsNear = 0;
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

          if (expDate != null) {
            if (expDate.isBefore(now)) {
              fsExpired++;
            } else {
              final diff = expDate.difference(now).inDays;
              if (diff >= 0 && diff <= 7) {
                // within next 7 days -> near-expiry
                fsNear++;
              }
            }
          }
        }
        expiredCount = fsExpired;
        nearExpiredCount = fsNear;
        // show local notifications for expired / near-expiry
        try {
          await NotificationService.instance.init();
          if (expiredCount > 0) {
            await NotificationService.instance.showNotification(1001, 'Produk Kedaluwarsa', 'Ada $expiredCount produk yang sudah kedaluwarsa.');
          }
          if (nearExpiredCount > 0) {
            await NotificationService.instance.showNotification(1002, 'Produk Hampir Kedaluwarsa', '$nearExpiredCount produk akan kedaluwarsa dalam 7 hari.');
          }
          // ensure daily reminder (09:00)
          await NotificationService.instance.ensureDailyScheduled(9, 0);
        } catch (_) {}
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

  /// Start a realtime listener on `order` collection to update pengirimanCount
  void startRealtimeOrders(BuildContext context) {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';
      final firestore = FirebaseFirestore.instance;

      Query<Map<String, dynamic>> q = firestore.collection('order');
      if (ownerId.isNotEmpty) q = q.where('ownerid', isEqualTo: ownerId);

      _ordersSub?.cancel();
      _ordersSub = q.snapshots().listen((snap) {
        try {
          pengirimanCount = snap.size;
          notifyListeners();
        } catch (e) {
          debugPrint('orders snapshot handling error: $e');
        }
      }, onError: (e) {
        debugPrint('orders listener error: $e');
        // fallback to periodic REST polling if Firestore listener fails (permissions/network)
        _startOrdersPolling(context);
      });
      // Also ensure polling is stopped when snapshot works
      _stopOrdersPolling();
    } catch (e) {
      debugPrint('startRealtimeOrders error: $e');
    }
  }

  /// Stop realtime listeners and cleanup
  void stopRealtimeOrders() {
    try {
      _ordersSub?.cancel();
      _ordersSub = null;
      _stopOrdersPolling();
    } catch (e) {
      debugPrint('stopRealtimeOrders error: $e');
    }
  }

  /// Start realtime listener for `order_items` for today's date to update today's keluar count
  void startRealtimeOrderItems(BuildContext context) {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';
      final firestore = FirebaseFirestore.instance;

      final now = DateTime.now();
      final start = DateTime(now.year, now.month, now.day);
      final end = DateTime(now.year, now.month, now.day, 23, 59, 59);
      final tsStart = Timestamp.fromDate(start);
      final tsEnd = Timestamp.fromDate(end);

      Query<Map<String, dynamic>> q = firestore.collection('order_items');
      if (ownerId.isNotEmpty) q = q.where('ownerid', isEqualTo: ownerId);

      // Filter by tanggal_order_items (primary field for item timestamp)
      try {
        q = q.where('tanggal_order_items', isGreaterThanOrEqualTo: tsStart).where('tanggal_order_items', isLessThanOrEqualTo: tsEnd);
      } catch (_) {
        // Fallback: try tanggal_order if tanggal_order_items not available
        try {
          q = q.where('tanggal_order', isGreaterThanOrEqualTo: tsStart).where('tanggal_order', isLessThanOrEqualTo: tsEnd);
        } catch (_) {
          // ignore - field may not be a Timestamp
        }
      }

      _orderItemsSub?.cancel();
      _orderItemsSub = q.snapshots().listen((snap) {
        try {
          int totalQty = 0;
          final Set<String> uniqueProductIds = {};
          
          for (final doc in snap.docs) {
            final data = doc.data();
            // if tanggal_order_items exists and is not today, skip (double-check just in case)
            final rawDate = data['tanggal_order_items'] ?? data['tanggal_order'] ?? data['created_at'] ?? data['tanggal'];
            if (rawDate != null) {
              DateTime? d;
              if (rawDate is Timestamp) {
                d = rawDate.toDate();
              } else if (rawDate is String) {
                // Accept formats like "yyyy-MM-dd", "yyyy-MM-dd HH:mm:ss", "yyyy-MM-ddTHH:mm:ss"
                try {
                  d = DateTime.parse(rawDate.trim());
                } catch (_) {
                  try {
                    // Fallback: try extracting just the date part (YYYY-MM-DD)
                    final sub = rawDate.trim().split(' ').first;
                    d = DateTime.parse(sub);
                  } catch (_) {
                    d = null;
                  }
                }
              }
              if (d != null) {
                if (!(d.year == now.year && d.month == now.month && d.day == now.day)) continue;
              }
            }

            // Track unique product id
            final productId = (data['id_product'] ?? '').toString();
            if (productId.isNotEmpty) {
              uniqueProductIds.add(productId);
            }

            // Determine quantity: prefer `jumlah_produk`, otherwise length of `list_barcode`, otherwise fallback fields
            int qty = 0;
            try {
              if (data.containsKey('jumlah_produk')) {
                qty = int.tryParse(data['jumlah_produk']?.toString() ?? '0') ?? 0;
              } else if (data.containsKey('list_barcode')) {
                final lb = data['list_barcode'];
                if (lb is List) {
                  qty = lb.length;
                } else if (lb is String) {
                  // try to decode JSON array string
                  try {
                    final parsed = jsonDecode(lb);
                    if (parsed is List) qty = parsed.length;
                  } catch (_) {
                    // fallback: bracket-less comma separated
                    qty = lb.split(',').where((s) => s.trim().isNotEmpty).length;
                  }
                }
              } else {
                qty = int.tryParse((data['qty'] ?? data['jumlah'] ?? '0').toString()) ?? 0;
              }
            } catch (_) {
              qty = 0;
            }

            totalQty += qty;
          }
          
          // Set the count to number of unique products (jenis produk yang keluar)
          todayOrderItemsCount = uniqueProductIds.length;
          // update _todaysOut entry
          _todaysOut.removeWhere((e) => (e['name'] ?? '') == 'Produk Keluar Hari Ini');
          if (todayOrderItemsCount > 0) {
            _todaysOut.add({
              'name': 'Produk Keluar Hari Ini',
              'qty': todayOrderItemsCount,
              'note': '$totalQty unit'
            });
          }
          notifyListeners();
        } catch (e) {
          debugPrint('order_items snapshot handling error: $e');
        }
      }, onError: (e) {
        debugPrint('order_items listener error: $e');
      });
    } catch (e) {
      debugPrint('startRealtimeOrderItems error: $e');
    }
  }

  void stopRealtimeOrderItems() {
    try {
      _orderItemsSub?.cancel();
      _orderItemsSub = null;
    } catch (e) {
      debugPrint('stopRealtimeOrderItems error: $e');
    }
  }

  void _startOrdersPolling(BuildContext context, {Duration interval = const Duration(seconds: 30)}) {
    try {
      _ordersPollTimer?.cancel();
      // run immediately then periodically
      _ordersPollTimer = Timer.periodic(interval, (t) async {
        try {
          await fetchAllOrdersCount(context);
        } catch (e) {
          debugPrint('orders polling error: $e');
        }
      });
      // also trigger one immediate fetch
      fetchAllOrdersCount(context);
    } catch (e) {
      debugPrint('_startOrdersPolling error: $e');
    }
  }

  /// Public API to start polling-only (no Firestore listener)
  void startOrdersPolling(BuildContext context, {Duration interval = const Duration(seconds: 30)}) {
    _startOrdersPolling(context, interval: interval);
  }

  void _stopOrdersPolling() {
    try {
      _ordersPollTimer?.cancel();
      _ordersPollTimer = null;
    } catch (e) {
      debugPrint('_stopOrdersPolling error: $e');
    }
  }

  /// Dispose resources used by this controller
  @override
  void dispose() {
    stopRealtimeOrders();
    super.dispose();
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