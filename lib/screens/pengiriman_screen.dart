import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/restapi.dart';
import '../services/config.dart';

class PengirimanScreen extends StatefulWidget {
  const PengirimanScreen({super.key});

  @override
  State<PengirimanScreen> createState() => _PengirimanScreenState();
}

class _PengirimanScreenState extends State<PengirimanScreen> {
  final DataService _api = DataService();
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final res = await _api.selectAll(token, project, 'order', appid);
      final jsonRes = json.decode(res);
      final data = List<Map<String, dynamic>>.from(jsonRes['data'] ?? []);
      setState(() => _orders = data);
    } catch (e) {
      debugPrint('Error loading orders: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _openMap(String alamat) async {
    final Uri uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(alamat)}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('History Pengiriman')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: _orders.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final o = _orders[index];
                final toko = o['nama_toko'] ?? o['customer_name'] ?? 'Toko';
                final alamat = o['alamat_toko'] ?? '';
                final tanggal = o['tanggal_order'] ?? '';
                return ListTile(
                  title: Text(toko),
                  subtitle: Text('$alamat\n$tanggal'),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.map),
                    onPressed: alamat.isNotEmpty ? () => _openMap(alamat) : null,
                  ),
                );
              },
            ),
    );
  }
}
