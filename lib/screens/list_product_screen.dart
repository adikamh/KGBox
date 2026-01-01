// lib/screens/list_product_screen.dart
import 'package:flutter/material.dart';
import 'package:kgbox/models/product_model.dart';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/config.dart';
import '../services/restApi.dart';
import '../pages/detail_product_page.dart';
import '../pages/edit_product_page.dart';

class ListProductScreen {
  final DataService _dataService = DataService();
  
  List<Map<String, dynamic>> products = [];
  bool isLoading = false;
  String filter = 'Semua';
  
  // Initialize
  Future<void> loadProducts({String? ownerId}) async {
    isLoading = true;
    
    try {
      debugPrint("🔄 Memuat produk dari Firestore 'products'...");
      final firestore = FirebaseFirestore.instance;
      Query query = firestore.collection('products');
      if (ownerId != null && ownerId.isNotEmpty) {
        // assume ownerId field is stored as 'ownerId' in Firestore
        query = query.where('ownerId', isEqualTo: ownerId);
      }

      final snapshot = await query.get();
      final dataList = snapshot.docs;
      debugPrint("✅ Ditemukan ${dataList.length} dokumen produk di Firestore");

      // Build master products from documents (doc.id is productId)
      final Map<String, Map<String, dynamic>> masterMap = {};
      for (final doc in dataList) {
        final raw = (doc.data() as Map<String, dynamic>?) ?? <String, dynamic>{};
        final prodId = doc.id;
        final name = (raw['nama'] ?? raw['name'] ?? '').toString();
        final category = (raw['category'] ?? raw['kategori'] ?? '').toString();
        final brand = (raw['brand'] ?? raw['merek'] ?? '').toString();
        final expired = (raw['expiredDate'] ?? raw['tanggal_expired'] ?? '').toString();

        // parse possible timestamp
        DateTime updated = DateTime.now();
        try {
          final created = raw['createdAt'] ?? raw['productionDate'] ?? raw['production_date'];
          if (created is Timestamp) {
            updated = created.toDate();
          } else if (created is String) {
            updated = DateTime.tryParse(created) ?? DateTime.now();
          }
        } catch (_) {}

        masterMap[prodId] = {
          'id': prodId,
          'name': name.isNotEmpty ? name : prodId,
          'category': category.isNotEmpty ? category : 'Umum',
          'price': _safeInt(raw['price'] ?? raw['harga'] ?? 0),
          'stock': 0,
          'updated': updated,
          'brand': brand,
          'expired': expired,
          'full': [raw],
        };
      }

      // Count barcodes for each productId
      final Map<String, int> counts = {};
      final futures = masterMap.keys.map((pk) async {
        try {
          final q = await firestore.collection('product_barcodes').where('productId', isEqualTo: pk).get();
          counts[pk] = q.size;
        } catch (e) {
          counts[pk] = 0;
        }
      }).toList();
      await Future.wait(futures);

      for (final pk in masterMap.keys) {
        masterMap[pk]!['stock'] = counts[pk] ?? 0;
      }

      products = masterMap.values.toList();
      debugPrint("✅ Berhasil load ${products.length} produk");

    } catch (e, stack) {
      debugPrint("❌ Error: $e");
      debugPrint("Stack: $stack");
      rethrow;
    } finally {
      isLoading = false;
    }
  }
  
  // Filter products based on search and category
  List<Map<String, dynamic>> getFilteredProducts(String searchQuery) {
    final query = searchQuery.toLowerCase();
    
      return products.where((product) {
      // Filter by category
      final prodCategory = (product['category'] ?? '').toString();
      if (filter != 'Semua' && prodCategory != filter) {
        return false;
      }
      
      // Filter by search query
      if (query.isNotEmpty) {
        final nameMatch = (product['name'] ?? '').toString().toLowerCase().contains(query);
        final brandMatch = (product['brand'] ?? '').toString().toLowerCase().contains(query);
        return nameMatch || brandMatch;
      }
      
      return true;
    }).toList();
  }

  // Return display products grouped by name (aggregate stock)
  List<Map<String, dynamic>> getDisplayProducts(String searchQuery) {
    final filtered = getFilteredProducts(searchQuery);

    final Map<String, List<Map<String, dynamic>>> grouped = {};
    for (var p in filtered) {
      final name = p['name'] as String? ?? 'Produk';
      grouped.putIfAbsent(name, () => []).add(p);
    }

    final List<Map<String, dynamic>> display = [];
    grouped.forEach((name, items) {
      // Aggregate stock and pick representative fields
      final totalStock = items.fold<int>(0, (sum, it) => sum + (it['stock'] as int));
      // pick latest updated
      items.sort((a, b) => (b['updated'] as DateTime).compareTo(a['updated'] as DateTime));
      final rep = items.first;

      display.add({
        'name': name,
        'category': rep['category'],
        'price': rep['price'],
        'stock': totalStock,
        'updated': rep['updated'],
        'brand': rep['brand'],
        'expired': rep['expired'],
        // keep original items for detail view
        'full': items.map((it) => it['full']).toList(),
      });
    });

    return display;
  }
  
  // Delete product
  Future<Map<String, dynamic>> deleteProduct(String productId) async {
    try {
      final success = await _dataService.removeId(
        token,
        project,
        collection,
        appid,
        productId,
      );
      
      if (success) {
        return {
          'success': true,
          'message': 'Produk berhasil dihapus',
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal menghapus produk',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }

  // Update multiple items with the same fields
  Future<Map<String, dynamic>> updateItemsFields(List<Map<String, dynamic>> items, Map<String, String> fields) async {
    if (fields.isEmpty) return {'success': false, 'message': 'No fields to update'};
    final List<Map<String, dynamic>> results = [];

    final fieldList = fields.keys.join(',');
    final valueList = fields.values.map((v) => v.replaceAll(',', '\\,')).join(',');

    for (final item in items) {
      final id = (item['id'] ?? item['id_product'] ?? '').toString();
      if (id.isEmpty) continue;
      try {
        final ok = await _dataService.updateId(
          fieldList,
          valueList,
          token,
          project,
          collection,
          appid,
          id,
        );
        results.add({'id': id, 'success': ok});
      } catch (e) {
        results.add({'id': id, 'success': false, 'error': e.toString()});
      }
      await Future.delayed(const Duration(milliseconds: 100));
    }

    final updatedCount = results.where((r) => r['success'] == true).length;
    return {
      'success': updatedCount == results.length,
      'updatedCount': updatedCount,
      'results': results,
      'message': 'Updated $updatedCount of ${results.length} items',
    };
  }
  
  // Show delete confirmation dialog
  Future<bool> showDeleteConfirmation(
    BuildContext context,
    String productName,
  ) async {
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
  
  // Navigate to detail screen
  void navigateToDetail(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
     // If 'full' contains a list of items (grouped), build an aggregated map
     final full = product['full'];
     if (full != null && full is List) {
       final items = full.cast<Map<String, dynamic>>();
       // aggregate into a single map expected by DetailProductPage
       final int totalStock = items.fold<int>(0, (s, it) => s + (_safeInt(it['jumlah_produk'])));
       final Map<String, dynamic> agg = Map<String, dynamic>.from(items.first);
       agg['jumlah_produk'] = totalStock.toString();
       agg['items'] = items; // attach individual units

       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (_) => DetailProductPage(product: agg),
         ),
       );
       return;
     }

     if (full != null) {
       Navigator.push(
         context,
         MaterialPageRoute(
           builder: (_) => DetailProductPage(product: full),
         ),
       );
     }
  }
  
  // Navigate to edit screen and return updated product map (if any)
  Future<Map<String, dynamic>?> navigateToEdit(
    BuildContext context,
    Map<String, dynamic> product,
  ) async {
    final full = product['full'];
    final Map<String, dynamic> target = (full is List && full.isNotEmpty) ? (full.first as Map<String, dynamic>) : ((full as Map<String, dynamic>?) ?? <String, dynamic>{});
     final result = await Navigator.push<Map<String, dynamic>?>(
       context,
       MaterialPageRoute(
         builder: (_) => EditProductPage(product: ProductModel.fromJson(target)),
       ),
    );
    return result;
  }
  
  // Helper methods
  int _safeInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is double) return value.round();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }
  
  DateTime _safeDateTime(dynamic value) {
    if (value == null) return DateTime.now();
    if (value is DateTime) return value;
    if (value is String && value.isNotEmpty) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }
    return DateTime.now();
  }
  
  // Format price
  String formatPrice(dynamic price) {
    final numPrice = price is int ? price : int.tryParse(price.toString()) ?? 0;
    return numPrice.toString().replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
  
  // Format date
  String formatDate(DateTime date) {
    final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Ags', 'Sep', 'Okt', 'Nov', 'Des'];
    return "${date.day} ${months[date.month - 1]} ${date.year}";
  }
  
  // Check if stock is low
  bool isStockLow(int stock) {
    return stock < 10;
  }
  
  // Get stock status text
  String getStockStatus(int stock) {
    return isStockLow(stock) ? 'Stok Rendah' : 'Stok Aman';
  }
  
  // Get stock status color
  Color getStockStatusColor(int stock) {
    return isStockLow(stock) ? Colors.orange : Colors.green;
  }
  
  // Get category icon
  IconData getCategoryIcon(String category) {
    final cat = category.toLowerCase();
    if (cat.contains('minuman')) {
      return Icons.local_drink_rounded;
    } else if (cat.contains('makanan')) {
      return Icons.restaurant_rounded;
    } else if (cat.contains('elektronik')) {
      return Icons.electrical_services_rounded;
    } else {
      return Icons.category_rounded;
    }
  }
  
  // Get category color
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
  
  // Get available categories
  List<String> getAvailableCategories() {
    final categories = products.map((p) => p['category'] as String).toSet().toList();
    return ['Semua', ...categories];
  }
  
  // Get total products count
  int getTotalProducts() {
    return products.length;
  }
  
  // Get total stock value
  int getTotalStockValue() {
    return products.fold(0, (sum, product) => sum + (product['price'] as int) * (product['stock'] as int));
  }
  
  // Get products by category
  Map<String, int> getProductsByCategory() {
    final result = <String, int>{};
    for (var product in products) {
      final category = product['category'] as String;
      result[category] = (result[category] ?? 0) + 1;
    }
    return result;
  }
}