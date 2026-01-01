// lib/screens/add_product_screen.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../pages/barcode_scanner_page.dart';
// removed unused imports

class AddProductScreen {
  // DataService removed (not used here)
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  
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
  TextEditingController? tanggalExpiredController;
  
  // Initialize
  void initialize({
    String? barcode,
    String? ownerId,
    TextEditingController? nameCtrl,
    TextEditingController? codeCtrl,
    TextEditingController? merekCtrl,
    TextEditingController? hargaCtrl,
    TextEditingController? tanggalExpiredCtrl,
  }) {
    nameController = nameCtrl ?? TextEditingController();
    codeController = codeCtrl ?? TextEditingController();
    merekController = merekCtrl ?? TextEditingController();
    hargaController = hargaCtrl ?? TextEditingController();
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
    
    
    // Tanggal Expired
    if (tanggalExpiredController?.text.trim().isEmpty ?? true) {
      errors['tanggalExpired'] = 'Tanggal expired wajib diisi';
    }
    
    return errors;
  }
  
  // Add product to database
  Future<Map<String, dynamic>> addProduct({String? supplierId, String? supplierName}) async {
    // Validate form
    final errors = validateForm();
    if (errors.isNotEmpty) {
      return {
        'success': false,
        'message': 'Validasi gagal',
        'errors': errors,
      };
    }
    
    // When adding without scanned barcodes, product will be created without barcode entries.

    // Create master product document in 'products' collection
    final String masterId = (productId.isNotEmpty && productId != codeController?.text) ? productId : _generateProductId();
    final Map<String, dynamic> productDoc = {
      'productId': masterId,
      'nama': nameController!.text.trim(),
      'brand': merekController!.text.trim(),
      'category': selectedCategory,
      'price': int.tryParse(hargaController?.text.trim() ?? '0') ?? 0,
      'sellingPrice': int.tryParse(hargaController?.text.trim() ?? '0') ?? 0,
      'productionDate': _formatCurrentDateTime(),
      'expiredDate': tanggalExpiredController!.text.trim(),
      'supplierId': supplierId ?? '',
      'supplierName': supplierName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': ownerId ?? '',
    };

    try {
      await _firestore.collection('products').doc(masterId).set(productDoc);

      // No scanned barcodes: do not create `product_barcode` documents here.

      return {
        'success': true,
        'message': 'Produk berhasil ditambahkan',
        'product': productDoc,
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
  Future<Map<String, dynamic>> addProductsFromScans(List<String> barcodes, {String? supplierId, String? supplierName}) async {
    // Validate required fields (except jumlah which will be per-item)
    final errors = validateForm();
    // jumlah field removed; no need to remove validation key
    if (errors.isNotEmpty) {
      return {
        'success': false,
        'message': 'Validasi gagal',
        'errors': errors,
      };
    }

    // Create one master product and then add all scanned barcodes to product_barcode
    final String masterId = _generateProductId();
    final Map<String, dynamic> productDoc = {
      'productId': masterId,
      'nama': nameController!.text.trim(),
      'brand': merekController!.text.trim(),
      'category': selectedCategory,
      'price': int.tryParse(hargaController?.text.trim() ?? '0') ?? 0,
      'sellingPrice': int.tryParse(hargaController?.text.trim() ?? '0') ?? 0,
      'productionDate': _formatCurrentDateTime(),
      'expiredDate': tanggalExpiredController!.text.trim(),
      'supplierId': supplierId ?? '',
      'supplierName': supplierName ?? '',
      'createdAt': FieldValue.serverTimestamp(),
      'ownerId': ownerId ?? '',
    };

    final List<Map<String, dynamic>> results = [];

    try {
      await _firestore.collection('products').doc(masterId).set(productDoc);

      for (final barcode in barcodes) {
        try {
          if (barcode.trim().isEmpty) {
            results.add({'barcode': barcode, 'success': false, 'error': 'Empty barcode'});
            continue;
          }
          // store barcode as document ID under 'product_barcodes' for easy querying
          await _firestore.collection('product_barcodes').doc(barcode.trim()).set({
            'productId': masterId,
            'scannedAt': FieldValue.serverTimestamp(),
          });
          results.add({'barcode': barcode, 'success': true});
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
        'product': productDoc,
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Gagal menambahkan batch: $e',
        'error': e.toString(),
      };
    }
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
    tanggalExpiredController?.dispose();
  }
}