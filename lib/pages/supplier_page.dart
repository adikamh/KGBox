import 'package:flutter/material.dart';


class SupplierPage extends StatelessWidget {
  final List<Map<String, dynamic>> suppliers;
  final bool loading;
  final VoidCallback onAdd;
  final VoidCallback? onRefresh;
  final void Function(int index) onView;    // Detail
  final void Function(int index) onEdit;    // Edit
  final void Function(int index) onDelete;  // Delete

  const SupplierPage({
    super.key,
    required this.suppliers,
    required this.loading,
    required this.onAdd,
    required this.onView,
    required this.onEdit,
    required this.onDelete,
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Daftar Supplier'),
        actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: onRefresh,
                tooltip: 'Refresh',
              ),
            ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: onAdd,
        child: const Icon(Icons.add),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : suppliers.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.group_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'Belum ada supplier',
                        style: TextStyle(color: Colors.grey, fontSize: 16),
                      ),
                      Text(
                        'Tap + untuk menambahkan',
                        style: TextStyle(color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: suppliers.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final s = suppliers[index];
                    return _buildSupplierCard(s, index, context);
                  },
                ),
    );
  }

  Widget _buildSupplierCard(Map<String, dynamic> supplier, int index, BuildContext context) {
    final company = supplier['company'] as String? ?? supplier['name'] as String? ?? 'Perusahaan';
    final contact = supplier['name'] as String? ?? '';
    final phone = supplier['phone'] as String? ?? '-';
    final address = supplier['alamat'] as String? ?? '-';

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => onView(index),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.blue.shade50,
                    child: Text(
                      _initials(company, contact),
                      style: const TextStyle(color: Colors.blue, fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          company,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                contact.isNotEmpty ? contact : phone,
                                style: const TextStyle(color: Colors.grey, fontSize: 14),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      switch (value) {
                        case 'view':
                          onView(index);
                          break;
                        case 'edit':
                          onEdit(index);
                          break;
                        case 'delete':
                          onDelete(index);
                          break;
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(value: 'view', child: Text('Detail')),
                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                      const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 10),
              _buildInfoRow(Icons.phone, phone),
              _buildInfoRow(Icons.location_on, address),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    tooltip: 'Detail',
                    onPressed: () => onView(index),
                    icon: const Icon(Icons.visibility, color: Colors.blue),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Edit',
                    onPressed: () => onEdit(index),
                    icon: const Icon(Icons.edit, color: Colors.green),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Hapus',
                    onPressed: () => onDelete(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  String _initials(String company, String contact) {
    final source = (company.isNotEmpty ? company : contact).trim();
    if (source.isEmpty) return '';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts[0].substring(0, 1) + parts[1].substring(0, 1)).toUpperCase();
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: Colors.grey),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}