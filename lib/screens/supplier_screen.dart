import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/restapi.dart';
import '../services/config.dart';

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
      final jsonRes = json.decode(res);
      setState(() => _suppliers = List<Map<String, dynamic>>.from(jsonRes['data'] ?? []));
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
      final map = {
        'ownerid': '',
        'company': result['company'] ?? '',
        'name': result['name'] ?? '',
        'phone': result['phone'] ?? '',
        'alamat': result['alamat'] ?? '',
      };
      await _api.insertOne(token, project, 'supplier', appid, map);
      await _loadSuppliers();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal tambah supplier: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Supplier')),
      floatingActionButton: FloatingActionButton(
        onPressed: _addSupplier,
        child: const Icon(Icons.add),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _suppliers.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final s = _suppliers[index];
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
