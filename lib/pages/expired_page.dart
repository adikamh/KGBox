import 'package:flutter/material.dart';

class ExpiredPage extends StatelessWidget {
  final List<Map<String, dynamic>> items;
  final bool loading;

  const ExpiredPage({super.key, required this.items, required this.loading});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Kadaluarsa')),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final row = items[index];
                final p = row['full'] as Map<String, dynamic>;
                final nama = p['nama_product'] ?? p['nama'] ?? 'Tanpa Nama';
                final exp = row['expired_at'];
                return ListTile(
                  title: Text(nama),
                  subtitle: Text('Kadaluarsa: $exp'),
                );
              },
            ),
    );
  }
}
