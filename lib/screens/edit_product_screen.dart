// lib/screens/edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../services/config.dart';
import '../services/restApi.dart';
import '../models/product_model.dart';

class EditProductScreen {
  final DataService _dataService = DataService();
  late ProductModel product;
  
  // Controllers (will be managed by UI)
  late Map<String, TextEditingController> controllers;
  
  // Initialize with product data
  void initialize(ProductModel productModel) {
    product = productModel;
    controllers = {};
  }
  
  // Create controllers
  Map<String, TextEditingController> createControllers() {
    return {
      'id_product': TextEditingController(text: product.id_product),
      'nama_product': TextEditingController(text: product.nama_product),
      'kategori_product': TextEditingController(text: product.kategori_product),
      'merek_product': TextEditingController(text: product.merek_product),
      'tanggal_beli': TextEditingController(
        text: _formatTanggalBeli(product.tanggal_beli),
      ),
      'harga_product': TextEditingController(text: product.harga_product),
      'jumlah_produk': TextEditingController(text: product.jumlah_produk),
      'tanggal_expired': TextEditingController(text: product.tanggal_expired),
    };
  }
  
  // Dispose controllers
  void disposeControllers() {
    for (var controller in controllers.values) {
      controller.dispose();
    }
  }
  
  // Format tanggal beli for display
  String _formatTanggalBeli(String tanggal) {
    if (tanggal.isEmpty) return '';
    
    try {
      // Try to parse various date formats
      DateTime? parsedDate;
      
      // Try yyyy-MM-dd format
      parsedDate = DateTime.tryParse(tanggal.split(' ').first);
      
      // Try dd/MM/yyyy format
      if (parsedDate == null && tanggal.contains('/')) {
        final parts = tanggal.split('/');
        if (parts.length == 3) {
          parsedDate = DateTime(
            int.parse(parts[2]),
            int.parse(parts[1]),
            int.parse(parts[0]),
          );
        }
      }
      
      if (parsedDate != null) {
        return DateFormat('dd/MM/yyyy').format(parsedDate);
      }
      
      return tanggal;
    } catch (e) {
      return tanggal;
    }
  }
  
  // Format price for display
  String formatPrice(String value) {
    if (value.isEmpty) return '';
    
    try {
      // Remove any non-digit characters
      final cleanValue = value.replaceAll(RegExp(r'[^\d]'), '');
      final number = int.tryParse(cleanValue) ?? 0;
      
      return NumberFormat.currency(
        locale: 'id_ID',
        symbol: '',
        decimalDigits: 0,
      ).format(number);
    } catch (e) {
      return value;
    }
  }
  
  // Format price for storage
  String formatPriceForStorage(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '');
  }
  
  // Select date
  Future<DateTime?> selectDate(
    BuildContext context, {
    DateTime? initialDate,
    DateTime? firstDate,
    DateTime? lastDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate ?? DateTime.now(),
      firstDate: firstDate ?? DateTime(2000),
      lastDate: lastDate ?? DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Colors.blue[700],
              ),
            ),
          ),
          child: child!,
        );
      },
    );
  }
  
  // Validate form
  Map<String, String?> validateForm(Map<String, TextEditingController> controllers) {
    final errors = <String, String?>{};
    
    // Nama Produk
    final nama = controllers['nama_product']?.text.trim() ?? '';
    if (nama.isEmpty) {
      errors['nama_product'] = 'Nama produk harus diisi';
    }
    
    // Kategori Produk
    final kategori = controllers['kategori_product']?.text.trim() ?? '';
    if (kategori.isEmpty) {
      errors['kategori_product'] = 'Kategori harus diisi';
    }
    
    // Merek Produk
    final merek = controllers['merek_product']?.text.trim() ?? '';
    if (merek.isEmpty) {
      errors['merek_product'] = 'Merek harus diisi';
    }
    
    // Harga Produk
    final hargaText = controllers['harga_product']?.text.trim() ?? '';
    if (hargaText.isEmpty) {
      errors['harga_product'] = 'Harga harus diisi';
    } else {
      final cleanHarga = formatPriceForStorage(hargaText);
      final harga = int.tryParse(cleanHarga);
      if (harga == null || harga <= 0) {
        errors['harga_product'] = 'Harga harus berupa angka positif';
      }
    }
    
    // Jumlah Produk
    final jumlahText = controllers['jumlah_produk']?.text.trim() ?? '';
    if (jumlahText.isEmpty) {
      errors['jumlah_produk'] = 'Jumlah stok harus diisi';
    } else {
      final jumlah = int.tryParse(jumlahText);
      if (jumlah == null || jumlah < 0) {
        errors['jumlah_produk'] = 'Jumlah stok harus berupa angka';
      }
    }
    
    // Tanggal Expired
    final tanggalExpired = controllers['tanggal_expired']?.text.trim() ?? '';
    if (tanggalExpired.isEmpty) {
      errors['tanggal_expired'] = 'Tanggal expired harus diisi';
    }
    
    return errors;
  }
  
  // Save product changes
  Future<Map<String, dynamic>> saveChanges(
    Map<String, TextEditingController> controllers,
  ) async {
    // Validate form
    final errors = validateForm(controllers);
    if (errors.isNotEmpty) {
      return {
        'success': false,
        'message': 'Validasi gagal',
        'errors': errors,
      };
    }
    
    try {
      // Prepare data for update
      final fieldsToUpdate = <String, String>{};
      
      // Format tanggal beli for storage
      String tanggalBeliFormatted = '';
      final tanggalBeliText = controllers['tanggal_beli']?.text.trim() ?? '';
      if (tanggalBeliText.isNotEmpty) {
        try {
          final parsedDate = DateFormat('dd/MM/yyyy').parse(tanggalBeliText);
          tanggalBeliFormatted = DateFormat('yyyy-MM-dd').format(parsedDate);
        } catch (e) {
          tanggalBeliFormatted = tanggalBeliText;
        }
      }
      
      // Add fields to update
      fieldsToUpdate['nama_product'] = controllers['nama_product']!.text.trim();
      fieldsToUpdate['kategori_product'] = controllers['kategori_product']!.text.trim();
      fieldsToUpdate['merek_product'] = controllers['merek_product']!.text.trim();
      fieldsToUpdate['tanggal_beli'] = tanggalBeliFormatted;
      fieldsToUpdate['harga_product'] = formatPriceForStorage(controllers['harga_product']!.text);
      fieldsToUpdate['jumlah_produk'] = controllers['jumlah_produk']!.text.trim();
      fieldsToUpdate['tanggal_expired'] = controllers['tanggal_expired']!.text.trim();
      
      // Update product
      final success = await _updateMultipleFields(
        fields: fieldsToUpdate,
        id: product.id,
      );
      
      if (success) {
        // Create updated product model
        final updatedProduct = ProductModel(
          id: product.id,
          id_product: product.id_product,
          nama_product: fieldsToUpdate['nama_product']!,
          kategori_product: fieldsToUpdate['kategori_product']!,
          merek_product: fieldsToUpdate['merek_product']!,
          tanggal_beli: fieldsToUpdate['tanggal_beli']!,
          harga_product: fieldsToUpdate['harga_product']!,
          jumlah_produk: fieldsToUpdate['jumlah_produk']!,
          tanggal_expired: fieldsToUpdate['tanggal_expired']!,
        );
        
        return {
          'success': true,
          'message': 'Produk berhasil diperbarui',
          'product': updatedProduct.toJson(),
        };
      } else {
        return {
          'success': false,
          'message': 'Gagal memperbarui produk',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Terjadi kesalahan: $e',
      };
    }
  }
  
  // Update multiple fields at once
  Future<bool> _updateMultipleFields({
    required Map<String, String> fields,
    required String id,
  }) async {
    try {
      // Convert map to comma-separated format
      final fieldList = fields.keys.join(',');
      final valueList = fields.values.map((v) => v.replaceAll(',', '\\,')).join(',');
      
      debugPrint('Update fields: $fieldList');
      debugPrint('Update values: $valueList');
      debugPrint('Product ID: $id');
      
      // Call DataService for update
      final ok = await _dataService.updateId(
        fieldList,
        valueList,
        token,
        project,
        collection,
        appid,
        id,
      );
      
      debugPrint('Update result: $ok');
      
      if (ok) {
        // Verify the update
        try {
          final docBody = await _dataService.selectId(
            token,
            project,
            collection,
            appid,
            id,
          );
          
          debugPrint('Select after update: $docBody');
          
          final parsed = json.decode(docBody);
          Map<String, dynamic>? updatedData;
          
          if (parsed is List && parsed.isNotEmpty) {
            updatedData = parsed[0] as Map<String, dynamic>;
          } else if (parsed is Map) {
            if (parsed.containsKey('data') && 
                parsed['data'] is List && 
                (parsed['data'] as List).isNotEmpty) {
              updatedData = parsed['data'][0] as Map<String, dynamic>;
            } else {
              updatedData = parsed as Map<String, dynamic>;
            }
          }
          
          if (updatedData != null) {
            // Check if all fields match
            bool allMatch = true;
            fields.forEach((key, expectedValue) {
              final serverValue = (updatedData![key] ?? '').toString().trim();
              if (serverValue != expectedValue.trim()) {
                debugPrint('Field mismatch: $key - expected: "$expectedValue", got: "$serverValue"');
                allMatch = false;
              }
            });
            
            if (allMatch) return true;
            
            // Fallback: update fields individually
            debugPrint('Attempting per-field updates...');
            bool allFieldOk = true;
            
            for (final entry in fields.entries) {
              final fieldOk = await _dataService.updateId(
                entry.key,
                entry.value,
                token,
                project,
                collection,
                appid,
                id,
              );
              
              debugPrint('Update ${entry.key}: $fieldOk');
              
              if (!fieldOk) allFieldOk = false;
              await Future.delayed(const Duration(milliseconds: 100));
            }
            
            return allFieldOk;
          }
        } catch (e) {
          debugPrint('Error verifying update: $e');
        }
      }
      
      return false;
    } catch (e) {
      debugPrint('Error in updateMultipleFields: $e');
      return false;
    }
  }
  
  // Get available categories (could be from API or predefined)
  List<String> getAvailableCategories() {
    return ['Makanan', 'Minuman', 'Elektronik', 'Pakaian', 'Lainnya'];
  }
  
  // Check if product is expired
  bool isProductExpired() {
    final expiredDate = product.tanggal_expired;
    if (expiredDate.isEmpty) return false;
    
    try {
      final parts = expiredDate.split('-');
      if (parts.length < 3) return false;
      
      final expired = DateTime(
        int.parse(parts[0]),
        int.parse(parts[1]),
        int.parse(parts[2]),
      );
      
      return expired.isBefore(DateTime.now());
    } catch (e) {
      return false;
    }
  }
  
  // Get expired status
  String getExpiredStatus() {
    return isProductExpired() ? 'Sudah Expired' : 'Masih Aktif';
  }
  
  // Get expired status color
  Color getExpiredStatusColor() {
    return isProductExpired() ? Colors.red : Colors.green;
  }
  
  // Get stock status
  String getStockStatus() {
    final stock = int.tryParse(product.jumlah_produk) ?? 0;
    if (stock < 10) return 'Stok Rendah';
    if (stock < 50) return 'Stok Sedang';
    return 'Stok Aman';
  }
  
  // Get stock status color
  Color getStockStatusColor() {
    final stock = int.tryParse(product.jumlah_produk) ?? 0;
    if (stock < 10) return Colors.orange;
    if (stock < 50) return Colors.blue;
    return Colors.green;
  }
  
  // Get category icon
  IconData getCategoryIcon() {
    final category = product.kategori_product.toLowerCase();
    
    if (category.contains('minuman')) {
      return Icons.local_drink_rounded;
    } else if (category.contains('makanan')) {
      return Icons.restaurant_rounded;
    } else if (category.contains('elektronik')) {
      return Icons.electrical_services_rounded;
    } else if (category.contains('pakaian')) {
      return Icons.checkroom_rounded;
    } else {
      return Icons.category_rounded;
    }
  }
  
  // Get category color
  Color getCategoryColor() {
    final category = product.kategori_product.toLowerCase();
    
    if (category.contains('minuman')) {
      return Colors.blue;
    } else if (category.contains('makanan')) {
      return Colors.green;
    } else if (category.contains('elektronik')) {
      return Colors.purple;
    } else if (category.contains('pakaian')) {
      return Colors.pink;
    } else {
      return Colors.orange;
    }
  }
}