import 'package:flutter/material.dart';

class StokProdukPage extends StatefulWidget {
  final List<Map<String, dynamic>> products;
  final bool loading;
  final void Function(String productId) onRequestStock;
  final VoidCallback onRefresh;
  final VoidCallback onViewHistory;
  final int Function() getLowStockCount;

  const StokProdukPage({
    super.key, 
    required this.products, 
    required this.loading, 
    required this.onRequestStock,
    required this.onRefresh,
    required this.onViewHistory,
    required this.getLowStockCount,
  });

  @override
  State<StokProdukPage> createState() => _StokProdukPageState();
}

class _StokProdukPageState extends State<StokProdukPage> {
  String _query = '';
  String _sortBy = 'stok'; // 'stok', 'nama', 'merek'
  bool _sortDescending = true;
  String _selectedCategory = 'Semua';
  List<String> _categories = [];

  @override
  void initState() {
    super.initState();
    _extractCategories();
  }

  @override
  void didUpdateWidget(StokProdukPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.products != oldWidget.products) {
      _extractCategories();
    }
  }

  void _extractCategories() {
    final Set<String> categorySet = {'Semua'};
    for (final p in widget.products) {
      final category = p['kategori'] ?? p['category'] ?? p['jenis'] ?? '';
      if (category.isNotEmpty) {
        categorySet.add(category);
      }
    }
    setState(() {
      _categories = categorySet.toList();
    });
  }

  // Filter products
  List<Map<String, dynamic>> get _filteredProducts {
    return widget.products.where((product) {
      final searchTerm = _query.toLowerCase();
      final nama = (product['nama_product'] ?? product['nama'] ?? '').toString().toLowerCase();
      final merek = (product['merek_product'] ?? product['merek'] ?? '').toString().toLowerCase();
      final kategori = (product['kategori'] ?? product['category'] ?? '').toString().toLowerCase();
      final sku = (product['sku'] ?? product['kode'] ?? '').toString().toLowerCase();
      
      final bool matchesSearch = _query.isEmpty || 
          nama.contains(searchTerm) || 
          merek.contains(searchTerm) ||
          kategori.contains(searchTerm) ||
          sku.contains(searchTerm);
      
      final bool matchesCategory = _selectedCategory == 'Semua' || 
          (product['kategori'] ?? product['category'] ?? '').toString() == _selectedCategory;
      
      return matchesSearch && matchesCategory;
    }).toList();
  }

  // Sort products
  List<Map<String, dynamic>> get _sortedProducts {
    final filtered = _filteredProducts;
    filtered.sort((a, b) {
      if (_sortBy == 'nama') {
        final aName = (a['nama_product'] ?? a['nama'] ?? '').toString();
        final bName = (b['nama_product'] ?? b['nama'] ?? '').toString();
        return _sortDescending ? bName.compareTo(aName) : aName.compareTo(bName);
      } else if (_sortBy == 'merek') {
        final aBrand = (a['merek_product'] ?? a['merek'] ?? '').toString();
        final bBrand = (b['merek_product'] ?? b['merek'] ?? '').toString();
        return _sortDescending ? bBrand.compareTo(aBrand) : aBrand.compareTo(bBrand);
      } else {
        // Sort by stock
        final aStock = int.tryParse((a['jumlah_produk'] ?? a['stok'] ?? '0').toString()) ?? 0;
        final bStock = int.tryParse((b['jumlah_produk'] ?? b['stok'] ?? '0').toString()) ?? 0;
        return _sortDescending ? bStock.compareTo(aStock) : aStock.compareTo(bStock);
      }
    });
    return filtered;
  }

  // Calculate statistics
  int get _totalProducts => _sortedProducts.length;
  
  int get _lowStockProducts => _sortedProducts.where((p) {
    final stock = int.tryParse((p['jumlah_produk'] ?? p['stok'] ?? '0').toString()) ?? 0;
    return stock <= 10;
  }).length;
  
  int get _outOfStockProducts => _sortedProducts.where((p) {
    final stock = int.tryParse((p['jumlah_produk'] ?? p['stok'] ?? '0').toString()) ?? 0;
    return stock == 0;
  }).length;
  
  int get _totalStock => _sortedProducts.fold<int>(0, (sum, p) {
    final stock = int.tryParse((p['jumlah_produk'] ?? p['stok'] ?? '0').toString()) ?? 0;
    return sum + stock;
  });

  String _formatNumber(String number) {
    try {
      final num = double.tryParse(number);
      if (num != null) {
        return num.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
      }
      return number;
    } catch (e) {
      return number;
    }
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.length >= 10) {
        return dateString.substring(0, 10);
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    final lowStockCount = widget.getLowStockCount();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Stok Produk'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () => _showSortOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.filter_alt),
            onPressed: () => _showFilterOptions(context),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: widget.onRefresh,
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.blue),
                  hintText: 'Cari produk...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => setState(() => _query = ''),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),

          // Quick Stats
          if (!widget.loading && _sortedProducts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildStatChip(
                      'Semua',
                      _totalProducts.toString(),
                      Colors.blue,
                      _selectedCategory == 'Semua',
                      () => setState(() => _selectedCategory = 'Semua'),
                    ),
                    if (_lowStockProducts > 0)
                      _buildStatChip(
                        'Stok Rendah',
                        _lowStockProducts.toString(),
                        Colors.orange,
                        false,
                        () {
                          setState(() {
                            _selectedCategory = 'Semua';
                            _query = '';
                            _sortBy = 'stok';
                            _sortDescending = false;
                          });
                        },
                      ),
                    if (_outOfStockProducts > 0)
                      _buildStatChip(
                        'Habis',
                        _outOfStockProducts.toString(),
                        Colors.red,
                        false,
                        () {
                          setState(() {
                            _selectedCategory = 'Semua';
                            _query = '';
                            _sortBy = 'stok';
                            _sortDescending = false;
                          });
                        },
                      ),
                    _buildStatChip(
                      'Total Stok',
                      _totalStock.toString(),
                      Colors.green,
                      false,
                      null,
                    ),
                  ],
                ),
              ),
            ),

          // Category Filter Chips
          if (_categories.length > 1 && !widget.loading)
            Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: FilterChip(
                      label: Text(category),
                      selected: _selectedCategory == category,
                      onSelected: (selected) {
                        setState(() => _selectedCategory = selected ? category : 'Semua');
                      },
                      backgroundColor: Colors.grey.shade100,
                      selectedColor: Colors.blue.shade100,
                      checkmarkColor: Colors.blue,
                    ),
                  );
                },
              ),
            ),

          // List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Produk ($_totalProducts)',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                Row(
                  children: [
                    const Icon(Icons.inventory, size: 16, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      '$_totalStock unit',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Main Product List
          Expanded(
            child: widget.loading
                ? _buildLoadingState()
                : _sortedProducts.isEmpty
                    ? _buildEmptyState()
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: _sortedProducts.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final product = _sortedProducts[index];
                          return _buildProductCard(product);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: widget.onViewHistory,
            icon: const Icon(Icons.history),
            label: const Text('Riwayat'),
            backgroundColor: Colors.orange,
            heroTag: 'history',
          ),
          const SizedBox(height: 16),
          if (lowStockCount > 0)
            FloatingActionButton.extended(
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: const Text('Stok Rendah'),
                    content: Text('Ada $lowStockCount produk dengan stok rendah (<10). Segera lakukan restock!'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(ctx),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
              icon: const Icon(Icons.warning),
              label: Text('$lowStockCount'),
              backgroundColor: Colors.red,
              heroTag: 'warning',
            ),
        ],
      ),
    );
  }

  Widget _buildStatChip(String label, String value, Color color, bool selected, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 8),
        child: Card(
          color: selected ? color.withOpacity(0.2) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: color.withOpacity(selected ? 0.5 : 0.2)),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 10,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final nama = product['nama_product'] ?? product['nama'] ?? 'Tanpa Nama';
    final merek = product['merek_product'] ?? product['merek'] ?? '';
    final kategori = product['kategori'] ?? product['category'] ?? '';
    final sku = product['sku'] ?? product['kode'] ?? '';
    final stok = int.tryParse((product['jumlah_produk'] ?? product['stok'] ?? '0').toString()) ?? 0;
    final id = product['id_product'] ?? product['id'] ?? product['_id'] ?? '';
    final harga = product['harga'] ?? product['harga_satuan'] ?? '';
    final minStock = 10;

    // Determine stock status color
    Color stockColor;
    IconData stockIcon;
    String stockStatus;
    
    if (stok == 0) {
      stockColor = Colors.red;
      stockIcon = Icons.error;
      stockStatus = 'HABIS';
    } else if (stok <= minStock) {
      stockColor = Colors.orange;
      stockIcon = Icons.warning;
      stockStatus = 'RENDAH';
    } else if (stok <= minStock * 2) {
      stockColor = Colors.yellow.shade700;
      stockIcon = Icons.info;
      stockStatus = 'PERHATIAN';
    } else {
      stockColor = Colors.green;
      stockIcon = Icons.check_circle;
      stockStatus = 'AMAN';
    }

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Stock indicator
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(color: stockColor, width: 2),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(stockIcon, size: 20, color: stockColor),
                        Text(
                          stok.toString(),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: stockColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                
                // Product info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        nama,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      if (merek.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.branding_watermark, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              merek,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                      if (kategori.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.category, size: 12, color: Colors.grey),
                            const SizedBox(width: 4),
                            Text(
                              kategori,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
                
                // Stock status badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: stockColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: stockColor),
                  ),
                  child: Text(
                    stockStatus,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: stockColor,
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Details row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (sku.isNotEmpty)
                      Text(
                        'SKU: $sku',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    if (harga.toString().isNotEmpty)
                      Text(
                        'Harga: Rp ${_formatNumber(harga.toString())}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
                
                // Stock progress bar
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        LinearProgressIndicator(
                          value: stok / 100,
                          backgroundColor: Colors.grey.shade200,
                          valueColor: AlwaysStoppedAnimation<Color>(stockColor),
                          minHeight: 6,
                          borderRadius: BorderRadius.circular(3),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '$stok unit tersedia',
                          style: TextStyle(
                            fontSize: 10,
                            color: stockColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.remove_red_eye, size: 16),
                    label: const Text('Detail'),
                    onPressed: () => _showProductDetail(product),
                    style: OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.shopping_cart, size: 16),
                    label: const Text('Minta Stok'),
                    onPressed: () => widget.onRequestStock(id.toString()),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: stok == 0 ? Colors.red : Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memuat data stok produk...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada produk ditemukan',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Pencarian: "$_query" tidak ditemukan',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          if (_selectedCategory != 'Semua')
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Kategori: "$_selectedCategory"',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _query = '';
                _selectedCategory = 'Semua';
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filter'),
          ),
        ],
      ),
    );
  }

  void _showSortOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Urutkan Berdasarkan',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  RadioListTile(
                    title: const Text('Stok (Tertinggi ke Terendah)'),
                    value: 'stok_desc',
                    groupValue: '${_sortBy}_${_sortDescending}',
                    onChanged: (value) {
                      setState(() {
                        _sortBy = 'stok';
                        _sortDescending = true;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile(
                    title: const Text('Stok (Terendah ke Tertinggi)'),
                    value: 'stok_asc',
                    groupValue: '${_sortBy}_${_sortDescending}',
                    onChanged: (value) {
                      setState(() {
                        _sortBy = 'stok';
                        _sortDescending = false;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile(
                    title: const Text('Nama A-Z'),
                    value: 'nama_asc',
                    groupValue: '${_sortBy}_${_sortDescending}',
                    onChanged: (value) {
                      setState(() {
                        _sortBy = 'nama';
                        _sortDescending = false;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  RadioListTile(
                    title: const Text('Nama Z-A'),
                    value: 'nama_desc',
                    groupValue: '${_sortBy}_${_sortDescending}',
                    onChanged: (value) {
                      setState(() {
                        _sortBy = 'nama';
                        _sortDescending = true;
                      });
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Terapkan'),
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

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Filter Stok',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),
                  const Text('Kategori:'),
                  const SizedBox(height: 10),
                  if (_categories.length > 1)
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _categories.map((category) => FilterChip(
                            label: Text(category),
                            selected: _selectedCategory == category,
                            onSelected: (selected) {
                              setStateSB(() {
                                _selectedCategory = selected ? category : 'Semua';
                              });
                              setState(() {
                                _selectedCategory = selected ? category : 'Semua';
                              });
                            },
                          )).toList(),
                    ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            setState(() {
                              _selectedCategory = 'Semua';
                              _query = '';
                            });
                            Navigator.pop(context);
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Terapkan'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showProductDetail(Map<String, dynamic> product) {
    final nama = product['nama_product'] ?? product['nama'] ?? 'Tanpa Nama';
    final merek = product['merek_product'] ?? product['merek'] ?? '';
    final kategori = product['kategori'] ?? product['category'] ?? '';
    final sku = product['sku'] ?? product['kode'] ?? '';
    final stok = int.tryParse((product['jumlah_produk'] ?? product['stok'] ?? '0').toString()) ?? 0;
    final harga = product['harga'] ?? product['harga_satuan'] ?? '';
    final deskripsi = product['deskripsi'] ?? product['description'] ?? '';
    final supplier = product['supplier'] ?? product['vendor'] ?? '';
    final lastRestock = product['last_restock'] ?? product['updated_at'] ?? '';
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      isScrollControlled: true,
      builder: (context) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.inventory, color: Colors.blue, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        if (merek.isNotEmpty)
                          Text(
                            merek,
                            style: const TextStyle(color: Colors.grey),
                          ),
                      ],
                    ),
                  ),
                  Chip(
                    label: Text(
                      '$stok unit',
                      style: const TextStyle(color: Colors.white),
                    ),
                    backgroundColor: stok == 0 ? Colors.red : Colors.blue,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              const Text(
                'Detail Produk',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    children: [
                      _buildDetailRow('SKU', sku),
                      if (kategori.isNotEmpty) _buildDetailRow('Kategori', kategori),
                      if (supplier.isNotEmpty) _buildDetailRow('Supplier', supplier),
                      if (harga.toString().isNotEmpty) 
                        _buildDetailRow('Harga', 'Rp ${_formatNumber(harga.toString())}'),
                      _buildDetailRow('Stok Tersedia', '$stok unit'),
                      if (lastRestock.toString().isNotEmpty) 
                        _buildDetailRow('Terakhir Update', _formatDate(lastRestock.toString())),
                    ],
                  ),
                ),
              ),
              if (deskripsi.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Deskripsi',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(deskripsi),
              ],
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onRequestStock((product['id_product'] ?? product['id'] ?? '').toString());
                  },
                  icon: const Icon(Icons.shopping_cart),
                  label: const Text('Minta Tambah Stok'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: Colors.grey),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }
}