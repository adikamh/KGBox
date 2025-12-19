// lib/screens/add_product_screen.dart
import 'package:flutter/material.dart';
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
    
    final product = ProductModel(
      id: productId,
      id_product: productId,
      nama_product: nameController!.text.trim(),
      kategori_product: selectedCategory,
      merek_product: merekController!.text.trim(),
      tanggal_beli: _formatCurrentDateTime(),
      harga_product: hargaController!.text.trim(),
      jumlah_produk: jumlahController!.text.trim(),
      tanggal_expired: tanggalExpiredController!.text.trim(),
    );
    
    try {
      await _dataService.insertProduct(
        appid,
        product.id_product,
        product.nama_product,
        product.kategori_product,
        product.merek_product,
        product.tanggal_beli,
        product.harga_product,
        product.jumlah_produk,
        product.tanggal_expired,
        ownerId ?? '',
      );
      
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
  
  // Scan barcode callback
  Future<String?> scanBarcode(BuildContext context) async {
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