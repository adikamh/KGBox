// lib/pages/add_product_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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
  final TextEditingController _productionDateController = TextEditingController();
  final TextEditingController _tanggalExpiredController = TextEditingController();
  final TextEditingController _categoryFreeController = TextEditingController();
  final TextEditingController _isiPerdusController = TextEditingController();
  final TextEditingController _ukuranController = TextEditingController();
  final TextEditingController _varianController = TextEditingController();
  List<Map<String, dynamic>> _suppliers = [];
  bool _loadingSuppliers = true;
  String? _selectedSupplierId;
  final TextEditingController _supplierFreeController = TextEditingController();
  bool _supplierSaved = false;
  
  bool _isLoading = false;
  Map<String, int>? _scannedCountsMap;
  final List<String> _barcodeList = [];
  // ignore: unused_field
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
      tanggalExpiredCtrl: _tanggalExpiredController,
      productionDateCtrl: _productionDateController,
      isiPerdusCtrl: _isiPerdusController,
      ukuranCtrl: _ukuranController,
      varianCtrl: _varianController,
    );
    
    _selectedCategory = _controller.selectedCategory;
    _selectedSupplierId = null;
    _loadSuppliers();
    // Ensure code field shows initial generated code
    _codeController.text = _controller.productCode;
    // If initial barcode provided, add to barcode list (avoid duplicates)
    if (widget.barcode != null && widget.barcode!.isNotEmpty) {
      // support comma-separated barcode string (from multi-scan result)
      final incoming = widget.barcode!.trim();
      final parts = incoming.split(',').map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
      if (parts.isEmpty) {
        if (!_barcodeList.contains(incoming)) _barcodeList.add(incoming);
      } else {
        for (final p in parts) {
          if (!_barcodeList.contains(p)) _barcodeList.add(p);
        }
      }
      _codeController.text = _barcodeList.join(',');
      // rebuild scanned counts map from barcode list
      _scannedCountsMap = {};
      for (final b in _barcodeList) {
        _scannedCountsMap![b] = (_scannedCountsMap![b] ?? 0) + 1;
      }
    }
    // persist any already-scanned barcodes into temp_barcodes
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _controller.saveScansToTemp(_barcodeList);
    });
  }

  Widget _buildProductionDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggal Produksi',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _productionDateController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'YYYY-MM-DD',
              prefixIcon: IconButton(
                icon: Icon(Icons.calendar_today_rounded, color: Colors.blue[700]),
                onPressed: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(2000),
                    lastDate: DateTime(2100),
                  );
                  if (picked != null) {
                    _productionDateController.text = '${picked.year}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
                  }
                },
                tooltip: 'Pilih Tanggal',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _productionDateController.dispose();
    _supplierFreeController.dispose();
    _categoryFreeController.dispose();
    _isiPerdusController.dispose();
    _ukuranController.dispose();
    _varianController.dispose();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _loadingSuppliers = true);
    try {
      final owner = _controller.ownerId ?? '';
      final firestore = FirebaseFirestore.instance;
      Query q = firestore.collection('suppliers');
      if (owner.isNotEmpty) q = q.where('ownerid', isEqualTo: owner);
      final snap = await q.get();
      final mapped = snap.docs.map((d) {
        final data = (d.data() as Map<String, dynamic>?) ?? {};
        return {
          'id': d.id,
          'company': data['nama_perusahaan'] ?? data['company'] ?? '',
          '_raw': {...data, '_docId': d.id},
        };
      }).toList();
      setState(() => _suppliers = List<Map<String, dynamic>>.from(mapped));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat supplier: $e')));
    } finally {
      setState(() => _loadingSuppliers = false);
    }
  }

  

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircularProgressIndicator(),
                  const SizedBox(height: 16),
                  Text(
                    'Menyimpan produk...',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            )
          : _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      foregroundColor: Colors.white,
      title: const Text(
        'Tambah Produk Baru',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Column(
        children: [
          // Header Section
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[700]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.inventory_2_rounded,
                    size: 32,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(width: 16),
                const Expanded(
                  child: Text(
                    'Lengkapi Informasi Produk',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Form Section
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildTextField(
                    label: 'Nama Produk',
                    hint: 'Contoh: Indomie Goreng',
                    icon: Icons.shopping_bag_rounded,
                    controller: _nameController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Nama produk wajib diisi';
                      }
                      return null;
                    },
                    onChanged: (value) => _controller.updateProductCode(),
                  ),
                  
                  const SizedBox(height: 16),

                  _buildProductionDateField(),
                  const SizedBox(height: 16),

                  _buildCodeField(),
                  
                  const SizedBox(height: 16),
                  
                  _buildCategoryField(),

                  const SizedBox(height: 16),

                  _buildSupplierField(),

                  const SizedBox(height: 16),

                  _buildTextField(
                    label: 'Merek Produk',
                    hint: 'Contoh: Indofood',
                    icon: Icons.verified_rounded,
                    controller: _merekController,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Merek produk wajib diisi';
                      }
                      return null;
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildTextField(
                    label: 'Harga Produk',
                    hint: '0',
                    icon: Icons.payments_rounded,
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
                  
                  const SizedBox(height: 16),

                  _buildTextField(
                    label: 'Isi Perdus (Waste/Loss)',
                    hint: '0',
                    icon: Icons.warning_amber_rounded,
                    controller: _isiPerdusController,
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value != null && value.isNotEmpty && int.tryParse(value) == null) {
                        return 'Isi perdus harus berupa angka';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    label: 'Ukuran (Size)',
                    hint: 'Contoh: M, L, XL atau 500ml',
                    icon: Icons.straighten_rounded,
                    controller: _ukuranController,
                  ),

                  const SizedBox(height: 16),

                  _buildTextField(
                    label: 'Varian (Variant)',
                    hint: 'Contoh: Rasa Pedas, Warna Merah',
                    icon: Icons.palette_rounded,
                    controller: _varianController,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  _buildDateField(),
                  
                  const SizedBox(height: 32),
                  
                  _buildActionButtons(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required String label,
    required String hint,
    required IconData icon,
    required TextEditingController controller,
    TextInputType? keyboardType,
    String? prefixText,
    String? Function(String?)? validator,
    void Function(String)? onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: Colors.blue[700]),
              prefixText: prefixText,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: validator,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildCodeField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kode Produk',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _codeController,
                  readOnly: true,
                  decoration: InputDecoration(
                    hintText: 'Otomatis dibuat',
                    prefixIcon: Icon(Icons.qr_code_rounded, color: Colors.blue[700]),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: Colors.grey[50],
                  ),
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.blue[700]!, Colors.blue[500]!],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: const Icon(Icons.qr_code_scanner_rounded, color: Colors.white),
                  onPressed: _scanBarcode,
                  tooltip: 'Scan Barcode',
                ),
              ),
              Container(
                margin: const EdgeInsets.only(right: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: IconButton(
                  icon: Icon(Icons.list, color: Colors.grey[700]),
                  onPressed: _showBarcodePreview,
                  tooltip: 'Preview / Edit Kode Produk',
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Kategori',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Column(
              children: [
                TextFormField(
                  controller: _categoryFreeController,
                  decoration: InputDecoration(
                    prefixIcon: Icon(Icons.category_rounded, color: Colors.blue[700]),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.arrow_drop_down),
                      onPressed: () => _showCategoryPicker(context),
                    ),
                    hintText: 'Pilih atau ketik kategori',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    filled: true,
                    fillColor: Colors.white,
                  ),
                  onChanged: (v) {
                    _selectedCategory = v;
                    _controller.selectedCategory = v;
                    _controller.updateProductCode();
                  },
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Kategori wajib diisi';
                    return null;
                  },
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showCategoryPicker(BuildContext ctx) async {
    final items = _controller.categories;
    final chosen = await showModalBottomSheet<String?>(
      context: ctx,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      builder: (c) {
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (_, i) => ListTile(
            title: Text(items[i], overflow: TextOverflow.ellipsis),
            onTap: () => Navigator.pop(c, items[i]),
          ),
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: items.length,
        );
      },
    );
    if (chosen != null) {
      setState(() {
        _categoryFreeController.text = chosen;
        _selectedCategory = chosen;
        _controller.selectedCategory = chosen;
        _controller.updateProductCode();
      });
    }
  }

  Future<void> _showSupplierPicker(BuildContext ctx) async {
    if (_loadingSuppliers) return;
    final chosen = await showModalBottomSheet<Map<String, dynamic>?>(
      context: ctx,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      builder: (c) {
        return ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (_, i) {
            final s = _suppliers[i];
            return ListTile(
              title: Text(s['company'] ?? '', overflow: TextOverflow.ellipsis),
              onTap: () => Navigator.pop(c, s),
            );
          },
          separatorBuilder: (_, __) => const Divider(height: 1),
          itemCount: _suppliers.length,
        );
      },
    );
    if (chosen != null) {
      setState(() {
        _selectedSupplierId = chosen['id']?.toString();
        _supplierSaved = true;
        _supplierFreeController.text = chosen['company'] ?? '';
      });
    }
  }

  Widget _buildSupplierField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Supplier', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0,2)),
          ]),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Column(
              children: [
                _loadingSuppliers
                  ? const Padding(padding: EdgeInsets.symmetric(vertical:12), child: Center(child: CircularProgressIndicator()))
                  : Column(
                      children: [
                        TextFormField(
                          controller: _supplierFreeController,
                          decoration: InputDecoration(
                            prefixIcon: Icon(Icons.business, color: Colors.blue[700]),
                            suffixIcon: IconButton(icon: const Icon(Icons.arrow_drop_down), onPressed: () => _showSupplierPicker(context)),
                            hintText: 'Pilih atau ketik supplier',
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            filled: true,
                            fillColor: Colors.white,
                          ),
                          onChanged: (v) {
                            setState(() {
                              _selectedSupplierId = '__other__';
                              _supplierSaved = false;
                            });
                          },
                        ),
                        if (_selectedSupplierId == '__other__')
                          Padding(
                            padding: const EdgeInsets.only(top:8.0),
                            child: Column(
                              children: [
                                const SizedBox(height: 8),
                                Row(
                                  children: [
                                    Expanded(
                                      child: ElevatedButton(
                                        onPressed: () async {
                                          await _saveSupplier();
                                        },
                                        child: const Text('Simpan Supplier'),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Tanggal Expired',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: TextFormField(
            controller: _tanggalExpiredController,
            readOnly: true,
            decoration: InputDecoration(
              hintText: 'YYYY-MM-DD',
              prefixIcon: IconButton(
                icon: Icon(Icons.calendar_today_rounded, color: Colors.blue[700]),
                onPressed: () => _controller.selectExpiredDate(context),
                tooltip: 'Pilih Tanggal',
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[200]!),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.blue[700]!, width: 2),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Colors.red, width: 2),
              ),
              filled: true,
              fillColor: Colors.white,
            ),
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Tanggal expired wajib diisi';
              }
              return null;
            },
          ),
        ),
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
                                        if (mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(
                                              content: Text('Tidak dapat mengganti dengan $res karena sudah ada di daftar.'),
                                              backgroundColor: Colors.orange,
                                              behavior: SnackBarBehavior.floating,
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                            ),
                                          );
                                        }
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

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              side: BorderSide(color: Colors.grey[400]!),
              backgroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Batal',
              style: TextStyle(
                color: Colors.grey[700],
                fontSize: 15,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: ElevatedButton(
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              elevation: 2,
              shadowColor: Colors.blue.withOpacity(0.5),
            ),
            onPressed: _submitForm,
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.save_rounded, size: 20),
                SizedBox(width: 8),
                Text(
                  'Simpan Produk',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _scanBarcode() async {
    final scanResult = await _controller.scanBarcode(context);
    if (scanResult != null && mounted) {
      // If scanner returned a single barcode string -> append to barcode list
      if (scanResult is String) {
        final scannedCode = scanResult;
        if (_barcodeList.contains(scannedCode)) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Row(
                  children: [
                    const Icon(Icons.info, color: Colors.white),
                    const SizedBox(width: 12),
                    Expanded(child: Text('Barcode $scannedCode sudah ada. Duplikat tidak diperbolehkan.')),
                  ],
                ),
                backgroundColor: Colors.orange[600],
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            );
          }
          return;
        }
        
          setState(() {
          _barcodeList.add(scannedCode);
          _codeController.text = _barcodeList.join(',');
          _controller.productId = _barcodeList.first;
          _controller.productCode = _barcodeList.first;
          if (_controller.codeController != null) {
            _controller.codeController!.text = _barcodeList.first;
          }
            // update scanned counts map
          _scannedCountsMap = {};
          for (final b in _barcodeList) {
            _scannedCountsMap![b] = (_scannedCountsMap![b] ?? 0) + 1;
          }
        });
          // persist this scan to temp_barcodes
          try { await _controller.saveScansToTemp([scannedCode]); } catch (_) {}
      }
      // If scanner returned multiple scanned counts -> expand and append (skip duplicates)
      else if (scanResult is Map) {
        final Map map = scanResult;
        if (map.isEmpty) return;
        final List<String> duplicates = [];
        final List<String> newBarcodes = [];
        
        // expand each barcode by its count and append but skip duplicates
        map.forEach((key, value) {
          final b = key.toString();
          final count = int.tryParse(value.toString()) ?? 0;
          for (int i = 0; i < count; i++) {
            if (_barcodeList.contains(b)) {
              if (!duplicates.contains(b)) duplicates.add(b);
            } else {
              newBarcodes.add(b);
            }
          }
        });
        
        if (duplicates.isNotEmpty && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.info, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Barcode duplikat diabaikan: ${duplicates.join(', ')}')),
                ],
              ),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }

        if (newBarcodes.isNotEmpty) {
          setState(() {
            _barcodeList.addAll(newBarcodes);
            _codeController.text = _barcodeList.join(',');
            _controller.productId = _barcodeList.first;
            _controller.productCode = _barcodeList.first;
            if (_controller.codeController != null) {
              _controller.codeController!.text = _barcodeList.first;
            }
            // store full map for later batch insert (aggregate from barcodeList)
            _scannedCountsMap = {};
            for (final b in _barcodeList) {
              _scannedCountsMap![b] = (_scannedCountsMap![b] ?? 0) + 1;
            }
          });
          // persist new scans to temp
          try { await _controller.saveScansToTemp(newBarcodes); } catch (_) {}
        }
      }
    }
  }

  Future<void> _saveSupplier() async {
    final supplierName = _supplierFreeController.text.trim();
    if (supplierName.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Masukkan nama supplier terlebih dahulu')));
      return;
    }

    // If user selected manual supplier, ensure they've saved it separately
    if (_selectedSupplierId == '__other__' && !_supplierSaved) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Simpan supplier terlebih dahulu menggunakan tombol "Simpan Supplier"')));
      }
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final owner = widget.ownerId ?? '';
      final newSupId = 'SUP${DateTime.now().millisecondsSinceEpoch}';
      final firestore = FirebaseFirestore.instance;
      final payload = {
        'ownerid': owner,
        'supplier_id': newSupId,
        'nama_perusahaan': supplierName,
        'nama_agen': '',
        'no_telepon_agen': '',
        'alamat_perusahaan': '',
        'createdAt': FieldValue.serverTimestamp(),
      };
      await firestore.collection('suppliers').doc(newSupId).set(payload);

      setState(() {
        _suppliers.insert(0, {'id': newSupId, 'company': supplierName, '_raw': {...payload, '_docId': newSupId}});
        _selectedSupplierId = newSupId;
        _supplierSaved = true;
      });

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier berhasil disimpan')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan supplier: $e')));
    } finally {
      setState(() {
        _isLoading = false;
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
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded, color: Colors.white),
                  const SizedBox(width: 12),
                  Expanded(child: Text('Terdapat barcode duplikat: ${dupes.join(', ')}. Hapus atau edit sebelum menyimpan.')),
                ],
              ),
              backgroundColor: Colors.orange[600],
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
        return;
      }
    }

    setState(() {
      _isLoading = true;
    });

    Map<String, dynamic> result;
    String? supplierId;
    String? supplierName;
    if (_selectedSupplierId != null) {
      if (_selectedSupplierId == '__other__') {
        supplierName = _supplierFreeController.text.trim();
      } else {
        supplierId = _selectedSupplierId;
        final found = _suppliers.firstWhere((s) => (s['id'] ?? '') == supplierId, orElse: () => {});
        supplierName = found.isNotEmpty ? (found['company'] ?? '') : null;
      }
    }

    

    if (_barcodeList.isNotEmpty) {
      result = await _controller.addProductsFromScans(_barcodeList, supplierId: supplierId, supplierName: supplierName);
    } else {
      result = await _controller.addProduct(supplierId: supplierId, supplierName: supplierName);
    }

    setState(() {
      _isLoading = false;
    });

    if (!mounted) return;

    if (result['success'] == true) {
      String msg = result['message'] ?? 'Operasi berhasil';
      if (result['total'] != null) {
        msg = '$msg — Total jumlah: ${result['total']}';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(msg)),
              ],
            ),
            backgroundColor: Colors.green[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      if (_scannedCountsMap != null && _scannedCountsMap!.isNotEmpty) {
        if (widget.onProductAdded != null && result['product'] != null) {
          widget.onProductAdded!(result['product']);
        }
      } else {
        if (widget.onProductAdded != null && result['product'] != null) {
          widget.onProductAdded!(result['product']);
        }
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text(result['message'] ?? 'Terjadi kesalahan')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }

      if (result['errors'] != null) {
        // ignore: unused_local_variable
        final errors = result['errors'] as Map<String, String?>;
      }
    }
  }
}

extension on AddProductScreen {
  void updateProductCode() {}
}