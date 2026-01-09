// ignore: unused_import
import 'dart:convert';
import 'package:flutter/material.dart';
// removed http dependency since functionsBaseUrl not used
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
// ignore: unused_import
import 'package:kgbox/screens/catat_barang_keluar_screen.dart';
// ignore: unused_import
import '../pages/dashboard_owner_page.dart';
import '../pages/list_product_page.dart';
import '../pages/pengiriman_page.dart';
import 'logout_screen.dart';
import '../services/restapi.dart';
import '../services/config.dart';
import 'package:kgbox/providers/auth_provider.dart';
import 'package:provider/provider.dart';

class DashboardOwnerController {
  // Data management
  final List<Map<String, dynamic>> _monthlyProductFlow = [
    {'month': 'Jan', 'in': 245, 'out': 189},
    {'month': 'Feb', 'in': 220, 'out': 175},
    {'month': 'Mar', 'in': 280, 'out': 195},
    {'month': 'Apr', 'in': 260, 'out': 210},
    {'month': 'Mei', 'in': 300, 'out': 230},
    {'month': 'Jun', 'in': 320, 'out': 250},
  ];

  final List<Map<String, dynamic>> _monthlyTransactions = [
    {'month': 'Jan', 'transactions': 1250, 'color': const Color(0xFF3B82F6)},
    {'month': 'Feb', 'transactions': 1380, 'color': const Color(0xFFEF4444)},
    {'month': 'Mar', 'transactions': 1450, 'color': const Color(0xFF10B981)},
    {'month': 'Apr', 'transactions': 1520, 'color': const Color(0xFFF59E0B)},
    {'month': 'Mei', 'transactions': 1600, 'color': const Color(0xFF8B5CF6)},
    {'month': 'Jun', 'transactions': 1680, 'color': const Color(0xFFEC4899)},
    {'month': 'Jul', 'transactions': 1350, 'color': const Color(0xFF14B8A6)},
    {'month': 'Agu', 'transactions': 1420, 'color': const Color(0xFFF97316)},
    {'month': 'Sep', 'transactions': 1700, 'color': const Color(0xFF6366F1)},
    {'month': 'Okt', 'transactions': 1750, 'color': const Color(0xFF84CC16)},
    {'month': 'Nov', 'transactions': 1480, 'color': const Color(0xFF06B6D4)},
    {'month': 'Des', 'transactions': 1750, 'color': const Color(0xFF8B5CF6)},
  ];

  static const int _maxTransactions = 2000;

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
    return _monthlyProductFlow.map((e) => e['in'] as int).reduce((a, b) => a + b);
  }

  int get totalProductOut {
    return _monthlyProductFlow.map((e) => e['out'] as int).reduce((a, b) => a + b);
  }

  int get remainingStock {
    return totalProductIn - totalProductOut;
  }

  int get totalTransactions {
    return _monthlyTransactions.map((e) => e['transactions'] as int).reduce((a, b) => a + b);
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
    final months = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - (11 - i), 1);
      return DateTime(dt.year, dt.month);
    });

    // initialize output with month labels and zero counts
    final monthNames = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    final colors = _monthlyTransactions.map((e) => e['color'] as Color).toList();
    final out = List<Map<String, dynamic>>.generate(12, (i) => {
      'month': monthNames[i],
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifikasi belum diimplementasikan')),
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
  Future<Map<String, List<double>>> fetchMonthlyTotals(String ownerId) async {
    final inTotals = List<double>.filled(12, 0);
    final outTotals = List<double>.filled(12, 0);
    
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 11, 1);
    final months = List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - (11 - i), 1);
      return DateTime(dt.year, dt.month);
    });

    // 1. Product barcodes (incoming) - per owner
    try {
      final startTs = Timestamp.fromDate(start);
      QuerySnapshot<Map<String, dynamic>>? pbSnap;
      
      // Try with owner field variants
      final ownerFields = ['ownerid', 'ownerId', 'owner', 'owner_id'];
      Exception? lastError;
      
      for (final ownerField in ownerFields) {
        try {
          pbSnap = await _fs.collection('product_barcodes')
            .where(ownerField, isEqualTo: ownerId)
            .where('scannedAt', isGreaterThanOrEqualTo: startTs)
            .get();
          debugPrint('fetchMonthlyTotals: Successfully queried product_barcodes with ownerField=$ownerField');
          break;
        } catch (e) {
          lastError = e as Exception;
          debugPrint('fetchMonthlyTotals: Failed with ownerField=$ownerField: $e');
          pbSnap = null;
        }
      }
      
      // If owner field filtering fails, try to get all and filter by productId
      if (pbSnap == null || pbSnap!.docs.isEmpty) {
        debugPrint('fetchMonthlyTotals: Falling back to productId-based filtering');
        try {
          // Get products for this owner
          final prods = await _fs.collection('products')
            .where('ownerid', isEqualTo: ownerId)
            .get();
          
          if (prods.docs.isEmpty) {
            // Try alternate field names for products
            final alternateProducts = await _fs.collection('products')
              .where('ownerId', isEqualTo: ownerId)
              .get();
            
            final productIds = alternateProducts.docs
              .map((d) => d['id'] ?? d['product_id'] ?? d.id)
              .whereType<String>()
              .toList();
            
            if (productIds.isNotEmpty && productIds.length <= 10) {
              pbSnap = await _fs.collection('product_barcodes')
                .where('productId', whereIn: productIds)
                .get();
            } else if (productIds.isNotEmpty) {
              // For large lists, fetch all and filter in memory
              final allBarcodes = await _fs.collection('product_barcodes').get();
              final filteredDocs = allBarcodes.docs.where((d) => 
                productIds.contains(d['productId']) || 
                productIds.contains(d['product_id'])
              ).toList();
              
              for (final doc in filteredDocs) {
                final data = doc.data();
                DateTime? dt;
                if (data['scannedAt'] is Timestamp) dt = (data['scannedAt'] as Timestamp).toDate();
                else if (data['scannedAt'] is String) {
                  try { dt = DateTime.parse(data['scannedAt']); } catch (_) {}
                }
                if (dt == null || dt.isBefore(start)) continue;

                final idx = months.indexWhere((m) => m.year == dt?.year && m.month == dt?.month);
                if (idx >= 0) inTotals[idx] = inTotals[idx] + 1.0;
              }
              pbSnap = null;
            }
          } else {
            final productIds = prods.docs
              .map((d) => d['id'] ?? d['product_id'] ?? d.id)
              .whereType<String>()
              .toList();
            
            if (productIds.isNotEmpty && productIds.length <= 10) {
              pbSnap = await _fs.collection('product_barcodes')
                .where('productId', whereIn: productIds)
                .get();
            } else if (productIds.isNotEmpty) {
              // For large lists, fetch all and filter in memory
              final allBarcodes = await _fs.collection('product_barcodes').get();
              final filteredDocs = allBarcodes.docs.where((d) => 
                productIds.contains(d['productId']) || 
                productIds.contains(d['product_id'])
              ).toList();
              
              for (final doc in filteredDocs) {
                final data = doc.data();
                DateTime? dt;
                if (data['scannedAt'] is Timestamp) dt = (data['scannedAt'] as Timestamp).toDate();
                else if (data['scannedAt'] is String) {
                  try { dt = DateTime.parse(data['scannedAt']); } catch (_) {}
                }
                if (dt == null || dt.isBefore(start)) continue;

                final idx = months.indexWhere((m) => m.year == dt?.year && m.month == dt?.month);
                if (idx >= 0) inTotals[idx] = inTotals[idx] + 1.0;
              }
              pbSnap = null;
            }
          }
        } catch (e) {
          debugPrint('fetchMonthlyTotals: productId-based fallback error: $e');
        }
      }

      // ignore: unnecessary_null_comparison
      if (pbSnap != null) {
        for (final doc in pbSnap.docs) {
          final data = doc.data();
          DateTime? dt;
          if (data['scannedAt'] is Timestamp) dt = (data['scannedAt'] as Timestamp).toDate();
          else if (data['scannedAt'] is String) {
            try { dt = DateTime.parse(data['scannedAt']); } catch (_) {}
          }
          if (dt == null || dt.isBefore(start)) continue;

          final idx = months.indexWhere((m) => m.year == dt?.year && m.month == dt?.month);
          if (idx >= 0) inTotals[idx] = inTotals[idx] + 1.0;
        }
      }
    } catch (e) {
      debugPrint('fetchMonthlyTotals: product_barcodes error: $e');
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
}

extension on String {
  // ignore: body_might_complete_normally_nullable
  DateTime? toDate() {}
}