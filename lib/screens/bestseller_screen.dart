import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/restapi.dart';
import '../services/config.dart';
import '../pages/bestseller_page.dart';

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

      // aggregate by nama_produk (from order_items)
      final Map<String, Map<String, dynamic>> agg = {};
      for (final it in data) {
        final productName = (it['nama_produk'] ?? it['id_product'] ?? '').toString();
        final qty = int.tryParse(it['jumlah_produk']?.toString() ?? '0') ?? 0;
        if (agg.containsKey(productName)) {
          agg[productName]!['count'] = (agg[productName]!['count'] as int) + qty;
        } else {
          agg[productName] = {'nama': productName, 'id_product': it['id_product'] ?? '', 'count': qty, 'sample': it};
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
    return BestSellerPage(items: _items, loading: _loading, onRefresh: _loadBestSellers);
  }
}
