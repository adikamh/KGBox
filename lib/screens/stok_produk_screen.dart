// ignore: unused_import
import 'dart:convert';
import 'package:flutter/material.dart';
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

      final firestore = FirebaseFirestore.instance;
      Query<Map<String, dynamic>> q = firestore.collection('products');
      if (ownerId.isNotEmpty) {
        final q1 = firestore.collection('products').where('ownerid', isEqualTo: ownerId);
        final snap1 = await q1.limit(1).get();
        if (snap1.docs.isNotEmpty) {
          q = q1;
        } else {
          final q2 = firestore.collection('products').where('ownerId', isEqualTo: ownerId);
          final snap2 = await q2.limit(1).get();
          if (snap2.docs.isNotEmpty) q = q2;
        }
      }

      final snap = await q.get();
      final docs = snap.docs;

      // gather product ids and build initial map
      final List<Map<String, dynamic>> items = [];
      final Set<String> productIds = {};
      for (final d in docs) {
        final m = d.data();
        final pid = d.id;
        productIds.add(pid);
        items.add({
          'id_product': pid,
          'id': pid,
          '_id': pid,
          'nama_product': m['nama_product'] ?? m['nama'] ?? m['product_name'] ?? '',
          'merek_product': m['merek_product'] ?? m['merek'] ?? m['brand'] ?? '',
          'kategori': m['kategori'] ?? m['category'] ?? m['jenis'] ?? '',
          'sku': m['sku'] ?? m['kode'] ?? '',
          'harga': m['harga'] ?? m['harga_satuan'] ?? m['price'] ?? '',
          // stok will be attached later
          'raw': m,
        });
      }

      // compute stock counts from product_barcodes
      final Map<String, int> counts = {};
      final futures = productIds.map((pid) async {
        try {
          final q2 = await firestore.collection('product_barcodes').where('productId', isEqualTo: pid).get();
          counts[pid] = q2.size;
        } catch (e) {
          counts[pid] = 0;
        }
      }).toList();
      await Future.wait(futures);

      // attach stok and jumlah_produk
      final enriched = items.map((item) {
        final pid = (item['id_product'] ?? item['id'] ?? item['_id'] ?? '').toString();
        final stock = counts[pid] ?? 0;
        final Map<String, dynamic> copy = Map<String, dynamic>.from(item);
        copy['stok'] = stock;
        copy['jumlah_produk'] = stock.toString();
        return copy;
      }).toList();

      setState(() => _products = enriched);
    } catch (e) {
      debugPrint('Error loading products (Firestore): $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat produk: $e'),
            backgroundColor: Colors.red,
          )
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _deleteStockRequest(String docId) async {
    if (docId.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID tidak valid')));
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('stock_requests').doc(docId).delete();
      await _loadStockHistory();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan stok dihapus')));
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
    }
  }

  Future<void> _showEditDialog(Map<String, dynamic> request) async {
    final docId = request['_id']?.toString() ?? request['permintaan_id']?.toString() ?? '';
    if (docId.isEmpty) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID tidak valid')));
      return;
    }

    String currentStatus = (request['status']?.toString() ?? 'Pending');
    final noteCtrl = TextEditingController(text: request['catatan']?.toString() ?? '');
    final statuses = ['Pending', 'diterima', 'ditolak'];

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        String selected = currentStatus;
        return AlertDialog(
          title: const Text('Edit Permintaan Stok'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<String>(
                  value: selected,
                  decoration: const InputDecoration(labelText: 'Status'),
                  items: statuses.map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
                  onChanged: (v) { if (v != null) selected = v; },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: noteCtrl,
                  maxLines: 3,
                  decoration: const InputDecoration(labelText: 'Catatan (opsional)', border: OutlineInputBorder()),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
            ElevatedButton(onPressed: () async {
              try {
                final firestore = FirebaseFirestore.instance;
                await firestore.collection('stock_requests').doc(docId).update({
                  'status': selected,
                  'catatan': noteCtrl.text,
                  'updated_at': DateTime.now().toIso8601String(),
                });

                // If status changed to 'diterima', create a notification
                try {
                  final prev = currentStatus.toString().toLowerCase();
                  final selectedLower = selected.toString().toLowerCase();
                  if ((selectedLower == 'diterima' || selectedLower == 'ditolak') && prev != selectedLower) {
                    final title = selectedLower == 'diterima' ? 'Permintaan Stok Diterima' : 'Permintaan Stok Ditolak';
                    final body = selectedLower == 'diterima'
                        ? 'Permintaan untuk ${request['product_name'] ?? request['product_name'] ?? ''} telah diterima.'
                        : 'Permintaan untuk ${request['product_name'] ?? request['product_name'] ?? ''} ditolak.';
                    final notif = {
                      'ownerid': request['ownerid'] ?? request['ownerId'] ?? '',
                      'type': 'stock_request',
                      'title': title,
                      'body': body,
                      'permintaan_id': docId,
                      'status': selected,
                      'created_at': DateTime.now().toIso8601String(),
                    };
                    await firestore.collection('notifications').add(notif);
                  }
                } catch (eNotif) {
                  debugPrint('Failed creating notification: $eNotif');
                }

                Navigator.pop(ctx, true);
              } catch (e) {
                Navigator.pop(ctx, false);
              }
            }, child: const Text('Simpan')),
          ],
        );
      }
    );

    if (result == true) {
      await _loadStockHistory();
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Permintaan diperbarui')));
    }
  }

  Future<void> _loadStockHistory() async {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';

      final firestore = FirebaseFirestore.instance;
      Query<Map<String, dynamic>> q = firestore.collection('stock_requests').orderBy('created_at', descending: true);
      if (ownerId.isNotEmpty) {
        final q1 = firestore.collection('stock_requests').where('ownerid', isEqualTo: ownerId).orderBy('created_at', descending: true);
        final snap1 = await q1.limit(1).get();
        if (snap1.docs.isNotEmpty) {
          q = q1;
        } else {
          final q2 = firestore.collection('stock_requests').where('ownerId', isEqualTo: ownerId).orderBy('created_at', descending: true);
          final snap2 = await q2.limit(1).get();
          if (snap2.docs.isNotEmpty) q = q2;
        }
      }

      try {
        final snap = await q.get();
        final data = snap.docs.map((d) {
          final m = d.data();
          return {
            '_id': d.id,
            'permintaan_id': m['permintaan_id'] ?? m['_id'] ?? d.id,
            'ownerid': m['ownerid'] ?? m['ownerId'] ?? '',
            'supplier_id': m['supplier_id'] ?? m['supplierId'] ?? '',
            'nama_perusahaan': m['nama_perusahaan'] ?? m['company_name'] ?? '',
            'nama_agen': m['nama_agen'] ?? m['requested_by'] ?? m['requested_by'] ?? '',
            'tanggal_permintaan': m['tanggal_permintaan'] ?? m['requested_at'] ?? m['created_at'] ?? '',
            'status': m['status'] ?? 'Pending',
            'staff_id': m['staff_id'] ?? m['requested_by_id'] ?? m['staffId'] ?? '',
            'nama_staff': m['nama_staff'] ?? m['requested_by_name'] ?? '',
            'catatan': m['catatan'] ?? m['note'] ?? m['notes'] ?? '',
            'created_at': m['created_at'] ?? '',
            'updated_at': m['updated_at'] ?? '',
            'product_id': m['product_id'] ?? m['productId'] ?? '',
            'product_name': m['product_name'] ?? m['product_name'] ?? '',
            'qty': m['qty'] ?? m['quantity'] ?? '',
          };
        }).toList();

        setState(() => _stockHistory = data);
      } catch (err) {
        // If Firestore requires a composite index, fall back to a simple query
        // and perform client-side sorting. This avoids a crash and displays data.
        debugPrint('Primary stock history query failed, attempting fallback: $err');
        try {
          QuerySnapshot<Map<String, dynamic>> snap;
          if (ownerId.isNotEmpty) {
            // try 'ownerid' then 'ownerId' without ordering
            final q1 = firestore.collection('stock_requests').where('ownerid', isEqualTo: ownerId);
            final s1 = await q1.limit(1).get();
            if (s1.docs.isNotEmpty) {
              snap = await firestore.collection('stock_requests').where('ownerid', isEqualTo: ownerId).get();
            } else {
              snap = await firestore.collection('stock_requests').where('ownerId', isEqualTo: ownerId).get();
            }
          } else {
            snap = await firestore.collection('stock_requests').get();
          }

          // sort docs by created_at (ISO string) descending on client
          final docs = snap.docs.toList();
          docs.sort((a, b) {
            final aCreated = (a.data()['created_at'] ?? '').toString();
            final bCreated = (b.data()['created_at'] ?? '').toString();
            return bCreated.compareTo(aCreated);
          });

          final data = docs.map((d) {
            final m = d.data();
            return {
              '_id': d.id,
              'permintaan_id': m['permintaan_id'] ?? m['_id'] ?? d.id,
              'ownerid': m['ownerid'] ?? m['ownerId'] ?? '',
              'supplier_id': m['supplier_id'] ?? m['supplierId'] ?? '',
              'nama_perusahaan': m['nama_perusahaan'] ?? m['company_name'] ?? '',
              'nama_agen': m['nama_agen'] ?? m['requested_by'] ?? m['requested_by'] ?? '',
              'tanggal_permintaan': m['tanggal_permintaan'] ?? m['requested_at'] ?? m['created_at'] ?? '',
              'status': m['status'] ?? 'Pending',
              'staff_id': m['staff_id'] ?? m['requested_by_id'] ?? m['staffId'] ?? '',
              'nama_staff': m['nama_staff'] ?? m['requested_by_name'] ?? '',
              'catatan': m['catatan'] ?? m['note'] ?? m['notes'] ?? '',
              'created_at': m['created_at'] ?? '',
              'updated_at': m['updated_at'] ?? '',
              'product_id': m['product_id'] ?? m['productId'] ?? '',
              'product_name': m['product_name'] ?? m['product_name'] ?? '',
              'qty': m['qty'] ?? m['quantity'] ?? '',
            };
          }).toList();

          if (mounted) {
            setState(() => _stockHistory = data);
            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
              content: Text('Menampilkan riwayat menggunakan fallback (index mungkin belum dibuat)'),
            ));
          }
        } catch (e2) {
          debugPrint('Fallback query also failed: $e2');
        }
      }
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
                Navigator.pop(ctx, {
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

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now();
    final createdAt = now.toIso8601String();

    // determine supplier info from product.raw if available, otherwise fallback to user/owner
    String supplierId = '';
    String namaPerusahaan = '';
    String namaAgen = requesterName ?? 'Unknown';
    try {
      final raw = (product['raw'] is Map) ? Map<String, dynamic>.from(product['raw']) : <String, dynamic>{};
      supplierId = (raw['supplier'] ?? raw['supplier_id'] ?? raw['supplierId'] ?? raw['vendor'] ?? '').toString();
      if (supplierId.isNotEmpty) {
        final supDoc = await FirebaseFirestore.instance.collection('suppliers').doc(supplierId).get();
        if (supDoc.exists) {
          final sm = supDoc.data() ?? {};
          namaPerusahaan = (sm['companyName'] ?? sm['nama_perusahaan'] ?? sm['company'] ?? sm['company_name'] ?? '').toString();
          namaAgen = (sm['name'] ?? sm['nama'] ?? sm['supplier_name'] ?? sm['displayName'] ?? namaAgen).toString();
        }
      }

      // fallback: if supplier not found, try to use owner's company or user displayName
      if (namaPerusahaan.isEmpty && user != null) {
        if (user.companyName != null && user.companyName!.isNotEmpty) {
          namaPerusahaan = user.companyName!;
        } else if ((user.ownerId ?? '').isNotEmpty) {
          final ownerDoc = await FirebaseFirestore.instance.collection('users').doc(user.ownerId).get();
          if (ownerDoc.exists) {
            final om = ownerDoc.data();
            if (om != null) {
              namaPerusahaan = (om['companyName'] ?? om['company_name'] ?? om['nama_perusahaan'] ?? '').toString();
            }
          }
        }
      }

      if (user != null && (namaAgen.isEmpty || namaAgen == 'Unknown')) {
        if (user.displayName.isNotEmpty) namaAgen = user.displayName;
        else if (user.username.isNotEmpty) namaAgen = user.username;
      }
    } catch (_) {}

    final Map<String, dynamic> doc = {
      'ownerid': ownerId,
      'permintaan_id': '', // will update after doc created
      'supplier_id': supplierId,
      'nama_perusahaan': namaPerusahaan,
      'nama_agen': namaAgen,
      'tanggal_permintaan': createdAt,
      'status': 'Pending',
      'staff_id': user?.id ?? '',
      'nama_staff': namaAgen,
      'catatan': result['note'] ?? '',
      'created_at': createdAt,
      'product_name': productName,
    };

    try {
      final docRef = await firestore.collection('stock_requests').add(doc);
      // set permintaan_id and updated_at
      await docRef.update({
        'permintaan_id': docRef.id,
        'updated_at': DateTime.now().toIso8601String(),
      });

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
      debugPrint('Error requesting stock (Firestore): $e');
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
                                                      if (request['catatan'] != null && request['catatan'].toString().isNotEmpty)
                                                        Text(
                                                          'Catatan: ${request['catatan']}',
                                                          style: const TextStyle(fontSize: 11),
                                                        ),
                                                      Text(
                                                        'Diajukan: ${_formatDate((request['tanggal_permintaan'] ?? request['created_at'] ?? '').toString())}',
                                                        style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                      ),
                                                      if (request['nama_agen'] != null && request['nama_agen'].toString().isNotEmpty)
                                                        Text(
                                                          'Oleh: ${request['nama_agen']}',
                                                          style: const TextStyle(fontSize: 10, color: Colors.grey),
                                                        ),
                                                    ],
                                                  ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Chip(
                                    label: Text(
                                      request['status']?.toString() ?? 'pending',
                                      style: const TextStyle(color: Colors.white, fontSize: 10),
                                    ),
                                    backgroundColor: _getStatusColor(request['status']?.toString() ?? 'pending'),
                                  ),
                                  const SizedBox(width: 8),
                                  PopupMenuButton<String>(
                                    onSelected: (v) async {
                                      if (v == 'edit') {
                                        await _showEditDialog(request);
                                      } else if (v == 'delete') {
                                        final id = request['_id']?.toString() ?? request['permintaan_id']?.toString() ?? '';
                                        await _deleteStockRequest(id);
                                      }
                                    },
                                    itemBuilder: (ctx) => [
                                      const PopupMenuItem(value: 'edit', child: Text('Edit')),
                                      const PopupMenuItem(value: 'delete', child: Text('Hapus')),
                                    ],
                                  ),
                                ],
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
      case 'diterima':
        return Colors.green;
      case 'ditolak':
        return Colors.red;
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
      case 'diterima':
        return Icons.check_circle;
      case 'ditolak':
        return Icons.cancel;
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