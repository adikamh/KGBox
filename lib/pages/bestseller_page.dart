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

  @override
  Widget build(BuildContext context) {
    final filtered = widget.items.where((it) {
      final name = (it['nama'] ?? it['id_product'] ?? '').toString().toLowerCase();
      return _query.isEmpty || name.contains(_query.toLowerCase());
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Best Seller')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              decoration: const InputDecoration(prefixIcon: Icon(Icons.search), hintText: 'Cari produk...'),
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: widget.loading
                ? const Center(child: CircularProgressIndicator())
                : ListView.separated(
                    padding: const EdgeInsets.all(12),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (context, index) {
                      final it = filtered[index];
                      final rank = index + 1;
                      final count = it['count'] ?? 0;
                      final id = it['id_product'] ?? '';
                      final name = it['nama'] ?? id;

                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: rank <= 3 ? Colors.orange : Colors.grey.shade300,
                          child: Text('$rank', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(name.toString()),
                        subtitle: Text('Terjual: $count'),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
