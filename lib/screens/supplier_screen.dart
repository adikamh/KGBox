// ignore_for_file: unnecessary_type_check

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/restapi.dart';
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
  final DataService _api = DataService();
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

      dynamic res;
      if (ownerId.isNotEmpty) {
        debugPrint('Loading suppliers for ownerId=$ownerId');
        res = await _api.selectWhere(token, project, 'suppliers', appid, 'ownerid', ownerId);
      } else {
        res = await _api.selectAll(token, project, 'suppliers', appid);
      }

      debugPrint('selectAll/selectWhere supplier raw response: $res');
      final decoded = res is String ? (res.trim().isEmpty ? [] : json.decode(res)) : res;
      final rawList = (decoded is Map) ? (decoded['data'] ?? []) : (decoded is List ? decoded : []);
      final items = List<Map<String, dynamic>>.from(rawList);

      debugPrint('supplier parsed items count: ${items.length}');

      final mapped = items.map((item) {
        return {
          'company': item['nama_perusahaan'] ?? item['company'] ?? '',
          'name': item['nama_agen'] ?? item['name'] ?? '',
          'phone': item['no_telepon_agen'] ?? item['phone'] ?? '',
          'alamat': item['alamat_perusahaan'] ?? item['alamat'] ?? '',
          '_raw': item,
        };
      }).toList();
      setState(() => _suppliers = mapped);
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

      final supplier = SuppliersModel(
        id: '',
        ownerid: ownerId,
        supplier_id: supplierId,
        nama_perusahaan: result['company'] ?? '',
        nama_agen: result['name'] ?? '',
        no_telepon_agen: result['phone'] ?? '',
        alamat_perusahaan: result['alamat'] ?? '',
      );

      final payload = Map<String, dynamic>.from(supplier.toJson());
      payload['_id'] = supplierId;

      final res = await _api.insertOne(token, project, 'suppliers', appid, payload);
      debugPrint('Insert response: $res');

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
      };

      final ok = await _api.updateOne(token, project, 'suppliers', appid, id, updateData);
      
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Supplier berhasil diperbarui')),
        );
        await _loadSuppliers();
      } else {
        debugPrint('updateOne returned false; attempting per-field updateId fallback');
        bool anyOk = false;
        try {
          // Try per-field update using updateId endpoint with extracted id
          for (final entry in updateData.entries) {
            final fOk = await _api.updateId(entry.key, entry.value.toString(), token, project, 'suppliers', appid, id);
            debugPrint('updateId by extracted id for ${entry.key}: $fOk');
            if (fOk) {
              anyOk = true;
            }
          }

          // If none succeeded, try using supplier_id field from raw document
          if (!anyOk) {
            // ignore: dead_code
            final supplierIdField = raw is Map ? (raw['supplier_id'] ?? raw['supplierId'] ?? '') : '';
            if (supplierIdField != null && supplierIdField.toString().isNotEmpty && supplierIdField.toString() != id) {
              for (final entry in updateData.entries) {
                final fOk = await _api.updateId(entry.key, entry.value.toString(), token, project, 'suppliers', appid, supplierIdField.toString());
                debugPrint('updateId by supplier_id for ${entry.key}: $fOk');
                if (fOk) {
                  anyOk = true;
                }
              }
            }
          }
          // If still not updated, try updateWhere (by supplier_id) for each field
          if (!anyOk) {
            try {
              // ignore: dead_code
              final supplierIdField2 = raw is Map ? (raw['supplier_id'] ?? raw['supplierId'] ?? '') : '';
              if (supplierIdField2 != null && supplierIdField2.toString().isNotEmpty) {
                for (final entry in updateData.entries) {
                  final uwOk = await _api.updateWhere('supplier_id', supplierIdField2.toString(), entry.key, entry.value.toString(), token, project, 'suppliers', appid);
                  debugPrint('updateWhere by supplier_id for ${entry.key}: $uwOk');
                  if (uwOk) anyOk = true;
                }
              }
            } catch (e) {
              debugPrint('updateWhere fallback exception: $e');
            }
          }
        } catch (e) {
          debugPrint('Fallback update exception: $e');
        }

        if (anyOk) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Supplier berhasil diperbarui (fallback)')),
          );
          await _loadSuppliers();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal memperbarui supplier')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui supplier: $e')),
      );
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
      debugPrint('Attempting remove_where by supplier_id for id=$id');
      final removedBySupplierId = await _api.removeWhere(token, project, 'suppliers', appid, 'supplier_id', id);
      debugPrint('removeWhere(supplier_id) result: $removedBySupplierId');
      if (removedBySupplierId == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier berhasil dihapus')));
        await _loadSuppliers();
        return;
      }

      // Fallback to removeId which has multiple fallbacks inside
      final ok = await _api.removeId(token, project, 'suppliers', appid, id);
      if (ok) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier berhasil dihapus')));
        await _loadSuppliers();
      } else {
        // Try one more fallback: select the document by supplier_id to obtain internal _id, then delete by that internal id
        try {
          debugPrint('removeId returned false; trying selectWhere to obtain internal _id for supplier_id=$id');
          final sel = await _api.selectWhere(token, project, 'suppliers', appid, 'supplier_id', id);
          debugPrint('selectWhere result for supplier_id: $sel');
          final decoded = sel is String ? (sel.trim().isEmpty ? [] : json.decode(sel)) : sel;
          final rawList = (decoded is Map) ? (decoded['data'] ?? []) : (decoded is List ? decoded : []);
          final list = List<Map<String, dynamic>>.from(rawList);
          if (list.isNotEmpty) {
            final first = list.first;
            final internalId = _extractIdFromRaw(first);
            debugPrint('Extracted internal id: $internalId');
            if (internalId.isNotEmpty && internalId != id) {
              final ok2 = await _api.removeId(token, project, 'suppliers', appid, internalId);
              if (ok2) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier berhasil dihapus')));
                await _loadSuppliers();
                return;
              }
            }
          }
        } catch (e) {
          debugPrint('select-then-delete fallback exception: $e');
        }

        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Gagal menghapus supplier')));
      }
    } catch (e) {
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