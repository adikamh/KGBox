import 'package:flutter/material.dart';

class PengirimanPage extends StatefulWidget {
  final List<Map<String, dynamic>> orders;
  final bool loading;
  final void Function(String alamat) onOpenMap;
  final void Function(Map<String, dynamic> order) onOpenOrder;
  final Future<void> Function()? onRefresh;
  final String? ownerId;

  const PengirimanPage({
    super.key,
    required this.orders,
    required this.loading,
    required this.onOpenMap,
    required this.onOpenOrder,
    this.onRefresh,
    this.ownerId,
  });

  @override
  State<PengirimanPage> createState() => _PengirimanPageState();
}

class _PengirimanPageState extends State<PengirimanPage> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _statusFilter = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = widget.orders.where((order) {
      final q = _searchCtrl.text.trim().toLowerCase();
      if (q.isNotEmpty) {
        final toko = (order['nama_toko'] ?? order['customer_name'] ?? '').toString().toLowerCase();
        final oid = (order['order_id'] ?? order['orderId'] ?? order['id'] ?? '').toString().toLowerCase();
        if (!toko.contains(q) && !oid.contains(q)) return false;
      }
      if (_statusFilter.isNotEmpty) {
        final status = (order['status'] ?? '').toString().toLowerCase();
        if (!status.contains(_statusFilter.toLowerCase())) return false;
      }
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context),
      body: widget.loading
          ? _buildLoadingState()
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 6),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.search),
                      hintText: 'Cari toko atau order id...',
                      suffixIcon: _searchCtrl.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () => setState(() => _searchCtrl.clear()),
                            )
                          : null,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                _buildCounterBadge(),
                const SizedBox(height: 8),
                Expanded(child: filtered.isEmpty ? _buildEmptyState(context) : _buildOrderList(filtered)),
              ],
            ),
    );
  }

  String formatRp(dynamic v) {
    try {
      final n = int.tryParse(v?.toString() ?? '0') ?? (v is num ? v.toInt() : 0);
      final s = n.toString();
      return s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
    } catch (_) {
      return '0';
    }
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
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
        'History Pengiriman',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 18,
        ),
      ),
      centerTitle: true,
      actions: [
        if (!widget.loading)
          IconButton(
          icon: const Icon(Icons.refresh_rounded),
          onPressed: widget.onRefresh != null ? () => widget.onRefresh!() : null,
          tooltip: 'Refresh',
        ),
        if (!widget.loading)
          IconButton(
            icon: const Icon(Icons.filter_list_rounded),
            onPressed: () => _showFilterDialog(context),
            tooltip: 'Filter',
          ),
        const SizedBox(width: 8),
      ],
    );
  }

  void _showFilterDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(Icons.filter_list_rounded, color: Colors.blue[700]),
            ),
            const SizedBox(width: 12),
            const Text('Filter Order'),
          ],
        ),
        content: Text(
          'Menampilkan ${widget.orders.length} order untuk owner ini',
          style: TextStyle(color: Colors.grey[600]),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  Widget _buildCounterBadge() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.blue[400]!, Colors.blue[600]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.local_shipping_rounded,
              size: 20,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '${widget.orders.length} Pengiriman',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: Colors.black87,
            ),
          ),
          const Spacer(),
          _buildStatusLegend(),
        ],
      ),
    );
  }

  Widget _buildStatusLegend() {
    return Row(
      children: [
        _buildLegendDot(Colors.green),
        const SizedBox(width: 4),
        _buildLegendDot(Colors.orange),
        const SizedBox(width: 4),
        _buildLegendDot(Colors.red),
      ],
    );
  }

  Widget _buildLegendDot(Color color) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }

  Widget _buildOrderList(List<Map<String, dynamic>> list) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final order = list[index];
        return _buildOrderCard(order, context);
      },
    );
  }

  Widget _buildOrderCard(Map<String, dynamic> order, BuildContext context) {
    final toko = (order['nama_toko'] ?? order['customer_name'] ?? (order['_customer'] is Map ? (order['_customer']['nama_toko'] ?? order['_customer']['nama']) : null) ?? '').toString();
    final tanggal = order['tanggal_order'] ?? '-';
    final status = order['status'] ?? '';

    // normalize alamat: treat '-' or empty as absent
    final rawAlamat = (order['alamat_toko'] ?? order['customer_address'] ?? (order['_customer'] is Map ? (order['_customer']['alamat_toko'] ?? order['_customer']['alamat']) : null) ?? '').toString();
    final alamat = (rawAlamat.trim().isEmpty || rawAlamat.trim() == '-' || rawAlamat.trim() == '--') ? '' : rawAlamat;

    // derive item count and total price for a clear summary
    final itemCount = order['jumlah_produk'] ?? order['total_items'] ?? order['items_count'] ?? order['items'] is List ? (order['items'] as List).length : null;
    final totalVal = order['total_harga'] ?? order['total'] ?? order['grand_total'] ?? order['subtotal'] ?? '0';

    final statusData = _getStatusData(status);

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
          onTap: () => widget.onOpenOrder(order),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [statusData['color'].withOpacity(0.8), statusData['color']],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: statusData['color'].withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Icon(
                        statusData['icon'],
                        color: Colors.white,
                        size: 30,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            toko.isNotEmpty ? toko : 'Customer',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.black87,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (itemCount != null) Text('Items: ${itemCount.toString()}', style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                              if (itemCount != null) const SizedBox(width: 8),
                              Text('Total: Rp ${formatRp(totalVal)}', style: TextStyle(fontSize: 12, color: Colors.grey[700], fontWeight: FontWeight.w600)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          if (status.isNotEmpty)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: statusData['color'].withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                status,
                                style: TextStyle(
                                  fontSize: 11,
                                  color: statusData['color'],
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(
                        Icons.location_on_rounded,
                        color: alamat.isNotEmpty ? Colors.red[600] : Colors.grey[400],
                      ),
                      onPressed: alamat.isNotEmpty ? () => widget.onOpenMap(alamat) : null,
                      tooltip: 'Buka Maps',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Information Container
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    children: [
                      if (alamat.isNotEmpty) ...[
                        _buildInfoRow(
                          Icons.location_on_rounded,
                          'Alamat',
                          alamat,
                          Colors.red[600]!,
                        ),
                        const SizedBox(height: 10),
                      ],
                      _buildInfoRow(
                        Icons.calendar_today_rounded,
                        'Tanggal Order',
                        tanggal,
                        Colors.blue[600]!,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 12),

                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => widget.onOpenOrder(order),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.blue[700],
                          side: BorderSide(color: Colors.blue[200]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.visibility_outlined, size: 18),
                        label: const Text(
                          'Detail',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: alamat.isNotEmpty ? () => widget.onOpenMap(alamat) : null,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: alamat.isNotEmpty ? Colors.red[700] : Colors.grey,
                          side: BorderSide(
                            color: alamat.isNotEmpty ? Colors.red[200]! : Colors.grey[300]!,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.map_rounded, size: 18),
                        label: const Text(
                          'Maps',
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Map<String, dynamic> _getStatusData(String status) {
    final statusLower = status.toLowerCase();
    if (statusLower.contains('selesai')) {
      return {
        'color': Colors.green[600],
        'icon': Icons.check_circle_rounded,
      };
    } else if (statusLower.contains('proses')) {
      return {
        'color': Colors.orange[600],
        'icon': Icons.pending_rounded,
      };
    } else if (statusLower.contains('batal')) {
      return {
        'color': Colors.red[600],
        'icon': Icons.cancel_rounded,
      };
    }
    return {
      'color': Colors.grey[600],
      'icon': Icons.local_shipping_rounded,
    };
  }

  Widget _buildInfoRow(IconData icon, String label, String text, Color iconColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: iconColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 16, color: iconColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                text,
                style: const TextStyle(
                  fontSize: 14,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ],
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
            'Memuat data pengiriman...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
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
                Icons.local_shipping_outlined,
                size: 64,
                color: Colors.blue[300],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Tidak Ada Pengiriman',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
                widget.ownerId != null
                  ? 'Belum ada data pengiriman'
                  : 'Belum ada data pengiriman.\nSilakan login terlebih dahulu',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: 160,
              height: 48,
              child: ElevatedButton.icon(
                onPressed: () {
                  (context as Element).markNeedsBuild();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text(
                  'Refresh',
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
}