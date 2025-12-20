import 'package:flutter/material.dart';

class BestSellerPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final bool loading;

  const BestSellerPage({super.key, required this.items, required this.loading});

  @override
  State<BestSellerPage> createState() => _BestSellerPageState();
}

class _BestSellerPageState extends State<BestSellerPage> {
  String _query = '';
  String _sortBy = 'terjual';
  bool _descending = true;

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> filtered = widget.items.where((it) {
      final name = (it['nama'] ?? it['id_product'] ?? '').toString().toLowerCase();
      return _query.isEmpty || name.contains(_query.toLowerCase());
    }).toList();

    // Sorting
    filtered.sort((a, b) {
      if (_sortBy == 'nama') {
        final aName = (a['nama'] ?? a['id_product'] ?? '').toString();
        final bName = (b['nama'] ?? b['id_product'] ?? '').toString();
        return _descending ? bName.compareTo(aName) : aName.compareTo(bName);
      } else {
        final aCount = (a['count'] ?? 0) as int;
        final bCount = (b['count'] ?? 0) as int;
        return _descending ? bCount.compareTo(aCount) : aCount.compareTo(aCount);
      }
    });

    final totalSold = filtered.fold<int>(0, (sum, item) => sum + ((item['count'] ?? 0) as int));
    final top3 = filtered.length > 3 ? filtered.sublist(0, 3) : filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Best Seller'),
        actions: [
          IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
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
                            const SizedBox(height: 16),
                            RadioListTile(
                              title: const Text('Jumlah Terjual'),
                              value: 'terjual',
                              // ignore: deprecated_member_use
                              groupValue: _sortBy,
                              // ignore: deprecated_member_use
                              onChanged: (value) {
                                setStateSB(() => _sortBy = value.toString());
                                setState(() => _sortBy = value.toString());
                                Navigator.pop(context);
                              },
                            ),
                            RadioListTile(
                              title: const Text('Nama Produk'),
                              value: 'nama',
                              // ignore: deprecated_member_use
                              groupValue: _sortBy,
                              // ignore: deprecated_member_use
                              onChanged: (value) {
                                setStateSB(() => _sortBy = value.toString());
                                setState(() => _sortBy = value.toString());
                                Navigator.pop(context);
                              },
                            ),
                            const Divider(),
                            SwitchListTile(
                              title: const Text('Urutan Menurun'),
                              value: _descending,
                              onChanged: (value) {
                                setStateSB(() => _descending = value);
                                setState(() => _descending = value);
                              },
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
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
                  prefixIcon: const Icon(Icons.search, color: Colors.blueGrey),
                  hintText: 'Cari produk best seller...',
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

          // Stats Summary
          if (!widget.loading && filtered.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Card(
                color: Colors.blue.shade50,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Column(
                        children: [
                          Text(
                            filtered.length.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                          const Text(
                            'Produk',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.blueGrey.shade200,
                      ),
                      Column(
                        children: [
                          Text(
                            totalSold.toString(),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            'Total Terjual',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                      Container(
                        width: 1,
                        height: 40,
                        color: Colors.blueGrey.shade200,
                      ),
                      Column(
                        children: [
                          Text(
                            (filtered.isNotEmpty ? totalSold / filtered.length : 0).toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const Text(
                            'Rata-rata',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),

          // Top 3 Podium
          if (!widget.loading && top3.isNotEmpty)
            Container(
              height: 180,
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  // Peringkat 2
                  if (top3.length >= 2)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 120,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.grey.shade400, Colors.grey.shade300],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: const BoxDecoration(
                                    color: Colors.grey,
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '2',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 20,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        (top3[1]['nama'] ?? top3[1]['id_product'] ?? '')
                                            .toString()
                                            .split(' ')
                                            .take(2)
                                            .join(' '),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    '${top3[1]['count'] ?? 0}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Peringkat 1
                  if (top3.isNotEmpty)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 160,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.yellow.shade700, Colors.yellow.shade500],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.yellow.shade800,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '1',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 24,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        (top3[0]['nama'] ?? top3[0]['id_product'] ?? '')
                                            .toString()
                                            .split(' ')
                                            .take(2)
                                            .join(' '),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 14,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    '${top3[0]['count'] ?? 0}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Peringkat 3
                  if (top3.length >= 3)
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Container(
                            height: 100,
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [Colors.brown.shade400, Colors.brown.shade300],
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                              ),
                              borderRadius: const BorderRadius.only(
                                topLeft: Radius.circular(12),
                                topRight: Radius.circular(12),
                              ),
                            ),
                            child: Column(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.brown.shade600,
                                    borderRadius: const BorderRadius.only(
                                      topLeft: Radius.circular(12),
                                      topRight: Radius.circular(12),
                                    ),
                                  ),
                                  child: const Text(
                                    '3',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  child: Center(
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Text(
                                        (top3[2]['nama'] ?? top3[2]['id_product'] ?? '')
                                            .toString()
                                            .split(' ')
                                            .take(2)
                                            .join(' '),
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          fontSize: 11,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 8.0),
                                  child: Text(
                                    '${top3[2]['count'] ?? 0}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),

          // List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Daftar Produk',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                Text(
                  '${filtered.length} produk ditemukan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Main List
          Expanded(
            child: widget.loading
                ? const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        CircularProgressIndicator(),
                        SizedBox(height: 16),
                        Text('Memuat data best seller...'),
                      ],
                    ),
                  )
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.emoji_events_outlined,
                              size: 80,
                              color: Colors.grey.shade300,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Tidak ada data best seller',
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
                          ],
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        itemCount: filtered.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 8),
                        itemBuilder: (context, index) {
                          final it = filtered[index];
                          final rank = index + 1;
                          final count = it['count'] ?? 0;
                          final id = it['id_product'] ?? '';
                          final name = it['nama'] ?? id;
                          final String soldText = count.toString();

                          // Calculate width percentage for progress bar
                          final maxCount = filtered.isNotEmpty
                              ? (filtered[0]['count'] ?? 1) as int
                              : 1;
                          final percentage = maxCount > 0 ? (count / maxCount) * 100 : 0;

                          return Card(
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: rank <= 3 ? _getRankColor(rank) : Colors.grey.shade200,
                                ),
                                child: Center(
                                  child: Text(
                                    '$rank',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: rank <= 3 ? Colors.white : Colors.blueGrey,
                                      fontSize: rank <= 3 ? 16 : 14,
                                    ),
                                  ),
                                ),
                              ),
                              title: Text(
                                name.toString(),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(height: 4),
                                  Row(
                                    children: [
                                      const Icon(Icons.shopping_cart_checkout,
                                          size: 14, color: Colors.green),
                                      const SizedBox(width: 4),
                                      Text(
                                        'Terjual: $soldText',
                                        style: const TextStyle(color: Colors.green, fontSize: 12),
                                      ),
                                      const Spacer(),
                                      Text(
                                        '${percentage.toStringAsFixed(1)}% dari teratas',
                                        style: const TextStyle(color: Colors.grey, fontSize: 11),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  LinearProgressIndicator(
                                    value: percentage / 100,
                                    backgroundColor: Colors.grey.shade200,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      _getProgressColor(percentage),
                                    ),
                                    minHeight: 6,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ],
                              ),
                              trailing: const Icon(Icons.chevron_right, color: Colors.blueGrey),
                              onTap: () {
                                // Tampilkan detail produk
                                _showProductDetail(it, rank);
                              },
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.yellow.shade700;
      case 2:
        return Colors.grey.shade600;
      case 3:
        return Colors.brown.shade600;
      default:
        return Colors.blueGrey;
    }
  }

  Color _getProgressColor(double percentage) {
    if (percentage >= 80) return Colors.green;
    if (percentage >= 50) return Colors.orange;
    if (percentage >= 30) return Colors.blue;
    return Colors.grey;
  }

  void _showProductDetail(Map<String, dynamic> product, int rank) {
    final name = product['nama'] ?? product['id_product'] ?? '';
    final count = product['count'] ?? 0;
    final id = product['id_product'] ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _getRankColor(rank),
                    boxShadow: [
                      BoxShadow(
                        // ignore: deprecated_member_use
                        color: _getRankColor(rank).withOpacity(0.3),
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      '$rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 24,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Center(
                child: Text(
                  name.toString(),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 8),
              Center(
                child: Text(
                  'ID: $id',
                  style: const TextStyle(color: Colors.grey),
                ),
              ),
              const SizedBox(height: 30),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        children: [
                          Text(
                            count.toString(),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          const Text(
                            'Total Terjual',
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                        ],
                      ),
                      Column(
                        children: [
                          Icon(
                            Icons.emoji_events,
                            size: 40,
                            color: _getRankColor(rank),
                          ),
                          Text(
                            'Peringkat $rank',
                            style: TextStyle(
                              color: _getRankColor(rank),
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Statistik:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem(Icons.trending_up, 'Best Seller', _getRankColor(rank)),
                  _buildStatItem(Icons.attach_money, 'Profit', Colors.green),
                  _buildStatItem(Icons.visibility, 'Popular', Colors.blue),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'TUTUP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            // ignore: deprecated_member_use
            color: color.withOpacity(0.1),
            shape: BoxShape.circle,
            // ignore: deprecated_member_use
            border: Border.all(color: color.withOpacity(0.3)),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }
}