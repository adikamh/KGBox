// lib/screens/add_product_screen.dart
import 'package:flutter/material.dart';
import 'dart:convert';
import '../pages/barcode_scanner_page.dart';
import '../services/restapi.dart';
import '../services/config.dart';
import '../models/product_model.dart';

class AddProductScreen {
  final DataService _dataService = DataService();
  
  // Product data
  String productId = '';
  String productCode = '';
  String selectedCategory = 'Makanan';
  List<String> categories = ['Makanan', 'Minuman'];
  String? ownerId;
  
  // Controllers (will be passed from UI)
  TextEditingController? nameController;
  TextEditingController? codeController;
  TextEditingController? merekController;
  TextEditingController? hargaController;
  TextEditingController? jumlahController;
  TextEditingController? tanggalExpiredController;
  
  // Initialize
  void initialize({
    String? barcode,
    String? ownerId,
    TextEditingController? nameCtrl,
    TextEditingController? codeCtrl,
    TextEditingController? merekCtrl,
    TextEditingController? hargaCtrl,
    TextEditingController? jumlahCtrl,
    TextEditingController? tanggalExpiredCtrl,
  }) {
    nameController = nameCtrl ?? TextEditingController();
    codeController = codeCtrl ?? TextEditingController();
    merekController = merekCtrl ?? TextEditingController();
    hargaController = hargaCtrl ?? TextEditingController();
    jumlahController = jumlahCtrl ?? TextEditingController(text: '1');
    tanggalExpiredController = tanggalExpiredCtrl ?? TextEditingController();
    this.ownerId = ownerId;
    
    productId = barcode ?? _generateProductId();
    productCode = barcode ?? _generateProductCode();
    
    if (barcode != null) {
      codeController!.text = barcode;
    } else {
      codeController!.text = productCode;
    }
  }
  
  // Generate product ID
  String _generateProductId() {
    return 'PRD${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}';
  }
  
  // Generate product code
  String _generateProductCode() {
    final namePrefix = (nameController?.text.isNotEmpty ?? false)
        ? nameController!.text.substring(0, 1).toUpperCase()
        : 'P';
    final catPrefix = selectedCategory.substring(0, 1).toUpperCase();
    final random = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    return '$namePrefix$catPrefix$random';
  }

  void updateCategory(String category) {
    selectedCategory = category;
    // Do not regenerate productCode on category change to keep code stable.
  }
  
  // Validate form
  Map<String, String?> validateForm() {
    final errors = <String, String?>{};
    
    // Nama Produk
    if (nameController?.text.trim().isEmpty ?? true) {
      errors['name'] = 'Nama produk wajib diisi';
    }
    
    // Merek Produk
    if (merekController?.text.trim().isEmpty ?? true) {
      errors['merek'] = 'Merek produk wajib diisi';
    }
    
    // Harga Produk
    final hargaText = hargaController?.text.trim() ?? '';
    if (hargaText.isEmpty) {
      errors['harga'] = 'Harga produk wajib diisi';
    } else if (int.tryParse(hargaText) == null) {
      errors['harga'] = 'Harga harus berupa angka';
    }
    
    // Jumlah Stok
    final jumlahText = jumlahController?.text.trim() ?? '';
    if (jumlahText.isEmpty) {
      errors['jumlah'] = 'Jumlah stok wajib diisi';
    } else if (int.tryParse(jumlahText) == null) {
      errors['jumlah'] = 'Jumlah harus berupa angka';
    }
    
    // Tanggal Expired
    if (tanggalExpiredController?.text.trim().isEmpty ?? true) {
      errors['tanggalExpired'] = 'Tanggal expired wajib diisi';
    }
    
    return errors;
  }
  
  // Add product to database
  Future<Map<String, dynamic>> addProduct() async {
    // Validate form
    final errors = validateForm();
    if (errors.isNotEmpty) {
      return {
        'success': false,
        'message': 'Validasi gagal',
        'errors': errors,
      };
    }
    
    final int jumlah = int.tryParse(jumlahController!.text.trim()) ?? 0;
    final List<String> barcodeList = List<String>.filled(jumlah, codeController?.text ?? productId);

    final product = ProductModel(
      id: productId,
      id_product: productId,
      nama_product: nameController!.text.trim(),
      kategori_product: selectedCategory,
      merek_product: merekController!.text.trim(),
      tanggal_beli: _formatCurrentDateTime(),
      harga_product: hargaController!.text.trim(),
      jumlah_produk: jumlahController!.text.trim(),
      barcode_list: barcodeList,
      ownerid: ownerId ?? '',
      tanggal_expired: tanggalExpiredController!.text.trim(),
    );
    
    try {
      final data = Map<String, dynamic>.from(product.toJson());
      // Ensure barcode_list stored as JSON string for API
      data['barcode_list'] = jsonEncode(product.barcode_list);
      // Ensure owner id is included
      data['ownerid'] = ownerId ?? '';
      await _dataService.insertOne(token, project, 'product', appid, data);

      return {
        'success': true,
        'message': 'Produk berhasil ditambahkan',
        'product': product.toJson(),
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menambahkan produk: $e',
        'error': e.toString(),
      };
    }
  }

  // Add products from scanned barcodes: create one product per barcode occurrence.
  Future<Map<String, dynamic>> addProductsFromScans(List<String> barcodes) async {
    // Validate required fields (except jumlah which will be per-item)
    final errors = validateForm();
    errors.remove('jumlah');
    if (errors.isNotEmpty) {
      return {
        'success': false,
        'message': 'Validasi gagal',
        'errors': errors,
      };
    }

    final List<Map<String, dynamic>> results = [];

    for (final barcode in barcodes) {
      final prodId = barcode.isNotEmpty ? barcode : _generateProductId();
      final product = ProductModel(
        id: prodId,
        id_product: prodId,
        nama_product: nameController!.text.trim(),
        kategori_product: selectedCategory,
        merek_product: merekController!.text.trim(),
        tanggal_beli: _formatCurrentDateTime(),
        harga_product: hargaController!.text.trim(),
        jumlah_produk: '1',
        barcode_list: [barcode],
        ownerid: ownerId ?? '',
        tanggal_expired: tanggalExpiredController!.text.trim(),
      );

      try {
        final data = Map<String, dynamic>.from(product.toJson());
        data['barcode_list'] = jsonEncode([barcode]);
        data['ownerid'] = ownerId ?? '';
        await _dataService.insertOne(token, project, 'product', appid, data);
        results.add({'barcode': barcode, 'success': true, 'product': product.toJson()});
      } catch (e) {
        results.add({'barcode': barcode, 'success': false, 'error': e.toString()});
      }
    }

    final successCount = results.where((r) => r['success'] == true).length;
    final failCount = results.length - successCount;

    return {
      'success': failCount == 0,
      'message': 'Batch insert selesai',
      'results': results,
      'total': results.length,
    };
  }
  
  // Scan barcode callback - returns either a String (single barcode)
  // or a Map<String,int> of scanned barcode counts when multi-scan used.
  Future<dynamic> scanBarcode(BuildContext context) async {
     final result = await Navigator.push(
       context,
       MaterialPageRoute(
         builder: (_) => const BarcodeScannerPage(userRole: ''),
       ),
     );
    
     return result;
  }
  
  // Select date for expired
  Future<void> selectExpiredDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    
    if (picked != null && tanggalExpiredController != null) {
      tanggalExpiredController!.text =
          '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }
  
  // Format current date time
  String _formatCurrentDateTime() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
        '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }
  
  // Dispose controllers
  void dispose() {
    nameController?.dispose();
    codeController?.dispose();
    merekController?.dispose();
    hargaController?.dispose();
    jumlahController?.dispose();
    tanggalExpiredController?.dispose();
  }
}