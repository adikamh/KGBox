import 'package:flutter/material.dart';

import 'barcode_scanner_screens.dart';
import '../../app.dart';

import '../../goclaud/resetapi.dart';
import '../../goclaud/config.dart';
import '../../goclaud/product_model.dart';

class AddProdukScreen extends StatefulWidget {
  final Function(Map<String, dynamic>)? onProductAdded;
  final String userRole;
  final String? barcode;

  const AddProdukScreen({
    super.key,
    this.onProductAdded,
    required this.userRole,
    this.barcode,
  });

  @override
  State<AddProdukScreen> createState() => _AddProdukScreenState();
}

class _AddProdukScreenState extends State<AddProdukScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _codeController = TextEditingController();
  final _merekController = TextEditingController();
  final _hargaController = TextEditingController();
  final _jumlahController = TextEditingController(text: '1');


  final List<String> _categories = ['Makanan', 'Minuman'];
  String _selectedCategory = 'Makanan';

  late final String _productId;
  late final String _productCode;

  @override
  void initState() {
    super.initState();
    _productId = widget.barcode ?? _generateProductId();
    _productCode = widget.barcode ?? _generateProductCode();
    _codeController.text = _productCode;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    _merekController.dispose();
    _hargaController.dispose();
    _jumlahController.dispose();
    super.dispose();
  }

  String _generateProductId() =>
      'PRD${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}';

  String _generateProductCode() {
    final namePrefix = _nameController.text.isNotEmpty
        ? _nameController.text.substring(0, 1).toUpperCase()
        : 'P';
    final catPrefix = _selectedCategory.substring(0, 1).toUpperCase();
    final random = DateTime.now().millisecondsSinceEpoch.toString().substring(9);
    return '$namePrefix$catPrefix$random';
  }


  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    // Validasi input numerik
    final hargaText = _hargaController.text.trim();
    final jumlahText = _jumlahController.text.trim();

    if (hargaText.isEmpty || int.tryParse(hargaText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Harga harus berupa angka')),
      );
      return;
    }

    if (jumlahText.isEmpty || int.tryParse(jumlahText) == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah harus berupa angka')),
      );
      return;
    }

    // Buat ProductModel
    final product = ProductModel(
      id: _productId,
      id_product: _productId,
      nama_product: _nameController.text.trim(),
      kategori_product: _selectedCategory,
      merek_product: _merekController.text.trim(),
      tanggal_beli: _formatCurrentDateTime(),
      harga_product: hargaText,
      jumlah_produk: jumlahText,
    );

    // Kirim ke server
    final svc = DataService();
    try {
      print('Mengirim data ke GoClaud: ${product.toJson()}');
      final response = await svc.insertProduct(
        appid,
        product.id_product,
        product.nama_product,
        product.kategori_product,
        product.merek_product,
        product.tanggal_beli,
        product.harga_product,
        product.jumlah_produk,
      );
      print('Respons dari GoClaud: $response');

      // Tampilkan sukses dan kembali
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Produk berhasil ditambahkan'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true); // Kirim `true` untuk menandakan produk berhasil ditambahkan
      }
    } catch (e) {
      print('Error adding product: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal menambahkan produk: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  String _formatCurrentDateTime() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tambah Produk Baru',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _addProduct,
            tooltip: 'Simpan Produk',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
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
                      ),
                      const SizedBox(height: 24),
                      
                      // Nama Produk
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk *',
                          border: OutlineInputBorder(),
                          hintText: 'Contoh: Indomie Goreng',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Nama produk wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Kode Produk
                      TextFormField(
                        controller: _codeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Kode Produk *',
                          border: const OutlineInputBorder(),
                          hintText: 'Kode otomatis',
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () async {
                              final scannedCode = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BarcodeScannerScreen(),
                                ),
                              );
                              if (scannedCode != null && mounted) {
                                setState(() {
                                  _codeController.text = scannedCode;
                                });
                              }
                            },
                            tooltip: 'Scan Barcode',
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Kode produk wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Kategori
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori *',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map((category) => DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _selectedCategory = value;
                            });
                          }
                        },
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Pilih kategori produk';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Merek Produk
                      TextFormField(
                        controller: _merekController,
                        decoration: const InputDecoration(
                          labelText: 'Merek Produk *',
                          border: OutlineInputBorder(),
                          hintText: 'Contoh: Indofood',
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Merek produk wajib diisi';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      // Harga Produk
                      TextFormField(
                        controller: _hargaController,
                        decoration: const InputDecoration(
                          labelText: 'Harga Produk *',
                          border: OutlineInputBorder(),
                          prefixText: 'Rp ',
                          hintText: 'Contoh: 2500',
                        ),
                        keyboardType: TextInputType.number,
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
                      const SizedBox(height: 16),
                      
                      // Jumlah Stok
                      TextFormField(
                        controller: _jumlahController,
                        decoration: const InputDecoration(
                          labelText: 'Jumlah Stok *',
                          border: OutlineInputBorder(),
                          hintText: 'Contoh: 100',
                        ),
                        keyboardType: TextInputType.number,
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              
              // Tombol Aksi
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text(
                        'Batal',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addProduct,
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        backgroundColor: Colors.blue,
                      ),
                      child: const Text(
                        'Simpan Produk',
                        style: TextStyle(fontSize: 16, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
