import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/restapi.dart';
import '../services/config.dart';
import '../pages/expired_page.dart';

class ExpiredScreen extends StatefulWidget {
  const ExpiredScreen({super.key});

  @override
  State<ExpiredScreen> createState() => _ExpiredScreenState();
}

class _ExpiredScreenState extends State<ExpiredScreen> {
  final DataService _api = DataService();
  List<Map<String, dynamic>> _expired = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadExpired();
  }

  Future<void> _loadExpired() async {
    setState(() => _loading = true);
    try {
      final res = await _api.selectAll(token, project, 'product', appid);
      final jsonRes = json.decode(res);
      final data = List<Map<String, dynamic>>.from(jsonRes['data'] ?? []);

      final now = DateTime.now();
      final threshold = DateTime(now.year, now.month + 2, now.day);

      final List<Map<String, dynamic>> expired = [];
      for (final p in data) {
        final raw = p['tanggal_expired']?.toString() ?? p['tanggal_expire']?.toString() ?? '';
        try {
          final dt = DateTime.parse(raw);
          if (dt.isBefore(now) || dt.isBefore(threshold)) {
            expired.add({'full': p, 'expired_at': dt.toIso8601String()});
          }
        } catch (_) {}
      }

      setState(() => _expired = expired);
    } catch (e) {
      debugPrint('Error loading expired: $e');
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ExpiredPage(items: _expired, loading: _loading);
  }
}
