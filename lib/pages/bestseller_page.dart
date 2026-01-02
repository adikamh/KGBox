import 'package:flutter/material.dart';

class BestSellerPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final bool loading;
  final Future<void> Function()? onRefresh;
  BestSellerPage({
    super.key,
    required this.items,
    required this.loading,
    this.onRefresh,
  });

  @override
  State<BestSellerPage> createState() => _BestSellerPageState();
}

class _BestSellerPageState extends State<BestSellerPage> {
  String _query = '';
  final String _sortBy = 'terjual';
  final bool _descending = true;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filtered = widget.items.where((it) {
      final name =
          (it['nama'] ?? it['id_product'] ?? '').toString().toLowerCase();
      return _query.isEmpty || name.contains(_query.toLowerCase());
    }).toList();

    filtered.sort((a, b) {
      if (_sortBy == 'nama') {
        final aName = (a['nama'] ?? a['id_product'] ?? '').toString();
        final bName = (b['nama'] ?? b['id_product'] ?? '').toString();
        return _descending
            ? bName.compareTo(aName)
            : aName.compareTo(bName);
      } else {
        final aCount = (a['count'] ?? 0) as int;
        final bCount = (b['count'] ?? 0) as int;
        return _descending
            ? bCount.compareTo(aCount)
            : aCount.compareTo(bCount);
      }
    });

    final totalSold =
        filtered.fold<int>(0, (s, i) => s + ((i['count'] ?? 0) as int));
    final top3 = filtered.length > 3 ? filtered.sublist(0, 3) : filtered;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: widget.loading
          ? _buildLoadingState()
          : Column(
              children: [
                _buildHeader(filtered, totalSold),
                if (filtered.isNotEmpty) _buildTopPodium(top3),
                _buildListHeader(filtered.length),
                Expanded(child: _buildProductList(filtered)),
              ],
            ),
    );
  }

  // ================= HEADER =================

  Widget _buildHeader(List<Map<String, dynamic>> filtered, int totalSold) {
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
                      'Best Seller',
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

              if (filtered.isNotEmpty) ...[
                const SizedBox(height: 10),
                _buildInlineStats(filtered, totalSold),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ================= INLINE STATS =================

  Widget _buildInlineStats(
      List<Map<String, dynamic>> filtered, int totalSold) {
    final avg =
        filtered.isNotEmpty ? totalSold / filtered.length : 0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _inlineStatItem(Icons.inventory_2_rounded,
            filtered.length.toString(), 'Produk'),
        _verticalDivider(),
        _inlineStatItem(Icons.shopping_cart_rounded,
            totalSold.toString(), 'Terjual'),
        _verticalDivider(),
        _inlineStatItem(Icons.analytics_rounded,
            avg.toStringAsFixed(1), 'Rata-rata'),
      ],
    );
  }

  Widget _inlineStatItem(
      IconData icon, String value, String label) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 6),
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
        color: Colors.white.withOpacity(0.35),
      );

  // ================= PODIUM =================

  Widget _buildTopPodium(List<Map<String, dynamic>> top3) {
    if (top3.isEmpty) return const SizedBox.shrink();

    return Container(
      height: 200,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (top3.length >= 2)
            Expanded(child: _buildPodiumItem(top3[1], 2, 130)),
          const SizedBox(width: 8),
          Expanded(child: _buildPodiumItem(top3[0], 1, 170)),
          const SizedBox(width: 8),
          if (top3.length >= 3)
            Expanded(child: _buildPodiumItem(top3[2], 3, 110)),
        ],
      ),
    );
  }

  Widget _buildPodiumItem(
      Map<String, dynamic> item, int rank, double height) {
    final color = _getRankColor(rank);
    final name =
        (item['nama'] ?? item['id_product'] ?? '').toString();
    final count = item['count'] ?? 0;

    return Container(
      height: height,
      decoration: BoxDecoration(
        gradient:
            LinearGradient(colors: [color.withOpacity(0.8), color]),
        borderRadius:
            const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          CircleAvatar(
            backgroundColor: Colors.white24,
            child: Text('$rank',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold)),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Text(
              name,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 13),
            ),
          ),
          Container(
            padding:
                const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
            color: Colors.white24,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.local_fire_department_rounded,
                    color: Colors.white, size: 14),
                const SizedBox(width: 4),
                Text('$count',
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          )
        ],
      ),
    );
  }

  // ================= LIST =================

  Widget _buildListHeader(int count) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Daftar Produk',
              style: TextStyle(fontWeight: FontWeight.w600)),
          Text('$count produk',
              style: TextStyle(
                  color: Colors.blue[700],
                  fontWeight: FontWeight.w600,
                  fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildProductList(List<Map<String, dynamic>> filtered) {
    if (filtered.isEmpty) return _buildEmptyState();

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      itemCount: filtered.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) =>
          _buildProductCard(filtered[i], i + 1, filtered),
    );
  }

  Widget _buildProductCard(
      Map<String, dynamic> item, int rank, List<Map<String, dynamic>> list) {
    final count = item['count'] ?? 0;
    final max = (list.first['count'] ?? 1) as int;
    final percent = (count / max).clamp(0, 1);

    return InkWell(
      onTap: () => _showProductDetail(item, rank),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16)),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                    colors: rank <= 3
                        ? [
                            _getRankColor(rank).withOpacity(0.8),
                            _getRankColor(rank)
                          ]
                        : [Colors.grey, Colors.grey.shade600]),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Center(
                  child: Text('$rank',
                      style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold))),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                        item['nama'] ??
                            item['id_product'] ??
                            '',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: LinearProgressIndicator(
                            value: percent,
                            minHeight: 6,
                            backgroundColor: Colors.grey[200],
                            valueColor: AlwaysStoppedAnimation(_getProgressColor(percent * 100)),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('Terjual', style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                            Text('$count', style: const TextStyle(fontWeight: FontWeight.bold)),
                          ],
                        )
                      ],
                    )
                  ]),
            ),
            const Icon(Icons.chevron_right_rounded,
                color: Colors.grey)
          ],
        ),
      ),
    );
  }

  // ================= HELPERS =================

  Widget _buildLoadingState() =>
      const Center(child: CircularProgressIndicator());

  Widget _buildEmptyState() =>
      const Center(child: Text('Tidak ada data'));

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber;
      case 2:
        return Colors.grey;
      case 3:
        return Colors.brown;
      default:
        return Colors.blueGrey;
    }
  }

  Color _getProgressColor(double p) {
    if (p >= 80) return Colors.green;
    if (p >= 50) return Colors.orange;
    if (p >= 30) return Colors.blue;
    return Colors.grey;
  }

  void _showSortOptions(BuildContext context) {}
  void _showProductDetail(
      Map<String, dynamic> product, int rank) {}
}
