import 'package:flutter/material.dart';

class PengirimanPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final bool loading;
  final void Function(String alamat) onOpenMap;

  const PengirimanPage({super.key, required this.orders, required this.loading, required this.onOpenMap});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Pengiriman')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: orders.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final o = orders[index];
                final toko = o['nama_toko'] ?? o['customer_name'] ?? 'Toko';
                final alamat = o['alamat_toko'] ?? '';
                final tanggal = o['tanggal_order'] ?? '';
                return ListTile(
                  title: Text(toko),
                  subtitle: Text('$alamat\n$tanggal'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: alamat.isNotEmpty ? () => onOpenMap(alamat) : null,
                  ),
                );
              },
            ),
    );
  }
}
