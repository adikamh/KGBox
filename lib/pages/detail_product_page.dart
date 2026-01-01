
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../screens/detail_product_screen.dart';

class DetailProductPage extends StatefulWidget {
  final Map<String, dynamic> product;

  const DetailProductPage({
    super.key,
    required this.product,
  });

  @override
  State<DetailProductPage> createState() => _DetailProductPageState();
}

class _DetailProductPageState extends State<DetailProductPage> {
  final DetailProductScreen _controller = DetailProductScreen();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  bool _loading = true;
  List<Map<String, dynamic>> _barcodes = [];

  @override
  void initState() {
    super.initState();
    _controller.initialize(widget.product);
    _loadBarcodes();
  }

  Future<void> _loadBarcodes() async {
    setState(() => _loading = true);
    try {
      final productId = (widget.product['id'] ?? widget.product['productId'] ?? '').toString();
      if (productId.isNotEmpty) {
        final q = await _firestore.collection('product_barcodes').where('productId', isEqualTo: productId).get();
        _barcodes = q.docs.map((d) {
          final data = (d.data() as Map<String, dynamic>?) ?? {};
          return {
            'barcode': d.id,
            'scannedAt': data['scannedAt'],
          };
        }).toList();
      } else {
        _barcodes = [];
      }
    } catch (e) {
      debugPrint('Error loading barcodes: $e');
      _barcodes = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final formattedProduct = _controller.getFormattedProduct();
    final unitCount = _barcodes.length;
    final isExpired = _controller.isProductExpired();
    final isStockLow = unitCount < 10;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with product info
            _buildHeader(_controller, formattedProduct, isExpired, isStockLow),
            
            // Body with details
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  // Price and Unit Cards
                  _buildStatsRow(_controller, formattedProduct, unitCount),
                  
                  const SizedBox(height: 20),
                  
                  // Product Information Card
                  _buildInfoCard(_controller, formattedProduct),
                  
                  const SizedBox(height: 16),
                  // Barcode list from Firestore
                  if (_loading)
                    const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                  else if (_barcodes.isNotEmpty)
                    Card(
                      elevation: 0,
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Daftar Barcode', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ..._barcodes.map((b) {
                              return ListTile(
                                dense: true,
                                title: Text(b['barcode'].toString()),
                                trailing: IconButton(
                                  icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                  onPressed: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        title: const Text('Hapus Barcode'),
                                        content: Text('Hapus barcode ${b['barcode']}?'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
                                          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Hapus')),
                                        ],
                                      ),
                                    );
                                    if (confirm != true) return;
                                    try {
                                      await _firestore.collection('product_barcodes').doc(b['barcode'].toString()).delete();
                                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barcode dihapus')));
                                      await _loadBarcodes();
                                      setState(() {});
                                    } catch (e) {
                                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
                                    }
                                  },
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                      ),
                    ),

                  const SizedBox(height: 24),
                  
                  // Action Buttons
                  _buildActionButtons(context, _controller, formattedProduct),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      title: const Text(
        'Detail Produk',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.blue[700],
      foregroundColor: Colors.white,
    );
  }

  Widget _buildHeader(
    DetailProductScreen controller,
    Map<String, dynamic> product,
    bool isExpired,
    bool isStockLow,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.blue[700]!,
            Colors.blue[900]!,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Product Icon
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withOpacity(0.3),
                width: 2,
              ),
            ),
            child: Icon(
              controller.getCategoryIcon(product['category']),
              size: 40,
              color: Colors.white,
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Product Name
          Text(
            product['name'],
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
              height: 1.3,
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Product Code
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              'Kode: ${product['code']}',
              style: const TextStyle(
                fontSize: 13,
                color: Colors.white,
                letterSpacing: 0.5,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Status Badges
          if (isExpired || isStockLow)
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isExpired)
                  _buildStatusBadge(
                    label: 'Expired',
                    color: Colors.red,
                  ),
                
                if (isExpired && isStockLow) const SizedBox(width: 8),
                
                if (isStockLow)
                  _buildStatusBadge(
                    label: 'Stok Rendah',
                    color: Colors.orange,
                  ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge({
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStatsRow(
    DetailProductScreen controller,
    Map<String, dynamic> product,
    int unitCount,
  ) {
    final bool isLow = unitCount < 10;
    return Row(
      children: [
        Expanded(
          child: _buildStatCard(
            icon: Icons.attach_money_rounded,
            iconColor: Colors.green[600]!,
            title: 'Harga',
            value: product['price']?.toString() ?? controller.formatPrice(product['priceRaw']),
          ),
        ),
        const SizedBox(width: 16),
            Expanded(
          child: _buildStatCard(
            icon: Icons.inventory_rounded,
            iconColor: Colors.orange[600]!,
            title: 'Unit',
            value: unitCount.toString(),
            subtitle: isLow ? 'Stok Rendah' : 'Stok Aman',
            subtitleColor: isLow ? Colors.orange : Colors.green,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    String? subtitle,
    Color? subtitleColor,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: subtitleColor ?? Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    DetailProductScreen controller,
    Map<String, dynamic> product,
  ) {
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
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    Icons.info_outline_rounded,
                    color: Colors.blue[700],
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Informasi Produk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 20),
            
            // Details
            _buildDetailRow(
              icon: Icons.category_rounded,
              label: 'Kategori',
              value: product['category'],
            ),
            
            const Divider(height: 32),
            
            _buildDetailRow(
              icon: Icons.business_rounded,
              label: 'Merek',
              value: product['brand'],
            ),
            
            const Divider(height: 32),
            
            _buildDetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Tanggal Beli',
              value: product['purchaseDate']?.toString() ?? '-',
            ),
            
            const Divider(height: 32),
            
            _buildDetailRow(
              icon: Icons.calendar_today_rounded,
              label: 'Tanggal Expired',
              value: product['expiredText']?.toString() ?? '-',
              valueColor: controller.getExpiredStatusColor(),
              showStatus: true,
              statusText: controller.getExpiredStatus(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    bool showStatus = false,
    String? statusText,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.grey[700]),
        ),
        
        const SizedBox(width: 14),
        
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              
              const SizedBox(height: 6),
              
              Row(
                children: [
                  Expanded(
                    child: Text(
                      value,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: valueColor ?? Colors.black,
                        height: 1.4,
                      ),
                    ),
                  ),
                  
                  if (showStatus && statusText != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: valueColor?.withOpacity(0.1) ?? Colors.grey[100],
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: (valueColor?.withOpacity(0.3)) ?? Colors.grey[300]!,
                        ),
                      ),
                      child: Text(
                        statusText,
                        style: TextStyle(
                          fontSize: 10,
                          color: valueColor ?? Colors.grey[700],
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(
    BuildContext context,
    DetailProductScreen controller,
    Map<String, dynamic> product,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final productModel = controller.createProductModel();
                  final updatedProduct = await controller.navigateToEdit(
                    context,
                    productModel,
                  );
                  
                  if (updatedProduct != null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Produk berhasil diperbarui'),
                        backgroundColor: Colors.green,
                      ),
                    );
                    Navigator.pop(context, updatedProduct);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[700],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.edit_rounded, size: 20),
                label: const Text(
                  'Edit',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          Expanded(
            child: SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () async {
                  // Ask whether to delete whole product or single barcode
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

                  // use barcodes loaded from Firestore in state
                  if (choice == 'single') {
                    if (_barcodes.isEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada barcode/unit yang dapat dihapus')));
                      return;
                    }
                    String? selected = _barcodes.length == 1 ? _barcodes.first['barcode']?.toString() : null;
                    final pick = await showDialog<String?>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Pilih Barcode untuk dihapus'),
                        content: SizedBox(
                          width: double.maxFinite,
                          child: ListView.builder(
                            shrinkWrap: true,
                            itemCount: _barcodes.length,
                            itemBuilder: (c, i) {
                              final v = _barcodes[i]['barcode']?.toString() ?? '';
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
                    try { await FirebaseFirestore.instance.collection('product_barcodes').doc(pick).delete(); } catch (_) {}
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barcode berhasil dihapus')));
                    await _loadBarcodes();
                    Navigator.of(context).pop(true);
                    return;
                  }

                  // delete all
                  final confirm = await controller.showDeleteConfirmation(context, product['name']);
                  if (confirm != true) return;
                  final result = await controller.deleteProduct();

                  if (result['success'] == true) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.green));
                    Navigator.of(context).pop(true);
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(result['message']), backgroundColor: Colors.red));
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[600],
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                icon: const Icon(Icons.delete_rounded, size: 20),
                label: const Text(
                  'Hapus',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}