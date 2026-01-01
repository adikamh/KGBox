// lib/pages/edit_product_page.dart
import 'package:flutter/material.dart';
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
  }

  @override
  void dispose() {
    _controller.disposeControllers();
    super.dispose();
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
            
            // Supplier (editable)
            _buildTextField(
              label: 'Supplier',
              controller: _controllers['supplier_name']!,
              icon: Icons.store_rounded,
            ),

            // Expired Date (read-only, derived from Created Date)
            _buildTextField(
              label: 'Tanggal Expired',
              controller: _controllers['tanggal_expired']!,
              icon: Icons.calendar_today_rounded,
              readOnly: true,
              enabled: false,
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
        
        DropdownButtonFormField<String>(
          initialValue: initialCategory,
          decoration: InputDecoration(
            prefixIcon: Icon(Icons.category_rounded, color: Colors.grey[600]),
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
          ),
          items: categories.map((category) {
            return DropdownMenuItem(
              value: category,
              child: Text(category),
            );
          }).toList(),
          onChanged: (value) {
            if (value != null) {
              _controllers['kategori_product']!.text = value;
            }
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Kategori harus dipilih';
            }
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
            prefixIcon: Icon(Icons.attach_money_rounded, color: Colors.grey[600]),
            suffixText: 'IDR',
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