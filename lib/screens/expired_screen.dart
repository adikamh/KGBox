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
      // Ambil semua produk
      final res = await _api.selectAll(token, project, 'product', appid);
      final jsonRes = res is String ? json.decode(res) : res;
      final data = List<Map<String, dynamic>>.from(jsonRes['data'] ?? []);

      final now = DateTime.now();
      // Ambil produk yang kadaluarsa dalam 2 bulan ke depan
      final threshold = DateTime(now.year, now.month + 2, now.day);

      final List<Map<String, dynamic>> expired = [];
      for (final p in data) {
        final raw = p['tanggal_expired']?.toString() ?? 
                   p['tanggal_expire']?.toString() ?? 
                   p['expired_date']?.toString() ?? 
                   p['expired_at']?.toString() ?? '';
        
        if (raw.isNotEmpty) {
          try {
            final dt = DateTime.parse(raw);
            // Tampilkan produk yang sudah lewat atau akan lewat dalam 2 bulan
            if (dt.isBefore(threshold)) {
              expired.add({
                'full': p, 
                'expired_at': dt.toIso8601String(),
                'product_id': p['id_product'] ?? p['id'] ?? '',
                'stock': p['stok'] ?? p['stock'] ?? 0,
              });
            }
          } catch (e) {
            debugPrint('Error parsing date for product ${p['nama_product'] ?? p['nama']}: $raw');
          }
        }
      }

      // Urutkan berdasarkan tanggal terdekat
      expired.sort((a, b) {
        try {
          final aDate = DateTime.parse(a['expired_at']);
          final bDate = DateTime.parse(b['expired_at']);
          return aDate.compareTo(bDate);
        } catch (_) {
          return 0;
        }
      });

      setState(() => _expired = expired);
      
      // Tampilkan notifikasi jika ada produk yang sudah lewat
      _checkCriticalExpired(expired, now);
      
    } catch (e) {
      debugPrint('Error loading expired products: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
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

  void _checkCriticalExpired(List<Map<String, dynamic>> expired, DateTime now) {
    int criticalCount = 0;
    for (final item in expired) {
      try {
        final expDate = DateTime.parse(item['expired_at']);
        final daysUntil = expDate.difference(now).inDays;
        if (daysUntil <= 3) {
          criticalCount++;
        }
      } catch (_) {}
    }
    
    if (criticalCount > 0 && mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (context) => AlertDialog(
            title: const Row(
              children: [
                Icon(Icons.warning, color: Colors.red),
                SizedBox(width: 10),
                Text('Peringatan!'),
              ],
            ),
            content: Text('Ada $criticalCount produk yang akan kadaluwarsa dalam 3 hari ke depan. Segera tinjau!'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      });
    }
  }

  Future<void> _refreshData() async {
    await _loadExpired();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: RefreshIndicator(
        onRefresh: _refreshData,
        child: ExpiredPage(items: _expired, loading: _loading),
      ),
    );
  }
}