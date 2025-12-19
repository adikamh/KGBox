import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/restapi.dart';
import '../services/config.dart';
import '../pages/pengiriman_page.dart';
import '../providers/auth_provider.dart';

class PengirimanScreen extends StatefulWidget {
  const PengirimanScreen({super.key});

  @override
  State<PengirimanScreen> createState() => _PengirimanScreenState();
}

class _PengirimanScreenState extends State<PengirimanScreen> {
  final DataService _api = DataService();
  List<Map<String, dynamic>> _orders = [];
  bool _loading = true;
  String? _currentOwnerId;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadOrders();
    });
  }

  Future<void> _loadOrders() async {
    setState(() => _loading = true);
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';

      if (ownerId.isEmpty) {
        debugPrint('Owner ID tidak ditemukan');
        setState(() {
          _orders = [];
          _currentOwnerId = null;
        });
        return;
      }

      // Update current ownerId
      _currentOwnerId = ownerId;
      debugPrint('Loading orders for ownerId=$ownerId');

      // Filter berdasarkan ownerId - sesuaikan dengan field yang benar di database
      // Coba beberapa kemungkinan nama field
      final res = await _api.selectWhere(
        token, 
        project, 
        'order', 
        appid, 
        'ownerid', // atau 'owner_id', 'id_owner', sesuaikan dengan database
        ownerId
      );

      final jsonRes = res is String ? 
          (res.trim().isEmpty ? {} : json.decode(res)) : 
          res;
      
      // Debug untuk melihat response
      debugPrint('Response dari API: ${jsonRes.toString()}');

      // Ekstrak data dari response
      List<Map<String, dynamic>> data = [];
      if (jsonRes is Map) {
        if (jsonRes['data'] != null && jsonRes['data'] is List) {
          data = List<Map<String, dynamic>>.from(jsonRes['data'] as List);
        } else if (jsonRes['orders'] != null && jsonRes['orders'] is List) {
          data = List<Map<String, dynamic>>.from(jsonRes['orders'] as List);
        }
      } else if (jsonRes is List) {
        data = List<Map<String, dynamic>>.from(jsonRes);
      }

      // Filter tambahan di sisi client untuk memastikan
      final filteredOrders = data.where((order) {
        final orderOwnerId = order['ownerid'] ?? 
                             order['owner_id'] ?? 
                             order['id_owner'] ?? 
                             order['userId'] ?? 
                             '';
        return orderOwnerId.toString() == ownerId;
      }).toList();

      setState(() => _orders = filteredOrders);
      
      debugPrint('Total orders ditemukan: ${data.length}');
      debugPrint('Orders setelah filter: ${filteredOrders.length}');

    } catch (e) {
      debugPrint('Error loading orders: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memuat data: $e'))
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // Refresh dengan pull-to-refresh
  Future<void> _refreshOrders() async {
    await _loadOrders();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final auth = Provider.of<AuthProvider>(context);
    final user = auth.currentUser;
    final ownerId = user?.ownerId ?? user?.id ?? '';
    
    // Reload jika ownerId berubah
    if (ownerId != _currentOwnerId) {
      _loadOrders();
    }
  }

  Future<void> _openOrderDetail(Map<String, dynamic> order) async {
    try {
      final orderId = order['order_id'] ?? order['orderId'] ?? order['id'] ?? '';
      if (orderId == null || orderId.toString().isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada order_id')));
        return;
      }

      // Verifikasi bahwa order ini milik user yang login
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';
      
      final orderOwnerId = order['ownerid'] ?? 
                           order['owner_id'] ?? 
                           order['id_owner'] ?? 
                           order['userId'] ?? 
                           '';
      
      if (orderOwnerId.toString() != ownerId) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anda tidak memiliki akses ke order ini'))
        );
        return;
      }

      // fetch order items
      final itemsRes = await _api.selectWhere(token, project, 'order_items', appid, 'order_id', orderId.toString());
      final decoded = itemsRes is String ? (itemsRes.trim().isEmpty ? [] : json.decode(itemsRes)) : itemsRes;
      final rawList = (decoded is Map) ? (decoded['data'] ?? []) : (decoded is List ? decoded : []);
      final items = List<Map<String, dynamic>>.from(rawList);

      final List<Map<String, dynamic>> display = [];
      for (final it in items) {
        final pid = it['id_product'] ?? it['id'] ?? '';
        String nama = '';
        if (pid != null && pid.toString().isNotEmpty) {
          try {
            final pRes = await _api.selectWhere(token, project, 'product', appid, 'id_product', pid.toString());
            final pd = pRes is String ? (pRes.trim().isEmpty ? [] : json.decode(pRes)) : pRes;
            final pRaw = (pd is Map) ? (pd['data'] ?? []) : (pd is List ? pd : []);
            if ((pRaw as List).isNotEmpty) {
              // ignore: unnecessary_cast
              final first = (pRaw as List).first as Map<String, dynamic>;
              nama = first['nama_product'] ?? first['nama'] ?? first['name'] ?? '';
            }
          } catch (_) {}
        }

        display.add({
          'product_id': pid,
          // ignore: dead_code
          'name': nama,
          'quantity': it['jumlah_produk'] ?? it['jumlah'] ?? it['qty'] ?? '0',
          'price': it['harga_satu_pack'] ?? it['harga'] ?? it['harga_satuan'] ?? it['harga_satu'] ?? '0',
          'subtotal': it['subtotal'] ?? '0',
        });
      }

      // show dialog
      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Detail Order $orderId'),
            content: SizedBox(
              width: double.maxFinite,
              child: display.isEmpty
                  ? const Text('Tidak ada detail produk')
                  : ListView.separated(
                      shrinkWrap: true,
                      itemBuilder: (c, i) {
                        final d = display[i];
                        return ListTile(
                          title: Text(d['name']?.toString().isNotEmpty == true ? d['name'].toString() : d['product_id'].toString()),
                          subtitle: Text('Jumlah: ${d['quantity']} • Harga: ${d['price']} • Subtotal: ${d['subtotal']}'),
                        );
                      },
                      separatorBuilder: (_, __) => const Divider(),
                      itemCount: display.length,
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
            ],
          );
        },
      );
    } catch (e) {
      debugPrint('Error opening order detail: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal memuat detail: $e')));
    }
  }

  Future<void> _openMap(String alamat) async {
    final Uri uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(alamat)}');
    if (await canLaunchUrl(uri)) await launchUrl(uri);
  }

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: _refreshOrders,
      child: PengirimanPage(
        orders: _orders, 
        loading: _loading, 
        onOpenMap: _openMap, 
        onOpenOrder: _openOrderDetail,
        ownerId: _currentOwnerId,
      ),
    );
  }
}