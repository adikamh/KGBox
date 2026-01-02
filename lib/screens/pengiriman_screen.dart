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

      // For better UI, attach order_items and customer info to each order when possible
      for (var i = 0; i < data.length; i++) {
        final order = Map<String, dynamic>.from(data[i]);
        try {
          // determine order id field
          final orderId = (order['order_id'] ?? order['orderId'] ?? order['id'] ?? order['order'] ?? '').toString();

          // fetch items
          if (orderId.isNotEmpty) {
            try {
              final itemsRes = await _api.selectWhere(token, project, 'order_items', appid, 'order_id', orderId);
              final itemsDecoded = itemsRes is String ? (itemsRes.trim().isEmpty ? [] : json.decode(itemsRes)) : itemsRes;
              final rawItems = (itemsDecoded is Map) ? (itemsDecoded['data'] ?? []) : (itemsDecoded is List ? itemsDecoded : []);
              order['_items'] = List<Map<String, dynamic>>.from(rawItems);
            } catch (e) {
              order['_items'] = <Map<String, dynamic>>[];
            }
          } else {
            order['_items'] = <Map<String, dynamic>>[];
          }

          // fetch customer by several possible fields
          final custId = (order['customor_id'] ?? order['customer_id'] ?? order['customerId'] ?? order['custom_id'] ?? order['customor'] ?? '').toString();
          if (custId.isNotEmpty) {
            try {
              final cRes = await _api.selectWhere(token, project, 'customer', appid, 'customer_id', custId);
              final cDecoded = cRes is String ? (cRes.trim().isEmpty ? {} : json.decode(cRes)) : cRes;
              Map<String, dynamic>? cm;
              if (cDecoded is Map) {
                final List<dynamic> cd = cDecoded['data'] ?? [];
                if (cd.isNotEmpty) cm = (cd.first as Map<String, dynamic>);
              } else if (cDecoded is List && cDecoded.isNotEmpty) {
                cm = (cDecoded.first as Map<String, dynamic>);
              }
              order['_customer'] = cm ?? <String, dynamic>{};
            } catch (e) {
              order['_customer'] = <String, dynamic>{};
            }
          } else {
            // maybe order already contains customer fields
            final cm = {
              'nama_toko': order['nama_toko'] ?? order['store_name'] ?? '',
              'alamat_toko': order['alamat_toko'] ?? order['address'] ?? '',
              'no_telepon_customer': order['no_telepon_customer'] ?? order['phone'] ?? '',
            };
            order['_customer'] = cm;
          }
        } catch (_) {
          order['_items'] = <Map<String, dynamic>>[];
          order['_customer'] = <String, dynamic>{};
        }
        data[i] = order;
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
      final orderId = (order['order_id'] ?? order['orderId'] ?? order['id'] ?? '').toString();
      if (orderId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada order_id')));
        return;
      }

      // verify owner
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';
      final orderOwnerId = (order['ownerid'] ?? order['owner_id'] ?? order['id_owner'] ?? order['userId'] ?? '').toString();
      if (orderOwnerId.isNotEmpty && orderOwnerId != ownerId) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anda tidak memiliki akses ke order ini')));
        return;
      }

      // Use attached data if present
      List<Map<String, dynamic>> items = [];
      try {
        if (order['_items'] is List) items = List<Map<String, dynamic>>.from(order['_items'] as List);
      } catch (_) {}

      Map<String, dynamic> customer = {};
      try {
        if (order['_customer'] is Map) customer = Map<String, dynamic>.from(order['_customer'] as Map);
      } catch (_) {}

      // fetch items if not preloaded
      if (items.isEmpty) {
        try {
          final itemsRes = await _api.selectWhere(token, project, 'order_items', appid, 'order_id', orderId);
          final decoded = itemsRes is String ? (itemsRes.trim().isEmpty ? [] : json.decode(itemsRes)) : itemsRes;
          final rawList = (decoded is Map) ? (decoded['data'] ?? []) : (decoded is List ? decoded : []);
          items = List<Map<String, dynamic>>.from(rawList);
        } catch (_) {
          items = <Map<String, dynamic>>[];
        }
      }

      // fetch customer if not present
      if (customer.isEmpty) {
        final custId = (order['customor_id'] ?? order['customer_id'] ?? order['customerId'] ?? '').toString();
        if (custId.isNotEmpty) {
          try {
            final cRes = await _api.selectWhere(token, project, 'customer', appid, 'customer_id', custId);
            final cDecoded = cRes is String ? (cRes.trim().isEmpty ? {} : json.decode(cRes)) : cRes;
            if (cDecoded is Map) {
              final List<dynamic> cd = cDecoded['data'] ?? [];
              if (cd.isNotEmpty) customer = (cd.first as Map<String, dynamic>);
            } else if (cDecoded is List && cDecoded.isNotEmpty) {
              customer = (cDecoded.first as Map<String, dynamic>);
            }
          } catch (_) {
            customer = <String, dynamic>{};
          }
        } else {
          customer = {
            'nama_toko': order['nama_toko'] ?? order['store_name'] ?? '',
            'alamat_toko': order['alamat_toko'] ?? order['address'] ?? '',
            'no_telepon_customer': order['no_telepon_customer'] ?? order['phone'] ?? '',
          };
        }
      }

      String formatRp(dynamic v) {
        try {
          final n = int.tryParse(v?.toString() ?? '0') ?? (v is num ? v.toInt() : 0);
          final s = n.toString();
          return s.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
        } catch (_) {
          return '0';
        }
      }

      final totalVal = order['total_harga'] ?? order['total'] ?? order['grand_total'] ?? order['subtotal'] ?? 0;

      showDialog(
        context: context,
        builder: (ctx) {
          return AlertDialog(
            title: Text('Detail Order $orderId'),
            content: SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (customer.isNotEmpty) ...[
                      Text('Customer', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),
                      Text(customer['nama_toko'] ?? customer['nama'] ?? customer['name'] ?? ''),
                      const SizedBox(height: 4),
                      Text(customer['alamat_toko'] ?? customer['alamat'] ?? customer['address'] ?? ''),
                      const SizedBox(height: 4),
                      Text('Tel: ${customer['no_telepon_customer'] ?? customer['phone'] ?? ''}'),
                      const Divider(),
                    ],

                    Text('Ringkasan', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    Text('Tanggal: ${order['tanggal_order'] ?? order['date'] ?? ''}'),
                    Text('Total: Rp ${formatRp(totalVal)}'),
                    const Divider(),

                    Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 6),
                    if (items.isEmpty) const Text('Tidak ada item')
                    else
                      ListView.separated(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemBuilder: (c, i) {
                          final it = items[i];
                          final qty = it['jumlah_produk'] ?? it['jumlah'] ?? it['qty'] ?? '0';
                          final price = it['harga'] ?? it['price'] ?? it['harga_satuan'] ?? '0';
                          final subtotal = it['total_harga'] ?? it['subtotal'] ?? (((int.tryParse(price?.toString() ?? '0') ?? 0) * (int.tryParse(qty?.toString() ?? '0') ?? 0)));
                          String name = '';
                          try {
                            if (it['nama_product'] != null) name = it['nama_product'].toString();
                            else if (it['name'] != null) name = it['name'].toString();
                          } catch (_) {}
                          return ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(name.isNotEmpty ? name : (it['id_product'] ?? it['id'] ?? '').toString()),
                            subtitle: Text('Qty: ${qty.toString()} • Harga: Rp ${formatRp(price)}'),
                            trailing: Text('Rp ${formatRp(subtotal)}'),
                          );
                        },
                        separatorBuilder: (_, __) => const Divider(),
                        itemCount: items.length,
                      ),
                  ],
                ),
              ),
            ),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup'))],
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
        onRefresh: _loadOrders,
        ownerId: _currentOwnerId,
      ),
    );
  }
}