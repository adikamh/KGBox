// lib/screens/edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
// ignore: unused_import
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

/// A lightweight controller/helper for the Edit Product page.
/// Provides methods to initialize data, create/dispose text controllers,
/// format prices, pick dates and perform a simple "save" operation.
class EditProductScreen {
  late ProductModel product;
  final Map<String, TextEditingController> _controllers = {};

  void initialize(ProductModel p) {
    product = p;
  }

  /// Create and return controllers used by the page. Subsequent calls
  /// will return the same controllers map.
  Map<String, TextEditingController> createControllers() {
    if (_controllers.isNotEmpty) return _controllers;

    String tanggalBeliText = product.tanggal_beli;
    // try to convert yyyy-MM-dd -> 'MMMM d, yyyy' for display (e.g., January 1, 2026)
    if (tanggalBeliText.isNotEmpty) {
      try {
        final parsed = DateFormat('yyyy-MM-dd').parse(tanggalBeliText);
        tanggalBeliText = DateFormat('MMMM d, yyyy').format(parsed);
      } catch (_) {
        try {
          final parsed2 = DateFormat('dd/MM/yyyy').parse(tanggalBeliText);
          tanggalBeliText = DateFormat('MMMM d, yyyy').format(parsed2);
        } catch (_) {}
      }
    }

    _controllers['id_product'] = TextEditingController(text: product.id_product);
    _controllers['nama_product'] = TextEditingController(text: product.nama_product);
    _controllers['kategori_product'] = TextEditingController(text: product.kategori_product);
    _controllers['merek_product'] = TextEditingController(text: product.merek_product);
    _controllers['tanggal_beli'] = TextEditingController(text: tanggalBeliText);
    _controllers['harga_product'] = TextEditingController(text: _formatPriceDisplay(product.harga_product));
    // production date (if present in model) - format for display
    String prodText = product.production_date;
    if (prodText.isNotEmpty) {
      try {
        final parsed = DateFormat('yyyy-MM-dd').parse(prodText);
        prodText = DateFormat('dd/MM/yyyy').format(parsed);
      } catch (_) {
        try {
          final parsed2 = DateFormat('dd/MM/yyyy').parse(prodText);
          prodText = DateFormat('dd/MM/yyyy').format(parsed2);
        } catch (_) {
          // leave as-is
        }
      }
    }
    _controllers['tanggal_produksi'] = TextEditingController(text: prodText);
    // stock is not editable in master form
    // expired will be computed from created date delta; include controller for display if needed
    _controllers['tanggal_expired'] = TextEditingController(text: product.tanggal_expired);

    // supplier name editable
    _controllers['supplier_name'] = TextEditingController(text: product.supplier_name);

    return _controllers;
  }

  void disposeControllers() {
    for (final c in _controllers.values) {
      c.dispose();
    }
    _controllers.clear();
  }

  String _formatPriceDisplay(String raw) {
    final clean = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return '';
    try {
      final n = int.parse(clean);
      final f = NumberFormat('#,###', 'en_US');
      return f.format(n);
    } catch (_) {
      return raw;
    }
  }

  /// Format user-typed price (thousand separators)
  String formatPrice(String value) {
    final clean = value.replaceAll(RegExp(r'[^\d]'), '');
    if (clean.isEmpty) return '';
    try {
      final n = int.parse(clean);
      return NumberFormat('#,###', 'en_US').format(n);
    } catch (_) {
      return value;
    }
  }

  /// Remove non-digits for storage
  String formatPriceForStorage(String value) {
    return value.replaceAll(RegExp(r'[^\d]'), '');
  }

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
      lastDate: lastDate ?? DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Colors.blue[700]!,
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(foregroundColor: Colors.blue[700]),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// Minimal form validation used by the page. Returns a map of field->error.
  Map<String, String?> validateForm(Map<String, TextEditingController> controllers) {
    final errors = <String, String?>{};

    final nama = controllers['nama_product']?.text.trim() ?? '';
    if (nama.isEmpty) errors['nama_product'] = 'Nama produk harus diisi';

    final kategori = controllers['kategori_product']?.text.trim() ?? '';
    if (kategori.isEmpty) errors['kategori_product'] = 'Kategori harus diisi';

    final merek = controllers['merek_product']?.text.trim() ?? '';
    if (merek.isEmpty) errors['merek_product'] = 'Merek harus diisi';

    final hargaText = controllers['harga_product']?.text.trim() ?? '';
    if (hargaText.isEmpty) {
      errors['harga_product'] = 'Harga harus diisi';
    } else {
      final clean = formatPriceForStorage(hargaText);
      final harga = int.tryParse(clean);
      if (harga == null || harga <= 0) errors['harga_product'] = 'Harga harus berupa angka positif';
    }
    // stock is not editable in master form; do not validate jumlah_produk
    // expiredDate will be derived from createdAt; no validation here

    return errors;
  }

  /// Perform a simple save: validate and return updated product JSON.
  /// This implementation is local-only; integrate API calls here if needed.
  Future<Map<String, dynamic>> saveChanges(Map<String, TextEditingController> controllers) async {
    final errors = validateForm(controllers);
    if (errors.isNotEmpty) {
      return {'success': false, 'message': 'Validasi gagal', 'errors': errors};
    }

    // Format tanggal_beli to yyyy-MM-dd for storage if possible
    String tanggalBeliFormatted = '';
    final tanggalBeliText = controllers['tanggal_beli']?.text.trim() ?? '';
    if (tanggalBeliText.isNotEmpty) {
      try {
        // try 'MMMM d, yyyy' e.g., January 1, 2026
        final parsed = DateFormat('MMMM d, yyyy').parse(tanggalBeliText);
        tanggalBeliFormatted = DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {
        try {
          final parsed2 = DateFormat('dd/MM/yyyy').parse(tanggalBeliText);
          tanggalBeliFormatted = DateFormat('yyyy-MM-dd').format(parsed2);
        } catch (_) {
          tanggalBeliFormatted = tanggalBeliText;
        }
      }
    }

    // production date formatting for storage
    String productionFormatted = '';
    final prodText = controllers['tanggal_produksi']?.text.trim() ?? '';
    if (prodText.isNotEmpty) {
      try {
        final p = DateTime.parse(prodText);
        productionFormatted = '${p.year}-${p.month.toString().padLeft(2,'0')}-${p.day.toString().padLeft(2,'0')}';
      } catch (_) {
        try {
          final p2 = DateFormat('dd/MM/yyyy').parse(prodText);
          productionFormatted = '${p2.year}-${p2.month.toString().padLeft(2,'0')}-${p2.day.toString().padLeft(2,'0')}';
        } catch (_) {
          try {
            final p3 = DateFormat('MMMM d, yyyy').parse(prodText);
            productionFormatted = '${p3.year}-${p3.month.toString().padLeft(2,'0')}-${p3.day.toString().padLeft(2,'0')}';
          } catch (_) {
            productionFormatted = prodText;
          }
        }
      }
    } else {
      productionFormatted = product.production_date;
    }

    final updated = ProductModel(
      id: product.id,
      id_product: product.id_product,
      nama_product: controllers['nama_product']!.text.trim(),
      kategori_product: controllers['kategori_product']!.text.trim(),
      merek_product: controllers['merek_product']!.text.trim(),
      tanggal_beli: tanggalBeliFormatted,
      production_date: productionFormatted,
      supplier_name: controllers['supplier_name']?.text.trim() ?? product.supplier_name,
      harga_product: formatPriceForStorage(controllers['harga_product']!.text),
      // keep existing jumlah_produk (not editable here)
      jumlah_produk: product.jumlah_produk,
      barcode_list: product.barcode_list,
      tanggal_expired: controllers['tanggal_expired']!.text.trim(),
    );
    // Prepare Firestore update payload for master product doc
    try {
      final firestore = FirebaseFirestore.instance;

      // Determine document id to update: prefer internal _id, then id_product
      String docId = product.id.isNotEmpty ? product.id : (product.id_product.isNotEmpty ? product.id_product : updated.id_product);
      if (docId.isEmpty) {
        return {'success': false, 'message': 'Tidak dapat menentukan docId untuk produk'};
      }

      // Parse original created & expired dates to compute delta
      DateTime? originalCreated;
      DateTime? originalExpired;
      try {
        if (product.tanggal_beli.isNotEmpty) {
          originalCreated = DateTime.tryParse(product.tanggal_beli) ?? DateFormat('dd/MM/yyyy').parse(product.tanggal_beli);
        }
      } catch (_) { originalCreated = null; }
      try {
        if (product.tanggal_expired.isNotEmpty) {
          originalExpired = DateTime.tryParse(product.tanggal_expired) ?? DateFormat('dd/MM/yyyy').parse(product.tanggal_expired);
        }
      } catch (_) { originalExpired = null; }

      // Build update map using Firestore master field names
      final Map<String, dynamic> updateData = {};
      updateData['nama'] = updated.nama_product;
      updateData['brand'] = updated.merek_product;
      updateData['category'] = updated.kategori_product;
      final int priceVal = int.tryParse(updated.harga_product) ?? 0;
      updateData['price'] = priceVal;
      updateData['sellingPrice'] = priceVal;

      // Parse new created date if provided
      DateTime? newCreated;
      if (tanggalBeliFormatted.isNotEmpty) {
        try {
          // tanggalBeliFormatted is yyyy-MM-dd
          newCreated = DateTime.parse(tanggalBeliFormatted);
          updateData['createdAt'] = Timestamp.fromDate(newCreated);
        } catch (_) {
          // ignore parse errors
        }
      }

      // Determine expiredDate to store. Prefer explicit value from form if provided.
      String? explicitExpired = controllers['tanggal_expired']?.text.trim();
      String? normalizedExpired;
      if (explicitExpired != null && explicitExpired.isNotEmpty) {
        // Try to normalize to yyyy-MM-dd
        try {
          DateTime p = DateTime.parse(explicitExpired);
          normalizedExpired = '${p.year}-${p.month.toString().padLeft(2,'0')}-${p.day.toString().padLeft(2,'0')}';
        } catch (_) {
          try {
            final p2 = DateFormat('dd/MM/yyyy').parse(explicitExpired);
            normalizedExpired = '${p2.year}-${p2.month.toString().padLeft(2,'0')}-${p2.day.toString().padLeft(2,'0')}';
          } catch (_) {
            try {
              final p3 = DateFormat('MMMM d, yyyy').parse(explicitExpired);
              normalizedExpired = '${p3.year}-${p3.month.toString().padLeft(2,'0')}-${p3.day.toString().padLeft(2,'0')}';
            } catch (_) {
              // fallback to raw input
              normalizedExpired = explicitExpired;
            }
          }
        }
      }

      if (normalizedExpired != null && normalizedExpired.isNotEmpty) {
        updateData['expiredDate'] = normalizedExpired;
      } else if (originalCreated != null && originalExpired != null && newCreated != null) {
        final diff = originalExpired.difference(originalCreated);
        final newExpired = newCreated.add(diff);
        updateData['expiredDate'] = '${newExpired.year}-${newExpired.month.toString().padLeft(2,'0')}-${newExpired.day.toString().padLeft(2,'0')}';
      }

      // Optional supplier fields if present in controllers
      if (controllers.containsKey('supplier_id')) updateData['supplierId'] = controllers['supplier_id']!.text.trim();
      if (controllers.containsKey('supplier_name')) updateData['supplierName'] = controllers['supplier_name']!.text.trim();

        // Production date update
        if (controllers.containsKey('tanggal_produksi') && controllers['tanggal_produksi']!.text.trim().isNotEmpty) {
          // attempt to normalize to yyyy-MM-dd
          final prodText = controllers['tanggal_produksi']!.text.trim();
          String prodFormatted = prodText;
          try {
            // support dd/MM/yyyy or yyyy-MM-dd or 'MMMM d, yyyy'
            DateTime parsed = DateTime.parse(prodText);
            prodFormatted = '${parsed.year}-${parsed.month.toString().padLeft(2,'0')}-${parsed.day.toString().padLeft(2,'0')}';
          } catch (_) {
            try {
              final parsed2 = DateFormat('dd/MM/yyyy').parse(prodText);
              prodFormatted = '${parsed2.year}-${parsed2.month.toString().padLeft(2,'0')}-${parsed2.day.toString().padLeft(2,'0')}';
            } catch (_) {
              try {
                final parsed3 = DateFormat('MMMM d, yyyy').parse(prodText);
                prodFormatted = '${parsed3.year}-${parsed3.month.toString().padLeft(2,'0')}-${parsed3.day.toString().padLeft(2,'0')}';
              } catch (_) {}
            }
          }
          updateData['productionDate'] = prodFormatted;
        }

          // Recompute productKey so masters stay consistent when name/brand/category/productionDate change
          final String prodForKey = updateData.containsKey('productionDate')
            ? (updateData['productionDate'] ?? '')
            : (product.production_date);
          final String keyName = updated.nama_product.trim().toLowerCase();
          final String keyBrand = updated.merek_product.trim().toLowerCase();
          final String keyCat = updated.kategori_product.trim().toLowerCase();
          final String productKey = '${keyName}_${keyBrand}_${keyCat}_$prodForKey';
          updateData['productKey'] = productKey;

      // Perform Firestore update
      debugPrint('Updating product docId=$docId with: $updateData');
      await firestore.collection('products').doc(docId).update(updateData);
      debugPrint('Update complete for docId=$docId');

      return {'success': true, 'message': 'Produk berhasil diperbarui', 'product': updated.toJson()};
    } catch (e) {
      debugPrint('Firestore update failed: $e');
      return {'success': false, 'message': 'Gagal memperbarui produk: $e'};
    }
  }

  List<String> getAvailableCategories() {
    return ['Makanan', 'Minuman', 'Elektronik', 'Pakaian', 'Lainnya'];
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