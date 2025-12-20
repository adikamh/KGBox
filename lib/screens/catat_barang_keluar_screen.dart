import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../services/config.dart';
import '../services/restapi.dart';
import '../pages/catat_barang_keluar_page.dart';
import '../providers/auth_provider.dart';
import '../pages/tambah_product_page.dart';

class CatatBarangKeluarScreen extends StatefulWidget {
  const CatatBarangKeluarScreen({super.key});

  @override
  State<CatatBarangKeluarScreen> createState() => _CatatBarangKeluarScreenState();
}

class _CatatBarangKeluarScreenState extends State<CatatBarangKeluarScreen> {
  final TextEditingController _namaTokoController = TextEditingController();
  final TextEditingController _alamatTokoController = TextEditingController();
  final TextEditingController _namaPemilikController = TextEditingController();
  final TextEditingController _noTeleponController = TextEditingController();

  List<Map<String, dynamic>> _scannedProducts = [];
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoading = false;
  String ownerId = '';
  String staffId = '';

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize ownerId and staffId from AuthProvider
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      ownerId = user?.ownerId ?? user?.id ?? '';
      staffId = user?.id ?? '';
    } catch (_) {}
  }

  Future<void> _loadAllProducts() async {
    try {
      final api = DataService();
      // Load products from the `product` collection
      final result = await api.selectAll(token, project, 'product', appid).timeout(const Duration(seconds: 15));

      final Map<String, dynamic> jsonResponse = json.decode(result);
      final List<dynamic> data = jsonResponse['data'] ?? [];

      final mapped = data.map<Map<String, dynamic>>((p) {
        // normalize id: try several common fields
        final rawId = p['id_product'] ?? p['id'] ?? p['_id'] ?? '';
        final parsedId = rawId is Map ? (rawId['\$oid'] ?? rawId['oid'] ?? rawId.toString()) : rawId.toString();
        final barcodeField = p['barcode'] ?? p['kode'] ?? p['id_product'] ?? parsedId;
        final nama = p['nama_product'] ?? p['nama'] ?? p['name'] ?? 'Tidak ada nama';
        final kategori = p['kategori_product'] ?? p['kategori'] ?? 'Umum';
        final harga = int.tryParse(p['harga_product']?.toString() ?? p['harga']?.toString() ?? '0') ?? 0;
        final stok = int.tryParse(p['jumlah_produk']?.toString() ?? p['stok']?.toString() ?? '0') ?? 0;

        return {
          'id': parsedId,
          'id_product': p['id_product'] ?? parsedId,
          'barcode': barcodeField?.toString(),
          'nama': nama,
          'kategori': kategori,
          'harga': harga,
          'stok': stok,
          'full': p,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allProducts = mapped;
        });
      }

      debugPrint('Loaded ${_allProducts.length} products');
    } catch (e) {
      debugPrint("Error loading products: $e");
    }
  }

  void openScanner(BuildContext context) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membuka scanner...'), duration: Duration(milliseconds: 500)),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ScannerScreen(
            allProducts: _allProducts,
            scannedProducts: _scannedProducts,
            ownerId: ownerId,
            onProductsChanged: (updatedProducts) {
              if (mounted) {
                setState(() {
                  _scannedProducts = updatedProducts;
                });
              }
            },
          ),
        ),
      ).catchError((e) {
        debugPrint('Navigator push error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka scanner: $e')));
      });
    } catch (e) {
      debugPrint('openScanner exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka scanner: $e')));
    }
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

  Future<void> _submitForm(BuildContext context) async {
    // Validasi input
    if (_namaTokoController.text.isEmpty ||
        _alamatTokoController.text.isEmpty ||
        _namaPemilikController.text.isEmpty ||
        _noTeleponController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua field customer'),
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

    // Confirmation dialog with item summary before proceeding (this will reduce stock)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final totalHarga = calculateTotal();
        String formatRp(num value) {
          final v = value.toInt().toString();
          return v.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
        }

        return AlertDialog(
          title: const Text('Konfirmasi Pengiriman'),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Periksa daftar barang yang akan dikirim:'),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _scannedProducts.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (context, i) {
                      final p = _scannedProducts[i];
                      final nama = p['nama'] ?? 'Tidak ada nama';
                      final jumlah = (p['jumlah'] is int) ? p['jumlah'] as int : int.tryParse(p['jumlah']?.toString() ?? '0') ?? 0;
                      final harga = (p['harga'] is int) ? p['harga'] as int : int.tryParse(p['harga']?.toString() ?? '0') ?? 0;
                      final subtotal = harga * jumlah;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('$nama × $jumlah')),
                          Text('Rp ${formatRp(subtotal)}'),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Rp ${formatRp(totalHarga)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Ya, Simpan')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final api = DataService();
      
      // 1. Generate Customer ID
      final customerId = 'CUST${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}';
      
      // 2. Simpan ke Customer
      // Build customer payload with exact field names
      final customerMap = {
        'ownerid': ownerId,
        'customer_id': customerId,
        'nama_toko': _namaTokoController.text.trim(),
        'nama_pemilik_toko': _namaPemilikController.text.trim(),
        'no_telepon_customer': _noTeleponController.text.trim(),
        'alamat_toko': _alamatTokoController.text.trim(),
      };

      // ignore: unused_local_variable
      final customerResult = await api.insertOne(
        token,
        project,
        'customer',
        appid,
        customerMap,
      );
      
      // 3. Generate Order ID
      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}';
      final totalHarga = calculateTotal();
      
      // 4. Simpan ke Order
      // Build order payload (include customer info for easier querying)
      final orderMap = {
        'ownerid': ownerId,
        'customer_id': customerId,
        'order_id': orderId,
        'staff_id': staffId,
        'tanggal_order': DateTime.now().toIso8601String(),
        'total_harga': totalHarga.toString(),
        // duplicate some customer fields if desired by backend
        'nama_toko': _namaTokoController.text.trim(),
        'nama_pemilik_toko': _namaPemilikController.text.trim(),
        'no_telepon_customer': _noTeleponController.text.trim(),
        'alamat_toko': _alamatTokoController.text.trim(),
      };

      // ignore: unused_local_variable
      final orderResult = await api.insertOne(
        token,
        project,
        'order',
        appid,
        orderMap,
      );
      
      // 5. Simpan ke Order Items
      for (final product in _scannedProducts) {
        final productId = product['id'] ?? '';
        final jumlah = product['jumlah'] ?? 1;
        final hargaSatuan = product['harga'] ?? 0;
        final subtotal = (hargaSatuan is int ? hargaSatuan : int.tryParse(hargaSatuan.toString()) ?? 0) * jumlah;
        
        final orderItemMap = {
          'ownerid': ownerId,
          'order_id': orderId,
          'id_product': productId,
          'jumlah_produk': jumlah.toString(),
          'harga_satu_pack': hargaSatuan.toString(),
          'subtotal': subtotal.toString(),
        };

        await api.insertOne(
          token,
          project,
          'order_items',
          appid,
          orderItemMap,
        );
        
        // 6. Update stok produk (optional)
        await _updateProductStock(productId, jumlah);
      }
      
      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengiriman ke ${_namaTokoController.text} dengan ${_scannedProducts.length} item berhasil disimpan',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reset form
      _resetForm();
      
    } catch (e) {
      debugPrint("Error submitting form: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProductStock(String productId, int jumlahKeluar) async {
    try {
      final api = DataService();
      
      // Cari produk dari collection yang dikonfigurasi (lebih aman daripada hardcode "products")
      final result = await api.selectAll(token, project, collection, appid).timeout(const Duration(seconds: 15));
      final Map<String, dynamic> jsonResponse = json.decode(result);
      final List<dynamic> products = jsonResponse['data'] ?? [];

      final product = products.firstWhere((p) {
        final idProduct = (p['id_product'] ?? p['id'] ?? p['_id'] ?? '').toString();
        final barcode = (p['barcode'] ?? p['kode'] ?? '').toString();

        final normId = idProduct.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
        final normBarcode = barcode.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
        final normSearch = productId.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();

        return idProduct == productId || barcode == productId || normId == normSearch || normBarcode == normSearch;
      }, orElse: () => null);
      
      if (product != null) {
        final currentStock = int.tryParse(product['jumlah_produk']?.toString() ?? '0') ?? 0;
        final newStock = currentStock - jumlahKeluar;
        
        // Update stok via updateId endpoint (API expects update_field/update_value)
        final idToUpdate = (product['_id'] ?? product['id'] ?? '').toString();
        final safeNewStock = newStock < 0 ? 0 : newStock;

        debugPrint('Updating stock for id=$idToUpdate -> $safeNewStock');

        final success = await api.updateId(
          'jumlah_produk',
          safeNewStock.toString(),
          token,
          project,
          'product',
          appid,
          idToUpdate,
        );

        if (!success) {
          debugPrint('Failed to update stock for $idToUpdate via updateId endpoint');
        }
      }
    } catch (e) {
      debugPrint("Error updating stock: $e");
    }
  }

  void _resetForm() {
    _namaTokoController.clear();
    _alamatTokoController.clear();
    _namaPemilikController.clear();
    _noTeleponController.clear();
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
    _noTeleponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CatatBarangKeluarPage(
      namaTokoController: _namaTokoController,
      alamatTokoController: _alamatTokoController,
      namaPemilikController: _namaPemilikController,
      noTeleponController: _noTeleponController,
      scannedProducts: _scannedProducts,
      total: calculateTotal(),
      onScanPressed: () => openScanner(context),
        onSelectProductPressed: () => openProductPicker(context),
      onSubmitPressed: () => _submitForm(context),
      onQuantityChanged: updateProductQuantity,
      isLoading: _isLoading,
    );
  }

  void openProductPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) {
            return Container(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  Container(
                    height: 6,
                    width: 60,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Pilih Produk', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  Expanded(
                    child: ListView.separated(
                      controller: controller,
                      itemCount: _allProducts.length,
                      separatorBuilder: (_, __) => const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final p = _allProducts[index];
                        final harga = p['harga'] ?? 0;
                        final stok = p['stok'] ?? 0;
                        return ListTile(
                          title: Text(p['nama'] ?? 'Tanpa Nama'),
                          subtitle: Text('Stok: $stok • Rp ${harga.toString()}'),
                          trailing: const Icon(Icons.add_circle_outline),
                          onTap: () async {
                            // Ask quantity
                            final qtyStr = await showDialog<String?>(
                              context: context,
                              builder: (dctx) {
                                final qtyController = TextEditingController(text: '1');
                                return AlertDialog(
                                  title: const Text('Jumlah'),
                                  content: TextField(
                                    controller: qtyController,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(hintText: 'Masukkan jumlah'),
                                  ),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(dctx, null), child: const Text('Batal')),
                                    ElevatedButton(onPressed: () => Navigator.pop(dctx, qtyController.text), child: const Text('OK')),
                                  ],
                                );
                              },
                            );

                            if (qtyStr == null) return;
                            final qty = int.tryParse(qtyStr) ?? 1;
                            if (qty <= 0) return;
                            if (stok is int && qty > stok) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Stok hanya $stok')));
                              return;
                            }

                            final idProd = p['id']?.toString() ?? p['id_product']?.toString() ?? '';

                            setState(() {
                              final existingIndex = _scannedProducts.indexWhere((e) => e['id'] == idProd);
                              if (existingIndex >= 0) {
                                final current = ( _scannedProducts[existingIndex]['jumlah'] ?? 0) as int;
                                _scannedProducts[existingIndex]['jumlah'] = current + qty;
                              } else {
                                _scannedProducts.add({
                                  'id': idProd,
                                  'nama': p['nama'],
                                  'kategori': p['kategori'],
                                  'harga': p['harga'],
                                  'stok': p['stok'],
                                  'full': p['full'] ?? p,
                                  'jumlah': qty,
                                });
                              }
                            });

                            Navigator.pop(context); // close bottom sheet
                          },
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

// Scanner Screen Logic
class ScannerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allProducts;
  final List<Map<String, dynamic>> scannedProducts;
  final String ownerId;
  final Function(List<Map<String, dynamic>>) onProductsChanged;

  const ScannerScreen({
    required this.allProducts,
    required this.scannedProducts,
    required this.ownerId,
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

        // Cari produk berdasarkan berbagai kemungkinan field (id_product, _id, id, barcode, kode, nama)
        final codeNormalized = code.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
        final codeLower = code.toLowerCase();

        final foundProduct = widget.allProducts.firstWhere(
          (p) {
            final productData = p['full'] ?? {};

            final idProduct = (productData['id_product'] ?? p['id_product'] ?? productData['id'] ?? p['id'] ?? productData['_id'] ?? '').toString();
            final barcodeProduct = (productData['barcode'] ?? productData['kode'] ?? p['barcode'] ?? '').toString();
            final nameStr = (p['nama'] ?? productData['nama_product'] ?? '').toString().toLowerCase();

            final idNormalized = idProduct.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
            final barcodeNormalized = barcodeProduct.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();

            return idProduct == code ||
                barcodeProduct == code ||
                idNormalized == codeNormalized ||
                barcodeNormalized == codeNormalized ||
                nameStr.contains(codeLower);
          },
          orElse: () => <String, dynamic>{},
        );

    if (foundProduct.isNotEmpty) {
      final productId = foundProduct['id'] ?? '';
      final stok = (foundProduct['stok'] is int)
          ? foundProduct['stok'] as int
          : int.tryParse(foundProduct['stok']?.toString() ?? '0') ?? 0;

      final existingIndex = widget.scannedProducts.indexWhere((p) => p['id'] == productId);

      // If stok kosong, jangan tambahkan
      if (stok <= 0) {
        HapticFeedback.vibrate();
        _showSnackbar('Stok ${foundProduct['nama']} habis', isError: true);
      } else {
        setState(() {
          if (existingIndex >= 0) {
            final current = (widget.scannedProducts[existingIndex]['jumlah'] ?? 0) as int;
            if (current + 1 > stok) {
              // melebihi stok
              HapticFeedback.vibrate();
              _showSnackbar('Tidak bisa menambah, stok hanya $stok', isError: true);
            } else {
              widget.scannedProducts[existingIndex]['jumlah'] = current + 1;
              HapticFeedback.mediumImpact();
              _showSnackbar('${foundProduct['nama']} jumlah diperbarui: ${current + 1}', isError: false);
            }
          } else {
            widget.scannedProducts.add({
              ...foundProduct,
              'jumlah': 1,
            });
            HapticFeedback.mediumImpact();
            _showSnackbar('${foundProduct['nama']} ditambahkan', isError: false);
          }
        });

        widget.onProductsChanged(List.from(widget.scannedProducts));
      }
    } else {
      HapticFeedback.vibrate();
      // Show snackbar with action to add product manually
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Produk tidak ditemukan: $code'),
          action: SnackBarAction(
            label: 'Tambah',
            onPressed: () async {
              // Open AddProductPage and register callback to receive created product
                        await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProductPage(
                    userRole: '',
                    barcode: code,
                    ownerId: widget.ownerId,
                    onProductAdded: (productMap) {
                      // Convert returned product to local format and add to scannedProducts
                      try {
                        final idProd = productMap['id_product']?.toString() ?? productMap['_id']?.toString() ?? '';
                        final nama = productMap['nama_product']?.toString() ?? 'Tidak ada nama';
                        final kategori = productMap['kategori_product']?.toString() ?? 'Umum';
                        final harga = int.tryParse(productMap['harga_product']?.toString() ?? '0') ?? 0;
                        final stok = int.tryParse(productMap['jumlah_produk']?.toString() ?? '0') ?? 0;

                        setState(() {
                          widget.scannedProducts.add({
                            'id': idProd,
                            'nama': nama,
                            'kategori': kategori,
                            'harga': harga,
                            'stok': stok,
                            'full': productMap,
                            'jumlah': 1,
                          });
                        });

                        widget.onProductsChanged(List.from(widget.scannedProducts));
                        _showSnackbar('$nama ditambahkan', isError: false);
                      } catch (e) {
                        _showSnackbar('Gagal menambahkan produk baru', isError: true);
                      }
                    },
                  ),
                ),
              );
            },
          ),
        ),
      );
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

  void _showSnackbar(String message, {bool isError = false}) {
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