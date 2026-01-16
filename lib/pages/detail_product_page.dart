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
    debugPrint('Product data received: ${widget.product}'); // Tambahkan log ini untuk memeriksa data
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

  // ignore: unused_element
  Future<void> _pickAndSaveExpiredDate(Map<String, dynamic> product) async {
    try {
      final rawExpired = product['expiredRaw'] ?? product['expiredDate'] ?? product['tanggal_expired'];
      DateTime initial = DateTime.now();
      final parsed = _localParseDate(rawExpired);
      if (parsed != null) initial = parsed;

      final picked = await showDatePicker(
        context: navigatorKeyCurrentContext(),
        initialDate: initial,
        firstDate: DateTime(2000),
        lastDate: DateTime(2100),
      );
      if (picked == null) return;

      // Format as yyyy-MM-dd string for storage
      final formatted = '${picked.year}-${picked.month.toString().padLeft(2,'0')}-${picked.day.toString().padLeft(2,'0')}';

      final productId = (product['id'] ?? product['productId'] ?? product['id_product'] ?? '').toString();
      if (productId.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat menentukan ID produk untuk menyimpan expired')));
        return;
      }

      await _firestore.collection('products').doc(productId).update({'expiredDate': formatted});

      // update local product map and controller
      product['expiredRaw'] = formatted;
      product['expiredText'] = _computeExpiredTextLocal(formatted);
      // reinitialize controller data
      _controller.initialize(product);

      if (mounted) {
        setState(() {});
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tanggal expired berhasil diperbarui')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan tanggal expired: $e')));
    }
  }

  BuildContext navigatorKeyCurrentContext() {
    // try to find a context to use for showDatePicker; fall back to this state's context
    return context;
  }

  DateTime? _localParseDate(dynamic v) {
    if (v == null) return null;
    try {
      if (v is DateTime) return v;
      if (v is Timestamp) return v.toDate();
      if (v is int) return DateTime.fromMillisecondsSinceEpoch(v);
      if (v is String) {
        final s = v.trim();
        if (RegExp(r"^\d{4}-\d{2}-\d{2}").hasMatch(s)) {
          return DateTime.parse(s);
        }
        return DateTime.tryParse(s);
      }
    } catch (_) {}
    return null;
  }

  String _computeExpiredTextLocal(dynamic rawExpired) {
    final dt = _localParseDate(rawExpired);
    if (dt == null) return '-';
    final now = DateTime.now();
    final end = DateTime(dt.year, dt.month, dt.day);
    final diff = end.difference(DateTime(now.year, now.month, now.day)).inDays;
    if (diff < 0) return 'Sudah expired';
    if (diff == 0) return 'Expired hari ini';
    if (diff <= 14) {
      if (diff % 7 == 0) {
        final weeks = (diff / 7).round();
        return 'Expired dalam $weeks minggu';
      }
      return 'Expired dalam $diff hari';
    }
    // fallback formatted
    final d = dt.toLocal();
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    final day = d.day.toString().padLeft(2, '0');
    final month = months[d.month - 1];
    final year = d.year.toString();
    return '$day $month $year';
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
                            }),
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
              label: 'Tanggal produksi',
              value: product['productionDate']?.toString() ?? '-',
            ),
            
            const Divider(height: 32),

            _buildDetailRow(
              icon: Icons.store_rounded,
              label: 'Supplier',
              value: product['supplierCompany']?.toString() ?? '-',
            ),

            const Divider(height: 32),

            _buildDetailRow(
              icon: Icons.straighten_rounded,
              label: 'Ukuran Produk',
              value: widget.product['ukuran']?.toString().isNotEmpty == true
                  ? widget.product['ukuran'].toString()
                  : '-',
            ),

            const Divider(height: 32),

            _buildDetailRow(
              icon: Icons.color_lens_rounded,
              label: 'Varian Produk',
              value: widget.product['varian']?.toString().isNotEmpty == true
                  ? widget.product['varian'].toString()
                  : 'Tidak ada',
            ),

            const Divider(height: 32),

            _buildDetailRow(
              icon: Icons.inventory_2_rounded,
              label: 'Isi per Dus',
              value: widget.product['isiPerDus']?.toString().isNotEmpty == true
                  ? widget.product['isiPerDus'].toString()
                  : '-',
            ),

            const Divider(height: 32),

            // Expired date: editable
            _buildExpiredRow(
              controller: controller,
              product: product,
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

  Widget _buildExpiredRow({
    required DetailProductScreen controller,
    required Map<String, dynamic> product,
  }) {
    // Use server value for expired date and format it for display.
    final raw = product['expiredRaw'] ?? product['expiredDate'] ?? product['tanggal_expired'] ?? '';
    final parsed = _localParseDate(raw);
    String display;
    if (parsed != null) {
      final d = parsed.toLocal();
      const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
      display = '${d.day.toString().padLeft(2,'0')} ${months[d.month - 1]} ${d.year}';
    } else if (raw is String && raw.toString().isNotEmpty) {
      display = raw.toString();
    } else {
      display = '-';
    }

    final Color textColor = Colors.black87;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.calendar_today_rounded, size: 18, color: Colors.grey[700]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tanggal Expired',
                style: TextStyle(fontSize: 13, color: Colors.grey[600], fontWeight: FontWeight.w500, letterSpacing: 0.2),
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      display,
                      style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: textColor, height: 1.4),
                    ),
                  ),
                  const SizedBox(width: 8),
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

                    final pick = await showDialog<List<String>?>(
                      context: context,
                      builder: (ctx) {
                        final TextEditingController searchCtrl = TextEditingController();
                        List<String> filtered = _barcodes.map((e) => e['barcode']?.toString() ?? '').toList();
                        final Set<String> selectedSet = {};

                        return StatefulBuilder(builder: (ctx2, setState2) {
                          void applyFilter(String q) {
                            final qq = q.trim().toLowerCase();
                            filtered = qq.isEmpty
                                ? _barcodes.map((e) => e['barcode']?.toString() ?? '').toList()
                                : _barcodes.map((e) => e['barcode']?.toString() ?? '').where((e) => e.toLowerCase().contains(qq)).toList();
                          }

                          return AlertDialog(
                            title: const Text('Pilih Barcode untuk dihapus'),
                            content: SizedBox(
                              width: double.maxFinite,
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  TextField(
                                    controller: searchCtrl,
                                    decoration: InputDecoration(
                                      hintText: 'Cari barcode...',
                                      prefixIcon: const Icon(Icons.search),
                                      suffixIcon: searchCtrl.text.isNotEmpty
                                          ? IconButton(icon: const Icon(Icons.close), onPressed: () { searchCtrl.clear(); applyFilter(''); setState2(() {}); })
                                          : null,
                                    ),
                                    onChanged: (v) { applyFilter(v); setState2(() {}); },
                                  ),
                                  const SizedBox(height: 8),
                                  // Select-all header
                                  Builder(builder: (ctx3) {
                                    final allSelected = filtered.isNotEmpty && filtered.every((e) => selectedSet.contains(e));
                                    return Row(
                                      children: [
                                        Checkbox(
                                          value: allSelected,
                                          onChanged: (val) {
                                            setState2(() {
                                              if (val == true) {
                                                selectedSet.addAll(filtered);
                                              } else {
                                                for (final f in filtered) {
                                                  selectedSet.remove(f);
                                                }
                                              }
                                            });
                                          },
                                        ),
                                        const SizedBox(width: 4),
                                        const Expanded(child: Text('Pilih Semua', style: TextStyle(fontWeight: FontWeight.w600))),
                                        TextButton(
                                          onPressed: () {
                                            setState2(() {
                                              if (allSelected) {
                                                for (final f in filtered) {
                                                  selectedSet.remove(f);
                                                }
                                              } else {
                                                selectedSet.addAll(filtered);
                                              }
                                            });
                                          },
                                          child: Text(allSelected ? 'Batal' : 'Pilih Semua'),
                                        ),
                                      ],
                                    );
                                  }),
                                  const SizedBox(height: 8),
                                  Expanded(
                                    child: filtered.isEmpty
                                        ? const Center(child: Text('Tidak ditemukan'))
                                        : ListView.builder(
                                            shrinkWrap: true,
                                            itemCount: filtered.length,
                                            itemBuilder: (c, i) {
                                              final v = filtered[i];
                                              final checked = selectedSet.contains(v);
                                              return CheckboxListTile(
                                                value: checked,
                                                title: Text(v),
                                                controlAffinity: ListTileControlAffinity.leading,
                                                onChanged: (val) {
                                                  setState2(() {
                                                    if (val == true) {
                                                      selectedSet.add(v);
                                                    } else {
                                                      selectedSet.remove(v);
                                                    }
                                                  });
                                                },
                                              );
                                            },
                                          ),
                                  ),
                                ],
                              ),
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Batal')),
                              ElevatedButton(
                                onPressed: selectedSet.isEmpty ? null : () => Navigator.pop(ctx, selectedSet.toList()),
                                child: const Text('Hapus Terpilih'),
                              ),
                            ],
                          );
                        });
                      },
                    );

                    if (pick == null || pick.isEmpty) return;
                    for (final code in pick) {
                      try { await FirebaseFirestore.instance.collection('product_barcodes').doc(code).delete(); } catch (_) {}
                    }
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${pick.length} barcode berhasil dihapus')));
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