// ignore_for_file: unnecessary_type_check

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
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
  List<Map<String, dynamic>> _filteredSuppliers = [];
  bool _loading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadSuppliers();
    _searchController.addListener(_onSearchChanged);
  }

  void _onSearchChanged() {
    final q = _searchController.text.trim().toLowerCase();
    if (q.isEmpty) {
      setState(() => _filteredSuppliers = List<Map<String, dynamic>>.from(_suppliers));
      return;
    }
    final filtered = _suppliers.where((s) {
      final company = (s['company'] ?? '').toString().toLowerCase();
      final name = (s['name'] ?? '').toString().toLowerCase();
      final phone = (s['phone'] ?? '').toString().toLowerCase();
      final alamat = (s['alamat'] ?? '').toString().toLowerCase();
      return company.contains(q) || name.contains(q) || phone.contains(q) || alamat.contains(q);
    }).toList();
    setState(() => _filteredSuppliers = filtered);
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
      setState(() {
        _loading = false;
        _filteredSuppliers = List<Map<String, dynamic>>.from(_suppliers);
      });
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
        final _formKey = GlobalKey<FormState>();
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.blue[400]!, Colors.blue[700]!]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.business_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Text('Tambah Supplier Baru', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    // Form Fields
                    Text('Informasi Perusahaan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: company,
                      decoration: InputDecoration(
                        labelText: 'Nama Perusahaan',
                        prefixIcon: const Icon(Icons.store_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama perusahaan harus diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Informasi Agen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: InputDecoration(
                        labelText: 'Nama Agen',
                        prefixIcon: const Icon(Icons.person_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phone,
                      decoration: InputDecoration(
                        labelText: 'No Telepon',
                        prefixIcon: const Icon(Icons.phone_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: alamat,
                      decoration: InputDecoration(
                        labelText: 'Alamat Perusahaan',
                        prefixIcon: const Icon(Icons.location_on_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => Navigator.pop(ctx, null),
                            style: OutlinedButton.styleFrom(
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            child: const Text('Batal'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? true) {
                                Navigator.pop(ctx, {
                                  'company': company.text,
                                  'name': name.text,
                                  'phone': phone.text,
                                  'alamat': alamat.text,
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.check_rounded),
                            label: const Text('Simpan'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
    final supplier = (_filteredSuppliers != null && _filteredSuppliers.length > 0) ? _filteredSuppliers[index] : _suppliers[index];
    final raw = supplier['_raw'] as Map<String, dynamic>? ?? {};
    
    showDialog(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Avatar
                Row(
                  children: [
                    Container(
                      width: 70,
                      height: 70,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [Colors.blue[400]!, Colors.blue[700]!]),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [BoxShadow(color: Colors.blue.withOpacity(0.3), blurRadius: 8)],
                      ),
                      child: Center(
                        child: Text(_initials(supplier['company'] ?? '', supplier['name'] ?? ''), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(supplier['company'] ?? '-', style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          Text(supplier['name'] ?? '', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
                        ],
                      ),
                    ),
                  ],
                ),
                const Divider(height: 24),
                // Contact Info Section
                Text('Informasi Kontak', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                const SizedBox(height: 12),
                _buildDetailRow('Nama Agen', supplier['name'] ?? '-', Icons.person_rounded),
                const SizedBox(height: 12),
                _buildDetailRow('Telepon', supplier['phone'] ?? '-', Icons.phone_rounded),
                const SizedBox(height: 12),
                _buildDetailRow('Alamat', supplier['alamat'] ?? '-', Icons.location_on_rounded),
                const SizedBox(height: 20),
                // System Info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.grey[50], borderRadius: BorderRadius.circular(12)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('ID Sistem', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.grey[600])),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Expanded(child: Text(_extractIdFromRaw(raw), style: const TextStyle(fontFamily: 'monospace', fontSize: 11))),
                          IconButton(
                            tooltip: 'Salin ID',
                            icon: const Icon(Icons.copy, size: 18),
                            onPressed: () {
                              final id = _extractIdFromRaw(raw);
                              Clipboard.setData(ClipboardData(text: id));
                              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID disalin')));
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                // Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pop(ctx);
                          _editSupplier(index);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue[700],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.edit_rounded, color: Colors.white),
                        label: const Text('Edit',style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          Navigator.pop(ctx);
                          await _deleteSupplier(index);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        icon: const Icon(Icons.delete_rounded, color: Colors.white),
                        label: const Text('Hapus',style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDetailRow(String label, String value, [IconData? icon]) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: Colors.blue[50], borderRadius: BorderRadius.circular(8)),
            child: Icon(icon, size: 18, color: Colors.blue[700]),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey[600], fontWeight: FontWeight.w500)),
              const SizedBox(height: 4),
              Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
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
    final _formKey = GlobalKey<FormState>();

    final Map<String, String>? result = await showDialog<Map<String, String>>(
      context: context,
      builder: (ctx) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [Colors.orange[400]!, Colors.orange[700]!]),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(Icons.edit_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 16),
                        const Text('Edit Supplier', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const Divider(height: 24),
                    // Form Fields
                    Text('Informasi Perusahaan', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: company,
                      decoration: InputDecoration(
                        labelText: 'Nama Perusahaan',
                        prefixIcon: const Icon(Icons.store_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nama perusahaan harus diisi' : null,
                    ),
                    const SizedBox(height: 16),
                    Text('Informasi Agen', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.grey[700])),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: name,
                      decoration: InputDecoration(
                        labelText: 'Nama Agen',
                        prefixIcon: const Icon(Icons.person_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: phone,
                      decoration: InputDecoration(
                        labelText: 'No Telepon',
                        prefixIcon: const Icon(Icons.phone_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: alamat,
                      decoration: InputDecoration(
                        labelText: 'Alamat Perusahaan',
                        prefixIcon: const Icon(Icons.location_on_rounded),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        filled: true,
                        fillColor: Colors.grey[50],
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 24),
                    // Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => Navigator.pop(ctx, null),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.close_rounded, color: Colors.white),
                            label: const Text('Batal', style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              if (_formKey.currentState?.validate() ?? true) {
                                Navigator.pop(ctx, {
                                  'company': company.text,
                                  'name': name.text,
                                  'phone': phone.text,
                                  'alamat': alamat.text,
                                });
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange[700],
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                            icon: const Icon(Icons.check_rounded, color: Colors.white),
                            label: const Text(
                              'Simpan',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
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
      // Determine document id robustly: prefer _docId, then supplier_id, then extracted id
      String docId = '';
      final rawMap = raw is Map ? raw : {};
      if (rawMap.containsKey('_docId')) docId = rawMap['_docId']?.toString() ?? '';
      if (docId.isEmpty && rawMap.containsKey('supplier_id')) docId = rawMap['supplier_id']?.toString() ?? '';
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
    final raw = _filteredSuppliers[index]['_raw'];
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
      // Determine doc id robustly
      String docId = '';
      if (raw is Map && raw.containsKey('_docId')) docId = raw['_docId']?.toString() ?? '';
      if (docId.isEmpty && raw is Map && raw.containsKey('supplier_id')) docId = raw['supplier_id']?.toString() ?? '';
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

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  String _extractIdFromRaw(dynamic raw) {
    try {
      if (raw == null) return '';
      if (raw is Map) {
        dynamic rawId = raw['_id'] ?? raw['id'] ?? '';
        // also support supplier_id
        if ((rawId == null || rawId.toString().isEmpty) && raw.containsKey('supplier_id')) rawId = raw['supplier_id'];
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

  String _initials(String company, String contact) {
    final source = (company.isNotEmpty ? company : contact).trim();
    if (source.isEmpty) return '?';
    final parts = source.split(RegExp(r'\s+'));
    if (parts.length == 1) {
      return parts.first.isNotEmpty ? parts.first.substring(0, 1).toUpperCase() : '?';
    }
    final first = parts[0].isNotEmpty ? parts[0].substring(0, 1) : '';
    final second = parts[1].isNotEmpty ? parts[1].substring(0, 1) : '';
    return (first + second).toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    return SupplierPage(
      suppliers: (_filteredSuppliers != null && _filteredSuppliers.length > 0) ? _filteredSuppliers : _suppliers,
      loading: _loading,
      searchController: _searchController,
      onSearch: (s) => _onSearchChanged(),
      onAdd: _addSupplier,
      onRefresh: _loadSuppliers,
      onView: _viewSupplier,
      onEdit: _editSupplier,
      onDelete: _deleteSupplier,
    );
  }
}