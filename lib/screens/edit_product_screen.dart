// lib/screens/edit_product_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../models/product_model.dart';
import '../services/restapi.dart';
import '../services/config.dart';

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
    // try to convert yyyy-MM-dd -> dd/MM/yyyy for display
    if (tanggalBeliText.isNotEmpty) {
      try {
        final parsed = DateFormat('yyyy-MM-dd').parse(tanggalBeliText);
        tanggalBeliText = DateFormat('dd/MM/yyyy').format(parsed);
      } catch (_) {}
    }

    _controllers['id_product'] = TextEditingController(text: product.id_product);
    _controllers['nama_product'] = TextEditingController(text: product.nama_product);
    _controllers['kategori_product'] = TextEditingController(text: product.kategori_product);
    _controllers['merek_product'] = TextEditingController(text: product.merek_product);
    _controllers['tanggal_beli'] = TextEditingController(text: tanggalBeliText);
    _controllers['harga_product'] = TextEditingController(text: _formatPriceDisplay(product.harga_product));
    _controllers['jumlah_produk'] = TextEditingController(text: product.jumlah_produk);
    _controllers['tanggal_expired'] = TextEditingController(text: product.tanggal_expired);

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
    if (hargaText.isEmpty) errors['harga_product'] = 'Harga harus diisi';
    else {
      final clean = formatPriceForStorage(hargaText);
      final harga = int.tryParse(clean);
      if (harga == null || harga <= 0) errors['harga_product'] = 'Harga harus berupa angka positif';
    }

    final jumlahText = controllers['jumlah_produk']?.text.trim() ?? '';
    if (jumlahText.isEmpty) errors['jumlah_produk'] = 'Jumlah stok harus diisi';
    else {
      final jumlah = int.tryParse(jumlahText);
      if (jumlah == null || jumlah < 0) errors['jumlah_produk'] = 'Jumlah stok harus berupa angka';
    }

    final tanggalExpired = controllers['tanggal_expired']?.text.trim() ?? '';
    if (tanggalExpired.isEmpty) errors['tanggal_expired'] = 'Tanggal expired harus diisi';

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
        final parsed = DateFormat('dd/MM/yyyy').parse(tanggalBeliText);
        tanggalBeliFormatted = DateFormat('yyyy-MM-dd').format(parsed);
      } catch (_) {
        tanggalBeliFormatted = tanggalBeliText;
      }
    }

    final updated = ProductModel(
      id: product.id,
      id_product: product.id_product,
      nama_product: controllers['nama_product']!.text.trim(),
      kategori_product: controllers['kategori_product']!.text.trim(),
      merek_product: controllers['merek_product']!.text.trim(),
      tanggal_beli: tanggalBeliFormatted,
      harga_product: formatPriceForStorage(controllers['harga_product']!.text),
      jumlah_produk: controllers['jumlah_produk']!.text.trim(),
      barcode_list: product.barcode_list,
      tanggal_expired: controllers['tanggal_expired']!.text.trim(),
    );
    // Attempt to update on server via DataService
    final api = DataService();

    // Prepare fields map for key->value update (preferred)
    final fields = <String, String>{
      'nama_product': updated.nama_product,
      'kategori_product': updated.kategori_product,
      'merek_product': updated.merek_product,
      'tanggal_beli': updated.tanggal_beli,
      'harga_product': updated.harga_product,
      'jumlah_produk': updated.jumlah_produk,
      'tanggal_expired': updated.tanggal_expired,
    };

    // First try updateOne (map-based) which is more robust than comma-separated updateId
    debugPrint('Attempting updateOne with _id=${product.id}');
    bool ok = await api.updateOne(token, project, collection, appid, product.id, Map<String, dynamic>.from(fields));

    if (ok != true && product.id_product.isNotEmpty) {
      debugPrint('updateOne by _id failed; trying with id_product=${product.id_product}');
      ok = await api.updateOne(token, project, collection, appid, product.id_product, Map<String, dynamic>.from(fields));
    }

    // If updateOne failed, fallback to existing bulk `updateId` strategy then per-field `updateWhere`
    if (ok != true) {
      final fieldList = fields.keys.join(',');
      final valueList = fields.values.map((v) => v.replaceAll(',', '\\,')).join(',');

      // Try primary update by internal id using legacy endpoint
      debugPrint('updateOne failed; attempting legacy updateId with _id=${product.id}');
      ok = await api.updateId(fieldList, valueList, token, project, collection, appid, product.id);

      if (ok != true && product.id_product.isNotEmpty) {
        debugPrint('updateId by _id failed; trying with id_product=${product.id_product}');
        ok = await api.updateId(fieldList, valueList, token, project, collection, appid, product.id_product);
      }

      if (ok != true) {
        debugPrint('Bulk update failed; attempting per-field updateWhere fallback');
        bool allFieldOk = true;
        for (final entry in fields.entries) {
          try {
            // try by _id first
            bool fieldOk = await api.updateWhere('_id', product.id, entry.key, entry.value, token, project, collection, appid);
            if (fieldOk != true && product.id.isNotEmpty) {
              // try by id (server may use 'id' field)
              fieldOk = await api.updateWhere('id', product.id, entry.key, entry.value, token, project, collection, appid);
            }
            if (fieldOk != true && product.id_product.isNotEmpty) {
              // try by id_product
              fieldOk = await api.updateWhere('id_product', product.id_product, entry.key, entry.value, token, project, collection, appid);
            }
            debugPrint('field ${entry.key} updateWhere result: $fieldOk');
            if (!fieldOk) allFieldOk = false;
          } catch (e) {
            debugPrint('Exception updating field ${entry.key}: $e');
            allFieldOk = false;
          }
          await Future.delayed(const Duration(milliseconds: 120));
        }
        ok = allFieldOk;
      }
    }

    if (ok == true) {
      debugPrint('Update succeeded');

      // If this product represents multiple "units" (e.g. barcode_list contains unit IDs),
      // prefer batching updates across all unit `id_product`s using `updateWhereIn` per field.
      if (product.barcode_list.isNotEmpty) {
        debugPrint('Detected ${product.barcode_list.length} unit(s) in barcode_list — attempting batch update');

        final ids = product.barcode_list.join(',');
        bool batchAllOk = true;
        final List<Map<String, dynamic>> batchResults = [];

        // Try updating each field for all unit ids in a single call (per-field batch)
        for (final entry in fields.entries) {
          try {
            final okField = await api.updateWhereIn('id_product', ids, entry.key, entry.value, token, project, collection, appid);
            batchResults.add({'field': entry.key, 'success': okField});
            debugPrint('batch update field ${entry.key} -> $okField');
            if (!okField) batchAllOk = false;
          } catch (e) {
            debugPrint('Exception batch updating field ${entry.key}: $e');
            batchResults.add({'field': entry.key, 'success': false, 'error': e.toString()});
            batchAllOk = false;
          }
          await Future.delayed(const Duration(milliseconds: 120));
        }

        if (batchAllOk) {
          debugPrint('Batch update succeeded for all fields');
        } else {
          debugPrint('Batch update incomplete — falling back to per-unit updates');
          // Fall back to per-unit update strategy for any remaining updates
          final List<Map<String, dynamic>> unitResults = [];
          for (final unitId in product.barcode_list) {
            bool unitOk = false;
            try {
              // Try updateOne by unitId
              unitOk = await api.updateOne(token, project, collection, appid, unitId.toString(), Map<String, dynamic>.from(fields));
              debugPrint('unit $unitId updateOne -> $unitOk');

              if (!unitOk) {
                // Try selectWhere -> updateId fallback
                try {
                  final sel = await api.selectWhere(token, project, collection, appid, 'id_product', unitId.toString());
                  debugPrint('selectWhere for unit $unitId -> $sel');
                  dynamic parsed;
                  try {
                    parsed = sel is String ? jsonDecode(sel) : sel;
                  } catch (_) {
                    parsed = null;
                  }
                  String serverId = '';
                  if (parsed != null) {
                    List docs = [];
                    if (parsed is List) docs = parsed;
                    else if (parsed is Map && parsed.containsKey('data') && parsed['data'] is List) docs = parsed['data'];
                    if (docs.isNotEmpty) {
                      final doc = docs.first;
                      if (doc is Map) serverId = (doc['_id'] ?? doc['id'] ?? doc['id_product'] ?? '').toString();
                    }
                  }
                  if (serverId.isNotEmpty) {
                    final fieldList = fields.keys.join(',');
                    final valueList = fields.values.map((v) => v.replaceAll(',', '\\,')).join(',');
                    final retry = await api.updateId(fieldList, valueList, token, project, collection, appid, serverId);
                    unitOk = retry == true;
                    debugPrint('unit $unitId updateId via serverId $serverId -> $unitOk');
                  }
                } catch (e) {
                  debugPrint('selectWhere/updateId fallback for unit $unitId failed: $e');
                }
              }

              if (!unitOk) {
                // per-field updateWhere
                bool allFieldOk = true;
                for (final entry in fields.entries) {
                  bool fOk = await api.updateWhere('id_product', unitId.toString(), entry.key, entry.value, token, project, collection, appid);
                  if (!fOk) {
                    fOk = await api.updateWhere('_id', unitId.toString(), entry.key, entry.value, token, project, collection, appid);
                  }
                  debugPrint('unit $unitId field ${entry.key} updateWhere -> $fOk');
                  if (!fOk) allFieldOk = false;
                  await Future.delayed(const Duration(milliseconds: 80));
                }
                unitOk = allFieldOk;
              }

              unitResults.add({'unit': unitId, 'success': unitOk});
            } catch (e) {
              debugPrint('Exception updating unit $unitId: $e');
              unitResults.add({'unit': unitId, 'success': false, 'error': e.toString()});
            }
            await Future.delayed(const Duration(milliseconds: 120));
          }

          final failed = unitResults.where((r) => r['success'] != true).toList();
          if (failed.isNotEmpty) {
            return {
              'success': false,
              'message': 'Beberapa unit gagal diperbarui',
              'details': unitResults,
              'product': updated.toJson(),
            };
          }
        }
      }

      return {'success': true, 'message': 'Produk berhasil diperbarui', 'product': updated.toJson()};
    }

    debugPrint('All update attempts failed — attempting to resolve server _id via selectWhere');

    // If we failed to update using provided ids, try to fetch actual document from server
    // using id_product and retry update with the server-side _id if found.
    if (product.id_product.isNotEmpty) {
      try {
        final selectRes = await api.selectWhere(token, project, collection, appid, 'id_product', product.id_product);
        debugPrint('selectWhere result: $selectRes');

        // parse response and attempt to extract _id or id
        dynamic parsed;
        try {
          parsed = selectRes is String ? jsonDecode(selectRes) : selectRes;
        } catch (_) {
          parsed = null;
        }

        if (parsed != null) {
          List docs = [];
          if (parsed is List) docs = parsed;
          else if (parsed is Map && parsed.containsKey('data') && parsed['data'] is List) docs = parsed['data'];

          if (docs.isNotEmpty) {
            final doc = docs.first;
            String serverId = '';
            if (doc is Map) {
              serverId = (doc['_id'] ?? doc['id'] ?? '').toString();
            }

            if (serverId.isNotEmpty) {
              debugPrint('Found server id: $serverId — retrying updateId with this id');
              final fieldList = fields.keys.join(',');
              final valueList = fields.values.map((v) => v.replaceAll(',', '\\,')).join(',');
              final retryOk = await api.updateId(fieldList, valueList, token, project, collection, appid, serverId);
              debugPrint('Retry updateId with serverId -> $retryOk');
              if (retryOk == true) {
                return {'success': true, 'message': 'Produk berhasil diperbarui (via server _id)', 'product': updated.toJson()};
              }
            }
          }
        }
      } catch (e) {
        debugPrint('selectWhere fallback failed: $e');
      }
    }

    debugPrint('All update attempts (including selectWhere fallback) failed');
    return {'success': false, 'message': 'Gagal memperbarui produk di server'};
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