import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/restapi.dart';
import '../services/config.dart';
import '../pages/stok_produk_page.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/auth_provider.dart';

class StokProdukScreen extends StatefulWidget {
  const StokProdukScreen({super.key});

  @override
  State<StokProdukScreen> createState() => _StokProdukScreenState();
}

class _StokProdukScreenState extends State<StokProdukScreen> {
  final DataService _api = DataService();
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _stockHistory = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadProducts();
    _loadStockHistory();
  }

  Future<void> _loadProducts() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';
      
      dynamic res;
      if (ownerId.isNotEmpty) {
        res = await _api.selectWhere(token, project, 'product', appid, 'ownerid', ownerId);
      } else {
        res = await _api.selectAll(token, project, 'product', appid);
      }

      final jsonRes = res is String ? json.decode(res) : res;
      final data = List<Map<String, dynamic>>.from(
        jsonRes is Map ? (jsonRes['data'] ?? []) : (jsonRes is List ? jsonRes : [])
      );

      // compute stock counts from Firestore product_barcodes collection
      final firestore = FirebaseFirestore.instance;
      final Map<String, int> counts = {};
      final Set<String> productKeys = {};
      for (final item in data) {
        final pk = (item['id_product'] ?? item['id'] ?? item['_id'] ?? '').toString();
        if (pk.isNotEmpty) productKeys.add(pk);
      }
      final futures = productKeys.map((pk) async {
        try {
          final q = await firestore.collection('product_barcodes').where('productId', isEqualTo: pk).get();
          counts[pk] = q.size;
        } catch (e) {
          counts[pk] = 0;
        }
      }).toList();
      await Future.wait(futures);

      // attach stock count to each product item
      final enriched = data.map((item) {
        final pk = (item['id_product'] ?? item['id'] ?? item['_id'] ?? '').toString();
        final stock = counts[pk] ?? 0;
        final Map<String, dynamic> copy = Map<String, dynamic>.from(item);
        copy['stok'] = stock;
        copy['jumlah_produk'] = stock.toString();
        return copy;
      }).toList();

      setState(() => _products = enriched);
    } catch (e) {
      debugPrint('Error loading products: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat produk: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  Future<void> _loadStockHistory() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';
      
      dynamic res;
      if (ownerId.isNotEmpty) {
        res = await _api.selectWhere(token, project, 'stock_requests', appid, 'ownerid', ownerId);
      } else {
        res = await _api.selectAll(token, project, 'stock_requests', appid);
      }

      final jsonRes = res is String ? json.decode(res) : res;
      final data = List<Map<String, dynamic>>.from(
        jsonRes is Map ? (jsonRes['data'] ?? []) : (jsonRes is List ? jsonRes : [])
      );
      
      // Sort by date (newest first)
      data.sort((a, b) {
        final aDate = a['created_at'] ?? a['timestamp'] ?? '';
        final bDate = b['created_at'] ?? b['timestamp'] ?? '';
        return bDate.compareTo(aDate);
      });
      
      setState(() => _stockHistory = data);
    } catch (e) {
      debugPrint('Error loading stock history: $e');
    }
  }

  Future<void> _requestStock(String productId, String productName) async {
    final product = _products.firstWhere(
      (p) => (p['id_product'] ?? p['id'] ?? '').toString() == productId,
      orElse: () => {},
    );
    
    final currentStock = int.tryParse((product['stok'] ?? product['jumlah_produk'] ?? '0').toString()) ?? 0;
    
    final qtyCtrl = TextEditingController(text: '10');
    final noteCtrl = TextEditingController();
    
    final result = await showDialog<Map<String, dynamic>?>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Minta Tambah Stok'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  productName,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text('Stok saat ini: $currentStock unit'),
                const SizedBox(height: 16),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'Jumlah yang diminta',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: 'Catatan (opsional)',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Status akan otomatis "pending"',
                  style: TextStyle(color: Colors.grey, fontSize: 12),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, null),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                final qty = int.tryParse(qtyCtrl.text) ?? 0;
                if (qty <= 0) {
                  ScaffoldMessenger.of(ctx).showSnackBar(
                    const SnackBar(content: Text('Jumlah harus lebih dari 0'))
                  );
                  return;
                }
                Navigator.pop(ctx, {
                  'qty': qty,
                  'note': noteCtrl.text,
                });
              },
              child: const Text('Kirim Permintaan'),
            ),
          ],
        );
      },
    );

    if (result == null) return;

    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.currentUser;
    final ownerId = user?.ownerId ?? user?.id ?? '';

    // Gunakan field yang tersedia di User object
    String? requesterName;
    if (user != null) {
      // ignore: unnecessary_null_comparison
      if (user.email != null) {
        requesterName = user.email.split('@').first;
      // ignore: dead_code, unnecessary_null_comparison
      } else if (user.username != null) {
        requesterName = user.username;
      } else {
        requesterName = 'User ${ownerId.substring(0, ownerId.length < 8 ? ownerId.length : 8)}';
      }
    }

    final map = {
      'ownerid': ownerId,
      'product_id': productId,
      'product_name': productName,
      'qty': result['qty'].toString(),
      'note': result['note'],
      'status': 'pending',
      'current_stock': currentStock.toString(),
      'requested_at': DateTime.now().toIso8601String(),
      'requested_by': requesterName ?? 'Unknown',
    };

    try {
      await _api.insertOne(token, project, 'stock_requests', appid, map);
      
      // Refresh history
      await _loadStockHistory();
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Permintaan stok berhasil dikirim'),
            backgroundColor: Colors.green,
          )
        );
      }
    } catch (e) {
      debugPrint('Error requesting stock: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal mengirim permintaan: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    }
  }

  Future<void> _refreshData() async {
    await Future.wait([
      _loadProducts(),
      _loadStockHistory(),
    ]);
  }

  void _showStockHistory(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.8,
          child: Column(
            children: [
              const Text(
                'Riwayat Permintaan Stok',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: _stockHistory.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.history, size: 60, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('Belum ada riwayat permintaan'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _stockHistory.length,
                        itemBuilder: (context, index) {
                          final request = _stockHistory[index];
                          return Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: ListTile(
                              leading: Container(
                                width: 40,
                                height: 40,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: _getStatusColor(request['status']?.toString() ?? 'pending').withOpacity(0.1),
                                  border: Border.all(
                                    color: _getStatusColor(request['status']?.toString() ?? 'pending'),
                                  ),
                                ),
                                child: Icon(
                                  _getStatusIcon(request['status']?.toString() ?? 'pending'),
                                  size: 20,
                                  color: _getStatusColor(request['status']?.toString() ?? 'pending'),
                                ),
                              ),
                              title: Text(request['product_name']?.toString() ?? 'Unknown Product'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Jumlah: ${request['qty']} unit'),
                                  if (request['note'] != null && request['note'].toString().isNotEmpty)
                                    Text(
                                      'Catatan: ${request['note']}',
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  Text(
                                    'Diajukan: ${_formatDate(request['requested_at']?.toString() ?? '')}',
                                    style: const TextStyle(fontSize: 10, color: Colors.grey),
                                  ),
                                  if (request['requested_by'] != null)
                                    Text(
                                      'Oleh: ${request['requested_by']}',
                                      style: const TextStyle(fontSize: 10, color: Colors.grey),
                                    ),
                                ],
                              ),
                              trailing: Chip(
                                label: Text(
                                  request['status']?.toString() ?? 'pending',
                                  style: const TextStyle(color: Colors.white, fontSize: 10),
                                ),
                                backgroundColor: _getStatusColor(request['status']?.toString() ?? 'pending'),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Tutup'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'selesai':
        return Colors.green;
      case 'rejected':
      case 'dibatalkan':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      case 'dikirim':
      case 'diproses':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'approved':
      case 'selesai':
        return Icons.check_circle;
      case 'rejected':
      case 'dibatalkan':
        return Icons.cancel;
      case 'pending':
        return Icons.access_time;
      case 'dikirim':
        return Icons.local_shipping;
      case 'diproses':
        return Icons.build;
      default:
        return Icons.help;
    }
  }

  String _formatDate(String dateString) {
    try {
      if (dateString.length >= 10) {
        return dateString.substring(0, 10);
      }
      return dateString;
    } catch (e) {
      return dateString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return StokProdukPage(
      products: _products,
      loading: _loading,
      onRequestStock: (productId) {
        final product = _products.firstWhere(
          (p) => (p['id_product'] ?? p['id'] ?? '').toString() == productId,
          orElse: () => {},
        );
        final productName = product['nama_product'] ?? product['nama'] ?? 'Produk';
        _requestStock(productId, productName);
      },
      onRefresh: _refreshData,
      onViewHistory: () => _showStockHistory(context),
      getLowStockCount: () {
        return _products.where((p) {
          final stock = int.tryParse((p['stok'] ?? p['jumlah_produk'] ?? '0').toString()) ?? 0;
          return stock <= 10;
        }).length;
      },
    );
  }
}