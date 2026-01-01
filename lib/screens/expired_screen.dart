import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/restapi.dart';
import '../services/config.dart';
import '../pages/expired_page.dart';
import '../providers/auth_provider.dart';

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
      // Prefer Firestore as source of truth. If unavailable, fallback to REST API.
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';

      final now = DateTime.now();
      // Ambil produk yang kadaluarsa dalam 2 bulan ke depan
      final threshold = DateTime(now.year, now.month + 2, now.day);

      final List<Map<String, dynamic>> expired = [];

      try {
        final firestore = FirebaseFirestore.instance;
        // products collection (plural) is used elsewhere in the app
        final coll = firestore.collection('products');

        // If ownerId is provided, try common owner field names ('ownerId' then 'ownerid')
        QuerySnapshot snap;
        if (ownerId.isNotEmpty) {
          snap = await coll.where('ownerId', isEqualTo: ownerId).get();
          if (snap.docs.isEmpty) {
            snap = await coll.where('ownerid', isEqualTo: ownerId).get();
          }
        } else {
          snap = await coll.get();
        }

        // fetch docs and parse expiry fields (support Timestamp/int/string)
        // 'snap' now holds the result set
        for (final doc in snap.docs) {
          try {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            // prefer the app's `expiredDate` field, but support other common names and types
            dynamic raw = data['expiredDate'] ?? data['tanggal_expired'] ?? data['tanggal_expire'] ?? data['expired_at'] ?? data['expired_date'];
            if (raw == null) continue;

            DateTime? dt;
            if (raw is Timestamp) {
              dt = raw.toDate();
            } else if (raw is int) {
              // try milliseconds vs seconds
              if (raw > 9999999999) {
                dt = DateTime.fromMillisecondsSinceEpoch(raw);
              } else {
                dt = DateTime.fromMillisecondsSinceEpoch(raw * 1000);
              }
            } else if (raw is String) {
              try {
                dt = DateTime.parse(raw);
              } catch (_) {
                // try simple yyyy-MM-dd
                final parts = raw.split('-');
                if (parts.length >= 3) {
                  final y = int.tryParse(parts[0]) ?? 0;
                  final m = int.tryParse(parts[1]) ?? 1;
                  final d = int.tryParse(parts[2].split(' ').first) ?? 1;
                  if (y > 0) dt = DateTime(y, m, d);
                }
              }
            }

            if (dt != null && dt.isBefore(threshold)) {
              expired.add({
                'full': data,
                'expired_at': dt.toIso8601String(),
                'product_id': (data['id_product'] ?? data['id'] ?? doc.id).toString(),
                'stock': int.tryParse((data['stok'] ?? data['stock'] ?? 0).toString()) ?? 0,
              });
            }
          } catch (e) {
            // ignore problematic doc
          }
        }
      } catch (e) {
        // Firestore failed — fallback to REST API as previously implemented
        debugPrint('Firestore expired fetch failed, falling back to REST: $e');
        final res = await _api.selectAll(token, project, 'product', appid);
        final jsonRes = res is String ? json.decode(res) : res;
        final data = List<Map<String, dynamic>>.from(jsonRes['data'] ?? []);

        for (final p in data) {
          final raw = p['tanggal_expired']?.toString() ?? 
                     p['tanggal_expire']?.toString() ?? 
                     p['expired_date']?.toString() ?? 
                     p['expired_at']?.toString() ?? '';
          if (raw.isEmpty) continue;
          try {
            final dt = DateTime.parse(raw);
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