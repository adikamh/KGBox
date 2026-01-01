// ignore_for_file: unnecessary_type_check

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/config.dart';
import '../pages/supplier_page.dart';
import '../providers/auth_provider.dart';
import '../models/supplier_model.dart';

class SupplierScreen extends StatefulWidget {
  const SupplierScreen({super.key});

  @override
  State<SupplierScreen> createState() => _SupplierScreenState();
}

class _SupplierScreenState extends State<SupplierScreen> {
  List<Map<String, dynamic>> _suppliers = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
  }

  Future<void> _loadSuppliers() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';
      // Load suppliers from Firestore
      final firestore = FirebaseFirestore.instance;
      Query q = firestore.collection('suppliers');
      if (ownerId.isNotEmpty) q = q.where('ownerid', isEqualTo: ownerId);
      final snap = await q.get();
      final items = snap.docs.map((d) {
        final data = (d.data() as Map<String, dynamic>?) ?? {};
        return {
          'company': data['nama_perusahaan'] ?? data['company'] ?? '',
          'name': data['nama_agen'] ?? data['name'] ?? '',
          'phone': data['no_telepon_agen'] ?? data['phone'] ?? '',
          'alamat': data['alamat_perusahaan'] ?? data['alamat'] ?? '',
          '_raw': {...data, '_docId': d.id},
        };
      }).toList();
      setState(() => _suppliers = List<Map<String, dynamic>>.from(items));
    } catch (e) {
      debugPrint('Error loading suppliers: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat supplier: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }

  }

  Future<void> _addSupplier() async {
    final Map<String, String>? result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        final name = TextEditingController();
        final company = TextEditingController();
        final phone = TextEditingController();
        final alamat = TextEditingController();
        return AlertDialog(
          title: const Text('Tambah Supplier'),
          content: SingleChildScrollView(
            child: Column(children: [
              TextField(controller: company, decoration: const InputDecoration(labelText: 'Perusahaan')),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Nama Penjual')),
              TextField(controller: phone, decoration: const InputDecoration(labelText: 'No Telepon')),
              TextField(controller: alamat, decoration: const InputDecoration(labelText: 'Alamat')),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.pop(ctx, {
              'company': company.text,
              'name': name.text,
              'phone': phone.text,
              'alamat': alamat.text,
            }), child: const Text('Simpan')),
          ],
        );
      },
    );

    if (result == null) return;

    if (result['company']?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama perusahaan harus diisi')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';

      final supplierId = 'SUP${DateTime.now().millisecondsSinceEpoch}';
      final firestore = FirebaseFirestore.instance;
      final payload = {
        'ownerid': ownerId,
        'supplier_id': supplierId,
        'nama_perusahaan': result['company'] ?? '',
        'nama_agen': result['name'] ?? '',
        'no_telepon_agen': result['phone'] ?? '',
        'alamat_perusahaan': result['alamat'] ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Use supplierId as document id for easier lookup
      await firestore.collection('suppliers').doc(supplierId).set(payload);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Supplier berhasil ditambahkan')),
      );
      await _loadSuppliers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal menambahkan supplier: $e')),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  void _viewSupplier(int index) {
    final supplier = _suppliers[index];
    final raw = supplier['_raw'] as Map<String, dynamic>? ?? {};
    
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Detail Supplier'),
          content: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildDetailRow('Perusahaan', supplier['company'] ?? '-'),
                _buildDetailRow('Nama Agen', supplier['name'] ?? '-'),
                _buildDetailRow('Telepon', supplier['phone'] ?? '-'),
                _buildDetailRow('Alamat', supplier['alamat'] ?? '-'),
                const SizedBox(height: 12),
                const Text('ID Sistem:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text(_extractIdFromRaw(raw), style: const TextStyle(fontFamily: 'monospace')),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 14)),
        ],
      ),
    );
  }

  Future<void> _editSupplier(int index) async {
    final item = _suppliers[index];
    final raw = item['_raw'] as Map<String, dynamic>? ?? {};
    final id = _extractIdFromRaw(raw);
    
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat menemukan ID supplier')),
      );
      return;
    }

    final company = TextEditingController(text: item['company'] ?? '');
    final name = TextEditingController(text: item['name'] ?? '');
    final phone = TextEditingController(text: item['phone'] ?? '');
    final alamat = TextEditingController(text: item['alamat'] ?? '');

    final Map<String, String>? result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Supplier'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: company,
                  decoration: const InputDecoration(
                    labelText: 'Nama Perusahaan',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: name,
                  decoration: const InputDecoration(
                    labelText: 'Nama Agen',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: phone,
                  decoration: const InputDecoration(
                    labelText: 'No Telepon',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: alamat,
                  decoration: const InputDecoration(
                    labelText: 'Alamat Perusahaan',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 3,
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
              onPressed: () => Navigator.pop(ctx, {
                'company': company.text,
                'name': name.text,
                'phone': phone.text,
                'alamat': alamat.text,
              }),
              child: const Text('Simpan Perubahan'),
            ),
          ],
        );
      },
    );

    if (result == null) return;
    
    if (result['company']?.isEmpty ?? true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama perusahaan harus diisi')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final updateData = {
        'nama_perusahaan': result['company'] ?? '',
        'nama_agen': result['name'] ?? '',
        'no_telepon_agen': result['phone'] ?? '',
        'alamat_perusahaan': result['alamat'] ?? '',
        'updatedAt': FieldValue.serverTimestamp(),
      };

      final firestore = FirebaseFirestore.instance;
      // Determine document id: prefer docId stored in _raw, else use id variable which may be supplier_id
      String docId = '';
      final rawMap = raw is Map ? raw : {};
      if (rawMap.containsKey('_docId')) docId = rawMap['_docId'].toString();
      if (docId.isEmpty) docId = id;

      if (docId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat menentukan dokumen supplier untuk diupdate')));
        return;
      }

      await firestore.collection('suppliers').doc(docId).update(updateData);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier berhasil diperbarui')));
      await _loadSuppliers();
    } catch (e) {
      debugPrint('Firestore update exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memperbarui supplier: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _deleteSupplier(int index) async {
    final raw = _suppliers[index]['_raw'];
    final id = _extractIdFromRaw(raw);
    
    if (id.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tidak dapat menemukan ID supplier')),
      );
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Konfirmasi Hapus'),
          content: const Text('Apakah Anda yakin ingin menghapus supplier ini? Data yang dihapus tidak dapat dikembalikan.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) return;

    setState(() => _loading = true);
    try {
      final firestore = FirebaseFirestore.instance;
      // Determine doc id
      String docId = '';
      if (raw is Map && raw.containsKey('_docId')) docId = raw['_docId'].toString();
      if (docId.isEmpty) docId = id;
      if (docId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak dapat menentukan dokumen supplier untuk dihapus')));
        return;
      }

      await firestore.collection('suppliers').doc(docId).delete();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier berhasil dihapus')));
      await _loadSuppliers();
    } catch (e) {
      debugPrint('Firestore delete exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus supplier: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  String _extractIdFromRaw(dynamic raw) {
    try {
      if (raw == null) return '';
      if (raw is Map) {
        dynamic rawId = raw['_id'] ?? raw['id'] ?? '';
        if (rawId is Map) {
          if (rawId.containsKey(r'\$oid')) return rawId[r'\$oid'].toString();
          if (rawId.containsKey('\$oid')) return rawId['\$oid'].toString();
          return rawId.toString();
        }
        return rawId?.toString() ?? '';
      }
      return raw.toString();
    } catch (e) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupplierPage(
      suppliers: _suppliers,
      loading: _loading,
      onAdd: _addSupplier,
      onRefresh: _loadSuppliers,
      onView: _viewSupplier,
      onEdit: _editSupplier,
      onDelete: _deleteSupplier,
    );
  }
}