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
            
            // Jumlah Stok
            _buildTextField(
              label: 'Jumlah Stok *',
              controller: _jumlahController,
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
          ],
        ),
        const SizedBox(height: 12),
      ],
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
          value: _selectedCategory,
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
    final scannedCode = await _controller.scanBarcode(context);
    if (scannedCode != null && mounted) {
      setState(() {
        _codeController.text = scannedCode;
        // Ensure controller uses scanned barcode as product id/code so saving uses barcode
        _controller.productId = scannedCode;
        _controller.productCode = scannedCode;
        if (_controller.codeController != null) {
          _controller.codeController!.text = scannedCode;
        }
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    final result = await _controller.addProduct();

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true) {
      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result['message']),
          backgroundColor: Colors.green,
        ),
      );

      // Callback jika ada
      if (widget.onProductAdded != null && result['product'] != null) {
        widget.onProductAdded!(result['product']);
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