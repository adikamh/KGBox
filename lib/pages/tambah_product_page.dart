// lib/pages/add_product_page.dart
import 'package:flutter/material.dart';
import '../screens/tambah_product_screen.dart';

class AddProductPage extends StatefulWidget {
  final String userRole;
  final String? barcode;
  final String? ownerId;
  final Function(Map<String, dynamic>)? onProductAdded;
  
  const AddProductPage({
    super.key,
    required this.userRole,
    this.barcode,
    this.ownerId,
    this.onProductAdded,
  });

  @override
  State<AddProductPage> createState() => _AddProductPageState();
}

class _AddProductPageState extends State<AddProductPage> {
  final AddProductScreen _controller = AddProductScreen();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();
  final TextEditingController _merekController = TextEditingController();
  final TextEditingController _hargaController = TextEditingController();
  final TextEditingController _jumlahController = TextEditingController(text: '1');
  final TextEditingController _tanggalExpiredController = TextEditingController();
  
  bool _isLoading = false;
  bool _jumlahFromScan = false;
  Map<String, int>? _scannedCountsMap;
  final List<String> _barcodeList = [];
  String _selectedCategory = 'Makanan';

  @override
  void initState() {
    super.initState();
    
    _controller.initialize(
      barcode: widget.barcode,
      ownerId: widget.ownerId,
      nameCtrl: _nameController,
      codeCtrl: _codeController,
      merekCtrl: _merekController,
      hargaCtrl: _hargaController,
      jumlahCtrl: _jumlahController,
      tanggalExpiredCtrl: _tanggalExpiredController,
    );
    
    _selectedCategory = _controller.selectedCategory;
    // Ensure code field shows initial generated code
    _codeController.text = _controller.productCode;
    // If initial barcode provided, add to barcode list (avoid duplicates)
    if (widget.barcode != null && widget.barcode!.isNotEmpty) {
      if (!_barcodeList.contains(widget.barcode!)) {
        _barcodeList.add(widget.barcode!);
      }
      _codeController.text = _barcodeList.join(',');
      _jumlahController.text = _barcodeList.length.toString();
      _jumlahFromScan = _barcodeList.isNotEmpty;
      // rebuild scanned counts map from barcode list
      _scannedCountsMap = {};
      for (final b in _barcodeList) {
        _scannedCountsMap![b] = (_scannedCountsMap![b] ?? 0) + 1;
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: const Text('Tambah Produk Baru'),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.save),
          onPressed: _submitForm,
          tooltip: 'Simpan Produk',
        ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            _buildProductInfoCard(),
            const SizedBox(height: 24),
            _buildActionButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildProductInfoCard() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            const SizedBox(height: 18),
            
            // Nama Produk
            _buildTextField(
              label: 'Nama Produk *',
              controller: _nameController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama produk wajib diisi';
                }
                return null;
              },
            ),
            
            // Kode Produk
            _buildCodeField(),
            
            // Kategori
            _buildCategoryField(),
            
            // Merek Produk
            _buildTextField(
              label: 'Merek Produk *',
              controller: _merekController,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Merek produk wajib diisi';
                }
                return null;
              },
            ),
            
            // Harga Produk
            _buildTextField(
              label: 'Harga Produk *',
              controller: _hargaController,
              keyboardType: TextInputType.number,
              prefixText: 'Rp ',
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Harga produk wajib diisi';
                }
                if (int.tryParse(value) == null) {
                  return 'Harga harus berupa angka';
                }
                return null;
              },
            ),
            
            // Jumlah Stok (tampilkan tooltip jika berasal dari hasil scan)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text(
                      'Jumlah Stok *',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (_jumlahFromScan)
                      Tooltip(
                        message: 'Jumlah berasal dari hasil scan (otomatis)',
                        child: Icon(Icons.info_outline, color: Colors.blue.shade700, size: 18),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _jumlahController,
                  readOnly: _jumlahFromScan,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    contentPadding: const EdgeInsets.symmetric(
                      vertical: 12,
                      horizontal: 12,
                    ),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Jumlah stok wajib diisi';
                    }
                    if (int.tryParse(value) == null) {
                      return 'Jumlah harus berupa angka';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
            
            // Tanggal Expired
            _buildDateField(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return const Row(
      children: [
        Icon(Icons.add_circle_outline, color: Colors.blue),
        SizedBox(width: 12),
        Text(
          "Informasi Produk",
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
    bool readOnly = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          readOnly: readOnly,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(
              vertical: 12,
              horizontal: 12,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            prefixText: prefixText,
          ),
          validator: validator,
          onChanged: onChanged,
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kode Produk *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            Expanded(
              child: TextFormField(
                controller: _codeController,
                readOnly: true,
                decoration: InputDecoration(
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 12,
                    horizontal: 12,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.qr_code_2, color: Colors.blue),
                onPressed: _scanBarcode,
                tooltip: 'Scan Barcode',
              ),
            ),
            const SizedBox(width: 6),
            Container(
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: IconButton(
                icon: const Icon(Icons.list, color: Colors.black54),
                onPressed: _showBarcodePreview,
                tooltip: 'Preview / Edit Kode Produk',
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Future<void> _showBarcodePreview() async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      builder: (ctx) {
        return StatefulBuilder(builder: (ctx2, sbSetState) {
          // compute counts from _barcodeList
          final Map<String, int> counts = {};
          for (final b in _barcodeList) {
            counts[b] = (counts[b] ?? 0) + 1;
          }

          void applyChanges() {
            // update controllers and maps in parent state
            setState(() {
              _codeController.text = _barcodeList.join(',');
              _jumlahController.text = _barcodeList.length.toString();
              _jumlahFromScan = _barcodeList.isNotEmpty;
              // rebuild scannedCountsMap
              _scannedCountsMap = {};
              for (final b in _barcodeList) {
                _scannedCountsMap![b] = (_scannedCountsMap![b] ?? 0) + 1;
              }
            });
            sbSetState(() {});
          }

          if (_barcodeList.isEmpty) {
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Tidak ada barcode.'),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text('Tutup'),
                  ),
                ],
              ),
            );
          }

          return Padding(
            padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
            child: SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Preview Kode Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        Text('${_barcodeList.length} items')
                      ],
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: ListView(
                      padding: const EdgeInsets.all(12),
                      children: counts.entries.map((e) {
                        final code = e.key;
                        final cnt = e.value;
                        return Card(
                          child: ListTile(
                            title: Text(code),
                            subtitle: Text('Jumlah: $cnt'),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.remove_circle_outline, color: Colors.orange),
                                  tooltip: 'Hapus 1',
                                  onPressed: () {
                                    // remove one occurrence
                                    final idx = _barcodeList.indexOf(code);
                                    if (idx >= 0) {
                                      setState(() => _barcodeList.removeAt(idx));
                                      sbSetState(() {});
                                      applyChanges();
                                    }
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                                  tooltip: 'Hapus semua',
                                  onPressed: () {
                                    setState(() => _barcodeList.removeWhere((x) => x == code));
                                    sbSetState(() {});
                                    applyChanges();
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  tooltip: 'Edit',
                                  onPressed: () async {
                                    final TextEditingController editCtrl = TextEditingController(text: code);
                                    final res = await showDialog<String?>(
                                      context: ctx,
                                      builder: (dctx) => AlertDialog(
                                        title: const Text('Edit Kode'),
                                        content: TextField(controller: editCtrl, decoration: const InputDecoration(labelText: 'Kode baru')),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(dctx), child: const Text('Batal')),
                                          TextButton(onPressed: () => Navigator.pop(dctx, editCtrl.text.trim()), child: const Text('Simpan')),
                                        ],
                                      ),
                                    );
                                    if (res != null && res.isNotEmpty && res != code) {
                                      // prevent creating duplicates via edit
                                      if (_barcodeList.contains(res)) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('Tidak dapat mengganti dengan $res karena sudah ada di daftar.'), backgroundColor: Colors.orange),
                                        );
                                      } else {
                                        // replace all occurrences of code with res
                                        for (int i = 0; i < _barcodeList.length; i++) {
                                          if (_barcodeList[i] == code) _barcodeList[i] = res;
                                        }
                                        sbSetState(() {});
                                        applyChanges();
                                      }
                                    }
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(ctx);
                            },
                            child: const Text('Tutup')),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              // finalize and close
                              applyChanges();
                              Navigator.pop(ctx);
                            },
                            child: const Text('Simpan Perubahan')),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        });
      },
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Kategori *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        DropdownButtonFormField<String>(
          initialValue: _selectedCategory,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          items: _controller.categories
              .map((c) => DropdownMenuItem(
                    value: c,
                    child: Text(c),
                  ))
              .toList(),
          onChanged: (value) {
            if (value != null) {
              setState(() {
                _selectedCategory = value;
                // Update controller's selectedCategory but do NOT change product code
                _controller.selectedCategory = value;
              });
            }
          },
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Tanggal Expired *',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: _tanggalExpiredController,
          readOnly: true,
          decoration: InputDecoration(
            hintText: 'YYYY-MM-DD',
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            suffixIcon: IconButton(
              icon: const Icon(Icons.calendar_today, color: Colors.blue),
              onPressed: () => _controller.selectExpiredDate(context),
              tooltip: 'Pilih Tanggal',
            ),
          ),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Tanggal expired wajib diisi';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey.shade400),
              backgroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Batal',
              style: TextStyle(color: Colors.black87),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: const Color(0xFF2965C0),
            ),
            onPressed: _submitForm,
            child: const Text(
              'Simpan Produk',
              style: TextStyle(color: Colors.white),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _scanBarcode() async {
    final scanResult = await _controller.scanBarcode(context);
    if (scanResult != null && mounted) {
      setState(() {
        // If scanner returned a single barcode string -> append to barcode list
        if (scanResult is String) {
          final scannedCode = scanResult;
          if (_barcodeList.contains(scannedCode)) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Barcode $scannedCode sudah ada. Duplikat tidak diperbolehkan.'), backgroundColor: Colors.orange),
            );
            return;
          }
          _barcodeList.add(scannedCode);

          _codeController.text = _barcodeList.join(',');
          _controller.productId = _barcodeList.first;
          _controller.productCode = _barcodeList.first;
          if (_controller.codeController != null) {
            _controller.codeController!.text = _barcodeList.first;
          }

          _jumlahController.text = _barcodeList.length.toString();
          _jumlahFromScan = true;

          // update scanned counts map
          _scannedCountsMap = {};
          for (final b in _barcodeList) {
            _scannedCountsMap![b] = (_scannedCountsMap![b] ?? 0) + 1;
          }
        }

        // If scanner returned multiple scanned counts -> expand and append (skip duplicates)
        else if (scanResult is Map) {
          final Map map = scanResult;
          if (map.isEmpty) return;
          final List<String> duplicates = [];
          // expand each barcode by its count and append but skip duplicates
          map.forEach((key, value) {
            final b = key.toString();
            final count = int.tryParse(value.toString()) ?? 0;
            for (int i = 0; i < count; i++) {
              if (_barcodeList.contains(b)) {
                if (!duplicates.contains(b)) duplicates.add(b);
              } else {
                _barcodeList.add(b);
              }
            }
          });
          if (duplicates.isNotEmpty) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Barcode duplikat diabaikan: ${duplicates.join(', ')}'), backgroundColor: Colors.orange),
            );
          }

          if (_barcodeList.isNotEmpty) {
            _codeController.text = _barcodeList.join(',');
            _controller.productId = _barcodeList.first;
            _controller.productCode = _barcodeList.first;
            if (_controller.codeController != null) {
              _controller.codeController!.text = _barcodeList.first;
            }

            _jumlahController.text = _barcodeList.length.toString();
            _jumlahFromScan = true;

            // store full map for later batch insert (aggregate from barcodeList)
            _scannedCountsMap = {};
            for (final b in _barcodeList) {
              _scannedCountsMap![b] = (_scannedCountsMap![b] ?? 0) + 1;
            }
          }
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Ensure there are no duplicate barcodes before submitting
    if (_barcodeList.isNotEmpty) {
      final Map<String, int> check = {};
      for (final b in _barcodeList) {
        check[b] = (check[b] ?? 0) + 1;
      }
      final dupes = check.entries.where((e) => e.value > 1).map((e) => e.key).toList();
      if (dupes.isNotEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Terdapat barcode duplikat: ${dupes.join(', ')}. Hapus atau edit sebelum menyimpan.'), backgroundColor: Colors.orange),
        );
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> result;
    if (_barcodeList.isNotEmpty) {
      // send one product per barcode occurrence
      result = await _controller.addProductsFromScans(_barcodeList);
    } else {
      result = await _controller.addProduct();
    }

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      // Show success message
      String msg = result['message'] ?? 'Operasi berhasil';
      // If batch (aggregated) we may have 'total'
      if (result['total'] != null) {
        msg = '$msg — Total jumlah: ${result['total']}';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.green,
        ),
      );

      // Callback jika ada
      if (_scannedCountsMap != null && _scannedCountsMap!.isNotEmpty) {
        if (widget.onProductAdded != null && result['product'] != null) {
          widget.onProductAdded!(result['product']);
        }
      } else {
        if (widget.onProductAdded != null && result['product'] != null) {
          widget.onProductAdded!(result['product']);
        }
      }

      // Navigate back
      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message'] ?? 'Terjadi kesalahan'),
          backgroundColor: Colors.red,
        ),
      );

      // Highlight error fields jika ada
      if (result['errors'] != null) {
        // ignore: unused_local_variable
        final errors = result['errors'] as Map<String, String?>;
        // Anda bisa menambahkan logika untuk highlight field error
      }
    }
  }
}