// lib/screens/detail_product_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';
import '../pages/edit_product_page.dart';

class DetailProductScreen {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Product data
  late Map<String, dynamic> product;
  
  // Initialize with product data
  void initialize(Map<String, dynamic> productData) {
    product = productData;
  }
  
  // Get formatted product values
  Map<String, dynamic> getFormattedProduct() {
    // Normalize and extract fields from different possible product shapes
    final code = product['id'] ?? product['productId'] ?? product['id_product'] ?? '';
    final name = product['name'] ?? product['nama'] ?? product['nama_product'] ?? '-';
    final category = product['category'] ?? product['kategori'] ?? product['kategori_product'] ?? '-';
    final brand = product['brand'] ?? product['merek'] ?? product['merek_product'] ?? '-';

    // price may be stored under different keys and types
    final dynamic rawPrice = product['sellingPrice'] ?? product['price'] ?? product['harga_product'];

    // purchase/created date
    final dynamic rawPurchase = product['createdAt'] ?? product['productionDate'] ?? product['tanggal_beli'] ?? product['purchaseDate'];

    final dynamic rawProductDate = product['productionDate'] ?? product['tanggal_beli'] ?? product['createdAt'] ?? product['productionDate'];

    // expired date
    final dynamic rawExpired = product['expiredDate'] ?? product['tanggal_expired'] ?? product['expired'];

    // stock if present, otherwise unknown (UI will rely on barcode count)
    final stockVal = product['stock'] ?? product['jumlah_produk'] ?? 0;

    return {
      'code': code.toString(),
      'name': name.toString(),
      'category': category.toString(),
      'brand': brand.toString(),
      'priceRaw': rawPrice,
      'price': formatPrice(rawPrice),
      'stock': stockVal?.toString() ?? '0',
      'purchaseRaw': rawPurchase,
      'purchaseDate': _formatDate(rawPurchase),
      'productDate': _formatDate(rawProductDate),
      // alias used by UI
      'productionDate': _formatDate(rawProductDate),
      'expiredRaw': rawExpired,
      'expiredText': _computeExpiredText(rawExpired),
    };
  }

  // Safe int parser helper
  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  List<Map<String, dynamic>> getItemUnits() {
    if (product.containsKey('items') && product['items'] is List) {
      return (product['items'] as List).cast<Map<String, dynamic>>();
    }
    return [product.cast<String, dynamic>()];
  }
  
  // Format price
  String formatPrice(dynamic price) {
    if (price == null) return '-';
    int value = 0;
    if (price is int) value = price;
    else if (price is double) value = price.round();
    else if (price is String) value = int.tryParse(price) ?? 0;
    else if (price is num) value = price.toInt();

    final formatted = value.toString().replaceAllMapped(
      RegExp(r"\B(?=(\d{3})+(?!\d))"),
      (m) => '.',
    );
    return 'Rp $formatted';
  }

  // Parse various date shapes (Timestamp, String, DateTime)
  DateTime? _parseDate(dynamic v) {
    if (v == null) return null;
    try {
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) {
        final s = v.trim();
        if (RegExp(r"^\d{4}-\d{2}-\d{2}").hasMatch(s)) {
          return DateTime.parse(s);
        }
        return DateTime.tryParse(s);
      }
    } catch (_) {}
    return null;
  }

  String _formatDate(dynamic raw) {
    final dt = _parseDate(raw);
    if (dt == null) return '-';
    final d = dt.toLocal();
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    final day = d.day.toString().padLeft(2, '0');
    final month = months[d.month - 1];
    final year = d.year.toString();
    return '$day $month $year';
  }

  String _computeExpiredText(dynamic rawExpired) {
    final dt = _parseDate(rawExpired);
    if (dt == null) return '-';
    final now = DateTime.now();
    final end = DateTime(dt.year, dt.month, dt.day);
    final diff = end.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff < 0) return 'Sudah expired';
    if (diff == 0) return 'Expired hari ini';
    if (diff <= 14) {
      if (diff % 7 == 0) {
        final weeks = (diff / 7).round();
        return 'Expired dalam $weeks minggu';
      }
      return 'Expired dalam $diff hari';
    }
    return _formatDate(rawExpired);
  }
  
  // Get icon based on category
  IconData getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('minuman')) {
      return Icons.local_drink_rounded;
    } else if (cat.contains('makanan') || cat.contains('food')) {
      return Icons.restaurant_rounded;
    } else if (cat.contains('elektronik')) {
      return Icons.electrical_services_rounded;
    } else if (cat.contains('pakaian')) {
      return Icons.checkroom_rounded;
    } else {
      return Icons.inventory_2_rounded;
    }
  }
  
  // Get icon color based on category
  Color getCategoryColor(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('minuman')) {
      return Colors.blue;
    } else if (cat.contains('makanan')) {
      return Colors.green;
    } else if (cat.contains('elektronik')) {
      return Colors.purple;
    } else {
      return Colors.orange;
    }
  }
  
  // Check if product is expired
  bool isProductExpired() {
    final raw = product['expiredDate'] ?? product['tanggal_expired'] ?? product['expired'] ?? product['expiredRaw'];
    final dt = _parseDate(raw);
    if (dt == null) return false;
    final now = DateTime.now();
    return DateTime(dt.year, dt.month, dt.day).isBefore(DateTime(now.year, now.month, now.day));
  }
  
  // Check if stock is low (less than 10)
  bool isStockLow() {
    final stock = product['jumlah_produk'];
    if (stock == null) return false;
    
    final stockValue = int.tryParse(stock.toString()) ?? 0;
    return stockValue < 10;
  }
  
  // Get stock status
  String getStockStatus() {
    if (isStockLow()) {
      return 'Stok Rendah';
    }
    return 'Stok Aman';
  }
  
  // Get stock status color
  Color getStockStatusColor() {
    if (isStockLow()) {
      return Colors.orange;
    }
    return Colors.green;
  }
  
  // Get expired status
  String getExpiredStatus() {
    if (isProductExpired()) {
      return 'Sudah Expired';
    }
    return 'Belum Expired';
  }
  
  // Get expired status color
  Color getExpiredStatusColor() {
    if (isProductExpired()) {
      return Colors.red;
    }
    return Colors.green;
  }
  
  // Navigate to edit screen
  Future<Map<String, dynamic>?> navigateToEdit(
    BuildContext context,
    ProductModel productModel,
  ) async {
     return await Navigator.push(
       context,
       MaterialPageRoute(
         builder: (context) => EditProductPage(product: productModel),
       ),
     );
  }
  
  Future<Map<String, dynamic>> deleteProduct() async {
    try {
      final productId = (product['id'] ?? product['productId'] ?? '').toString();
      if (productId.isEmpty) {
        return {'success': false, 'message': 'Product ID kosong'};
      }

      // delete master product doc
      try {
        await _firestore.collection('products').doc(productId).delete();
      } catch (_) {}

      // delete all barcode docs referencing this productId
      try {
        final q = await _firestore.collection('product_barcodes').where('productId', isEqualTo: productId).get();
        for (final d in q.docs) {
          try { await d.reference.delete(); } catch (_) {}
        }
      } catch (_) {}

      return {'success': true, 'message': 'Produk berhasil dihapus'};
    } catch (e) {
      return {'success': false, 'message': 'Terjadi kesalahan: $e'};
    }
  }
  
  // Show delete confirmation dialog
  Future<bool> showDeleteConfirmation(BuildContext context, String productName) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus produk "$productName"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    
    return result ?? false;
  }
  
  // Create ProductModel from product data
  ProductModel createProductModel() {
    // Build a normalized map from available product fields so ProductModel is fully populated
    final Map<String, dynamic> src = Map<String, dynamic>.from(product);

    final String docId = (src['id'] ?? src['productId'] ?? src['id_product'] ?? '').toString();
    final String idProduct = src['productId']?.toString() ?? src['id_product']?.toString() ?? docId;
    final String nama = (src['name'] ?? src['nama'] ?? src['nama_product'] ?? '').toString();
    final String kategori = (src['category'] ?? src['kategori'] ?? src['kategori_product'] ?? '').toString();
    final String merek = (src['brand'] ?? src['merek'] ?? src['merek_product'] ?? '').toString();

    // production/purchase/expired fields may be in different keys
    final dynamic rawPurchase = src['createdAt'] ?? src['purchaseDate'] ?? src['tanggal_beli'] ?? src['tanggal_beli_raw'];
    final dynamic rawProduction = src['productionDate'] ?? src['production_date'] ?? src['tanggal_produksi'] ?? rawPurchase;
    final dynamic rawExpired = src['expiredDate'] ?? src['expired'] ?? src['tanggal_expired'] ?? src['expiredRaw'];

    String tanggalBeli = '';
    try {
      if (rawPurchase is String) tanggalBeli = rawPurchase;
      else if (rawPurchase is Timestamp) tanggalBeli = rawPurchase.toDate().toIso8601String().split('T').first;
    } catch (_) {}

    String productionDate = '';
    try {
      if (rawProduction is String) productionDate = rawProduction;
      else if (rawProduction is Timestamp) productionDate = rawProduction.toDate().toIso8601String().split('T').first;
    } catch (_) {}

    String expired = '';
    try {
      if (rawExpired is String) expired = rawExpired;
      else if (rawExpired is Timestamp) expired = rawExpired.toDate().toIso8601String().split('T').first;
    } catch (_) {}

    final String price = (src['sellingPrice'] ?? src['price'] ?? src['priceRaw'] ?? '').toString();
    final String jumlah = (src['stock'] ?? src['jumlah_produk'] ?? 0).toString();
    final List<String> barcodes = (src['barcode_list'] is List) ? List<String>.from(src['barcode_list']) : (src['barcode_list']?.toString().split(',')?.map((s) => s.trim())?.where((s) => s.isNotEmpty)?.toList() ?? <String>[]);
    final String supplier = (src['supplierName'] ?? src['supplier_name'] ?? src['supplier'] ?? '').toString();

    return ProductModel(
      id: docId,
      id_product: idProduct,
      nama_product: nama,
      kategori_product: kategori,
      merek_product: merek,
      tanggal_beli: tanggalBeli,
      production_date: productionDate,
      harga_product: price,
      jumlah_produk: jumlah,
      barcode_list: barcodes,
      tanggal_expired: expired,
      supplier_name: supplier,
      ownerid: src['ownerId']?.toString() ?? src['ownerid']?.toString() ?? '',
    );
  }
}