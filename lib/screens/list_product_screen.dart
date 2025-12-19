// lib/screens/list_product_screen.dart
import 'package:flutter/material.dart';
import 'package:kgbox/models/product_model.dart';
import 'dart:convert';
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
      debugPrint("🔄 Memulai request ke API...");
      var result = await _dataService.selectAll(token, project, collection, appid);
      
      debugPrint("📦 Response diterima: ${result.runtimeType}");
      debugPrint("📦 Response content: $result");

      if (result == null) {
        throw Exception('Response null dari server');
      }

      // Parse JSON dengan aman
      dynamic parsedData;
      if (result is String) {
        parsedData = jsonDecode(result);
      } else if (result is Map) {
        parsedData = result;
      } else {
        parsedData = jsonDecode(result.toString());
      }

      debugPrint("📊 Parsed data type: ${parsedData.runtimeType}");

      // Extract data array
      List dataList = [];
      if (parsedData is Map && parsedData.containsKey('data')) {
        dataList = parsedData['data'] as List? ?? [];
      } else if (parsedData is List) {
        dataList = parsedData;
      }

      debugPrint("✅ Jumlah data: ${dataList.length}");

      // Convert ke format lokal (filter by ownerId jika diberikan)
      List<Map<String, dynamic>> tempProducts = [];
      for (var item in dataList) {
        if (item is Map) {
          // Jika ownerId diberikan, hanya masukkan item yang cocok
          if (ownerId != null && ownerId.isNotEmpty) {
            final itemOwner = (item['ownerid'] ?? item['ownerId'] ?? '').toString();
            if (itemOwner != ownerId) continue;
          }
          tempProducts.add({
            'id': item['id']?.toString() ?? '',
            'name': item['nama_product']?.toString() ?? 'Produk',
            'category': item['kategori_product']?.toString() ?? 'Umum',
            'price': _safeInt(item['harga_product']),
            'stock': _safeInt(item['jumlah_produk']),
            'updated': _safeDateTime(item['tanggal_beli']),
            'brand': item['merek_product']?.toString() ?? '',
            'expired': item['tanggal_expired']?.toString() ?? '',
            'full': item,
          });
        }
      }

      products = tempProducts;
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
      if (filter != 'Semua' && product['category'] != filter) {
        return false;
      }
      
      // Filter by search query
      if (query.isNotEmpty) {
        final nameMatch = product['name'].toLowerCase().contains(query);
        final brandMatch = product['brand'].toLowerCase().contains(query);
        return nameMatch || brandMatch;
      }
      
      return true;
    }).toList();
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
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (_) => DetailProductPage(product: product['full']),
       ),
     );
  }
  
  // Navigate to edit screen
  void navigateToEdit(
    BuildContext context,
    Map<String, dynamic> product,
  ) {
     Navigator.push(
       context,
       MaterialPageRoute(
         builder: (_) => EditProductPage(product: ProductModel.fromJson(product['full'])),
       ),
    );
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