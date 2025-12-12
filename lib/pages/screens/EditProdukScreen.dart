import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:kg_dns/goclaud/config.dart';
import 'package:kg_dns/goclaud/resetapi.dart';
import 'package:kg_dns/goclaud/product_model.dart';

class EditProdukScreen extends StatefulWidget {
  final ProductModel product;

  const EditProdukScreen({super.key, required this.product});

  @override
  State<EditProdukScreen> createState() => _EditProdukScreenState();
}

class _EditProdukScreenState extends State<EditProdukScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  // Controller untuk setiap field
  late TextEditingController _idProductController;
  late TextEditingController _namaProductController;
  late TextEditingController _kategoriController;
  late TextEditingController _merekController;
  late TextEditingController _tanggalBeliController;
  late TextEditingController _hargaController;
  late TextEditingController _jumlahController;

  // Variabel untuk tanggal
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    // Inisialisasi controller dengan data produk yang ada
    _idProductController = TextEditingController(text: widget.product.id_product);
    _namaProductController = TextEditingController(text: widget.product.nama_product);
    _kategoriController = TextEditingController(text: widget.product.kategori_product);
    _merekController = TextEditingController(text: widget.product.merek_product);
    _hargaController = TextEditingController(text: widget.product.harga_product);
    _jumlahController = TextEditingController(text: widget.product.jumlah_produk);
    
    // Parse tanggal beli
    if (widget.product.tanggal_beli.isNotEmpty) {
      try {
        _selectedDate = DateFormat('yyyy-MM-dd').parse(widget.product.tanggal_beli);
        _tanggalBeliController = TextEditingController(
          text: DateFormat('dd/MM/yyyy').format(_selectedDate!),
        );
      } catch (e) {
        _selectedDate = null;
        _tanggalBeliController = TextEditingController(text: widget.product.tanggal_beli);
      }
    } else {
      _selectedDate = null;
      _tanggalBeliController = TextEditingController();
    }
  }

  @override
  void dispose() {
    _idProductController.dispose();
    _namaProductController.dispose();
    _kategoriController.dispose();
    _merekController.dispose();
    _tanggalBeliController.dispose();
    _hargaController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  // Fungsi untuk memilih tanggal
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
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
    
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _tanggalBeliController.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  // Fungsi untuk format harga
  String _formatHarga(String value) {
    if (value.isEmpty) return '';
    final number = int.tryParse(value.replaceAll('.', '')) ?? 0;
    return NumberFormat.currency(locale: 'id_ID', symbol: '', decimalDigits: 0).format(number);
  }

  // Fungsi untuk simpan perubahan
  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      // Format tanggal untuk disimpan ke API
      String tanggalFormatted = '';
      if (_selectedDate != null) {
        tanggalFormatted = DateFormat('yyyy-MM-dd').format(_selectedDate!);
      } else if (_tanggalBeliController.text.isNotEmpty) {
        try {
          final parsedDate = DateFormat('dd/MM/yyyy').parse(_tanggalBeliController.text);
          tanggalFormatted = DateFormat('yyyy-MM-dd').format(parsedDate);
        } catch (e) {
          tanggalFormatted = _tanggalBeliController.text;
        }
      }

      // Format harga (hapus titik)
      String hargaFormatted = _hargaController.text.replaceAll('.', '');

      // Coba update menggunakan satu API call untuk multiple fields
      final success = await _updateMultipleFields(
        fields: {
          'nama_product': _namaProductController.text,
          'kategori_product': _kategoriController.text,
          'merek_product': _merekController.text,
          'tanggal_beli': tanggalFormatted,
          'harga_product': hargaFormatted,
          'jumlah_produk': _jumlahController.text,
        },
        id: widget.product.id,
      );

      if (success) {
        // Jika berhasil, buat objek produk yang diperbarui
        final updatedProduct = ProductModel(
          id: widget.product.id,
          id_product: _idProductController.text,
          nama_product: _namaProductController.text,
          kategori_product: _kategoriController.text,
          merek_product: _merekController.text,
          tanggal_beli: tanggalFormatted,
          harga_product: hargaFormatted,
          jumlah_produk: _jumlahController.text,
        );

        // Tampilkan snackbar sukses
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Produk berhasil diperbarui'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        // Kembali ke halaman sebelumnya dengan data yang diperbarui
        Navigator.of(context).pop(updatedProduct);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gagal memperbarui produk'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Fungsi untuk update multiple fields sekaligus
  Future<bool> _updateMultipleFields({
    required Map<String, String> fields,
    required String id,
  }) async {
    try {
      // Konversi map ke format fields dan values yang dipisahkan koma
      String fieldList = fields.keys.join(',');
      String valueList = fields.values.map((v) => v.replaceAll(',', '\\,')).join(',');

      print('Update fields: $fieldList');
      print('Update values: $valueList');
      print('ID: $id');
      // Use shared DataService helper to perform the update
      final ds = DataService();
      print('Calling multi-field update via DataService.updateId');
      final ok = await ds.updateId(fieldList, valueList, token, project, collection, appid, id);
      print('DataService.updateId result: $ok');

      if (ok) {
        // Verify the update by fetching the document and comparing fields
        try {
          final docBody = await ds.selectId(token, project, collection, appid, id);
          print('SelectId after update: $docBody');
          // docBody may be JSON array or object; attempt to parse
          final parsed = json.decode(docBody);
          Map<String, dynamic>? obj;
          if (parsed is List && parsed.isNotEmpty) {
            obj = parsed[0] as Map<String, dynamic>;
          } else if (parsed is Map) {
            if (parsed.containsKey('data') && parsed['data'] is List && parsed['data'].isNotEmpty) {
              obj = parsed['data'][0] as Map<String, dynamic>;
            } else {
              obj = parsed as Map<String, dynamic>;
            }
          }
          if (obj != null) {
            // Check each updated field matches expected value
            bool allMatch = true;
            fields.forEach((k, v) {
              var serverVal = (obj![k] ?? '').toString();
              serverVal = serverVal.replaceAll('\n', ' ').trim();
              final expected = v.toString().trim();
              if (serverVal != expected) {
                allMatch = false;
                print('Field mismatch for $k: expected="$expected" got="$serverVal"');
              }
            });
            if (allMatch) return true;
            print('Verification failed: server values did not match expected.');

            // Fallback: try updating each field individually
            print('Attempting per-field updates as fallback');
            bool allFieldOk = true;
            for (final entry in fields.entries) {
              final fOk = await ds.updateId(entry.key, entry.value, token, project, collection, appid, id);
              print('Update field ${entry.key} result: $fOk');
              if (!fOk) allFieldOk = false;
              await Future.delayed(const Duration(milliseconds: 200));
            }

            if (allFieldOk) {
              try {
                final docBody2 = await ds.selectId(token, project, collection, appid, id);
                print('SelectId after per-field updates: $docBody2');
                final parsed2 = json.decode(docBody2);
                Map<String, dynamic>? obj2;
                if (parsed2 is List && parsed2.isNotEmpty) {
                  obj2 = parsed2[0] as Map<String, dynamic>;
                } else if (parsed2 is Map) {
                  if (parsed2.containsKey('data') && parsed2['data'] is List && parsed2['data'].isNotEmpty) {
                    obj2 = parsed2['data'][0] as Map<String, dynamic>;
                  } else {
                    obj2 = parsed2 as Map<String, dynamic>;
                  }
                }
                if (obj2 != null) {
                  bool allMatch2 = true;
                  fields.forEach((k, v) {
                    var serverVal = (obj2![k] ?? '').toString();
                    serverVal = serverVal.replaceAll('\n', ' ').trim();
                    final expected = v.toString().trim();
                    if (serverVal != expected) {
                      allMatch2 = false;
                      print('Field mismatch for $k after per-field: expected="$expected" got="$serverVal"');
                    }
                  });
                  if (allMatch2) return true;
                }
              } catch (e) {
                print('Error verifying after per-field updates: $e');
              }
            }

            return false;
          }
        } catch (e) {
          print('Error verifying update: $e');
        }
      }
      return false;
    } catch (e) {
      print('Error updating multiple fields: $e');
      return false;
    }
  }

  // Validator untuk form
  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    return null;
  }

  String? _validateNumber(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName harus diisi';
    }
    final number = int.tryParse(value.replaceAll('.', ''));
    if (number == null || number <= 0) {
      return '$fieldName harus berupa angka positif';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Edit Produk',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
        actions: [
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white.withOpacity(0.8)),
                ),
              ),
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Informasi Produk
                Card(
                  elevation: 0,
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.grey[200]!),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Header Informasi Produk
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Icon(
                                Icons.edit_rounded,
                                color: Colors.blue[700],
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Edit Informasi Produk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ID Produk (read-only)
                        TextFormField(
                          controller: _idProductController,
                          decoration: InputDecoration(
                            labelText: 'ID Produk',
                            prefixIcon: const Icon(Icons.qr_code_rounded),
                            filled: true,
                            fillColor: Colors.grey[100],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            enabled: false,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Nama Produk
                        TextFormField(
                          controller: _namaProductController,
                          decoration: InputDecoration(
                            labelText: 'Nama Produk',
                            prefixIcon: const Icon(Icons.shopping_bag_rounded),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          validator: (value) => _validateRequired(value, 'Nama produk'),
                        ),
                        const SizedBox(height: 16),

                        // Kategori Produk
                        TextFormField(
                          controller: _kategoriController,
                          decoration: InputDecoration(
                            labelText: 'Kategori',
                            prefixIcon: const Icon(Icons.category_rounded),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          validator: (value) => _validateRequired(value, 'Kategori'),
                        ),
                        const SizedBox(height: 16),

                        // Merek Produk
                        TextFormField(
                          controller: _merekController,
                          decoration: InputDecoration(
                            labelText: 'Merek',
                            prefixIcon: const Icon(Icons.business_rounded),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          validator: (value) => _validateRequired(value, 'Merek'),
                        ),
                        const SizedBox(height: 16),

                        // Tanggal Beli
                        TextFormField(
                          controller: _tanggalBeliController,
                          decoration: InputDecoration(
                            labelText: 'Tanggal Beli',
                            prefixIcon: const Icon(Icons.calendar_today_rounded),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.calendar_month_rounded),
                              onPressed: () => _selectDate(context),
                            ),
                          ),
                          readOnly: true,
                          onTap: () => _selectDate(context),
                          validator: (value) => _validateRequired(value, 'Tanggal beli'),
                        ),
                        const SizedBox(height: 16),

                        // Harga Produk
                        TextFormField(
                          controller: _hargaController,
                          decoration: InputDecoration(
                            labelText: 'Harga Produk',
                            prefixIcon: const Icon(Icons.attach_money_rounded),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                            suffixText: 'IDR',
                          ),
                          keyboardType: TextInputType.number,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              _hargaController.text = _formatHarga(value);
                              _hargaController.selection = TextSelection.fromPosition(
                                TextPosition(offset: _hargaController.text.length),
                              );
                            }
                          },
                          validator: (value) => _validateNumber(value, 'Harga'),
                        ),
                        const SizedBox(height: 16),

                        // Jumlah Produk
                        TextFormField(
                          controller: _jumlahController,
                          decoration: InputDecoration(
                            labelText: 'Jumlah Stok',
                            prefixIcon: const Icon(Icons.inventory_rounded),
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide(color: Colors.grey[300]!),
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          validator: (value) => _validateNumber(value, 'Jumlah stok'),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Tombol Aksi
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () {
                            Navigator.of(context).pop();
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.grey[200],
                            foregroundColor: Colors.grey[800],
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text(
                            'Batal',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _saveChanges,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue[700],
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            disabledBackgroundColor: Colors.blue[700]!.withOpacity(0.5),
                          ),
                          child: _isLoading
                              ? SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Text(
                                  'Simpan',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}