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
      final res = await _api.selectAll(token, project, 'supplier', appid);
      final decoded = res is String ? json.decode(res) : res;
      final rawList = (decoded is Map) ? (decoded['data'] ?? []) : (decoded is List ? decoded : []);
      final items = List<Map<String, dynamic>>.from(rawList);

      // Normalize backend field names to UI-friendly keys
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
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';

      // generate supplier_id if needed
      final supplierId = 'SUP' + DateTime.now().millisecondsSinceEpoch.toString();

      final supplier = SuppliersModel(
        id: '',
        ownerid: ownerId,
        supplier_id: supplierId,
        nama_perusahaan: result['company'] ?? '',
        nama_agen: result['name'] ?? '',
        no_telepon_agen: result['phone'] ?? '',
        alamat_perusahaan: result['alamat'] ?? '',
      );

      await _api.insertOne(token, project, 'supplier', appid, supplier.toJson());
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Supplier berhasil ditambahkan')));
      await _loadSuppliers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal tambah supplier: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SupplierPage(suppliers: _suppliers, loading: _loading, onAdd: _addSupplier);
  }
}
