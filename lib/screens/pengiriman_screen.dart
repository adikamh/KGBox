import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/restapi.dart';
import '../services/config.dart';
import '../pages/pengiriman_page.dart';

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
    return PengirimanPage(orders: _orders, loading: _loading, onOpenMap: _openMap);
  }
}
