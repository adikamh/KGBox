import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'barcode_scanner_screens.dart';
import '../../app.dart';
import 'manage_products_screen.dart'; // <-- import store static dari ManageProductsScreen
import '../../goclaud/resetapi.dart'; // <-- NEW
import '../../goclaud/config.dart'; // <-- NEW
import '../../goclaud/product_model.dart'; // <-- NEW: gunakan ProductModel


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
  final _jenisController = TextEditingController();

  XFile? _imageFile;
  String? _webImagePath;

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
    _jenisController.dispose();
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

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        if (kIsWeb) {
          _webImagePath = picked.path;
        } else {
          _imageFile = picked;
        }
      });
    }
  }

  Future<void> _addProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final imageUrl = kIsWeb ? (_webImagePath ?? '') : (_imageFile?.path ?? '');

    // buat ProductModel sesuai product_model.dart (semua field String non-nullable)
    final pm = ProductModel(
      id: _productId,
      id_product: _productId,
      nama_product: _nameController.text.trim(),
      kategori_product: _selectedCategory,
      jenis_product: _jenisController.text.trim(),
      gambar_product: imageUrl,
      tanggal_beli: ManageProductsScreen.formatCurrentDateTime(),
      harga_product: '', // default, tambahkan field di form kalau diperlukan
      jumlah_produk: '1', // default
    );

    // map ProductModel ke format UI
    final uiItem = {
      'id': pm.id_product,
      'name': pm.nama_product,
      'code': pm.id_product,
      'category': pm.kategori_product,
      'jenis': pm.jenis_product,
      'has_image': pm.gambar_product.isNotEmpty,
      'image_url': pm.gambar_product,
      'last_updated': pm.tanggal_beli,
      'status': 'active',
    };

    // 1) Tambah lokal segera supaya ManageProductsScreen langsung update
    // gunakan callback saja (caller ManageProductsScreen sudah menerapkan addProduct)
    widget.onProductAdded?.call(uiItem);

    // 2) Kirim ke server di background (tidak menunggu)
    final svc = DataService();
    svc.insertProduct(
      appid,
      pm.id_product,
      pm.nama_product,
      pm.kategori_product,
      pm.jenis_product,
      pm.gambar_product,
      pm.tanggal_beli,
      pm.harga_product,
      pm.jumlah_produk,
    ).then((resp) {
      // opsional: jika ingin sinkron ulang dari server ketika insert sukses, bisa panggil _loadProductsFromServer dari ManageProductsScreen
      print('[goclaud.insertProduct] resp: $resp');
    }).catchError((e) {
      print('[goclaud.insertProduct] error: $e');
      // tidak melakukan rollback otomatis untuk menjaga UX; jika perlu rollback, implementasikan logika tambahan
    });

    // 3) Beri feedback dan kembali cepat ke layar sebelumnya
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Produk ditambahkan (offline).'), backgroundColor: Colors.green),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: CustomAppBar(
        title: 'Tambah Produk Baru',
        showBackButton: true,
        actions: [
          IconButton(icon: const Icon(Icons.save), onPressed: _addProduct),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
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
                          )
                        ],
                      ),
                      const SizedBox(height: 24),
                      GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 120,
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: kIsWeb
                              ? (_webImagePath != null
                                  ? Image.network(_webImagePath!, fit: BoxFit.cover)
                                  : const Icon(Icons.image, size: 50, color: Colors.grey))
                              : (_imageFile != null
                                  ? Image.file(File(_imageFile!.path), fit: BoxFit.cover)
                                  : const Icon(Icons.image, size: 50, color: Colors.grey)),
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _nameController,
                        decoration: const InputDecoration(
                          labelText: 'Nama Produk *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Nama produk wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _codeController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Kode Produk *',
                          border: const OutlineInputBorder(),
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.qr_code_scanner),
                            onPressed: () async {
                              final scannedCode = await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const BarcodeScannerScreen(),
                                ),
                              );
                              if (scannedCode != null) {
                                setState(() {
                                  _codeController.text = scannedCode;
                                });
                              }
                            },
                          ),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Kode produk wajib diisi' : null,
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCategory,
                        decoration: const InputDecoration(
                          labelText: 'Kategori *',
                          border: OutlineInputBorder(),
                        ),
                        items: _categories
                            .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                            .toList(),
                        onChanged: (v) {
                          setState(() => _selectedCategory = v!);
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _jenisController,
                        decoration: const InputDecoration(
                          labelText: 'Jenis *',
                          border: OutlineInputBorder(),
                        ),
                        validator: (v) =>
                            v!.isEmpty ? 'Jenis wajib diisi' : null,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                      child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Batal'))),
                  const SizedBox(width: 16),
                  Expanded(
                      child: ElevatedButton(
                          onPressed: _addProduct, child: const Text('Simpan Produk'))),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
