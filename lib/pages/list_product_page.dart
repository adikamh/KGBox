// lib/pages/list_product_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../screens/list_product_screen.dart';
import '../providers/auth_provider.dart';

class ListProductPage extends StatefulWidget {
  const ListProductPage({super.key});

  @override
  State<ListProductPage> createState() => _ListProductPageState();
}

class _ListProductPageState extends State<ListProductPage> {
  final ListProductScreen _controller = ListProductScreen();
  final TextEditingController _searchController = TextEditingController();
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadProducts();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProducts() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id;
      await _controller.loadProducts(ownerId: ownerId);
      if (mounted) setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: _loadProducts,
            ),
          ),
        );
      }
    }
  }

  Future<void> _refreshProducts() async {
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: RefreshIndicator(
        onRefresh: _refreshProducts,
        color: const Color(0xFF2965C0),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 8),
            Expanded(child: _buildProductList()),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      backgroundColor: const Color(0xFF2965C0),
      title: const Text(
        'Kelola Produk',
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded, color: Colors.white),
          onPressed: _refreshProducts,
          tooltip: 'Refresh',
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFF2965C0),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
        child: Column(
          children: [
            _buildSearchBar(),
            const SizedBox(height: 12),
            _buildFilterChips(),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(horizontal: 16),
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
          const Icon(Icons.search, color: Color(0xFF2965C0)),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Cari produk...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          if (_searchController.text.isNotEmpty)
            GestureDetector(
              onTap: () {
                _searchController.clear();
                setState(() {});
              },
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.close, size: 16, color: Colors.grey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildFilterChips() {
    final categories = _controller.getAvailableCategories();
    
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: _controller.filter == category,
              onSelected: (selected) {
                setState(() {
                  _controller.filter = category;
                });
              },
              backgroundColor: Colors.transparent,
              selectedColor: Colors.white,
              labelStyle: TextStyle(
                color: _controller.filter == category 
                    ? const Color(0xFF2965C0) 
                    : Colors.white,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: _controller.filter == category 
                      ? Colors.transparent 
                      : Colors.white,
                  width: 1.5,
                ),
              ),
              showCheckmark: false,
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProductList() {
    if (_controller.isLoading) {
      return _buildLoadingState();
    }

    final displayProducts = _controller.getDisplayProducts(_searchController.text);

    if (displayProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: displayProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = displayProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isLowStock = _controller.isStockLow(product['stock']);
    
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _controller.navigateToDetail(context, product),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Product Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _controller.getCategoryColor(product['category']).withOpacity(0.8),
                      _controller.getCategoryColor(product['category']),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: _controller.getCategoryColor(product['category']).withOpacity(0.2),
                      blurRadius: 6,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Icon(
                  _controller.getCategoryIcon(product['category']),
                  color: Colors.white,
                  size: 28,
                ),
              ),
              
              const SizedBox(width: 12),
              
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            product['name'],
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        PopupMenuButton<int>(
                          icon: Icon(
                            Icons.more_vert_rounded,
                            color: Colors.grey[400],
                            size: 20,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          itemBuilder: (ctx) => [
                            PopupMenuItem(
                              value: 1,
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_rounded, size: 18, color: Colors.blue),
                                  const SizedBox(width: 10),
                                  const Text('Edit', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 4,
                              child: Row(
                                children: [
                                  const Icon(Icons.edit_square, size: 18, color: Colors.blue),
                                  const SizedBox(width: 10),
                                  const Text('Edit Semua Unit', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 2,
                              child: Row(
                                children: [
                                  const Icon(Icons.remove_circle_outline, size: 18, color: Colors.orange),
                                  const SizedBox(width: 10),
                                  const Text('Hapus Satu Unit', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                            PopupMenuItem(
                              value: 3,
                              child: Row(
                                children: [
                                  const Icon(Icons.delete_rounded, size: 18, color: Colors.red),
                                  const SizedBox(width: 10),
                                  const Text('Hapus Semua Unit', style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          ],
                          onSelected: (value) async {
                            if (value == 1) {
                              _controller.navigateToEdit(context, product);
                            } else if (value == 4) {
                              await _handleEditAllUnits(product);
                            } else if (value == 2) {
                              await _handleDeleteSingleUnit(product);
                            } else if (value == 3) {
                              await _handleDeleteAllUnits(product);
                            }
                          },
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Category
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: _controller.getCategoryColor(product['category']).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        product['category'],
                        style: TextStyle(
                          fontSize: 11,
                          color: _controller.getCategoryColor(product['category']),
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    
                    const SizedBox(height: 12),
                    
                    // Price and Stock
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Harga',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Rp ${_controller.formatPrice(product['price'])}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                        
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Stok',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey[600],
                              ),
                            ),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                  isLowStock ? Icons.warning_rounded : Icons.check_circle_rounded,
                                  size: 14,
                                  color: isLowStock ? Colors.orange : Colors.green,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${product['stock']} unit',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: isLowStock ? Colors.orange : Colors.green,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                    
                    const SizedBox(height: 8),
                    
                    // Updated Date
                    Row(
                      children: [
                        Icon(
                          Icons.access_time_rounded,
                          size: 12,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Update: ${_controller.formatDate(product['updated'])}',
                          style: TextStyle(
                            color: Colors.grey[500],
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.blue[700]),
          const SizedBox(height: 16),
          Text(
            'Memuat produk...',
            style: TextStyle(color: Colors.grey[600]),
          ),
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
            color: Colors.grey[300],
          ),
          const SizedBox(height: 16),
          Text(
            'Tidak ada produk',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Coba ubah filter atau pencarian',
            style: TextStyle(color: Colors.grey[400]),
          ),
          const SizedBox(height: 16),
          if (_searchController.text.isNotEmpty || _controller.filter != 'Semua')
            ElevatedButton(
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _controller.filter = 'Semua';
                });
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
              ),
              child: const Text('Reset Filter'),
            ),
        ],
      ),
    );
  }

  Future<void> _handleDeleteProduct(Map<String, dynamic> product) async {
    final confirm = await _controller.showDeleteConfirmation(
      context,
      product['name'],
    );

    if (confirm == true) {
      // If grouped entry, delete first underlying item by id
      final full = product['full'];
      String targetId = '';
      if (full is List && full.isNotEmpty) {
        final first = full.first as Map<String, dynamic>;
        targetId = first['id']?.toString() ?? first['id_product']?.toString() ?? '';
      } else if (full is Map) {
        targetId = full['id']?.toString() ?? full['id_product']?.toString() ?? '';
      }

      final result = await _controller.deleteProduct(targetId);
      
      if (result['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.green,
          ),
        );
        await _refreshProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result['message']),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDeleteSingleUnit(Map<String, dynamic> product) async {
    final full = product['full'];
    if (full is! List || full.isEmpty) {
      // fallback to normal delete
      await _handleDeleteProduct(product);
      return;
    }

    // Let user pick which unit to delete
    final selected = await showModalBottomSheet<String?>(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      builder: (ctx) {
        return ListView(
          shrinkWrap: true,
          children: full.map<Widget>((item) {
            final m = item as Map<String, dynamic>;
            final id = m['id']?.toString() ?? m['id_product']?.toString() ?? '';
            final barcode = (() {
              final raw = m['barcode_list'] ?? '';
              if (raw is List) return raw.join(', ');
              return raw.toString();
            })();
            return ListTile(
              title: Text(id),
              subtitle: Text(barcode),
              onTap: () => Navigator.of(ctx).pop(id),
            );
          }).toList(),
        );
      },
    );

    if (selected == null || selected.isEmpty) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Konfirmasi'),
        content: const Text('Hapus unit ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Hapus')),
        ],
      ),
    );

    if (confirm != true) return;

    final result = await _controller.deleteProduct(selected);
    if (result['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.green),
      );
      await _refreshProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  Future<void> _handleDeleteAllUnits(Map<String, dynamic> product) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (dctx) => AlertDialog(
        title: const Text('Konfirmasi Hapus Semua'),
        content: const Text('Apakah Anda yakin ingin menghapus semua unit untuk produk ini?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dctx, false), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(dctx, true), child: const Text('Hapus Semua')),
        ],
      ),
    );

    if (confirm != true) return;

    final full = product['full'];
    if (full is! List || full.isEmpty) {
      // fallback
      await _handleDeleteProduct(product);
      return;
    }

    int success = 0;
    for (final item in full) {
      final m = item as Map<String, dynamic>;
      final id = m['id']?.toString() ?? m['id_product']?.toString() ?? '';
      if (id.isEmpty) continue;
      final res = await _controller.deleteProduct(id);
      if (res['success'] == true) success++;
      await Future.delayed(const Duration(milliseconds: 100));
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Hapus selesai: $success unit berhasil dihapus.'), backgroundColor: Colors.green),
    );
    await _refreshProducts();
  }

  Future<void> _handleEditAllUnits(Map<String, dynamic> product) async {
    final full = product['full'];
    if (full is! List || full.isEmpty) {
      _controller.navigateToEdit(context, product);
      return;
    }

    // Open edit page for the first unit, then apply returned changes to all units
    final first = full.first as Map<String, dynamic>;
    final updated = await _controller.navigateToEdit(context, {
      'full': first,
    });

    if (updated == null) return;

    // Build fields to update from returned product map
    final fields = <String, String>{};
    final keys = ['nama_product', 'kategori_product', 'merek_product', 'tanggal_beli', 'harga_product', 'jumlah_produk', 'tanggal_expired'];
    for (final k in keys) {
      if (updated[k] != null) fields[k] = updated[k].toString();
    }

    // Collect ids
    final List<Map<String, dynamic>> items = full.map<Map<String, dynamic>>((e) => e as Map<String, dynamic>).toList();
    final res = await _controller.updateItemsFields(items, fields);
    if (res['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Perubahan diterapkan ke ${res['updatedCount'] ?? 0} unit.'), backgroundColor: Colors.green),
      );
      await _refreshProducts();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(res['message'] ?? 'Gagal memperbarui semua unit'), backgroundColor: Colors.red),
      );
    }
  }
}