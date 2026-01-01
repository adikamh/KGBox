// lib/pages/edit_product_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/edit_product_screen.dart';
import '../models/product_model.dart';
// ignore: depend_on_referenced_packages
import 'package:intl/intl.dart';

class EditProductPage extends StatefulWidget {
  final ProductModel product;
  
  const EditProductPage({
    super.key,
    required this.product,
  });

  @override
  State<EditProductPage> createState() => _EditProductPageState();
}

class _EditProductPageState extends State<EditProductPage> {
  final EditProductScreen _controller = EditProductScreen();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  
  late Map<String, TextEditingController> _controllers;
  bool _isLoading = false;
  DateTime? _selectedDate;
  List<Map<String, dynamic>> _suppliers = [];
  bool _loadingSuppliers = true;
  String? _selectedSupplierId;
  bool _isCategoryOther = false;
  final TextEditingController _categoryFreeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.initialize(widget.product);
    _controllers = _controller.createControllers();
    
    // Parse tanggal beli for date picker (support multiple formats)
    final tanggalBeliText = _controllers['tanggal_beli']!.text;
    if (tanggalBeliText.isNotEmpty) {
      try {
        _selectedDate = DateFormat('MMMM d, yyyy').parse(tanggalBeliText);
      } catch (_) {
        try {
          _selectedDate = DateFormat('dd/MM/yyyy').parse(tanggalBeliText);
        } catch (_) {
          try {
            _selectedDate = DateFormat('yyyy-MM-dd').parse(tanggalBeliText);
          } catch (_) {
            _selectedDate = null;
          }
        }
      }
    }
    // Initialize suppliers and category state
    _loadSuppliers();
    final categories = _controller.getAvailableCategories();
    final currentCat = _controllers['kategori_product']?.text ?? '';
    if (currentCat.isNotEmpty && !categories.contains(currentCat)) {
      _isCategoryOther = true;
      _categoryFreeController.text = currentCat;
    }
  }

  @override
  void dispose() {
    _controller.disposeControllers();
    _categoryFreeController.dispose();
    super.dispose();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _loadingSuppliers = true);
    try {
      final owner = widget.product.ownerid ?? '';
      final firestore = FirebaseFirestore.instance;
      Query q = firestore.collection('suppliers');
      if (owner.isNotEmpty) q = q.where('ownerid', isEqualTo: owner);
      final snap = await q.get();
      final items = snap.docs.map((d) {
        final data = (d.data() as Map<String, dynamic>?) ?? {};
        return {
          'id': d.id,
          'company': data['nama_perusahaan'] ?? data['company'] ?? '',
          '_raw': {...data, '_docId': d.id},
        };
      }).toList();

      setState(() {
        _suppliers = List<Map<String, dynamic>>.from(items);
        // try to preselect supplier by matching company name
        final prodSupplier = _controllers['supplier_name']?.text ?? '';
        final match = _suppliers.firstWhere((s) => (s['company'] ?? '') == prodSupplier, orElse: () => {});
        if (match.isNotEmpty) {
          _selectedSupplierId = match['id'];
          // ensure supplier_id controller exists
          _controllers['supplier_id'] = TextEditingController(text: _selectedSupplierId);
        } else {
          _selectedSupplierId = '__other__';
        }
      });
    } catch (e) {
      debugPrint('Error loading suppliers in edit page: $e');
    } finally {
      setState(() => _loadingSuppliers = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
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
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.white.withOpacity(0.8),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildBody() {
    return SingleChildScrollView(
      child: Form(
        key: _formKey,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product Info Card
              _buildProductInfoCard(),
              
              const SizedBox(height: 24),
              
              // Action Buttons
              _buildActionButtons(),
              
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProductInfoCard() {
    return Card(
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
            // Header
            _buildHeader(),
            
            const SizedBox(height: 20),
            
            // Product ID (read-only)
            _buildTextField(
              label: 'ID Produk',
              controller: _controllers['id_product']!,
              icon: Icons.qr_code_rounded,
              readOnly: true,
              enabled: false,
            ),
            
            // Product Name
            _buildTextField(
              label: 'Nama Produk',
              controller: _controllers['nama_product']!,
              icon: Icons.shopping_bag_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Nama produk harus diisi';
                }
                return null;
              },
            ),
            
            // Category with dropdown
            _buildCategoryField(),
            
            // Brand
            _buildTextField(
              label: 'Merek',
              controller: _controllers['merek_product']!,
              icon: Icons.business_rounded,
              validator: (value) {
                if (value == null || value.isEmpty) {
                  return 'Merek harus diisi';
                }
                return null;
              },
            ),
            
            // Purchase Date
            _buildDateField(),
            
            // Production Date picker
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 16),
                const Text(
                  'Tanggal produksi',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 8),
                InkWell(
                  onTap: _selectProductionDate,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.white,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Icon(Icons.precision_manufacturing_rounded, color: Colors.grey[600]),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _controllers['tanggal_produksi']!.text.isEmpty
                                ? 'Pilih tanggal produksi'
                                : _controllers['tanggal_produksi']!.text,
                            style: TextStyle(
                              color: _controllers['tanggal_produksi']!.text.isEmpty ? Colors.grey[400] : Colors.black87,
                            ),
                          ),
                        ),
                        Icon(Icons.calendar_month_rounded, color: Colors.blue[700]),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // Price
            _buildPriceField(),
            
            // Supplier (text field with dropdown button)
            const SizedBox(height: 16),
            const Text('Supplier', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: Colors.black87)),
            const SizedBox(height: 8),
            _loadingSuppliers
                ? const Padding(padding: EdgeInsets.symmetric(vertical:12), child: Center(child: CircularProgressIndicator()))
                : TextFormField(
                    controller: _controllers['supplier_name'],
                    decoration: InputDecoration(
                      prefixIcon: Icon(Icons.store_rounded, color: Colors.grey[600]),
                      suffixIcon: IconButton(icon: const Icon(Icons.arrow_drop_down), onPressed: () => _showSupplierPicker(context)),
                      hintText: 'Pilih atau ketik supplier',
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
                    ),
                    onChanged: (v) {
                      setState(() {
                        _selectedSupplierId = '__other__';
                        if (!_controllers.containsKey('supplier_id')) _controllers['supplier_id'] = TextEditingController(text: '');
                        _controllers['supplier_id']?.text = '';
                      });
                    },
                  ),

            // Expired Date (editable here)
            const SizedBox(height: 16),
            const Text(
              'Tanggal Expired',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _selectExpiredDate,
              child: Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.white,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today_rounded, color: Colors.grey[600]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _controllers['tanggal_expired']!.text.isEmpty
                            ? 'Pilih tanggal expired'
                            : _controllers['tanggal_expired']!.text,
                        style: TextStyle(
                          color: _controllers['tanggal_expired']!.text.isEmpty ? Colors.grey[400] : Colors.black87,
                        ),
                      ),
                    ),
                    Icon(Icons.calendar_month_rounded, color: Colors.blue[700]),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
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
    );
  }

  Widget _buildTextField({
    required String label,
    required TextEditingController controller,
    required IconData icon,
    TextInputType? keyboardType,
    bool readOnly = false,
    bool enabled = true,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 8),
        
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          readOnly: readOnly,
          enabled: enabled,
          decoration: InputDecoration(
            prefixIcon: Icon(icon, color: Colors.grey[600]),
            filled: true,
            fillColor: enabled ? Colors.white : Colors.grey[100],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            disabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Widget _buildCategoryField() {
    final categories = _controller.getAvailableCategories();
    final current = _controllers['kategori_product']?.text ?? '';
    final initialCategory = categories.contains(current) ? current : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),

        const Text(
          'Kategori',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),

        const SizedBox(height: 8),

        TextFormField(
          controller: _controllers['kategori_product'],
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.category_rounded, color: Colors.grey[600]),
            suffixIcon: IconButton(icon: const Icon(Icons.arrow_drop_down), onPressed: () => _showCategoryPicker(context)),
            hintText: 'Pilih atau ketik kategori',
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
          ),
          onChanged: (v) {
            // keep controller in sync
            _controllers['kategori_product']!.text = v;
          },
          validator: (v) {
            if (v == null || v.trim().isEmpty) return 'Kategori harus dipilih';
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
        const Text(
          'Tanggal Beli',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 8),
        
        InkWell(
          onTap: _selectDate,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(12),
              color: Colors.white,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(Icons.calendar_today_rounded, color: Colors.grey[600]),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _controllers['tanggal_beli']!.text.isEmpty
                        ? 'Pilih tanggal'
                        : _controllers['tanggal_beli']!.text,
                    style: TextStyle(
                      color: _controllers['tanggal_beli']!.text.isEmpty
                          ? Colors.grey[400]
                          : Colors.black87,
                    ),
                  ),
                ),
                Icon(
                  Icons.calendar_month_rounded,
                  color: Colors.blue[700],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectProductionDate() async {
    final initial = () {
      try {
        final txt = _controllers['tanggal_produksi']?.text ?? '';
        if (txt.isEmpty) return DateTime.now();
        // try dd/MM/yyyy first
        try {
          return DateFormat('dd/MM/yyyy').parse(txt);
        } catch (_) {}
        try {
          return DateFormat('yyyy-MM-dd').parse(txt);
        } catch (_) {}
        try {
          return DateFormat('MMMM d, yyyy').parse(txt);
        } catch (_) {}
        return DateTime.now();
      } catch (_) {
        return DateTime.now();
      }
    }();

    final picked = await _controller.selectDate(context, initialDate: initial);
    if (picked != null) {
      setState(() {
        _controllers['tanggal_produksi']!.text = DateFormat('dd/MM/yyyy').format(picked);
      });
    }
  }

  Future<void> _selectExpiredDate() async {
    final initial = () {
      try {
        final txt = _controllers['tanggal_expired']?.text ?? '';
        if (txt.isEmpty) return DateTime.now();
        try {
          return DateTime.parse(txt);
        } catch (_) {}
        try {
          return DateFormat('dd/MM/yyyy').parse(txt);
        } catch (_) {}
        try {
          return DateFormat('MMMM d, yyyy').parse(txt);
        } catch (_) {}
        return DateTime.now();
      } catch (_) {
        return DateTime.now();
      }
    }();

    final picked = await _controller.selectDate(context, initialDate: initial);
    if (picked != null) {
      setState(() {
        // store in yyyy-MM-dd for consistency with Firestore storage
        _controllers['tanggal_expired']!.text = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';
      });
    }
  }

  Future<void> _showCategoryPicker(BuildContext ctx) async {
    final items = _controller.getAvailableCategories();
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
        _controllers['kategori_product']!.text = chosen;
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
        _controllers['supplier_name']?.text = chosen['company'] ?? '';
        final sid = _selectedSupplierId ?? '';
        if (!_controllers.containsKey('supplier_id')) _controllers['supplier_id'] = TextEditingController(text: sid);
        else _controllers['supplier_id']?.text = sid;
      });
    }
  }

  Widget _buildPriceField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        
        const Text(
          'Harga Produk',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        
        const SizedBox(height: 8),
        
        TextFormField(
          controller: _controllers['harga_product'],
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            prefixText: 'Rp. ',
            prefixStyle: TextStyle(color: Colors.grey[800], fontWeight: FontWeight.w600),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          onChanged: (value) {
            if (value.isNotEmpty) {
              final formatted = _controller.formatPrice(value);
              if (formatted != value) {
                _controllers['harga_product']!.text = formatted;
                _controllers['harga_product']!.selection = TextSelection.collapsed(
                  offset: _controllers['harga_product']!.text.length,
                );
              }
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Harga harus diisi';
            }
            final cleanValue = _controller.formatPriceForStorage(value);
            final harga = int.tryParse(cleanValue);
            if (harga == null || harga <= 0) {
              return 'Harga harus berupa angka positif';
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
        // Cancel Button
        Expanded(
          child: SizedBox(
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
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
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ),
        
        const SizedBox(width: 16),
        
        // Save Button
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
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _selectDate() async {
    final selectedDate = await _controller.selectDate(
      context,
      initialDate: _selectedDate ?? DateTime.now(),
    );
    
    if (selectedDate != null) {
      setState(() {
        _selectedDate = selectedDate;
        _controllers['tanggal_beli']!.text = 
            DateFormat('dd/MM/yyyy').format(selectedDate);
      });
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _controller.saveChanges(_controllers);

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
        ),
      );

      // Return updated product
      if (mounted) {
        Navigator.of(context).pop(result['product']);
      }
    } else {
      // Show error message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.red,
        ),
      );

      // Highlight error fields if any
      if (result['errors'] != null) {
        // ignore: unused_local_variable
        final errors = result['errors'] as Map<String, String?>;
        // You could add logic to scroll to first error field
      }
    }
  }
}