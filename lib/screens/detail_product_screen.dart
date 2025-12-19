// lib/screens/detail_product_screen.dart
import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../services/restApi.dart';
import '../services/config.dart';
import '../pages/edit_product_page.dart';

class DetailProductScreen {
  final DataService _dataService = DataService();
  
  // Product data
  late Map<String, dynamic> product;
  
  // Initialize with product data
  void initialize(Map<String, dynamic> productData) {
    product = productData;
  }
  
  // Get formatted product values
  Map<String, dynamic> getFormattedProduct() {
    return {
      'code': product['id_product'] ?? '-',
      'name': product['nama_product'] ?? '-',
      'category': product['kategori_product'] ?? '-',
      'brand': product['merek_product'] ?? '-',
      'purchaseDate': product['tanggal_beli'] ?? '-',
      'price': product['harga_product'] ?? '-',
      'stock': product['jumlah_produk'] ?? '-',
      'expiredDate': product['tanggal_expired'] ?? '-',
    };
  }
  
  // Format price
  String formatPrice(String? price) {
    if (price == null) return '-';
    final value = int.tryParse(price) ?? 0;
    return 'Rp ${value.toString().replaceAllMapped(
      RegExp(r"\B(?=(\d{3})+(?!\d))"),
      (m) => '.',
    )}';
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
    final expiredDate = product['tanggal_expired'];
    if (expiredDate == null || expiredDate.isEmpty) return false;
    
    try {
      final parts = expiredDate.toString().split('-');
      if (parts.length < 3) return false;
      
      final expired = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      final now = DateTime.now();
      
      return expired.isBefore(now);
    } catch (e) {
      return false;
    }
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
      final productId = product['id'] ?? '';
      
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
    return ProductModel(
      id: product['id'] ?? '',
      id_product: product['id_product'] ?? '',
      nama_product: product['nama_product'] ?? '',
      kategori_product: product['kategori_product'] ?? '',
      merek_product: product['merek_product'] ?? '',
      tanggal_beli: product['tanggal_beli'] ?? '',
      harga_product: product['harga_product'] ?? '',
      jumlah_produk: product['jumlah_produk']?.toString() ?? '0',
      tanggal_expired: product['tanggal_expired'] ?? '',
    );
  }
}