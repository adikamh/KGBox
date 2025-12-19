import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/restapi.dart';
import '../services/config.dart';

class BestSellerScreen extends StatefulWidget {
  const BestSellerScreen({super.key});

  @override
  State<BestSellerScreen> createState() => _BestSellerScreenState();
}

class _BestSellerScreenState extends State<BestSellerScreen> {
  final DataService _api = DataService();
  List<Map<String, dynamic>> _items = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadBestSellers();
  }

  Future<void> _loadBestSellers() async {
    setState(() => _loading = true);
    try {
      final res = await _api.selectAll(token, project, 'order_items', appid);
      final jsonRes = json.decode(res);
      final data = List<Map<String, dynamic>>.from(jsonRes['data'] ?? []);

      // aggregate by id_product
      final Map<String, Map<String, dynamic>> agg = {};
      for (final it in data) {
        final id = (it['id_product'] ?? '').toString();
        final qty = int.tryParse(it['jumlah_produk']?.toString() ?? '0') ?? 0;
        if (agg.containsKey(id)) {
          agg[id]!['count'] = (agg[id]!['count'] as int) + qty;
        } else {
          agg[id] = {'id_product': id, 'count': qty, 'sample': it};
        }
      }

      final list = agg.values.toList();
      list.sort((a, b) => (b['count'] as int).compareTo(a['count'] as int));

      setState(() {
        _items = List<Map<String, dynamic>>.from(list);
      });
    } catch (e) {
      debugPrint('Error loading bestsellers: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Best Seller')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final it = _items[index];
                final rank = index + 1;
                final count = it['count'] ?? 0;
                final id = it['id_product'] ?? '';

                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: rank <= 3 ? Colors.orange : Colors.grey.shade300,
                    child: Text('$rank', style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text(id.toString()),
                  subtitle: Text('Terjual: $count'),
                );
              },
            ),
    );
  }
}
