import 'dart:math';

import 'package:flutter/material.dart';

class PengirimanPage extends StatelessWidget {
  final List<Map<String, dynamic>> orders;
  final bool loading;
  final void Function(String alamat) onOpenMap;
  final void Function(Map<String, dynamic> order) onOpenOrder;
  final String? ownerId;

  const PengirimanPage({
    super.key, 
    required this.orders, 
    required this.loading, 
    required this.onOpenMap, 
    required this.onOpenOrder,
    this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('History Pengiriman'),
            if (ownerId != null) ...[
              const SizedBox(height: 4),
              Text(
                'Owner: ${ownerId!.substring(0, min(8, ownerId!.length))}...',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.normal,
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (!loading)
            IconButton(
              icon: const Icon(Icons.filter_list),
              onPressed: () {
                // Tampilkan filter options jika diperlukan
                showDialog(
                  context: context,
                  builder: (context) => AlertDialog(
                    title: const Text('Filter Order'),
                    content: Text('Menampilkan ${orders.length} order untuk owner ini'),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('OK'),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : orders.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.inbox, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Tidak ada data pengiriman',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        ownerId != null 
                          ? 'Untuk owner ID: ${ownerId!.substring(0, min(6, ownerId!.length))}...'
                          : 'Silakan login terlebih dahulu',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () {
                          // Trigger refresh
                          (context as Element).markNeedsBuild();
                        },
                        child: const Text('Refresh'),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(12),
                  itemCount: orders.length,
                  separatorBuilder: (_, __) => const Divider(),
                  itemBuilder: (context, index) {
                    final o = orders[index];
                    final toko = o['nama_toko'] ?? o['customer_name'] ?? 'Toko';
                    final alamat = o['alamat_toko'] ?? '';
                    final tanggal = o['tanggal_order'] ?? '';
                    final status = o['status'] ?? '';
                    
                    // Tampilkan badge status
                    Color statusColor = Colors.grey;
                    if (status.toString().toLowerCase().contains('selesai')) {
                      statusColor = Colors.green;
                    } else if (status.toString().toLowerCase().contains('proses')) {
                      statusColor = Colors.orange;
                    } else if (status.toString().toLowerCase().contains('batal')) {
                      statusColor = Colors.red;
                    }

                    return Card(
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      child: ListTile(
                        title: Row(
                          children: [
                            Expanded(child: Text(toko)),
                            if (status.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: statusColor.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(color: statusColor),
                                ),
                                child: Text(
                                  status,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: statusColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(alamat),
                            const SizedBox(height: 4),
                            Text(
                              tanggal,
                              style: const TextStyle(color: Colors.grey, fontSize: 12),
                            ),
                            // Tampilkan owner ID jika berbeda dengan user saat ini
                            if (o['ownerid'] != null || o['owner_id'] != null)
                              Text(
                                'Owner: ${o['ownerid'] ?? o['owner_id']}',
                                style: const TextStyle(color: Colors.blueGrey, fontSize: 10),
                              ),
                          ],
                        ),
                        isThreeLine: true,
                        onTap: () => onOpenOrder(o),
                        trailing: IconButton(
                          icon: const Icon(Icons.map),
                          onPressed: alamat.isNotEmpty ? () => onOpenMap(alamat) : null,
                        ),
                      ),
                    );
                  },
                ),
    );
  }
}