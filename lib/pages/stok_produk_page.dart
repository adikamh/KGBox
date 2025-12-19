import 'package:flutter/material.dart';

class StokProdukPage extends StatelessWidget {
  final List<Map<String, dynamic>> products;
  final bool loading;
  final void Function(String productId) onRequestStock;

  const StokProdukPage({super.key, required this.products, required this.loading, required this.onRequestStock});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Stok Produk')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: products.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final p = products[index];
                final nama = p['nama_product'] ?? p['nama'] ?? 'Tanpa Nama';
                final merek = p['merek_product'] ?? p['merek'] ?? '';
                final stok = p['jumlah_produk'] ?? p['stok'] ?? '0';
                final id = p['id_product'] ?? p['id'] ?? p['_id'] ?? '';
                return ListTile(
                  title: Text(nama),
                  subtitle: Text('$merek • Stok: $stok'),
                  trailing: TextButton(onPressed: () => onRequestStock(id.toString()), child: const Text('Minta Stok')),
                );
              },
            ),
    );
  }
}
