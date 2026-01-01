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
      backgroundColor: Colors.grey[50],
      body: widget.loading
          ? _buildLoadingState()
          : Column(
              children: [
                _buildHeader(),
                if (_sortedProducts.isNotEmpty) _buildListHeader(),
                Expanded(child: _buildProductList()),
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

  // _buildStatChip removed (unused)

  // ================= HEADER =================

  Widget _buildHeader() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.blue[700]!, Colors.blue[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 6, 16, 14),
          child: Column(
            children: [
              // AppBar
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded,
                        color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Stok Produk',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.sort_rounded, color: Colors.white),
                    onPressed: () => _showSortOptions(context),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.filter_alt, color: Colors.white),
                    onPressed: () => _showFilterOptions(context),
                  ),
                  IconButton(
                    icon:
                        const Icon(Icons.refresh, color: Colors.white),
                    onPressed: widget.onRefresh,
                  ),
                ],
              ),

              // Search
              Container(
                height: 48,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded,
                        color: Colors.blue[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          hintText: 'Cari produk...',
                          border: InputBorder.none,
                        ),
                        onChanged: (v) =>
                            setState(() => _query = v),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _query = ''),
                        child: const Icon(Icons.close_rounded,
                            size: 18, color: Colors.grey),
                      ),
                  ],
                ),
              ),

              if (_sortedProducts.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildInlineStats(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ================= INLINE STATS =================

  Widget _buildInlineStats() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _inlineStatItem(
            _totalProducts.toString(), 'Semua'),
        _verticalDivider(),
        _inlineStatItem(
            _lowStockProducts.toString(), 'Stok Rendah'),
        _verticalDivider(),
        _inlineStatItem(
            _totalStock.toString(), 'Total Stok'),
      ],
    );
  }

  Widget _inlineStatItem(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold),
        ),
        Text(label,
            style:
                const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  Widget _verticalDivider() => Container(
        width: 1,
        height: 42,
        color: Colors.white24,
      );

  // ================= LIST HEADER =================

  Widget _buildListHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
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
    );
  }

  // ================= PRODUCT LIST =================

  Widget _buildProductList() {
    return _sortedProducts.isEmpty
        ? _buildEmptyState()
        : ListView.separated(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _sortedProducts.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final product = _sortedProducts[index];
              return _buildProductCard(product);
            },
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
                    groupValue: '${_sortBy}_$_sortDescending',
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
                    groupValue: '${_sortBy}_$_sortDescending',
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
                    groupValue: '${_sortBy}_$_sortDescending',
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
                    groupValue: '${_sortBy}_$_sortDescending',
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