// ignore: unused_import
import 'dart:convert';
import 'package:flutter/material.dart';
// removed http dependency since functionsBaseUrl not used
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// ignore: unused_import
import 'package:KGbox/screens/catat_barang_keluar_screen.dart';
// ignore: unused_import
import '../pages/dashboard_owner_page.dart';
import '../pages/list_product_page.dart';
import '../pages/pengiriman_page.dart';
import '../pages/notifikasi_owner_page.dart';
import 'logout_screen.dart';
import '../services/restapi.dart';
import '../services/config.dart';
import 'package:KGbox/providers/auth_provider.dart';
import 'package:provider/provider.dart';
// Platform-specific IO is handled by `ExportService` to support web builds.
import 'dart:typed_data';
import '../services/export_service.dart';
import 'package:excel/excel.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

class DashboardOwnerController {
  // Data management - now dynamic based on current month
  List<Map<String, dynamic>> _monthlyProductFlow = [];
  List<Map<String, dynamic>> _monthlyTransactions = [];
  
  static const int _maxTransactions = 2000;
  static const List<String> _monthLabels = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
  static const List<Color> _transactionColors = [
    Color(0xFF3B82F6), // Blue
    Color(0xFFEF4444), // Red
    Color(0xFF10B981), // Green
    Color(0xFFF59E0B), // Amber
    Color(0xFF8B5CF6), // Purple
    Color(0xFFEC4899), // Pink
    Color(0xFF14B8A6), // Teal
    Color(0xFFF97316), // Orange
    Color(0xFF6366F1), // Indigo
    Color(0xFF84CC16), // Lime
    Color(0xFF06B6D4), // Cyan
    Color(0xFF8B5CF6), // Purple
  ];

  // Dynamic dashboard counts
  int totalProduk = 0;
  int barangMasuk = 0; // last week
  int barangKeluar = 0; // total dari order_items
  int expiredCount = 0;
  bool isLoadingCounts = false;

  final DataService _api = DataService();
  final FirebaseFirestore _fs = FirebaseFirestore.instance;

  // Getters for UI
  List<Map<String, dynamic>> get monthlyProductFlow => _monthlyProductFlow;
  List<Map<String, dynamic>> get monthlyTransactions => _monthlyTransactions;
  int get maxTransactions => _maxTransactions;

  // Calculations
  int get totalProductIn {
    return _monthlyProductFlow.isEmpty ? 0 : _monthlyProductFlow.map((e) => (e['in'] as int?) ?? 0).reduce((a, b) => a + b);
  }

  int get totalProductOut {
    return _monthlyProductFlow.isEmpty ? 0 : _monthlyProductFlow.map((e) => (e['out'] as int?) ?? 0).reduce((a, b) => a + b);
  }

  int get remainingStock {
    return totalProductIn - totalProductOut;
  }

  int get totalTransactions {
    return _monthlyTransactions.isEmpty ? 0 : _monthlyTransactions.map((e) => (e['transactions'] as int?) ?? 0).reduce((a, b) => a + b);
  }

  // Helper function untuk menghitung barcode dari string
  int _countBarcodesFromString(String barcodeString) {
    if (barcodeString.isEmpty) return 0;
    
    try {
      // Coba parse sebagai JSON array
      final parsed = jsonDecode(barcodeString);
      if (parsed is List) {
        return parsed.where((b) => b != null && b.toString().trim().isNotEmpty).length;
      }
    } catch (_) {
      // Jika bukan JSON, coba sebagai CSV
      // Hapus karakter [ ] " '
      String cleaned = barcodeString
        .replaceAll('[', '')
        .replaceAll(']', '')
        .replaceAll('"', '')
        .replaceAll("'", '');
      
      final barcodes = cleaned.split(',').where((b) => b.trim().isNotEmpty).toList();
      return barcodes.length;
    }
    
    return 0;
  }

  /// Fetch dynamic product flow data (in/out) for last 12 months from current month
  Future<void> fetchDynamicProductFlow(String ownerId) async {
    try {
      final result = await fetchMonthlyTotals(ownerId);
      final inTotals = result['in'] ?? List<double>.filled(12, 0);
      final outTotals = result['out'] ?? List<double>.filled(12, 0);
      
      final now = DateTime.now();
      final months = <DateTime>[];
      
      // Generate last 12 months dates from current month backwards
      for (int i = 11; i >= 0; i--) {
        DateTime dt = DateTime(now.year, now.month - i, 1);
        months.add(dt);
      }
      
      _monthlyProductFlow = List.generate(12, (i) {
        final dt = months[i];
        final monthLabel = _monthLabels[dt.month - 1];
        return {
          'month': monthLabel,
          'in': inTotals[i].toInt(),
          'out': outTotals[i].toInt(),
        };
      });
      
      debugPrint('fetchDynamicProductFlow: updated with ${_monthlyProductFlow.length} months');
    } catch (e) {
      debugPrint('fetchDynamicProductFlow error: $e');
      _monthlyProductFlow = [];
    }
  }

  /// Fetch dynamic transaction data for last 12 months from current month
  Future<void> fetchDynamicTransactions(String ownerId) async {
    try {
      final data = await fetchFinancialMonthlyTotals(ownerId);
      
      final now = DateTime.now();
      final months = <DateTime>[];
      
      // Generate last 12 months dates from current month backwards
      for (int i = 11; i >= 0; i--) {
        DateTime dt = DateTime(now.year, now.month - i, 1);
        months.add(dt);
      }
      
      _monthlyTransactions = List.generate(12, (i) {
        final result = i < data.length ? data[i] : {'transactions': 0};
        return {
          'month': result['month'] ?? _monthLabels[i],
          'transactions': result['transactions'] ?? 0,
          'total': result['total'] ?? 0.0,
          'color': _transactionColors[i % _transactionColors.length],
        };
      });
      
      debugPrint('fetchDynamicTransactions: updated with ${_monthlyTransactions.length} months');
    } catch (e) {
      debugPrint('fetchDynamicTransactions error: $e');
      _monthlyTransactions = [];
    }
  }

  // Load dynamic counts for the dashboard owner
  Future<void> loadCounts(BuildContext context) async {
    try {
      isLoadingCounts = true;
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';

      debugPrint('loadCounts: start ownerId=$ownerId');

      // DEBUG: fetch a few sample product_barcodes docs to inspect schema
      try {
        Query<Map<String, dynamic>> sampleQ = _fs.collection('product_barcodes');
        if (ownerId.isNotEmpty) {
          // try common owner field variants
          try { sampleQ = sampleQ.where('ownerid', isEqualTo: ownerId); } catch (_) {}
          try { sampleQ = sampleQ.where('ownerId', isEqualTo: ownerId); } catch (_) {}
          try { sampleQ = sampleQ.where('owner', isEqualTo: ownerId); } catch (_) {}
        }
        final sampleSnap = await sampleQ.limit(5).get();
        debugPrint('loadCounts: sample product_barcodes fetched=${sampleSnap.docs.length}');
        for (final d in sampleSnap.docs) {
          debugPrint('loadCounts: sample doc id=${d.id}, data=${d.data()}');
        }
      } catch (e) {
        debugPrint('loadCounts: sample fetch error: $e');
      }

      // reset counts to safe defaults
      totalProduk = 0;
      barangMasuk = 0;
      barangKeluar = 0;
      expiredCount = 0;

      // 1. TOTAL PRODUK: count documents in `products` collection dari Firebase
      try {
        Query prodQ = _fs.collection('products');
        if (ownerId.isNotEmpty) {
          // Coba kedua variasi field name
          try {
            prodQ = prodQ.where('ownerId', isEqualTo: ownerId);
          } catch (_) {
            try {
              prodQ = prodQ.where('ownerid', isEqualTo: ownerId);
            } catch (_) {}
          }
        }
        
        try {
          final agg = prodQ.count();
          final aggSnap = await agg.get();
          totalProduk = aggSnap.count ?? 0;
          debugPrint('loadCounts: totalProduk aggregated=$totalProduk');
        } catch (_) {
          final prodSnap = await prodQ.get();
          totalProduk = prodSnap.docs.length;
          debugPrint('loadCounts: totalProduk scanned=${prodSnap.docs.length}');
        }
      } catch (e) {
        totalProduk = 0;
        debugPrint('loadCounts: totalProduk error: $e');
      }

      // 2. BARANG MASUK: count incoming barcodes for owner's products in last 7 days
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      final lastWeekTs = Timestamp.fromDate(lastWeek);
      int masukCount = 0;

      // If ownerId present, first try counting barcodes that have owner info directly
      if (ownerId.isNotEmpty) {
        try {
          for (final ownerField in ['ownerid', 'ownerId', 'owner', 'owner_id']) {
            try {
              Query<Map<String, dynamic>> q = _fs.collection('product_barcodes').where(ownerField, isEqualTo: ownerId).where('scannedAt', isGreaterThanOrEqualTo: lastWeekTs);
              try {
                final agg = q.count();
                final snap = await agg.get();
                final c = snap.count ?? 0;
                debugPrint('loadCounts: barangMasuk ownerField=$ownerField count=$c (via count)');
                if (c > 0) {
                  masukCount = c;
                  break;
                }
              } catch (_) {
                final snap2 = await q.get();
                final c2 = snap2.docs.length;
                debugPrint('loadCounts: barangMasuk ownerField=$ownerField count=$c2 (via get)');
                if (c2 > 0) {
                  masukCount = c2;
                  break;
                }
              }
            } catch (_) {
              // ignore and try next owner field
            }
          }
        } catch (_) {}

        // if we found a direct owner-based count, skip product-based counting
        if (masukCount > 0) {
          barangMasuk = masukCount;
          debugPrint('loadCounts: barangMasuk (direct owner field)=$barangMasuk');
        } else {
          // fallthrough to productId-based counting below
        }
      }

      // If ownerId present, prefer counting barcodes for products owned by this owner
      if (ownerId.isNotEmpty && masukCount == 0) {
        try {
          Query<Map<String, dynamic>> prodQ = _fs.collection('products');
          try {
            prodQ = prodQ.where('ownerId', isEqualTo: ownerId);
          } catch (_) {
            try {
              prodQ = prodQ.where('ownerid', isEqualTo: ownerId);
            } catch (_) {}
          }

          final prodSnap = await prodQ.get();
          final productIds = prodSnap.docs.map((d) {
            final data = d.data();
            return (data['id'] ?? data['id_product'] ?? d.id).toString();
          }).where((s) => s.isNotEmpty).toSet().toList();

          debugPrint('loadCounts: productIds list: $productIds');

          // DEBUG: fetch a few barcode docs for these productIds to inspect schema
          try {
            final sampleBatches = <List<String>>[];
            const sampleBatchSize = 10;
            for (var i = 0; i < productIds.length; i += sampleBatchSize) {
              sampleBatches.add(productIds.sublist(i, (i + sampleBatchSize) > productIds.length ? productIds.length : i + sampleBatchSize));
            }
            for (final b in sampleBatches) {
              try {
                final sampleBarcodes = await _fs.collection('product_barcodes').where('productId', whereIn: b).limit(5).get();
                debugPrint('loadCounts: sample barcodes for batch(${b.length}) fetched=${sampleBarcodes.docs.length}');
                for (final sd in sampleBarcodes.docs) {
                  debugPrint('loadCounts: sample barcode id=${sd.id}, data=${sd.data()}');
                }
              } catch (e) {
                debugPrint('loadCounts: sample barcode fetch error for batch $b: $e');
              }
            }
          } catch (e) {
            debugPrint('loadCounts: sample barcode batches error: $e');
          }

            if (productIds.isNotEmpty) {
              int total = 0;
              const batchSize = 10; // whereIn limit
              for (var i = 0; i < productIds.length; i += batchSize) {
                final batch = productIds.sublist(i, (i + batchSize) > productIds.length ? productIds.length : i + batchSize);
                try {
                  // fetch all barcodes for this batch and parse date fields locally to be robust
                  final snap = await _fs.collection('product_barcodes').where('productId', whereIn: batch).get();
                  for (final d in snap.docs) {
                    final m = d.data();
                    // try multiple possible date keys and formats
                    final dateKeys = ['scannedAt', 'scanned_at', 'scannedAtStr', 'createdAt', 'created_at', 'timestamp', 'tanggal', 'date'];
                    DateTime? dt;
                    for (final k in dateKeys) {
                      if (m.containsKey(k) && m[k] != null) {
                        final raw = m[k];
                        if (raw is Timestamp) { dt = raw.toDate(); break; }
                        if (raw is String && raw.isNotEmpty) { try { dt = DateTime.parse(raw); break; } catch (_) {} }
                      }
                    }
                    // fallback: no date found on document — log for debugging
                    if (dt == null) {
                      debugPrint('loadCounts: barcode id=${d.id} has no date fields');
                    }
                    if (dt != null) {
                      if (dt.isAfter(lastWeek) && dt.isBefore(now)) total++;
                    }
                  }
                } catch (_) {
                  // ignore batch errors
                }
              }
              masukCount = total;
            debugPrint('loadCounts: productIds (${productIds.length}) processed, weeklyCount=$masukCount');

            // If weekly count is zero, try a no-date fallback to see if there are barcodes at all for these products
            if (masukCount == 0) {
              int totalNoDate = 0;
              for (var i = 0; i < productIds.length; i += batchSize) {
                final batch = productIds.sublist(i, (i + batchSize) > productIds.length ? productIds.length : i + batchSize);
                try {
                  final qNoDate = await _fs.collection('product_barcodes').where('productId', whereIn: batch).get();
                  totalNoDate += qNoDate.docs.length;
                } catch (_) {
                  // ignore
                }
              }
              if (totalNoDate > 0) {
                debugPrint('loadCounts: weekly count is 0 but total barcodes for owner products = $totalNoDate (fallback no-date)');
                // Use the no-date total as a fallback so the dashboard shows something informative
                masukCount = totalNoDate;
              }
            }
          } else {
            // no owned products found -> 0
            masukCount = 0;
          }
        } catch (_) {
          masukCount = 0;
        }
      } else {
        // ownerId not provided: count globally within last week
        try {
          Query<Map<String, dynamic>> q = _fs.collection('product_barcodes').where('scannedAt', isGreaterThanOrEqualTo: lastWeekTs);
          try {
            final agg = q.count();
            final snap = await agg.get();
            masukCount = snap.count ?? 0;
          } catch (_) {
            final snap2 = await q.get();
            masukCount = snap2.docs.length;
          }
        } catch (_) {
          // fallback: scan all and parse scannedAt fields
          final all = await _fs.collection('product_barcodes').get();
          for (final d in all.docs) {
            final m = d.data();
            final raw = m['scannedAt'] ?? m['scanned_at'] ?? m['scannedAtStr'] ?? '';
            DateTime? dt;
            if (raw is Timestamp) dt = raw.toDate();
            else if (raw is String && raw.isNotEmpty) {
              try { dt = DateTime.parse(raw); } catch (_) {}
            }
            if (dt != null && dt.isAfter(lastWeek) && dt.isBefore(now)) masukCount++;
          }
        }
      }

      barangMasuk = masukCount;
      debugPrint('loadCounts: barangMasuk=$barangMasuk');

      // 3. BARANG KELUAR: hitung TOTAL dari REST API order_items
      int keluarCount = 0;
      try {
        final apiToken = token; // dari config.dart
        final projectName = project;
        final app = appid;
        
        // Menggunakan selectWhere untuk mendapatkan semua order_items milik owner
        debugPrint('loadCounts: fetching order_items for owner $ownerId');
        final orderItemsRes = await _api.selectWhere(
          apiToken, 
          projectName, 
          'order_items', // collection dari REST API
          app, 
          'ownerid', 
          ownerId
        );
        
        // Parse response dengan null safety
        List<dynamic> orderItems = [];
        try { 
          if (orderItemsRes is String) {
            if (orderItemsRes.isEmpty || orderItemsRes == '[]') {
              orderItems = [];
              debugPrint('loadCounts: selectWhere returned empty array');
            } else {
              try {
                final decoded = jsonDecode(orderItemsRes);
                if (decoded is List) {
                  orderItems = decoded;
                  debugPrint('loadCounts: parsed ${orderItems.length} items from selectWhere JSON');
                } else if (decoded is Map) {
                  debugPrint('loadCounts: decoded is Map, keys: ${decoded.keys}');
                  if (decoded.containsKey('data') && decoded['data'] is List) {
                    orderItems = decoded['data'];
                    debugPrint('loadCounts: got ${orderItems.length} items from data field');
                  }
                }
              } catch (e) {
                debugPrint('loadCounts: JSON decode error for selectWhere: $e');
              }
            }
          } else if (orderItemsRes is List) {
            orderItems = orderItemsRes;
            debugPrint('loadCounts: got ${orderItems.length} items directly from selectWhere');
          } else if (orderItemsRes is Map) {
            debugPrint('loadCounts: selectWhere returned Map, keys: ${orderItemsRes.keys}');
            if (orderItemsRes.containsKey('data') && orderItemsRes['data'] is List) {
              orderItems = orderItemsRes['data'];
              debugPrint('loadCounts: got ${orderItems.length} items from data field');
            }
          }
        } catch (e) {
          debugPrint('loadCounts: parse orderItemsRes error: $e');
          orderItems = [];
        }
        
        debugPrint('loadCounts: found ${orderItems.length} order items for owner $ownerId');
        
        // Jika kosong, coba selectAll sebagai fallback
        if (orderItems.isEmpty) {
          debugPrint('loadCounts: trying selectAll as fallback');
          try {
            final allItemsRes = await _api.selectAll(token, project, 'order_items', appid);
            
            debugPrint('loadCounts: selectAll response type: ${allItemsRes.runtimeType}');
            
            if (allItemsRes is String) {
              if (allItemsRes.isEmpty || allItemsRes == '[]') {
                debugPrint('loadCounts: selectAll returned empty array');
              } else {
                try {
                  final decoded = jsonDecode(allItemsRes);
                  if (decoded is List) {
                    orderItems = decoded;
                    debugPrint('loadCounts: parsed ${orderItems.length} items from selectAll JSON');
                  } else if (decoded is Map) {
                    debugPrint('loadCounts: decoded is Map, keys: ${decoded.keys}');
                    if (decoded.containsKey('data') && decoded['data'] is List) {
                      orderItems = decoded['data'];
                      debugPrint('loadCounts: got ${orderItems.length} items from data field');
                    }
                  }
                } catch (e) {
                  debugPrint('loadCounts: JSON decode error for selectAll: $e');
                }
              }
            } else if (allItemsRes is List) {
              orderItems = allItemsRes;
              debugPrint('loadCounts: got ${orderItems.length} items directly from selectAll');
            }
          } catch (e) {
            debugPrint('loadCounts: selectAll error: $e');
          }
        }
        
        // Debug: tampilkan beberapa item pertama untuk melihat struktur
        for (int i = 0; i < orderItems.length && i < 3; i++) {
          final item = orderItems[i];
          if (item is Map) {
            debugPrint('loadCounts: item[$i] keys: ${item.keys.toList()}');
            debugPrint('loadCounts: item[$i] ownerid: ${item['ownerid']}');
            debugPrint('loadCounts: item[$i] list_barcode: ${item['list_barcode']}');
          }
        }
        
        // Hitung total barang keluar dari list_barcode dengan format ["089686060102","0989844924"]
        for (final item in orderItems) {
          if (item == null) continue;
          
          Map<String, dynamic>? itemMap;
          try {
            if (item is Map<String, dynamic>) {
              itemMap = item;
            } else if (item is Map) {
              itemMap = Map<String, dynamic>.from(item.cast<String, dynamic>());
            } else {
              continue;
            }
          } catch (e) {
            debugPrint('loadCounts: error converting item to Map: $e');
            continue;
          }
          
          // Cari ownerId dari berbagai kemungkinan field
          final itemOwnerId = itemMap['ownerid']?.toString() ?? 
                             itemMap['ownerId']?.toString() ?? 
                             itemMap['owner_id']?.toString() ??
                             itemMap['user_id']?.toString() ??
                             '';
          
          // Filter berdasarkan ownerId jika tersedia
          if (ownerId.isNotEmpty && itemOwnerId != ownerId) {
            continue;
          }
          
          // Cari field list_barcode dengan berbagai kemungkinan nama
          dynamic lb = itemMap['list_barcode'] ?? 
                       itemMap['listBarcode'] ?? 
                       itemMap['list_barcode_json'] ?? 
                       itemMap['barcodes'] ??
                       itemMap['barcode_list'] ??
                       itemMap['list'] ??
                       '';
          
          if (lb == null || (lb is String && lb.isEmpty)) {
            // Jika tidak ada list_barcode, coba gunakan jumlah_produk
            final jumlahProduk = itemMap['jumlah_produk'] ?? 
                                itemMap['jumlah'] ?? 
                                itemMap['qty'] ?? 
                                itemMap['quantity'] ??
                                '0';
            
            try { 
              final jumlah = int.tryParse(jumlahProduk.toString()) ?? 0;
              if (jumlah > 0) {
                keluarCount += jumlah;
                debugPrint('loadCounts: added $jumlah from jumlah_produk (no list_barcode)');
              }
            } catch (_) {}
            continue;
          }
          
          // Proses list_barcode berdasarkan tipenya
          if (lb is String && lb.isNotEmpty) {
            debugPrint('loadCounts: processing list_barcode string: ${lb.length > 50 ? lb.substring(0, 50) + '...' : lb}');
            
            // Gunakan helper function
            final count = _countBarcodesFromString(lb);
            if (count > 0) {
              keluarCount += count;
              debugPrint('loadCounts: added $count barcodes from string');
            } else {
              debugPrint('loadCounts: no barcodes found in string: $lb');
            }
          } else if (lb is List) {
            final validCount = lb.where((b) => 
              b != null && b.toString().trim().isNotEmpty
            ).length;
            
            keluarCount += validCount;
            debugPrint('loadCounts: added $validCount barcodes from direct List');
          } else {
            debugPrint('loadCounts: unknown list_barcode type: ${lb.runtimeType}');
            
            // Coba gunakan jumlah_produk sebagai fallback
            final jumlahProduk = itemMap['jumlah_produk'] ?? 
                                itemMap['jumlah'] ?? 
                                itemMap['qty'] ?? 
                                itemMap['quantity'] ??
                                '0';
            
            try { 
              final jumlah = int.tryParse(jumlahProduk.toString()) ?? 0;
              if (jumlah > 0) {
                keluarCount += jumlah;
                debugPrint('loadCounts: added $jumlah from jumlah_produk (fallback)');
              }
            } catch (_) {}
          }
        }
        
        debugPrint('loadCounts: barangKeluar total counted=$keluarCount from order_items');
        
        // TESTING: Jika masih 0, coba dengan hardcoded example
        if (keluarCount == 0 && orderItems.isNotEmpty) {
          debugPrint('loadCounts: WARNING - barangKeluar is 0 but orderItems is not empty');
          // Test parsing dengan contoh format
          final testString = '["089686060102","0989844924"]';
          final testCount = _countBarcodesFromString(testString);
          debugPrint('loadCounts: TEST - Example string "$testString" would give $testCount items');
        }
        
      } catch (e) {
        debugPrint('Error in barang keluar calculation: $e');
        debugPrint('Error stack trace: ${e.toString()}');
        keluarCount = 0;
      }
      barangKeluar = keluarCount;

      // 4. EXPIRED COUNT: produk yang sudah expired
      int expired = 0;
      try {
        final nowDate = DateTime.now();
        final candidates = ['tanggal_expired', 'tanggal_expire', 'expiredDate', 'expired_at', 'expired_date', 'expired', 'expired_date_str'];
        bool usedCountQuery = false;
        debugPrint('loadCounts: attempting expired aggregation on products');
        
        for (final field in candidates) {
          try {
            Query q = _fs.collection('products');
            if (ownerId.isNotEmpty) {
              // Filter by owner
              try {
                q = q.where('ownerId', isEqualTo: ownerId);
              } catch (_) {
                try {
                  q = q.where('ownerid', isEqualTo: ownerId);
                } catch (_) {}
              }
            }
            q = q.where(field, isLessThan: Timestamp.fromDate(nowDate));
            
            final agg = q.count();
            final aggSnap = await agg.get();
            final cnt = aggSnap.count ?? 0;
            usedCountQuery = true;
            debugPrint('loadCounts: agg field=$field cnt=$cnt');
            if (cnt > 0) {
              expired = cnt;
              debugPrint('loadCounts: expired aggregated via products field $field count=$cnt');
              break;
            }
          } catch (e) {
            debugPrint('loadCounts: agg error for field $field -> $e');
          }
        }
        
        if (!usedCountQuery || expired == 0) {
          debugPrint('loadCounts: falling back to scanning products for expiry');
          Query prodQuery = _fs.collection('products');
          if (ownerId.isNotEmpty) {
            try {
              prodQuery = prodQuery.where('ownerId', isEqualTo: ownerId);
            } catch (_) {
              try {
                prodQuery = prodQuery.where('ownerid', isEqualTo: ownerId);
              } catch (_) {}
            }
          }
          
          final prodSnap2 = await prodQuery.get();
          debugPrint('loadCounts: scanned products docs=${prodSnap2.docs.length}');
          
          final candidates2 = ['tanggal_expired', 'tanggal_expire', 'expiredDate', 'expired_at', 'expired_date', 'expired', 'expired_date_str'];
          for (final d in prodSnap2.docs) {
            final p = d.data();
            String rawExpired = '';
            for (final k in candidates2) {
              final value = p??[k];
              // ignore: unnecessary_null_comparison
              if (value != null && value.toString().isNotEmpty) {
                rawExpired = value.toString();
                break;
              }
            }
            if (rawExpired.isEmpty) continue;
            try {
              // Coba parse sebagai DateTime
              DateTime? expDate;
              if (rawExpired is Timestamp) {
                expDate = rawExpired.toDate();
              } else {
                expDate = DateTime.tryParse(rawExpired);
                if (expDate == null) {
                  // Coba format lain
                  try {
                    expDate = DateFormat('yyyy-MM-dd').parse(rawExpired);
                  } catch (_) {
                    try {
                      expDate = DateFormat('dd/MM/yyyy').parse(rawExpired);
                    } catch (_) {}
                  }
                }
              }
              
              if (expDate != null && expDate.isBefore(nowDate)) {
                expired++;
              }
            } catch (e) {
              debugPrint('loadCounts: parse expiry error for doc ${d.id}: $e');
            }
          }
          debugPrint('loadCounts: expired after scanning products=$expired');
        }
      } catch (e) {
        debugPrint('expired count error: $e');
      }
      expiredCount = expired;
      
      // Fetch dynamic product flow and transaction data
      if (ownerId.isNotEmpty) {
        await fetchDynamicProductFlow(ownerId);
        await fetchDynamicTransactions(ownerId);
      }
      
      isLoadingCounts = false;
      debugPrint('loadCounts completed: totalProduk=$totalProduk, barangMasuk=$barangMasuk, barangKeluar=$barangKeluar, expiredCount=$expiredCount');
      
    } catch (e) {
      isLoadingCounts = false;
      debugPrint('loadCounts error: $e');
    }
  }

  /// Fetch monthly transaction counts (and optionally totals) from REST API `order` collection
  /// Filters by `ownerid` and aggregates per month for the last 12 months.
  Future<List<Map<String, dynamic>>> fetchFinancialMonthlyTotals(String ownerId) async {
    final now = DateTime.now();
    final months = <DateTime>[];
    
    // Generate last 12 months dates from current month backwards
    for (int i = 11; i >= 0; i--) {
      DateTime dt = DateTime(now.year, now.month - i, 1);
      months.add(dt);
    }

    // initialize output with month labels and zero counts
    final monthNames = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    final colors = _monthlyTransactions.map((e) => e['color'] as Color).toList();
    final out = List<Map<String, dynamic>>.generate(12, (i) => {
      'month': monthNames[months[i].month - 1],
      'transactions': 0,
      'total': 0.0,
      'color': colors.length > i ? colors[i] : const Color(0xFF3B82F6),
    });

    try {
      // fetch orders from REST API filtered by ownerid
      final apiToken = token;
      final projectName = project;
      final app = appid;
      dynamic raw;
      try {
        raw = await _api.selectWhere(apiToken, projectName, 'order', app, 'ownerid', ownerId);
      } catch (e) {
        raw = [];
      }

      List<dynamic> orders = [];
      try {
        if (raw is String) {
          final parsed = jsonDecode(raw);
          if (parsed is Map && parsed.containsKey('data')) orders = parsed['data'] as List<dynamic>;
          else if (parsed is List) orders = parsed;
        } else if (raw is List) {
          orders = raw;
        } else if (raw is Map && raw.containsKey('data')) {
          orders = raw['data'] as List<dynamic>;
        }
      } catch (_) {
        orders = [];
      }

      for (final od in orders) {
        if (od is! Map) continue;
        final data = od as Map<String, dynamic>;
        // ensure owner filter
        final ownerField = data['ownerid'] ?? data['owner_id'] ?? data['ownerId'];
        if (ownerField == null || ownerField.toString() != ownerId) continue;

        // parse date from `tanggal_order` or fallbacks
        DateTime? dt;
        final dateCandidates = ['tanggal_order', 'tanggal', 'order_date', 'date', 'created_at'];
        for (final k in dateCandidates) {
          if (data.containsKey(k) && data[k] != null) {
            final v = data[k];
            if (v is String) {
              try { dt = DateTime.parse(v); break; } catch (_) {}
            }
            if (v is Timestamp) { dt = v.toDate(); break; }
          }
        }
        if (dt == null) continue;

        // only last 12 months
        final idx = months.indexWhere((m) => m.year == dt?.year && m.month == dt?.month);
        if (idx < 0) continue;

        // increment transaction count
        out[idx]['transactions'] = (out[idx]['transactions'] as int) + 1;

        // add total_harga if present
        final totalRaw = data['total_harga'] ?? data['total'] ?? data['grand_total'];
        double amt = 0.0;
        if (totalRaw != null) {
          if (totalRaw is num) amt = totalRaw.toDouble();
          else if (totalRaw is String) {
            amt = double.tryParse(totalRaw.replaceAll(',', '')) ?? 0.0;
          }
        }
        out[idx]['total'] = (out[idx]['total'] as double) + amt;
      }
    } catch (e) {
      debugPrint('fetchFinancialMonthlyTotals error: $e');
    }

    return out;
  }

  /// Count unique customers in `order` REST collection for given ownerId
  Future<int> fetchTotalCustomers(String ownerId) async {
    try {
      final apiToken = token;
      final projectName = project;
      final app = appid;
      dynamic raw;
      try {
        raw = await _api.selectWhere(apiToken, projectName, 'order', app, 'ownerid', ownerId);
      } catch (_) {
        raw = [];
      }

      List<dynamic> orders = [];
      try {
        if (raw is String) {
          final parsed = jsonDecode(raw);
          if (parsed is Map && parsed.containsKey('data')) orders = parsed['data'] as List<dynamic>;
          else if (parsed is List) orders = parsed;
        } else if (raw is List) orders = raw;
        else if (raw is Map && raw.containsKey('data')) orders = raw['data'] as List<dynamic>;
      } catch (_) { orders = []; }

      final customers = <String>{};
      for (final od in orders) {
        if (od is! Map) continue;
        final data = od as Map<String, dynamic>;
        final cid = data['customor_id'] ?? data['customerId'] ?? data['customer'];
        if (cid != null) customers.add(cid.toString());
      }
      return customers.length;
    } catch (e) {
      debugPrint('fetchTotalCustomers error: $e');
      return 0;
    }
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
  void navigateToStaffScreen(BuildContext context) async {
    // Import your AddStaffScreen here
    // final result = await Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => const AddStaffScreen()),
    // );
    // if (result != null && result is Map) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Karyawan ${result['username']} ditambahkan')),
    //   );
    // }
  }

  void navigateToProductsScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const ListProductPage()),
    );
  }

  void navigateToStoreScreen(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PengirimanPage(
          orders: const [],
          loading: false,
          onOpenMap: _openMap,
          onOpenOrder: _openOrder,
        ),
      ),
    );
  }

  void _openMap(String alamat) {
    // TODO: Implement map opening
  }

  void _openOrder(Map<String, dynamic> order) {
    // TODO: Implement order opening
  }

  void showNotifications(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const NotifikasiOwnerPage(),
      ),
    );
  }

  // Count remaining stock from product_barcodes collection
  Future<int> countRemainingStock(String ownerId) async {
    try {
      // prefer using the controller-level Firestore instance
      final firestore = _fs;

      // 1) Try querying by explicit owner field(s) on product_barcodes
      for (final ownerField in ['ownerid', 'ownerId']) {
        try {
          final q = firestore.collection('product_barcodes').where(ownerField, isEqualTo: ownerId);
          try {
            final agg = q.count();
            final snap = await agg.get();
            final c = snap.count ?? 0;
            debugPrint('countRemainingStock: ownerId=$ownerId, field=$ownerField, count=$c (via count())');
            if (c > 0) return c;
          } catch (_) {
            final snap2 = await q.get();
            final c2 = snap2.docs.length;
            debugPrint('countRemainingStock: ownerId=$ownerId, field=$ownerField, count=$c2 (via get())');
            if (c2 > 0) return c2;
          }
        } catch (_) {
          // ignore errors and try next owner field
        }
      }

      // 2) If owner field not present on barcodes, try: fetch products owned by owner and count barcodes by productId
      try {
        Query<Map<String, dynamic>> prodQ = firestore.collection('products');
        try {
          prodQ = prodQ.where('ownerId', isEqualTo: ownerId);
        } catch (_) {
          try {
            prodQ = prodQ.where('ownerid', isEqualTo: ownerId);
          } catch (_) {}
        }

        final prodSnap = await prodQ.get();
        final productIds = prodSnap.docs.map((d) {
          final data = d.data();
          return (data['id'] ?? data['id_product'] ?? d.id).toString();
        }).where((s) => s.isNotEmpty).toSet().toList();

        if (productIds.isNotEmpty) {
          int total = 0;
          const batchSize = 10; // Firestore whereIn limit
          for (var i = 0; i < productIds.length; i += batchSize) {
            final batch = productIds.sublist(i, (i + batchSize) > productIds.length ? productIds.length : i + batchSize);
            try {
              final q = firestore.collection('product_barcodes').where('productId', whereIn: batch);
              try {
                final agg = q.count();
                final snap = await agg.get();
                total += snap.count ?? 0;
              } catch (_) {
                final snap2 = await q.get();
                total += snap2.docs.length;
              }
            } catch (_) {
              // ignore per-batch failures
            }
          }
          debugPrint('countRemainingStock by productIds: ownerId=$ownerId, count=$total');
          if (total > 0) return total;
        }
      } catch (_) {
        // ignore product-based fallback errors
      }

      // 3) Final fallback: count all barcodes (no owner info)
      try {
        final aggAll = firestore.collection('product_barcodes').count();
        final snapAll = await aggAll.get();
        final allCount = snapAll.count ?? 0;
        debugPrint('countRemainingStock fallback: totalBarcodes=$allCount');
        return allCount;
      } catch (_) {
        final snapAll2 = await firestore.collection('product_barcodes').get();
        debugPrint('countRemainingStock fallback(get): totalBarcodes=${snapAll2.docs.length}');
        return snapAll2.docs.length;
      }
    } catch (e) {
      debugPrint('countRemainingStock error: $e');
      return 0;
    }
  }

  // Fetch dynamic monthly totals for chart (in/out untuk 12 bulan)
  // Helper: parse various scannedAt value formats into DateTime
  DateTime? _parseScannedAtValue(dynamic val) {
    if (val == null) return null;
    try {
      if (val is Timestamp) return val.toDate();
      if (val is DateTime) return val;
      if (val is int) return DateTime.fromMillisecondsSinceEpoch(val);
      if (val is double) return DateTime.fromMillisecondsSinceEpoch(val.toInt());
      if (val is String) {
        // Normalize narrow/no-break spaces
        final s = val.replaceAll('\u202F', ' ').trim();
        // Try ISO first
        final iso = DateTime.tryParse(s);
        if (iso != null) return iso;

        // Example format: "January 3, 2026 at 2:02:13 AM UTC+7"
        // Split on ' at ' (case-insensitive) to separate date and time+tz
        final parts = s.split(RegExp(r'\bat\b', caseSensitive: false));
        String datePart = parts.isNotEmpty ? parts[0].trim() : '';
        String timePart = parts.length > 1 ? parts[1].trim() : '';

        // Extract UTC offset if present
        final tzMatch = RegExp(r'UTC([+-]\d{1,2})').firstMatch(timePart);
        int tzOffsetHours = 0;
        if (tzMatch != null) {
          tzOffsetHours = int.tryParse(tzMatch.group(1) ?? '0') ?? 0;
          timePart = timePart.replaceAll(RegExp(r'UTC[+-]\d{1,2}'), '').trim();
        }

        // Try parsing with pattern 'MMMM d, y h:mm:ss a'
        try {
          final combined = '$datePart $timePart';
          final df = DateFormat('MMMM d, y h:mm:ss a', 'en_US');
          var parsed = df.parse(combined);
          if (tzMatch != null) {
            // parsed is considered local; adjust from the provided UTC offset to local
            parsed = parsed.subtract(Duration(hours: tzOffsetHours)).toLocal();
          }
          return parsed;
        } catch (_) {
          // ignore and fallback
        }
      }
    } catch (_) {}
    return null;
  }

  /// Compute monthly incoming counts from `product_barcodes` using the
  /// same owner filtering and parsing logic as `loadCounts` (Barang Masuk).
  Future<List<double>> computeMonthlyIncomingFromBarcodes(String ownerId) async {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 11, 1);
    final months = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - (11 - i), 1);
      return DateTime(dt.year, dt.month);
    });

    final inTotals = List<double>.filled(12, 0);

    try {
      // Try direct owner-based queries first
      QuerySnapshot<Map<String, dynamic>>? pbSnap;
      for (final ownerField in ['ownerid', 'ownerId', 'owner', 'owner_id']) {
        try {
          final q = _fs.collection('product_barcodes').where(ownerField, isEqualTo: ownerId);
          pbSnap = await q.get();
          if (pbSnap.docs.isNotEmpty) {
            debugPrint('computeMonthlyIncomingFromBarcodes: ownerField=$ownerField matched ${pbSnap.docs.length} docs');
            break;
          }
        } catch (_) {
          pbSnap = null;
        }
      }

      // If we have direct owner-based docs, process them
      if (pbSnap != null && pbSnap.docs.isNotEmpty) {
        for (final doc in pbSnap.docs) {
          final data = doc.data();
          DateTime? dt;
          try { dt = _parseScannedAtValue(data['scannedAt']); } catch (_) { dt = null; }
          if (dt == null || dt.isBefore(start)) continue;
          final idx = months.indexWhere((m) => m.year == dt?.year && m.month == dt?.month);
          if (idx >= 0) inTotals[idx] = inTotals[idx] + 1.0;
        }
        return inTotals;
      }

      // Fallback: find products owned by ownerId and count barcodes by productId
      Query<Map<String, dynamic>> prodQ = _fs.collection('products');
      try { prodQ = prodQ.where('ownerId', isEqualTo: ownerId); } catch (_) {
        try { prodQ = prodQ.where('ownerid', isEqualTo: ownerId); } catch (_) {}
      }

      final prodSnap = await prodQ.get();
      final productIds = prodSnap.docs.map((d) {
        final data = d.data();
        return (data['id'] ?? data['product_id'] ?? d.id).toString();
      }).where((s) => s.isNotEmpty).toSet().toList();

      if (productIds.isEmpty) return inTotals;

      const batchSize = 10;
      for (var i = 0; i < productIds.length; i += batchSize) {
        final batch = productIds.sublist(i, (i + batchSize) > productIds.length ? productIds.length : i + batchSize);
        try {
          final snap = await _fs.collection('product_barcodes').where('productId', whereIn: batch).get();
          for (final d in snap.docs) {
            final data = d.data();
            DateTime? dt;
            try { dt = _parseScannedAtValue(data['scannedAt']); } catch (_) { dt = null; }
            if (dt == null || dt.isBefore(start)) continue;
            final idx = months.indexWhere((m) => m.year == dt?.year && m.month == dt?.month);
            if (idx >= 0) inTotals[idx] = inTotals[idx] + 1.0;
          }
        } catch (e) {
          debugPrint('computeMonthlyIncomingFromBarcodes batch error: $e');
        }
      }
    } catch (e) {
      debugPrint('computeMonthlyIncomingFromBarcodes error: $e');
    }

    return inTotals;
  }

  Future<Map<String, List<double>>> fetchMonthlyTotals(String ownerId) async {
    final inTotals = List<double>.filled(12, 0);
    final outTotals = List<double>.filled(12, 0);
    
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 11, 1);
    final months = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - (11 - i), 1);
      return DateTime(dt.year, dt.month);
    });

    // 1. Product barcodes (incoming) - use shared helper that mirrors Barang Masuk logic
    try {
      final computed = await computeMonthlyIncomingFromBarcodes(ownerId);
      for (var i = 0; i < inTotals.length; i++) inTotals[i] = computed[i];
      debugPrint('fetchMonthlyTotals: computed inTotals via shared helper=$inTotals');
    } catch (e) {
      debugPrint('fetchMonthlyTotals: product_barcodes error (helper): $e');
    }

    // 2. Order items (outgoing) via REST API
    try {
      dynamic oiRaw;
      try {
        if (ownerId.isNotEmpty) {
          final resp = await _api.selectWhere(token, project, 'order_items', appid, 'ownerid', ownerId);
          oiRaw = resp;
          debugPrint('fetchMonthlyTotals: selectWhere returned: $resp');
        } else {
          final resp = await _api.selectAll(token, project, 'order_items', appid);
          oiRaw = resp;
          debugPrint('fetchMonthlyTotals: selectAll returned: $resp');
        }
      } catch (e) {
        debugPrint('fetchMonthlyTotals: selectWhere/selectAll error: $e');
        oiRaw = '[]';
      }

      List<dynamic> orderItemsList = [];
      try {
        dynamic parsed;
        if (oiRaw is String) {
          try {
            parsed = jsonDecode(oiRaw);
          } catch (e) {
            debugPrint('fetchMonthlyTotals: jsonDecode oiRaw failed: $e');
            parsed = null;
          }
        } else {
          parsed = oiRaw;
        }

        if (parsed is List) orderItemsList = parsed;
        else if (parsed is Map && parsed['data'] is List) orderItemsList = parsed['data'] as List<dynamic>;
        else orderItemsList = [];
      } catch (e) {
        debugPrint('fetchMonthlyTotals: parsing order items error: $e');
        orderItemsList = [];
      }

      debugPrint('fetchMonthlyTotals: orderItemsList.length=${orderItemsList.length}');

      // Collect order_ids
      final orderIds = <String>{};
      for (final item in orderItemsList) {
        if (item is Map) {
          final oid = item['order_id'] ?? item['orderId'];
          if (oid != null) orderIds.add(oid.toString());
        }
      }
      
      debugPrint('fetchMonthlyTotals: collected ${orderIds.length} order IDs');

      // Fetch orders via REST in batch
      final orderDateMap = <String, DateTime>{};
      if (orderIds.isNotEmpty) {
        final ids = orderIds.toList();
        const batchSize = 50;
        for (var i = 0; i < ids.length; i += batchSize) {
          final batch = ids.sublist(i, (i + batchSize) > ids.length ? ids.length : i + batchSize);
          try {
            final winValue = batch.join(',');
            final resp = await _api.selectWhereIn(token, project, 'orders', appid, 'order_id', winValue);
            debugPrint('fetchMonthlyTotals: orders selectWhereIn resp type=${resp.runtimeType}');
            if (resp != null) {
              try {
                final raw = (resp is String) ? jsonDecode(resp) : resp;
                List<dynamic> ordersList = [];
                if (raw is List) ordersList = raw;
                else if (raw is Map && raw.containsKey('data') && raw['data'] is List) ordersList = raw['data'];
                debugPrint('fetchMonthlyTotals: ordersList.length=${ordersList.length}');
                for (final od in ordersList) {
                  if (od is Map) {
                    DateTime? d;
                    final v = od['tanggal_order'] ?? od['tanggal'] ?? od['order_date'] ?? od['date'];
                    if (v is String) {
                      try {
                        d = DateTime.parse(v);
                      } catch (_) {}
                    }
                    final key = od['order_id']?.toString() ?? od['id']?.toString() ?? '';
                    if (d != null && key.isNotEmpty) {
                      orderDateMap[key] = d;
                      debugPrint('fetchMonthlyTotals: orderDateMap[$key] = $d');
                    }
                  }
                }
              } catch (e) {
                debugPrint('fetchMonthlyTotals: error parsing orders resp: $e');
              }
            }
          } catch (_) {}
        }
      }

      // Process order items
      for (final raw in orderItemsList) {
        if (raw is! Map) continue;
        final data = raw as Map<String, dynamic>;

        DateTime? dt;
        
        // Priority 1: tanggal_order_items (newly added to order_items collection)
        final tanggalOrderItems = data['tanggal_order_items'];
        if (tanggalOrderItems is String) {
          try {
            dt = DateTime.parse(tanggalOrderItems);
            debugPrint('fetchMonthlyTotals: parsed tanggal_order_items=$tanggalOrderItems');
          } catch (_) {}
        }
        
        // Priority 2: lookup from orders collection (fallback)
        if (dt == null) {
          final oid = data['order_id'] ?? data['orderId'];
          if (oid != null && orderDateMap.containsKey(oid.toString())) {
            dt = orderDateMap[oid.toString()];
            debugPrint('fetchMonthlyTotals: got date from orderDateMap for order_id=$oid');
          }
        }

        // Priority 3: other date fields (legacy fallback)
        if (dt == null) {
          final dateKeys = ['created_at', 'timestamp', 'order_date', 'date', 'tanggal', 'scannedAt'];
          for (final k in dateKeys) {
            if (data.containsKey(k) && data[k] != null) {
              final v = data[k];
              if (v is String) { try { dt = DateTime.parse(v); break; } catch (_) {} }
            }
          }
        }
        if (dt == null || dt.isBefore(start)) {
          debugPrint('fetchMonthlyTotals: skipping item (dt=$dt, start=$start), data keys: ${data.keys}');
          continue;
        }

        final idx = months.indexWhere((m) => m.year == dt?.year && m.month == dt?.month);
        if (idx < 0) continue;

        // Quantity via list_barcode
        num qty = 0;
        if (data.containsKey('list_barcode') && data['list_barcode'] != null) {
          final lb = data['list_barcode'];
          if (lb is List) qty = lb.length;
          else if (lb is String) {
            final parsed = lb.trim();
            if (parsed.startsWith('[') && parsed.endsWith(']')) {
              try {
                final inner = parsed.substring(1, parsed.length - 1);
                final items = inner.split(',').map((s) => s.replaceAll(RegExp(r'''["']'''), '').trim()).where((s) => s.isNotEmpty).toList();
                qty = items.length;
              } catch (_) {}
            }
          }
        }
        if (qty == 0) {
          final qtyKeys = ['jumlah_produk', 'quantity', 'qty', 'jumlah'];
          for (final k in qtyKeys) {
            if (data.containsKey(k) && data[k] != null) {
              final v = data[k];
              if (v is num) qty = v;
              else if (v is String) qty = num.tryParse(v.replaceAll(',', '')) ?? 0;
              break;
            }
          }
        }
        if (qty == 0) qty = 1;
        debugPrint('fetchMonthlyTotals: adding qty=$qty to outTotals[$idx]');
        outTotals[idx] = outTotals[idx] + qty.toDouble();
      }
      debugPrint('fetchMonthlyTotals: final outTotals=$outTotals');
    } catch (e) {
      debugPrint('fetchMonthlyTotals: order items error: $e');
    }

    return {'in': inTotals, 'out': outTotals};
  }

  void showSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings belum tersedia')),
    );
  }

  void logout(BuildContext context) {
    handleLogout(context);
  }

  // ============ EXPORT METHODS ============
  
  /// Laporan keseluruhan produk tersedia
  Future<Map<String, dynamic>> fetchAvailableProductsReport(String ownerId) async {
    try {
      final productsRes = await _api.selectAll(token, project, 'product', appid);
      final products = _safeParseList(productsRes);

      // Filter by owner
      final ownerProducts = products.where((p) {
        final owner = (p['ownerid'] ?? p['owner_id'] ?? p['ownerId'] ?? '').toString();
        return owner == ownerId;
      }).toList();

      return {
        'type': 'Laporan Keseluruhan Produk Tersedia',
        'timestamp': DateTime.now(),
        'data': ownerProducts,
        'columns': ['ID', 'Nama Produk', 'Kategori', 'Harga', 'Stok', 'Satuan']
      };
    } catch (e) {
      debugPrint('Error fetching available products report: $e');
      return {'type': 'Error', 'data': [], 'error': e.toString()};
    }
  }

  /// Laporan keseluruhan produk kadaluarsa
  Future<Map<String, dynamic>> fetchExpiredProductsReport(String ownerId) async {
    try {
      // Use Firestore-based helper to get products and barcode counts relative to expiry
      final items = await fetchProductsWithBarcodeCountsByExpiry(ownerId);

      // Map to exportable rows
      final data = items.map((it) {
        final p = it['productData'] as Map<String, dynamic>? ?? {};
        return {
          'product_doc_id': it['product_doc_id'] ?? '',
          'productIdentifier': it['productIdentifier'] ?? '',
          'nama': p['name'] ?? p['nama'] ?? p['product_name'] ?? '',
          'expiredRaw': it['expiredRaw'] ?? '',
          'expiredDate': it['expiredDate'] ?? '',
          'totalBarcodes': it['totalBarcodes'] ?? 0,
          'barcodesBeforeOrOnExpiry': it['barcodesBeforeOrOnExpiry'] ?? 0,
          'category': p['category'] ?? p['kategori'] ?? '',
          'stock': p['stock'] ?? p['stok'] ?? p['jumlah'] ?? 0,
        };
      }).toList();

      return {
        'type': 'Laporan Keseluruhan Produk Kadaluarsa',
        'timestamp': DateTime.now(),
        'data': data,
        'columns': ['Product Doc ID', 'Product Identifier', 'Nama', 'Tanggal Kadaluarsa', 'Total Barcodes', 'Barcodes Sebelum/Pada Kadaluarsa', 'Kategori', 'Stok']
      };
    } catch (e) {
      debugPrint('Error fetching expired products report: $e');
      return {'type': 'Error', 'data': [], 'error': e.toString()};
    }
  }

  /// Fetch products for owner and join with `product_barcodes` to count barcodes
  /// whose `scannedAt` is before or on the product's expiry date (if available).
  Future<List<Map<String, dynamic>>> fetchProductsWithBarcodeCountsByExpiry(String ownerId) async {
    final firestore = _fs;
    final results = <Map<String, dynamic>>[];

    // Build product query scoped to owner
    Query<Map<String, dynamic>> prodQuery = firestore.collection('products');
    try {
      prodQuery = prodQuery.where('ownerid', isEqualTo: ownerId);
    } catch (_) {
      try {
        prodQuery = prodQuery.where('ownerId', isEqualTo: ownerId);
      } catch (_) {}
    }

    final prodSnap2 = await prodQuery.get();
    debugPrint('fetchProductsWithBarcodeCountsByExpiry: scanned products docs=${prodSnap2.docs.length}');

    final candidates2 = ['tanggal_expired', 'tanggal_expire', 'expiredDate', 'expired_at', 'expired_date', 'expired', 'expired_date_str'];

    for (final d in prodSnap2.docs) {
      final p = d.data();

      // locate raw expiry string/value
      dynamic rawExpiredVal;
      for (final k in candidates2) {
        if (p.containsKey(k) && p[k] != null && p[k].toString().isNotEmpty) {
          rawExpiredVal = p[k];
          break;
        }
      }

      DateTime? expDate;
      String expRawStr = '';
      if (rawExpiredVal != null) {
        expRawStr = rawExpiredVal.toString();
        // If it's a Timestamp
        if (rawExpiredVal is Timestamp) {
          expDate = rawExpiredVal.toDate();
        } else {
          // Try direct parse
          expDate = DateTime.tryParse(expRawStr);
          if (expDate == null) {
            // try common formats
            try {
              expDate = DateFormat('yyyy-MM-dd').parse(expRawStr);
            } catch (_) {
              try {
                expDate = DateFormat('dd/MM/yyyy').parse(expRawStr);
              } catch (_) {
                try {
                  expDate = DateFormat('MMMM d, y', 'en_US').parse(expRawStr);
                } catch (_) {}
              }
            }
          }
        }
      }

      final productIdentifier = (p['productId'] ?? p['product_id'] ?? d.id).toString();
      // Fetch barcodes for this product
      List<QueryDocumentSnapshot<Map<String, dynamic>>> barcodeDocs = [];
      try {
        final q = await firestore.collection('product_barcodes').where('productId', isEqualTo: productIdentifier).get();
        barcodeDocs = q.docs;
      } catch (_) {
        try {
          final q2 = await firestore.collection('product_barcodes').where('product_id', isEqualTo: productIdentifier).get();
          barcodeDocs = q2.docs;
        } catch (_) {
          // fallback: try fetching all and filter in memory (heavy)
          final all = await firestore.collection('product_barcodes').get();
          barcodeDocs = all.docs.where((bd) {
            final b = bd.data();
            return (b['productId'] == productIdentifier) || (b['product_id'] == productIdentifier);
          }).toList();
        }
      }

      int totalBarcodes = barcodeDocs.length;
      int barcodesBeforeOrOnExpiry = 0;

      if (expDate != null && barcodeDocs.isNotEmpty) {
        for (final bd in barcodeDocs) {
          final bdata = bd.data();
          DateTime? scanned;
          try {
            scanned = _parseScannedAtValue(bdata['scannedAt']);
          } catch (_) {
            scanned = null;
          }
          if (scanned != null) {
            if (!scanned.isAfter(expDate)) barcodesBeforeOrOnExpiry++;
          }
        }
      }

      results.add({
        'product_doc_id': d.id,
        'productIdentifier': productIdentifier,
        'productData': p,
        'expiredRaw': expRawStr,
        'expiredDate': expDate?.toIso8601String() ?? null,
        'totalBarcodes': totalBarcodes,
        'barcodesBeforeOrOnExpiry': barcodesBeforeOrOnExpiry,
      });
    }

    return results;
  }

  /// Laporan order pengiriman
  Future<Map<String, dynamic>> fetchDeliveryOrderReport(String ownerId) async {
    try {
      // 1) Fetch order_items for this owner via REST
      dynamic oiRaw;
      try {
        debugPrint('=== FETCHING order_items with ownerid=$ownerId ===');
        oiRaw = await _api.selectWhere(token, project, 'order_items', appid, 'ownerid', ownerId);
        debugPrint('Response: ${oiRaw.runtimeType}');
      } catch (e) {
        debugPrint('✗ selectWhere order_items error: $e');
        oiRaw = '[]';
      }

      List<dynamic> orderItemsList = [];
      try {
        if (oiRaw is String) {
          final parsed = jsonDecode(oiRaw);
          if (parsed is List) orderItemsList = parsed;
          else if (parsed is Map && parsed['data'] is List) orderItemsList = parsed['data'];
        } else if (oiRaw is List) orderItemsList = oiRaw;
        else if (oiRaw is Map && oiRaw['data'] is List) orderItemsList = oiRaw['data'];
      } catch (e) {
        debugPrint('✗ parsing order_items failed: $e');
        orderItemsList = [];
      }

      debugPrint('✓ Got ${orderItemsList.length} order_items');

      // Collect order_ids from order_items
      final orderIds = <String>{};
      for (final raw in orderItemsList) {
        if (raw is! Map) continue;
        final oid = raw['order_id'] ?? raw['orderId'] ?? raw['order_id_server'] ?? raw['order'];
        if (oid != null) orderIds.add(oid.toString());
      }

      debugPrint('✓ Extracted ${orderIds.length} order_ids: $orderIds');

      // 2) Extract customer IDs from order collection using customor_id field
      final orderMap = <String, Map<String, dynamic>>{};
      final customerIds = <String>{};
      
      debugPrint('Extracting customor_id from ${orderIds.length} order_ids...');
      
      // Fetch orders to get customor_id
      if (orderIds.isNotEmpty) {
        final ids = orderIds.toList();
        const batchSize = 50;
        
        for (var i = 0; i < ids.length; i += batchSize) {
          final batch = ids.sublist(i, (i + batchSize) > ids.length ? ids.length : i + batchSize);
          try {
            debugPrint('Fetching orders batch: $batch');
            final resp = await _api.selectWhereIn(token, project, 'order', appid, 'order_id', batch.join(','));
            
            if (resp != null) {
              final raw = (resp is String) ? jsonDecode(resp) : resp;
              List<dynamic> ordersList = [];
              if (raw is List) ordersList = raw;
              else if (raw is Map && raw['data'] is List) ordersList = raw['data'];
              
              debugPrint('✓ Parsed ${ordersList.length} orders from batch');
              
              if (ordersList.isNotEmpty) {
                // Log first order to see all fields
                final firstOrder = ordersList[0];
                if (firstOrder is Map) {
                  debugPrint('Sample order fields: ${firstOrder.keys.toList()}');
                  debugPrint('Sample order data: $firstOrder');
                }
              }
              
              for (final o in ordersList) {
                if (o is Map) {
                  final key = o['order_id']?.toString() ?? '';
                  if (key.isNotEmpty) {
                    orderMap[key] = Map<String, dynamic>.from(o);
                    
                    // Extract customor_id (the typo field name in order collection)
                    final customorId = (o['customor_id'] ?? o['customer_id'] ?? o['customerId'])?.toString() ?? '';
                    debugPrint('✓ Order $key -> customor_id=$customorId');
                    
                    if (customorId.isNotEmpty) {
                      customerIds.add(customorId);
                    } else {
                      debugPrint('✗ Order $key has NO customor_id!');
                    }
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('✗ Orders batch error: $e');
          }
        }
      }
      
      debugPrint('Extracted ${customerIds.length} unique customor_ids: $customerIds');

      debugPrint('✓ Loaded ${orderMap.length} orders, ${customerIds.length} customer_ids: $customerIds');

      // 3) Fetch customers in batches via REST (collection name 'customer' expected)
      final customerMap = <String, Map<String, dynamic>>{};
      if (customerIds.isNotEmpty) {
        final ids = customerIds.toList();
        const batchSize = 50;
        for (var i = 0; i < ids.length; i += batchSize) {
          final batch = ids.sublist(i, (i + batchSize) > ids.length ? ids.length : i + batchSize);
          try {
            debugPrint('Fetching customers: $batch');
            final resp = await _api.selectWhereIn(token, project, 'customer', appid, 'customer_id', batch.join(','));
            debugPrint('Response: ${resp.runtimeType}');
            if (resp != null) {
              final raw = (resp is String) ? jsonDecode(resp) : resp;
              List<dynamic> custList = [];
              if (raw is List) custList = raw;
              else if (raw is Map && raw['data'] is List) custList = raw['data'];
              debugPrint('✓ Parsed ${custList.length} customers');
              for (final c in custList) {
                if (c is Map) {
                  final key = c['customer_id']?.toString() ?? c['id']?.toString() ?? '';
                  if (key.isNotEmpty) {
                    customerMap[key] = Map<String, dynamic>.from(c);
                    debugPrint('Customer $key: nama_toko=${c['nama_toko']}, no_telepon=${c['no_telepon_customer']}');
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('✗ fetch customers batch error: $e');
          }
        }

        // If still empty, try fetching each customer individually with selectWhere
        if (customerMap.isEmpty && customerIds.isNotEmpty) {
          debugPrint('Batch empty, trying selectWhere for each customer...');
          for (final custId in customerIds) {
            try {
              debugPrint('selectWhere customer: $custId');
              final resp = await _api.selectWhere(token, project, 'customer', appid, 'customer_id', custId);
              debugPrint('Response: ${resp.runtimeType}');
              if (resp != null) {
                final raw = (resp is String) ? jsonDecode(resp) : resp;
                List<dynamic> custList = [];
                if (raw is List) custList = raw;
                else if (raw is Map && raw['data'] is List) custList = raw['data'];
                debugPrint('✓ Parsed ${custList.length} records');
                for (final c in custList) {
                  if (c is Map) {
                    final key = c['customer_id']?.toString() ?? c['id']?.toString() ?? '';
                    if (key.isNotEmpty) {
                      customerMap[key] = Map<String, dynamic>.from(c);
                      debugPrint('✓ Loaded customer $key: nama_toko=${c['nama_toko']}');
                    }
                  }
                }
              }
            } catch (e) {
              debugPrint('✗ selectWhere error for $custId: $e');
            }
          }
        }
      }

      debugPrint('✓ Loaded ${customerMap.length} customers');
      if (customerMap.isNotEmpty) {
        final firstCust = customerMap.values.first;
        debugPrint('Sample keys: ${firstCust.keys.toList()}');
      }

      // 4) Assemble report per order
      final Map<String, List<Map<String, dynamic>>> itemsByOrder = {};
      for (final raw in orderItemsList) {
        if (raw is! Map) continue;
        final oid = (raw['order_id'] ?? raw['orderId'] ?? raw['order'])?.toString() ?? '';
        if (oid.isEmpty) continue;
        final item = <String, dynamic>{
          'id_produk': raw['product_id'] ?? raw['productId'] ?? raw['id_produk'] ?? raw['product'] ?? '',
          'nama_barang': raw['product_name'] ?? raw['nama'] ?? raw['nama_barang'] ?? raw['productName'] ?? '',
          'list_barcode': raw['list_barcode'] ?? raw['listBarcode'] ?? raw['barcodes'] ?? [],
        };
        itemsByOrder.putIfAbsent(oid, () => []).add(item);
      }

      final results = <Map<String, dynamic>>[];
      for (final oid in orderIds) {
        final orderData = orderMap[oid] ?? {};
        final custId = (orderData['customer_id'])?.toString() ?? '';
        final cust = customerMap[custId] ?? {};

        debugPrint('fetchDeliveryOrderReport: order_id=$oid, customer_id=$custId, cust_data=${cust.isEmpty ? 'EMPTY' : 'found ${cust.keys.length} fields'}');

        final row = <String, dynamic>{
          'order_id': oid,
          'id_staff': orderData['id_staff'] ?? orderData['staff_id'] ?? orderData['user_id'] ?? '',
          'customer_id': custId,
          'nama_toko': cust['nama_toko'] ?? cust['store_name'] ?? cust['toko'] ?? cust['shop_name'] ?? cust['store'] ?? '',
          'nama_pemilik_toko': cust['nama_pemilik_toko'] ?? cust['owner_name'] ?? cust['pemilik'] ?? cust['pemilik_toko'] ?? cust['owner'] ?? '',
          'no_telepon_customer': cust['no_telepon'] ?? cust['phone'] ?? cust['telepon'] ?? cust['phone_number'] ?? cust['no_hp'] ?? cust['nomor_telepon'] ?? '',
          'alamat_toko': cust['alamat'] ?? cust['address'] ?? cust['alamat_toko'] ?? cust['alamat_lengkap'] ?? '',
          'tanggal_order': orderData['tanggal_order'] ?? orderData['order_date'] ?? orderData['created_at'] ?? orderData['date'] ?? '',
          'total_harga': orderData['total'] ?? orderData['total_price'] ?? orderData['grand_total'] ?? 0,
          'items': itemsByOrder[oid] ?? [],
        };

        results.add(row);
      }

      debugPrint('fetchDeliveryOrderReport: assembled ${results.length} final orders');
      return {
        'type': 'Laporan Order Pengiriman',
        'timestamp': DateTime.now(),
        'data': results,
        'columns': ['order_id','id_staff','customer_id','nama_toko','nama_pemilik_toko','no_telepon_customer','alamat_toko','tanggal_order','total_harga','items']
      };
    } catch (e) {
      debugPrint('Error fetching delivery order report: $e');
      return {'type': 'Error', 'data': [], 'error': e.toString()};
    }
  }

  /// Laporan keseluruhan staff
  Future<Map<String, dynamic>> fetchStaffReport(String ownerId) async {
    try {
      // Firebase Firestore staff collection
      final staffSnap = await _fs.collection('staff').get();
      final allStaff = staffSnap.docs.map((doc) {
        return {...doc.data(), 'id': doc.id};
      }).toList();

      // Filter by owner
      final ownerStaff = allStaff.where((s) {
        final owner = (s['ownerid'] ?? s['owner_id'] ?? s['ownerId'] ?? '').toString();
        return owner == ownerId;
      }).toList();

      return {
        'type': 'Laporan Keseluruhan Staff',
        'timestamp': DateTime.now(),
        'data': ownerStaff,
        'columns': ['Nama', 'Email', 'Posisi', 'Telepon', 'Tanggal Bergabung', 'Status']
      };
    } catch (e) {
      debugPrint('Error fetching staff report: $e');
      return {'type': 'Error', 'data': [], 'error': e.toString()};
    }
  }

  /// Laporan keseluruhan suppliers
  Future<Map<String, dynamic>> fetchSuppliersReport(String ownerId) async {
    try {
      final suppliersRes = await _api.selectAll(token, project, 'supplier', appid);
      final suppliers = _safeParseList(suppliersRes);

      // Filter by owner
      final ownerSuppliers = suppliers.where((s) {
        final owner = (s['ownerid'] ?? s['owner_id'] ?? s['ownerId'] ?? '').toString();
        return owner == ownerId;
      }).toList();

      return {
        'type': 'Laporan Keseluruhan Suppliers',
        'timestamp': DateTime.now(),
        'data': ownerSuppliers,
        'columns': ['Nama Supplier', 'Alamat', 'Telepon', 'Email', 'Kontak Person', 'Kategori Barang']
      };
    } catch (e) {
      debugPrint('Error fetching suppliers report: $e');
      return {'type': 'Error', 'data': [], 'error': e.toString()};
    }
  }

  /// Laporan transaksi
  Future<Map<String, dynamic>> fetchTransactionsReport(String ownerId) async {
    try {
      final transRes = await _api.selectAll(token, project, 'order', appid);
      final transactions = _safeParseList(transRes);

      // Filter by owner
      final ownerTransactions = transactions.where((t) {
        final owner = (t['ownerid'] ?? t['owner_id'] ?? t['ownerId'] ?? '').toString();
        return owner == ownerId;
      }).toList();

      return {
        'type': 'Laporan Transaksi',
        'timestamp': DateTime.now(),
        'data': ownerTransactions,
        'columns': ['No Transaksi', 'Tanggal', 'Customer', 'Total', 'Metode Pembayaran', 'Status']
      };
    } catch (e) {
      debugPrint('Error fetching transactions report: $e');
      return {'type': 'Error', 'data': [], 'error': e.toString()};
    }
  }

  /// Laporan barang keluar
  Future<Map<String, dynamic>> fetchOutgoingItemsReport(String ownerId) async {
    try {
      final itemsRes = await _api.selectAll(token, project, 'order_items', appid);
      final items = _safeParseList(itemsRes);

      // Filter by owner
      final ownerItems = items.where((item) {
        final owner = (item['ownerid'] ?? item['owner_id'] ?? item['ownerId'] ?? '').toString();
        return owner == ownerId;
      }).toList();

      return {
        'type': 'Laporan Barang Keluar',
        'timestamp': DateTime.now(),
        'data': ownerItems,
        'columns': ['ID Produk', 'Nama Produk', 'Jumlah', 'Tanggal Keluar', 'Tujuan', 'Status']
      };
    } catch (e) {
      debugPrint('Error fetching outgoing items report: $e');
      return {'type': 'Error', 'data': [], 'error': e.toString()};
    }
  }

  /// Laporan barang masuk
  Future<Map<String, dynamic>> fetchIncomingItemsReport(String ownerId) async {
    try {
      // Ambil dari product_barcodes Firebase
      final barcodeSnap = await _fs.collection('product_barcodes').get();
      final allBarcodes = barcodeSnap.docs.map((doc) {
        return {...doc.data(), 'id': doc.id};
      }).toList();

      // Filter by owner
      final ownerBarcodes = allBarcodes.where((b) {
        final owner = (b['ownerid'] ?? b['owner_id'] ?? b['ownerId'] ?? b['owner'] ?? '').toString();
        return owner == ownerId;
      }).toList();

      return {
        'type': 'Laporan Barang Masuk',
        'timestamp': DateTime.now(),
        'data': ownerBarcodes,
        'columns': ['Barcode', 'ID Produk', 'Nama Produk', 'Jumlah', 'Tanggal Masuk', 'Supplier']
      };
    } catch (e) {
      debugPrint('Error fetching incoming items report: $e');
      return {'type': 'Error', 'data': [], 'error': e.toString()};
    }
  }

  /// Export ke CSV
  Future<String> exportToCSV(Map<String, dynamic> reportData) async {
    try {
      final List<List<dynamic>> csvData = [];
      
      // Add header
      csvData.add(reportData['columns'] ?? []);
      
      // Add data rows
      final data = reportData['data'] ?? [];
      for (var item in data) {
        if (item is Map) {
          final columns = reportData['columns'] ?? [];
          // Cast item to Map<String, dynamic> for proper typing
          // ignore: unnecessary_cast
          final itemMap = Map<String, dynamic>.from(item as Map);
          final row = columns.map((col) => _mapColumnToValue(col, itemMap)).toList();
          csvData.add(row);
        }
      }

      // Convert to CSV string
      final csvText = _convertToCsv(csvData);
      final String fileName = 'laporan_${reportData['type']?.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.csv';
      return await ExportService.saveText(fileName, csvText, mimeType: 'text/csv');
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      return '';
    }
  }

  /// Export ke JSON
  Future<String> exportToJSON(Map<String, dynamic> reportData) async {
    try {
      final jsonData = {
        'type': reportData['type'],
        'timestamp': reportData['timestamp'],
        'totalRecords': (reportData['data'] as List).length,
        'data': reportData['data']
      };

      final String json = jsonEncode(jsonData);
      final String fileName = 'laporan_${reportData['type']?.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.json';
      return await ExportService.saveText(fileName, json, mimeType: 'application/json');
    } catch (e) {
      debugPrint('Error exporting to JSON: $e');
      return '';
    }
  }

  /// Helper: Map column name ke value dari item
  dynamic _mapColumnToValue(String columnName, Map<String, dynamic> item) {
    // Map user-friendly column names ke actual field names
    final Map<String, List<String>> columnMapping = {
      'ID': ['id', '_id', 'product_id', 'id_product'],
      'Nama Produk': ['nama_produk', 'name', 'product_name'],
      'Kategori': ['category', 'kategori', 'tipe'],
      'Harga': ['harga_product', 'harga', 'price', 'price_unit'],
      'Stok': ['stok', 'qty', 'jumlah', 'stock', 'quantity'],
      'Satuan': ['satuan', 'unit'],
      'Tanggal Kadaluarsa': ['tanggal_kadaluarsa', 'exp_date', 'expiry_date'],
      'No Order': ['id', 'order_id', 'order_no'],
      'Tgl Order': ['tanggal_order', 'order_date', 'created_at'],
      'Customer': ['customer', 'customer_id', 'customer_name'],
      'Status': ['status', 'order_status'],
      'Total': ['total', 'total_price', 'grand_total'],
      'Alamat Pengiriman': ['alamat', 'address', 'shipping_address'],
      'Email': ['email'],
      'Posisi': ['position', 'posisi', 'role'],
      'Telepon': ['phone', 'telepon', 'no_hp'],
      'Tanggal Bergabung': ['join_date', 'created_at'],
      'Kontak Person': ['contact_person', 'kontak'],
      'Kategori Barang': ['kategori_barang', 'product_category'],
      'Metode Pembayaran': ['payment_method', 'metode_pembayaran'],
      'Jumlah': ['jumlah', 'qty', 'quantity'],
      'Tanggal Keluar': ['tanggal_order_items', 'tanggal_out', 'out_date'],
      'Tujuan': ['destination', 'tujuan'],
      'Tanggal Masuk': ['scannedAt', 'created_at', 'in_date'],
      'Supplier': ['supplier', 'supplier_name'],
      'Barcode': ['barcode', 'code'],
    };

    final candidates = columnMapping[columnName] ?? [columnName.toLowerCase()];
    
    for (var candidate in candidates) {
      if (item.containsKey(candidate)) {
        return item[candidate];
      }
    }
    
    return '';
  }

  /// Helper: Convert list to CSV
  String _convertToCsv(List<List<dynamic>> data) {
    final StringBuffer sb = StringBuffer();
    for (var i = 0; i < data.length; i++) {
      final row = data[i];
      for (var j = 0; j < row.length; j++) {
        final cell = row[j]?.toString() ?? '';
        // Escape quotes and wrap if contains comma
        final escaped = cell.replaceAll('"', '""');
        if (escaped.contains(',') || escaped.contains('\n') || escaped.contains('"')) {
          sb.write('"$escaped"');
        } else {
          sb.write(escaped);
        }
        if (j < row.length - 1) sb.write(',');
      }
      if (i < data.length - 1) sb.write('\n');
    }
    return sb.toString();
  }

  /// Helper: Save file ke local storage
  // File saving is handled by `ExportService` (uses conditional imports).

  /// Export to PDF
  Future<String> exportToPDF(Map<String, dynamic> reportData) async {
    try {
      final doc = pw.Document();

      final columns = List<String>.from(reportData['columns'] ?? []);
      final data = List<dynamic>.from(reportData['data'] ?? []);

      final headers = columns.map((c) => c.toString()).toList();
      final rows = <List<String>>[];
      for (final item in data) {
        if (item is Map) {
          final row = columns.map((col) => '${_mapColumnToValue(col, Map<String, dynamic>.from(item))}').toList();
          rows.add(row);
        }
      }

      doc.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context ctx) => pw.Table.fromTextArray(
            context: ctx,
            data: <List<String>>[headers, ...rows],
          ),
        ),
      );

      final bytes = await doc.save();
      final fileName = 'laporan_${reportData['type']?.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.pdf';
      return await ExportService.saveBytes(fileName, bytes, mimeType: 'application/pdf');
    } catch (e) {
      debugPrint('Error exporting to PDF: $e');
      return '';
    }
  }

  /// Export to XLSX
  Future<String> exportToXLSX(Map<String, dynamic> reportData) async {
    try {
      // Use excel package to build workbook
      final ex = Excel.createExcel();
      final sheet = ex[ex.getDefaultSheet() ?? 'Sheet1'];

      final columns = List<String>.from(reportData['columns'] ?? []);
      // header
      sheet.appendRow(columns);

      final data = List<dynamic>.from(reportData['data'] ?? []);
      for (final item in data) {
        if (item is Map) {
          final row = columns.map((col) => _mapColumnToValue(col, Map<String, dynamic>.from(item)).toString()).toList();
          sheet.appendRow(row);
        }
      }

      final encoded = ex.encode();
      if (encoded == null) return '';
      final bytes = Uint8List.fromList(encoded);
      final fileName = 'laporan_${reportData['type']?.replaceAll(' ', '_')}_${DateTime.now().millisecondsSinceEpoch}.xlsx';
      return await ExportService.saveBytes(fileName, bytes, mimeType: 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet');
    } catch (e) {
      debugPrint('Error exporting to XLSX: $e');
      return '';
    }
  }

  /// Helper: Parse list safely dari response
  List<dynamic> _safeParseList(dynamic raw) {
    try {
      if (raw == null) return [];
      if (raw is String) {
        if (raw.isEmpty || raw == '[]') return [];
        final d = jsonDecode(raw);
        if (d is Map && d.containsKey('data')) return d['data'] as List? ?? [];
        if (d is List) return d;
        return [];
      }
      if (raw is Map && raw.containsKey('data')) return raw['data'] as List? ?? [];
      if (raw is List) return raw;
      return [];
    } catch (e) {
      debugPrint('Error parsing list: $e');
      return [];
    }
  }

  /// Helper: Share file
  Future<void> shareFile(String filePath) async {
    try {
      if (filePath.isNotEmpty) {
        // For now, just show a snackbar with the file path
        debugPrint('File ready to share: $filePath');
      }
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }
}

extension on String {
  // ignore: body_might_complete_normally_nullable
  DateTime? toDate() {}
}