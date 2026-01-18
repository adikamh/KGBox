import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import '../services/export_service.dart';
import 'dart:typed_data';
import 'package:KGbox/services/restapi.dart';
import 'package:KGbox/services/config.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Advanced export service untuk berbagai jenis laporan dan format
class AdvancedExportService {
  static final DataService _api = DataService();
  static final FirebaseFirestore _fs = FirebaseFirestore.instance;

  /// Laporan keseluruhan produk tersedia
  static Future<Map<String, dynamic>> fetchAvailableProductsReport(String ownerId) async {
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
  static Future<Map<String, dynamic>> fetchExpiredProductsReport(String ownerId) async {
    try {
      final productsRes = await _api.selectAll(token, project, 'product', appid);
      final products = _safeParseList(productsRes);
      final now = DateTime.now();

      // Filter by owner and expired
      final expiredProducts = products.where((p) {
        final owner = (p['ownerid'] ?? p['owner_id'] ?? p['ownerId'] ?? '').toString();
        final expireDate = p['tanggal_kadaluarsa'] ?? p['exp_date'] ?? p['expiry_date'];
        
        if (owner != ownerId) return false;
        if (expireDate == null) return false;

        try {
          final parsedDate = DateTime.parse(expireDate.toString());
          return parsedDate.isBefore(now);
        } catch (_) {
          return false;
        }
      }).toList();

      return {
        'type': 'Laporan Keseluruhan Produk Kadaluarsa',
        'timestamp': DateTime.now(),
        'data': expiredProducts,
        'columns': ['ID', 'Nama Produk', 'Tanggal Kadaluarsa', 'Stok', 'Kategori']
      };
    } catch (e) {
      debugPrint('Error fetching expired products report: $e');
      return {'type': 'Error', 'data': [], 'error': e.toString()};
    }
  }

  /// Laporan order pengiriman
  static Future<Map<String, dynamic>> fetchDeliveryOrderReport(String ownerId) async {
    try {
      final ordersRes = await _api.selectAll(token, project, 'order', appid);
      final orders = _safeParseList(ordersRes);

      // Filter by owner
      final ownerOrders = orders.where((o) {
        final owner = (o['ownerid'] ?? o['owner_id'] ?? o['ownerId'] ?? '').toString();
        return owner == ownerId;
      }).toList();

      return {
        'type': 'Laporan Order Pengiriman',
        'timestamp': DateTime.now(),
        'data': ownerOrders,
        'columns': ['No Order', 'Tgl Order', 'Customer', 'Status', 'Total', 'Alamat Pengiriman']
      };
    } catch (e) {
      debugPrint('Error fetching delivery order report: $e');
      return {'type': 'Error', 'data': [], 'error': e.toString()};
    }
  }

  /// Laporan keseluruhan staff
  static Future<Map<String, dynamic>> fetchStaffReport(String ownerId) async {
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
  static Future<Map<String, dynamic>> fetchSuppliersReport(String ownerId) async {
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
  static Future<Map<String, dynamic>> fetchTransactionsReport(String ownerId) async {
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
  static Future<Map<String, dynamic>> fetchOutgoingItemsReport(String ownerId) async {
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
  static Future<Map<String, dynamic>> fetchIncomingItemsReport(String ownerId) async {
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
  static Future<String> exportToCSV(Map<String, dynamic> reportData) async {
    try {
      final List<List<dynamic>> csvData = [];
      
      // Add header
      csvData.add(reportData['columns'] ?? []);
      
      // Add data rows
      final data = reportData['data'] ?? [];
      for (var item in data) {
        if (item is Map) {
          final columns = reportData['columns'] ?? [];
          final row = columns.map((col) => _mapColumnToValue(col, item as Map<String, dynamic>)).toList();
          csvData.add(row);
        }
      }

      final String csv = const ListToCsvConverter().convert(csvData);
      final String fileName = '${reportData['type']}_${DateTime.now().millisecondsSinceEpoch}.csv';
      return await ExportService.saveText(fileName, csv, mimeType: 'text/csv');
    } catch (e) {
      debugPrint('Error exporting to CSV: $e');
      return '';
    }
  }

  /// Export ke format lainnya (placeholder untuk integrasi dengan package)
  static Future<String> exportToJSON(Map<String, dynamic> reportData) async {
    try {
      final jsonData = {
        'type': reportData['type'],
        'timestamp': reportData['timestamp'],
        'totalRecords': (reportData['data'] as List).length,
        'data': reportData['data']
      };

      final String json = jsonEncode(jsonData);
      final String fileName = '${reportData['type']}_${DateTime.now().millisecondsSinceEpoch}.json';
      return await ExportService.saveText(fileName, json, mimeType: 'application/json');
    } catch (e) {
      debugPrint('Error exporting to JSON: $e');
      return '';
    }
  }

  /// Helper: Map column name ke value dari item
  static dynamic _mapColumnToValue(String columnName, Map<String, dynamic> item) {
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
      'Supplier': ['supplier', 'supplier_name']
    };

    final candidates = columnMapping[columnName] ?? [columnName.toLowerCase()];
    
    for (var candidate in candidates) {
      if (item.containsKey(candidate)) {
        return item[candidate];
      }
    }
    
    return '';
  }

  /// Helper: Save file ke local storage
  static Future<String> _saveFile(String fileName, String content) async {
    try {
      return await ExportService.saveText(fileName, content, mimeType: 'text/plain');
    } catch (e) {
      debugPrint('Error saving file: $e');
      return '';
    }
  }

  /// Helper: Parse list safely dari response
  static List<dynamic> _safeParseList(dynamic raw) {
    try {
      if (raw == null) return [];
      if (raw is String) {
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

  /// Share file
  static Future<void> shareFile(String filePath) async {
    try {
      await Share.shareXFiles([XFile(filePath)]);
    } catch (e) {
      debugPrint('Error sharing file: $e');
    }
  }
}
