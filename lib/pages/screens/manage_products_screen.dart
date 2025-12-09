import 'package:flutter/material.dart';
import '../../app.dart';

class ManageProductsScreen extends StatefulWidget {
  final String userRole;

  const ManageProductsScreen({super.key, required this.userRole});

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  final List<Map<String, dynamic>> _products = [
    {
      'id': 'PRD001',
      'name': 'Produk X',
      'code': 'PX001',
      'category': 'Elektronik',
      'stock': 150,
      'price': 250000,
      'min_stock': 20,
      'supplier': 'Supplier A',
      'last_updated': '18 Des 2024',
    },
    {
      'id': 'PRD002',
      'name': 'Produk Y',
      'code': 'PY002',
      'category': 'Elektronik',
      'stock': 85,
      'price': 180000,
      'min_stock': 15,
      'supplier': 'Supplier B',
      'last_updated': '17 Des 2024',
    },
    {
      'id': 'PRD003',
      'name': 'Produk Z',
      'code': 'PZ003',
      'category': 'Aksesoris',
      'stock': 200,
      'price': 75000,
      'min_stock': 30,
      'supplier': 'Supplier C',
      'last_updated': '19 Des 2024',
    },
    {
      'id': 'PRD004',
      'name': 'Produk A',
      'code': 'PA004',
      'category': 'Perkakas',
      'stock': 45,
      'price': 350000,
      'min_stock': 10,
      'supplier': 'Supplier A',
      'last_updated': '16 Des 2024',
    },
    {
      'id': 'PRD005',
      'name': 'Produk B',
      'code': 'PB005',
      'category': 'Elektronik',
      'stock': 120,
      'price': 420000,
      'min_stock': 25,
      'supplier': 'Supplier D',
      'last_updated': '15 Des 2024',
    },
  ];

  List<Map<String, dynamic>> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(_products);
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    
    setState(() {
      _filteredProducts = _products.where((product) {
        final matchesSearch = product['name'].toLowerCase().contains(query) ||
                            product['code'].toLowerCase().contains(query) ||
                            product['category'].toLowerCase().contains(query);
        
        final matchesCategory = _selectedCategory == 'Semua' || 
                               product['category'] == _selectedCategory;
        
        return matchesSearch && matchesCategory;
      }).toList();
    });
  }

  void _showEditProductDialog(Map<String, dynamic> product) {
    final TextEditingController nameController = TextEditingController(text: product['name']);
    final TextEditingController codeController = TextEditingController(text: product['code']);
    final TextEditingController stockController = TextEditingController(text: product['stock'].toString());
    final TextEditingController priceController = TextEditingController(text: product['price'].toString());
    final TextEditingController minStockController = TextEditingController(text: product['min_stock'].toString());

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Edit Produk',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  
                  // Form Edit
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nama Produk',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: codeController,
                    decoration: const InputDecoration(
                      labelText: 'Kode Produk',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: stockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stok',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextField(
                          controller: minStockController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Stok Minimal',
                            border: OutlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  TextField(
                    controller: priceController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'Harga (Rp)',
                      border: OutlineInputBorder(),
                      prefixText: 'Rp ',
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Kategori
                  DropdownButtonFormField<String>(
                    value: product['category'],
                    items: const [
                      DropdownMenuItem(value: 'Elektronik', child: Text('Elektronik')),
                      DropdownMenuItem(value: 'Aksesoris', child: Text('Aksesoris')),
                      DropdownMenuItem(value: 'Perkakas', child: Text('Perkakas')),
                      DropdownMenuItem(value: 'Lainnya', child: Text('Lainnya')),
                    ],
                    onChanged: (value) {},
                    decoration: const InputDecoration(
                      labelText: 'Kategori',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Tombol Simpan
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        // Update produk
                        setState(() {
                          final index = _products.indexWhere((p) => p['id'] == product['id']);
                          if (index != -1) {
                            _products[index] = {
                              ...product,
                              'name': nameController.text,
                              'code': codeController.text,
                              'stock': int.tryParse(stockController.text) ?? 0,
                              'price': int.tryParse(priceController.text) ?? 0,
                              'min_stock': int.tryParse(minStockController.text) ?? 0,
                              'last_updated': '19 Des 2024',
                            };
                          }
                        });
                        _filterProducts();
                        Navigator.of(context).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Produk berhasil diupdate!'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Simpan Perubahan',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _showDeleteConfirmationDialog(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: Text('Apakah Anda yakin ingin menghapus produk "${product['name']}"?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  _products.removeWhere((p) => p['id'] == product['id']);
                });
                _filterProducts();
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produk berhasil dihapus!'),
                    backgroundColor: Colors.green,
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.danger,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final categories = ['Semua', ..._products.map((p) => p['category']).toSet().toList()];

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Kelola Produk',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              // Navigate to add product
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Search Bar
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari produk...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            _searchController.clear();
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((category) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: FilterChip(
                              label: Text(category),
                              selected: _selectedCategory == category,
                              onSelected: (selected) {
                                setState(() {
                                  _selectedCategory = selected ? category : 'Semua';
                                  _filterProducts();
                                });
                              },
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            
            // Product List
            Expanded(
              child: Card(
                elevation: 2,
                child: _filteredProducts.isEmpty
                    ? const Center(
                        child: Text('Tidak ada produk ditemukan'),
                      )
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context, index) {
                          final product = _filteredProducts[index];
                          final isLowStock = product['stock'] < product['min_stock'];
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            elevation: 1,
                            child: ListTile(
                              contentPadding: const EdgeInsets.all(16),
                              leading: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.blue.withOpacity(0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.inventory_2, color: Colors.blue),
                              ),
                              title: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product['name'],
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    'Kode: ${product['code']} • ${product['category']}',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              'Stok: ${product['stock']} unit',
                                              style: TextStyle(
                                                fontWeight: FontWeight.w500,
                                                color: isLowStock ? AppColors.danger : AppColors.success,
                                              ),
                                            ),
                                            Text(
                                              'Minimal: ${product['min_stock']} unit',
                                              style: const TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        'Rp ${product['price'].toString().replaceAllMapped(
                                          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
                                              (Match m) => '${m[1]}.',
                                        )}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.blue,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'edit',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit, size: 18),
                                        SizedBox(width: 8),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'delete',
                                    child: Text('Hapus', style: TextStyle(color: AppColors.danger)),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'edit') {
                                    _showEditProductDialog(product);
                                  } else if (value == 'delete') {
                                    _showDeleteConfirmationDialog(product);
                                  }
                                },
                              ),
                              onTap: () {
                                _showEditProductDialog(product);
                              },
                            ),
                          );
                        },
                      ),
              ),
            ),
            
            // Summary
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total Produk: ${_filteredProducts.length}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Stok Rendah: ${_filteredProducts.where((p) => p['stock'] < p['min_stock']).length}',
                          style: TextStyle(color: AppColors.danger),
                        ),
                      ],
                    ),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Export data
                      },
                      icon: const Icon(Icons.download),
                      label: const Text('Export Data'),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}