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

      // 2. BARANG MASUK: tetap dari product_barcodes dalam 7 hari terakhir
      final now = DateTime.now();
      final lastWeek = now.subtract(const Duration(days: 7));
      int masukCount = 0;
      try {
        Query masukQuery = _fs.collection('product_barcodes');
        if (ownerId.isNotEmpty) {
          // Coba kedua variasi field name
          try {
            masukQuery = masukQuery.where('ownerId', isEqualTo: ownerId);
          } catch (_) {
            try {
              masukQuery = masukQuery.where('ownerid', isEqualTo: ownerId);
            } catch (_) {}
          }
        }
        masukQuery = masukQuery.where('scannedAt', isGreaterThanOrEqualTo: Timestamp.fromDate(lastWeek));
        try {
          final agg = masukQuery.count();
          final aggSnap = await agg.get();
          masukCount = aggSnap.count ?? 0;
        } catch (_) {
          final masukSnap = await masukQuery.get();
          masukCount = masukSnap.docs.length;
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