import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/restapi.dart';
import '../services/config.dart';
import '../pages/stok_produk_page.dart';

class StokProdukScreen extends StatefulWidget {
  const StokProdukScreen({super.key});

  @override
  State<StokProdukScreen> createState() => _StokProdukScreenState();
}

class _StokProdukScreenState extends State<StokProdukScreen> {
  final DataService _api = DataService();
  List<Map<String, dynamic>> _products = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final res = await _api.selectAll(token, project, 'product', appid);
      final jsonRes = json.decode(res);
      setState(() => _products = List<Map<String, dynamic>>.from(jsonRes['data'] ?? []));
    } catch (e) {
      debugPrint('Error loading products: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _requestStock(String productId) async {
    final qtyCtrl = TextEditingController(text: '1');
    final qtyStr = await showDialog<String?>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Minta Stok'),
        content: TextField(controller: qtyCtrl, keyboardType: TextInputType.number),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Batal')),
          ElevatedButton(onPressed: () => Navigator.pop(ctx, qtyCtrl.text), child: const Text('Kirim')),
        ],
      ),
    );

    if (qtyStr == null) return;
    final qty = int.tryParse(qtyStr) ?? 0;
    if (qty <= 0) return;

    final map = {
      'ownerid': '',
      'product_id': productId,
      'qty': qty.toString(),
      'status': 'pending',
    };

    try {
      await _api.insertOne(token, project, 'stock_requests', appid, map);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan stok dikirim')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal kirim: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StokProdukPage(products: _products, loading: _loading, onRequestStock: _requestStock);
  }
}
