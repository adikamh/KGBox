import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/config.dart';
import '../services/restapi.dart';
import '../pages/catat_barang_keluar_page.dart';

class CatatBarangKeluarScreen extends StatefulWidget {
  const CatatBarangKeluarScreen({super.key});

  @override
  State<CatatBarangKeluarScreen> createState() => _CatatBarangKeluarScreenState();
}

class _CatatBarangKeluarScreenState extends State<CatatBarangKeluarScreen> {
  final TextEditingController _namaTokoController = TextEditingController();
  final TextEditingController _alamatTokoController = TextEditingController();
  final TextEditingController _namaPemilikController = TextEditingController();

  List<Map<String, dynamic>> _scannedProducts = [];
  List<Map<String, dynamic>> _allProducts = [];

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  Future<void> _loadAllProducts() async {
    try {
      final api = DataService();
      final result = await api.selectAll(token, project, collection, appid).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> jsonResponse = json.decode(result);
      final List<dynamic> data = jsonResponse['data'] ?? [];

      if (mounted) {
        setState(() {
          _allProducts = data.map<Map<String, dynamic>>((p) {
            return {
              'id': p['id_product'] ?? '',
              'nama': p['nama_product'] ?? 'Tidak ada nama',
              'kategori': p['kategori_product'] ?? 'Umum',
              'harga': int.tryParse(p['harga_product']?.toString() ?? '0') ?? 0,
              'stok': int.tryParse(p['jumlah_produk']?.toString() ?? '0') ?? 0,
              'full': p,
            };
          }).toList();
        });
      }
    } catch (e) {
      debugPrint("Error loading products: $e");
    }
  }

  void openScanner(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScannerScreen(
          allProducts: _allProducts,
          scannedProducts: _scannedProducts,
          onProductsChanged: (updatedProducts) {
            setState(() {
              _scannedProducts = updatedProducts;
            });
          },
        ),
      ),
    );
  }

  double calculateTotal() {
    return _scannedProducts.fold<double>(
      0,
      (sum, p) {
        final harga = p['harga'] ?? 0;
        final jumlah = p['jumlah'] ?? 0;
        return sum + ((harga is int ? harga : int.tryParse(harga.toString()) ?? 0) *
                      (jumlah is int ? jumlah : int.tryParse(jumlah.toString()) ?? 0));
      },
    );
  }

  void submitForm(BuildContext context) {
    if (_namaTokoController.text.isEmpty ||
        _alamatTokoController.text.isEmpty ||
        _namaPemilikController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua field toko'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_scannedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal scan 1 barang'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Pengiriman ke ${_namaTokoController.text} dengan ${_scannedProducts.length} item berhasil disimpan',
        ),
        backgroundColor: Colors.green,
      ),
    );

    // Reset form
    _namaTokoController.clear();
    _alamatTokoController.clear();
    _namaPemilikController.clear();
    setState(() {
      _scannedProducts = [];
    });
  }

  void updateProductQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _scannedProducts[index]['jumlah'] = newQuantity;
      });
    } else {
      setState(() {
        _scannedProducts.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _alamatTokoController.dispose();
    _namaPemilikController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CatatBarangKeluarPage(
      namaTokoController: _namaTokoController,
      alamatTokoController: _alamatTokoController,
      namaPemilikController: _namaPemilikController,
      scannedProducts: _scannedProducts,
      total: calculateTotal(),
      onScanPressed: () => openScanner(context),
      onSubmitPressed: () => submitForm(context),
      onQuantityChanged: updateProductQuantity,
    );
  }
}

// Scanner Screen Logic
class ScannerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allProducts;
  final List<Map<String, dynamic>> scannedProducts;
  final Function(List<Map<String, dynamic>>) onProductsChanged;

  const ScannerScreen({
    required this.allProducts,
    required this.scannedProducts,
    required this.onProductsChanged,
    super.key,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> 
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedCode;

  late AnimationController _animController;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 180).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  void onBarcodeDetect(String barcode) {
    final code = barcode.trim();
    if (code.isEmpty) return;
    if (_isProcessing) return;
    if (_lastScannedCode == code) return;

    _lastScannedCode = code;
    _isProcessing = true;

    final foundProduct = widget.allProducts.firstWhere(
      (p) {
        final idStr = (p['id'] ?? '').toString();
        final idProduct = (p['full'] != null && p['full']['id_product'] != null)
            ? p['full']['id_product'].toString()
            : '';
        final nameStr = (p['nama'] ?? '').toString();
        return idStr == code || idProduct == code || idStr.contains(code) || idProduct.contains(code) || nameStr.toLowerCase() == code.toLowerCase();
      },
      orElse: () => <String, dynamic>{},
    );

    if (foundProduct.isNotEmpty) {
      final existingIndex = widget.scannedProducts.indexWhere((p) => p['id'] == foundProduct['id']);
      setState(() {
        if (existingIndex >= 0) {
          widget.scannedProducts[existingIndex]['jumlah'] = (widget.scannedProducts[existingIndex]['jumlah'] ?? 0) + 1;
        } else {
          widget.scannedProducts.add({
            ...foundProduct,
            'jumlah': 1,
          });
        }
      });

      HapticFeedback.mediumImpact();
      widget.onProductsChanged(List.from(widget.scannedProducts));
      showSnackbar('${foundProduct['nama']} ditambahkan', isError: false);
    } else {
      HapticFeedback.vibrate();
      showSnackbar('Produk tidak ditemukan: $code', isError: true);
    }

    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _lastScannedCode = null;
          _isProcessing = false;
        });
      }
    });
  }

  void showSnackbar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        duration: const Duration(milliseconds: 600),
      ),
    );
  }

  void switchCamera() {
    controller.switchCamera();
  }

  void toggleTorch() {
    controller.toggleTorch();
  }

  @override
  void dispose() {
    controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScannerPage(
      controller: controller,
      scanLineAnim: _scanLineAnim,
      scannedProductsCount: widget.scannedProducts.length,
      onBarcodeDetect: onBarcodeDetect,
      onSwitchCamera: switchCamera,
      onToggleTorch: toggleTorch,
    );
  }
}