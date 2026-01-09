import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:kgbox/services/restapi.dart';

/// ChartOwnerScreen
/// - Streams documents from a collection (default: 'stock_movements')
/// - Aggregates monthly `in` and `out` totals for the last 12 months
/// - Renders a simple bar chart (no external chart package)
///
/// Document mapping heuristics (to be compatible with various schemas):
/// - date fields: `timestamp`, `created_at`, `date` (Timestamp or ISO string)
/// - quantity fields: `quantity`, `qty`, `jumlah`
/// - type fields: `type`, `movement`, `direction` (values containing 'in'/'masuk' or 'out'/'keluar')
class ChartOwnerScreen extends StatefulWidget {
  final String collectionPath;
  final String? ownerId;
  final bool useRestApi;
  final DataService? dataService;
  final Map<String, String>? restApiConfig; // expects keys: token, project, appid

  /// If `ownerId` is provided, outgoing items will be filtered by that owner.
  /// If `useRestApi` is true and `dataService` provided, `order_items` and `orders`
  /// will be fetched via the REST API using `restApiConfig`.
  const ChartOwnerScreen({
    Key? key,
    this.collectionPath = 'stock_movements',
    this.ownerId,
    this.useRestApi = false,
    this.dataService,
    this.restApiConfig,
  }) : super(key: key);

  @override
  State<ChartOwnerScreen> createState() => _ChartOwnerScreenState();
}

class _ChartOwnerScreenState extends State<ChartOwnerScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  List<String> _monthLabels() {
    final now = DateTime.now();
    return List.generate(12, (i) {
      final dt = DateTime(now.year, now.month - (11 - i));
      return DateFormat('MMM').format(dt);
    });
  }

  DateTime _startOfRange() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 11, 1);
    return start;
  }

  @override
  Widget build(BuildContext context) {
    final months = List.generate(12, (i) {
      final now = DateTime.now();
      final dt = DateTime(now.year, now.month - (11 - i), 1);
      return DateTime(dt.year, dt.month);
    });

    final start = _startOfRange();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Diagram Produk Masuk/Keluar'),
        backgroundColor: Colors.blue.shade700,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FutureBuilder<Map<String, List<double>>>(
          future: _fetchTotals(start, months),
          builder: (context, snap) {
            if (snap.hasError) return Center(child: Text('Gagal memuat data: ${snap.error}'));
            if (!snap.hasData) return const Center(child: CircularProgressIndicator());

            final inTotals = snap.data!['in']!;
            final outTotals = snap.data!['out']!;
            final maxVal = [ ...inTotals, ...outTotals ].fold<double>(1, (prev, e) => e > prev ? e : prev);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 180,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(12, (i) {
                      final inVal = inTotals[i];
                      final outVal = outTotals[i];
                      final inHeight = maxVal <= 0 ? 0.0 : (inVal / maxVal) * 140;
                      final outHeight = maxVal <= 0 ? 0.0 : (outVal / maxVal) * 140;

                      return Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (outHeight > 0)
                              Container(
                                height: outHeight,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade400,
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                                ),
                              ),
                            if (inHeight > 0)
                              Container(
                                height: inHeight,
                                margin: const EdgeInsets.symmetric(horizontal: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade400,
                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                                ),
                              ),
                            const SizedBox(height: 6),
                            Text(
                              DateFormat('MMM').format(months[i]),
                              style: const TextStyle(fontSize: 11, color: Colors.black87),
                            ),
                          ],
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _legendItem(Colors.green.shade400, 'Masuk'),
                    const SizedBox(width: 16),
                    _legendItem(Colors.red.shade400, 'Keluar'),
                  ],
                ),
                const SizedBox(height: 12),
                Center(
                  child: Text('Sumber: product_barcodes (Masuk) + order_items (Keluar) — Menampilkan ${DateFormat('MMM yyyy').format(months.first)} hingga ${DateFormat('MMM yyyy').format(months.last)}'),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<Map<String, List<double>>> _fetchTotals(DateTime start, List<DateTime> months) async {
    // initialize
    final inTotals = List<double>.filled(12, 0);
    final outTotals = List<double>.filled(12, 0);

    // try to limit queries by timestamp when possible
    final startTs = Timestamp.fromDate(start);

    QuerySnapshot<Map<String, dynamic>> pbSnap;
    try {
      pbSnap = await _firestore.collection('product_barcodes').where('scannedAt', isGreaterThanOrEqualTo: startTs).get();
    } catch (_) {
      pbSnap = await _firestore.collection('product_barcodes').get();
    }

    for (final doc in pbSnap.docs) {
      final data = doc.data();
      DateTime? dt;
      if (data['scannedAt'] is Timestamp) dt = (data['scannedAt'] as Timestamp).toDate();
      else if (data['scannedAt'] is String) {
        try { dt = DateTime.parse(data['scannedAt']); } catch (_) {}
      }
      if (dt == null) continue;
      if (dt.isBefore(start)) continue;

      final idx = months.indexWhere((m) => m.year == dt?.year && m.month == dt?.month);
      if (idx < 0) continue;

      // each barcode scan equals one incoming unit
      inTotals[idx] = inTotals[idx] + 1.0;
    }

    // If REST API is enabled and a DataService is provided, use it to fetch order_items and orders
    if (widget.useRestApi && widget.dataService != null && widget.restApiConfig != null) {
      final cfg = widget.restApiConfig!;
      final token = cfg['token'] ?? '';
      final project = cfg['project'] ?? '';
      final appid = cfg['appid'] ?? '';

      // fetch order_items (filter by ownerid if available)
      dynamic oiRaw;
      try {
        if (widget.ownerId != null && widget.ownerId!.isNotEmpty) {
          final resp = await widget.dataService!.selectWhere(token, project, 'order_items', appid, 'ownerid', widget.ownerId!);
          oiRaw = resp;
        } else {
          final resp = await widget.dataService!.selectAll(token, project, 'order_items', appid);
          oiRaw = resp;
        }
      } catch (e) {
        oiRaw = '[]';
      }

      List<dynamic> orderItemsList = [];
      try {
        if (oiRaw is String) orderItemsList = jsonDecode(oiRaw) as List<dynamic>;
        else if (oiRaw is List) orderItemsList = oiRaw;
      } catch (_) {
        orderItemsList = [];
      }

      // collect order_ids
      final orderIds = <String>{};
      for (final item in orderItemsList) {
        if (item is Map) {
          final oid = item['order_id'] ?? item['orderId'];
          if (oid != null) orderIds.add(oid.toString());
        }
      }

      // fetch orders via REST in batch using selectWhereIn (comma separated)
      final orderDateMap = <String, DateTime>{};
      if (orderIds.isNotEmpty) {
        final batches = <List<String>>[];
        final ids = orderIds.toList();
        const batchSize = 50; // REST endpoint may accept large lists; adjust if needed
        for (var i = 0; i < ids.length; i += batchSize) {
          batches.add(ids.sublist(i, (i + batchSize) > ids.length ? ids.length : i + batchSize));
        }

        for (final b in batches) {
          try {
            final winValue = b.join(',');
            final resp = await widget.dataService!.selectWhereIn(token, project, 'orders', appid, 'order_id', winValue);
            if (resp != null) {
              final parsed = (resp is String) ? jsonDecode(resp) : resp;
              if (parsed is List) {
                for (final od in parsed) {
                  if (od is Map) {
                    DateTime? d;
                    final v = od['tanggal_order'] ?? od['tanggal'] ?? od['order_date'] ?? od['date'];
                    if (v is String) {
                      try { d = DateTime.parse(v); } catch (_) {}
                    }
                    // sometimes id stored in 'order_id' or 'id'
                    final key = od['order_id']?.toString() ?? od['id']?.toString() ?? '';
                    if (d != null && key.isNotEmpty) orderDateMap[key] = d;
                  }
                }
              }
            }
          } catch (_) {
            // ignore batch errors
          }
        }
      }

      // process order items list
      for (final raw in orderItemsList) {
        if (raw is! Map) continue;
        final data = raw as Map<String, dynamic>;

        // owner filter already applied when fetching, but double-check
        if (widget.ownerId != null) {
          final ownerField = data['ownerid'] ?? data['owner_id'];
          if (ownerField == null || ownerField.toString() != widget.ownerId) continue;
        }

        // date: prefer order date
        DateTime? dt;
        final oid = data['order_id'] ?? data['orderId'];
        if (oid != null && orderDateMap.containsKey(oid.toString())) dt = orderDateMap[oid.toString()];

        // fallback to date fields in item
        if (dt == null) {
          final dateKeys = ['created_at', 'timestamp', 'order_date', 'date', 'tanggal', 'scannedAt'];
          for (final k in dateKeys) {
            if (data.containsKey(k) && data[k] != null) {
              final v = data[k];
              if (v is String) { try { dt = DateTime.parse(v); break; } catch (_) {} }
            }
          }
        }
        if (dt == null) continue;
        if (dt.isBefore(start)) continue;

        final idx = months.indexWhere((m) => m.year == dt?.year && m.month == dt?.month);
        if (idx < 0) continue;

        // quantity via list_barcode
        num qty = 0;
        if (data.containsKey('list_barcode') && data['list_barcode'] != null) {
          final lb = data['list_barcode'];
          if (lb is List) qty = lb.length;
          else if (lb is String) {
            final parsed = lb.trim();
            if (parsed.startsWith('[') && parsed.endsWith(']')) {
              try {
                final inner = parsed.substring(1, parsed.length - 1);
                final items = inner.split(',').map((s) => s.replaceAll(RegExp(r'''["']'''), '').trim()).where((s) => s.isNotEmpty).toList();
                qty = items.length;
              } catch (_) {}
            }
          }
        }
        if (qty == 0) {
          final qtyKeys = ['jumlah_produk', 'quantity', 'qty', 'jumlah'];
          for (final k in qtyKeys) {
            if (data.containsKey(k) && data[k] != null) {
              final v = data[k];
              if (v is num) qty = v;
              else if (v is String) qty = num.tryParse(v.replaceAll(',', '')) ?? 0;
              break;
            }
          }
        }
        if (qty == 0) qty = 1;
        outTotals[idx] = outTotals[idx] + qty.toDouble();
      }
    } else {
      // FIRESTORE branch (existing behavior)
      // load order_items for outgoing
      QuerySnapshot<Map<String, dynamic>> oiSnap;
      try {
        oiSnap = await _firestore.collection('order_items').where('created_at', isGreaterThanOrEqualTo: startTs).get();
      } catch (_) {
        // fallback: fetch all and filter
        oiSnap = await _firestore.collection('order_items').get();
      }

      // Preload orders by order_id to get `tanggal_order` for each order
      final orderIds = <String>{};
      for (final doc in oiSnap.docs) {
        final data = doc.data();
        final oid = data['order_id'] ?? data['orderId'] ?? data['order_id_server'];
        if (oid != null) orderIds.add(oid.toString());
      }

      final Map<String, DateTime> orderDateMap = {};
      final ordersCollection = _firestore.collection('order');
      // Firestore whereIn supports max 10 values per query - batch if needed
      final orderIdList = orderIds.toList();
      const batchSize = 10;
      for (var i = 0; i < orderIdList.length; i += batchSize) {
        final batch = orderIdList.sublist(i, (i + batchSize) > orderIdList.length ? orderIdList.length : i + batchSize);
        try {
          final q = await ordersCollection.where('order_id', whereIn: batch).get();
          for (final od in q.docs) {
            final odData = od.data();
            DateTime? d;
            final v = odData['tanggal_order'] ?? odData['tanggal'] ?? odData['order_date'] ?? odData['date'];
            if (v is Timestamp) d = v.toDate();
            else if (v is String) {
              try { d = DateTime.parse(v); } catch (_) {}
            }
            if (d != null) orderDateMap[odData['order_id']?.toString() ?? od.id] = d;
          }
        } catch (_) {
          // ignore failures to fetch orders in batch
        }
      }

      // Now process order_items and use orderDateMap to find tanggal_order
      for (final doc in oiSnap.docs) {
        final data = doc.data();

        // owner filter
        if (widget.ownerId != null) {
          final ownerField = data['ownerid'] ?? data['owner_id'];
          if (ownerField == null || ownerField.toString() != widget.ownerId) continue;
        }

        // determine date: prefer order's `tanggal_order`
        DateTime? dt;
        final oid = data['order_id'] ?? data['orderId'] ?? data['order_id_server'];
        if (oid != null && orderDateMap.containsKey(oid.toString())) {
          dt = orderDateMap[oid.toString()];
        }

        // fallback: try date fields in order_items
        if (dt == null) {
          final dateKeys = ['created_at', 'timestamp', 'order_date', 'date', 'tanggal', 'scannedAt'];
          for (final k in dateKeys) {
            if (data.containsKey(k) && data[k] != null) {
              final v = data[k];
              if (v is Timestamp) { dt = v.toDate(); break; }
              if (v is String) { try { dt = DateTime.parse(v); break;} catch (_) {} }
            }
          }
        }

        if (dt == null) continue;
        if (dt.isBefore(start)) continue;

        final idx = months.indexWhere((m) => m.year == dt?.year && m.month == dt?.month);
        if (idx < 0) continue;

        // quantity field: prefer counting `list_barcode` array if present
        num qty = 0;
        if (data.containsKey('list_barcode') && data['list_barcode'] != null) {
          final lb = data['list_barcode'];
          if (lb is List) {
            qty = lb.length;
          } else if (lb is String) {
            // try to parse simple JSON-like array string
            final parsed = lb.trim();
            if (parsed.startsWith('[') && parsed.endsWith(']')) {
              try {
                final inner = parsed.substring(1, parsed.length - 1);
                final items = inner.split(',').map((s) => s.replaceAll(RegExp(r'''["']'''), '').trim()).where((s) => s.isNotEmpty).toList();
                qty = items.length;
              } catch (_) {
                // ignore parse errors
              }
            }
          }
        }

        if (qty == 0) {
          final qtyKeys = ['jumlah_produk', 'quantity', 'qty', 'jumlah'];
          for (final k in qtyKeys) {
            if (data.containsKey(k) && data[k] != null) {
              final v = data[k];
              if (v is num) qty = v;
              else if (v is String) qty = num.tryParse(v.replaceAll(',', '')) ?? 0;
              break;
            }
          }
        }

        if (qty == 0) qty = 1; // default to 1 if not present

        outTotals[idx] = outTotals[idx] + qty.toDouble();
      }
    }

    return {'in': inTotals, 'out': outTotals};
  }

  Widget _legendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 12, height: 12, color: color),
        const SizedBox(width: 6),
        Text(text),
      ],
    );
  }
}