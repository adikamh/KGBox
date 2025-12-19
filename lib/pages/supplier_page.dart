import 'package:flutter/material.dart';

class SupplierPage extends StatelessWidget {
  final List<Map<String, dynamic>> suppliers;
  final bool loading;
  final VoidCallback onAdd;

  const SupplierPage({super.key, required this.suppliers, required this.loading, required this.onAdd});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier')),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: suppliers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final s = suppliers[index];
                return ListTile(
                  title: Text(s['company'] ?? 'Perusahaan'),
                  subtitle: Text('${s['name'] ?? ''} • ${s['phone'] ?? ''}\n${s['alamat'] ?? ''}'),
                  isThreeLine: true,
                );
              },
            ),
    );
  }
}
