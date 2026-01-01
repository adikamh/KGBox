// lib/pages/list_product_page.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/restapi.dart';
import '../services/config.dart';
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
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 12),
                Expanded(child: Text('Error: ${e.toString()}')),
              ],
            ),
            backgroundColor: Colors.red[600],
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
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
        color: Colors.blue[700],
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
        'Kelola Produk',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_rounded),
        onPressed: () => Navigator.pop(context),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: _refreshProducts,
          tooltip: 'Refresh',
        ),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
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
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
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
          Icon(Icons.search_rounded, color: Colors.blue[700]),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Cari produk...',
                border: InputBorder.none,
                hintStyle: TextStyle(color: Colors.grey[400]),
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
                child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
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
          final isSelected = _controller.filter == category;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _controller.filter = category;
                });
              },
              backgroundColor: Colors.white.withOpacity(0.2),
              selectedColor: Colors.white,
              labelStyle: TextStyle(
                color: isSelected ? Colors.blue[700] : Colors.white,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: BorderSide(
                  color: isSelected ? Colors.transparent : Colors.white,
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

    final filteredProducts = _controller.getFilteredProducts(_searchController.text);
    
    if (filteredProducts.isEmpty) {
      return _buildEmptyState();
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: filteredProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = filteredProducts[index];
        return _buildProductCard(product);
      },
    );
  }

  Widget _buildProductCard(Map<String, dynamic> product) {
    final isLowStock = _controller.isStockLow(product['stock']);
    
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _controller.navigateToDetail(context, product),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Product Icon
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        _controller.getCategoryColor(product['category']).withOpacity(0.8),
                        _controller.getCategoryColor(product['category']),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: _controller.getCategoryColor(product['category']).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(
                    _controller.getCategoryIcon(product['category']),
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                
                const SizedBox(width: 16),
                
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
                                fontSize: 16,
                                color: Colors.black87,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: Icon(Icons.edit_rounded, color: Colors.blue, size: 20),
                                tooltip: 'Edit produk',
                                onPressed: () async {
                                  final res = await _controller.navigateToEdit(context, product);
                                  if (res != null) {
                                    // reload list after edit
                                    await _loadProducts();
                                    if (mounted) setState(() {});
                                  }
                                },
                              ),
                              PopupMenuButton<int>(
                                icon: Icon(
                                  Icons.more_vert_rounded,
                                  color: Colors.grey[600],
                                  size: 22,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                itemBuilder: (ctx) => [
                                  const PopupMenuItem(
                                    value: 1,
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit_rounded, size: 20, color: Colors.blue),
                                        SizedBox(width: 12),
                                        Text('Edit'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 2,
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete_rounded, size: 20, color: Colors.red),
                                        SizedBox(width: 12),
                                        Text('Hapus'),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) async {
                                  if (value == 1) {
                                    final res = await _controller.navigateToEdit(context, product);
                                    if (res != null) {
                                      await _loadProducts();
                                      if (mounted) setState(() {});
                                    }
                                  } else if (value == 2) {
                                    await _handleDeleteProduct(product);
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 8),
                      
                      // Category
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _controller.getCategoryColor(product['category']).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
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
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                  color: Colors.green[700],
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
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isLowStock 
                                      ? Colors.orange[50] 
                                      : Colors.green[50],
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: isLowStock 
                                        ? Colors.orange[200]! 
                                        : Colors.green[200]!,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isLowStock 
                                          ? Icons.warning_rounded 
                                          : Icons.check_circle_rounded,
                                      size: 14,
                                      color: isLowStock 
                                          ? Colors.orange[700] 
                                          : Colors.green[700],
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '${product['stock']} unit',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isLowStock 
                                            ? Colors.orange[700] 
                                            : Colors.green[700],
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
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
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inventory_2_outlined,
                size: 64,
                color: Colors.blue[300],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tidak Ada Produk',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchController.text.isNotEmpty || _controller.filter != 'Semua'
                  ? 'Coba ubah filter atau pencarian'
                  : 'Belum ada produk yang tersedia',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (_searchController.text.isNotEmpty || _controller.filter != 'Semua')
              SizedBox(
                width: 160,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    _searchController.clear();
                    setState(() {
                      _controller.filter = 'Semua';
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Reset Filter',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleDeleteProduct(Map<String, dynamic> product) async {
    // Ask whether to delete whole product or a single barcode
    final choice = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Produk'),
        content: const Text('Hapus seluruh produk beserta semua barcode, atau hapus hanya satu barcode?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, 'cancel'), child: const Text('Batal')),
          TextButton(onPressed: () => Navigator.pop(ctx, 'single'), child: const Text('Hapus 1 Barcode')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, 'all'), child: const Text('Hapus Semua')),
        ],
      ),
    );

    if (choice == null || choice == 'cancel') return;

    final firestore = FirebaseFirestore.instance;
    final api = DataService();

    // Build list of unit ids/barcodes from product['full']
    final List<String> unitIds = [];
    final full = product['full'];
    if (full is List) {
      for (final u in full) {
        if (u is Map) {
          final id = (u['id_product'] ?? u['id'] ?? u['_id'] ?? u['kode'] ?? u['barcode'] ?? '').toString();
          if (id.isNotEmpty && !unitIds.contains(id)) unitIds.add(id);
        }
      }
    } else if (full is Map) {
      final id = (full['id_product'] ?? full['id'] ?? full['_id'] ?? full['kode'] ?? full['barcode'] ?? '').toString();
      if (id.isNotEmpty) unitIds.add(id);
    }

    if (choice == 'single') {
      // Ask which barcode to delete
      if (unitIds.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada barcode/unit yang dapat dihapus')));
        return;
      }
      String? selected = unitIds.length == 1 ? unitIds.first : null;
      final pick = await showDialog<String?>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Pilih Barcode untuk dihapus'),
          content: SizedBox(
            width: double.maxFinite,
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: unitIds.length,
              itemBuilder: (c, i) {
                final v = unitIds[i];
                return RadioListTile<String>(
                  value: v,
                  groupValue: selected,
                  title: Text(v),
                  onChanged: (val) { selected = val; Navigator.of(ctx).pop(val); },
                );
              },
            ),
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Batal'))],
        ),
      );

      if (pick == null) return;

      // Delete single barcode from Firestore and attempt server delete
      try {
        await firestore.collection('product_barcodes').doc(pick).delete();
      } catch (_) {}
      try {
        await api.removeId(token, project, collection, appid, pick);
      } catch (_) {}

      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barcode berhasil dihapus')));
      await _refreshProducts();
      return;
    }

    // choice == 'all' -> delete product record and all related barcode documents
    final confirm = await _controller.showDeleteConfirmation(context, product['name']);
    if (confirm != true) return;

    final serverResult = await _controller.deleteProduct(product['id']);
    // Attempt to delete Firestore product doc(s) and barcode docs
    try {
      // Determine possible product master id from first unit
      String masterId = '';
      if (full is List && full.isNotEmpty && full.first is Map) {
        final fm = full.first as Map<String, dynamic>;
        masterId = (fm['id_product'] ?? fm['id'] ?? fm['_id'] ?? '').toString();
      }
      if (masterId.isNotEmpty) {
        // delete master product doc
        try { await firestore.collection('products').doc(masterId).delete(); } catch (_) {}
        // delete all barcode docs with productId == masterId
        final q = await firestore.collection('product_barcodes').where('productId', isEqualTo: masterId).get();
        for (final d in q.docs) {
          try { await d.reference.delete(); } catch (_) {}
        }
      }
    } catch (e) {
      debugPrint('Error deleting Firestore docs: $e');
    }

    if (!mounted) return;
    if (serverResult['success'] == true) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverResult['message'] ?? 'Produk dihapus'), backgroundColor: Colors.green[600]));
      await _refreshProducts();
    } else {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(serverResult['message'] ?? 'Gagal menghapus'), backgroundColor: Colors.red[600]));
    }
    return;
  }
}