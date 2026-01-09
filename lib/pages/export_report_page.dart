import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import '../services/config.dart';
import '../services/restapi.dart';
import 'dart:convert';
import '../services/export_service.dart';
import 'package:share_plus/share_plus.dart';
// ignore: unused_import
import 'package:path_provider/path_provider.dart' as pp;

class ExportReportPage extends StatefulWidget {
  const ExportReportPage({super.key});

  @override
  State<ExportReportPage> createState() => _ExportReportPageState();
}

class _ExportReportPageState extends State<ExportReportPage> {
  final TextEditingController _productsCollectionController = TextEditingController(text: 'product');
  final TextEditingController _transactionsCollectionController = TextEditingController(text: 'transactions');
  bool _loading = false;

  @override
  void dispose() {
    _productsCollectionController.dispose();
    _transactionsCollectionController.dispose();
    super.dispose();
  }

  Future<void> _exportReport() async {
    setState(() => _loading = true);
    final api = DataService();
    final prodCol = _productsCollectionController.text.trim();
    final trxCol = _transactionsCollectionController.text.trim();

    List<dynamic> products = [];
    List<dynamic> transactions = [];

    try {
      final prodRaw = await api.selectAll(token, project, prodCol, appid);
      products = _safeParseList(prodRaw);
    } catch (e) {
      debugPrint('Failed fetching products: $e');
    }

    try {
      final trxRaw = await api.selectAll(token, project, trxCol, appid);
      transactions = _safeParseList(trxRaw);
    } catch (e) {
      debugPrint('Failed fetching transactions: $e');
    }

    // Show quick feedback about fetched counts so user knows data came from server
    try {
      final prodCount = products.length;
      final trxCount = transactions.length;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Fetched products: $prodCount, transactions: $trxCount'),
          duration: const Duration(seconds: 3),
        ));
      }
    } catch (e) {
      debugPrint('Failed showing fetch counts: $e');
    }

    // Aggregate per month (YYYY-MM)
    final Map<String, int> itemsPurchased = {}; // total stock added per month
    final Map<String, double> revenuePurchased = {}; // harga * jumlah per month
    final Map<String, int> itemsOut = {}; // total items out per month (from transactions)
    final Map<String, double> revenueOut = {}; // revenue from transactions per month

    DateTime toMonthKey(dynamic dateVal) {
      DateTime dt;
      if (dateVal == null) return DateTime.now();
      if (dateVal is DateTime) {
        dt = dateVal;
      } else if (dateVal is int) dt = DateTime.fromMillisecondsSinceEpoch(dateVal);
      else {
        dt = DateTime.tryParse(dateVal.toString()) ?? DateTime.now();
      }
      return DateTime(dt.year, dt.month);
    }

    String monthKeyFromDate(dynamic dateVal) {
      final dt = toMonthKey(dateVal);
      return '${dt.year.toString().padLeft(4,'0')}-${dt.month.toString().padLeft(2,'0')}';
    }

    int toInt(dynamic v) {
      if (v == null) return 0;
      if (v is int) return v;
      if (v is double) return v.round();
      if (v is String) return int.tryParse(v.replaceAll(RegExp(r'[^0-9-]'), '')) ?? 0;
      return 0;
    }

    double toDouble(dynamic v) {
      if (v == null) return 0.0;
      if (v is double) return v;
      if (v is int) return v.toDouble();
      if (v is String) return double.tryParse(v.replaceAll(RegExp(r'[^0-9\.]'), '')) ?? 0.0;
      return 0.0;
    }

    // Products aggregation: use tanggal_beli, jumlah_produk, harga_product
    for (var item in products) {
      if (item is! Map) continue;
      final dateVal = item['tanggal_beli'] ?? item['created_at'] ?? item['date'] ?? item['tanggal'] ?? item['updated'];
      final key = monthKeyFromDate(dateVal);
      final jumlah = toInt(item['jumlah_produk'] ?? item['stok'] ?? item['qty'] ?? item['jumlah']);
      final harga = toDouble(item['harga_product'] ?? item['harga'] ?? item['price'] ?? item['price_total']);
      itemsPurchased[key] = (itemsPurchased[key] ?? 0) + jumlah;
      revenuePurchased[key] = (revenuePurchased[key] ?? 0.0) + (harga * jumlah);
    }

    // Transactions aggregation: try to extract totals and items
    for (var trx in transactions) {
      if (trx is! Map) continue;
      final dateVal = trx['tanggal'] ?? trx['date'] ?? trx['created_at'] ?? trx['time'] ?? trx['waktu'];
      final key = monthKeyFromDate(dateVal);

      // get transaction total
      double total = 0.0;
      // Try common total fields
      final candidates = ['total', 'total_price', 'harga_total', 'grand_total', 'amount', 'nominal'];
      for (var c in candidates) {
        if (trx.containsKey(c)) {
          total = toDouble(trx[c]);
          break;
        }
      }

      int totalQty = 0;
      // If items list exists
      if (trx.containsKey('items') && trx['items'] is List) {
        for (var it in trx['items']) {
          if (it is Map) {
            final q = toInt(it['qty'] ?? it['jumlah'] ?? it['quantity']);
            final p = toDouble(it['price'] ?? it['harga'] ?? it['price_unit']);
            totalQty += q;
            if (total == 0.0) total += p * q;
          }
        }
      }

      // If total still zero, some records might store value in nested 'full' or other structure
      if (total == 0.0) {
        // try sum of number-like fields
        for (var v in trx.values) {
          if (v is num) total += v.toDouble();
        }
      }

      itemsOut[key] = (itemsOut[key] ?? 0) + totalQty;
      revenueOut[key] = (revenueOut[key] ?? 0.0) + total;
    }

    // Build combined month list
    final Set<String> months = {};
    months.addAll(itemsPurchased.keys);
    months.addAll(revenuePurchased.keys);
    months.addAll(itemsOut.keys);
    months.addAll(revenueOut.keys);

    final List<String> sortedMonths = months.toList()..sort();

    // Create CSV
    final sb = StringBuffer();
    sb.writeln('month,total_items_purchased,revenue_purchased,total_items_out,revenue_out');
    for (var m in sortedMonths) {
      final a = itemsPurchased[m] ?? 0;
      final b = (revenuePurchased[m] ?? 0.0);
      final c = itemsOut[m] ?? 0;
      final d = (revenueOut[m] ?? 0.0);
      sb.writeln('$m,$a,${b.toStringAsFixed(2)},$c,${d.toStringAsFixed(2)}');
    }

    // Save/share CSV
    try {
      final fileName = 'report_${DateTime.now().millisecondsSinceEpoch}.csv';
      String savedPath = '';
      if (kIsWeb) {
        await ExportService.saveText(fileName, sb.toString(), mimeType: 'text/csv');
      } else {
        savedPath = await ExportService.saveText(fileName, sb.toString(), mimeType: 'text/csv');
        if (savedPath.isNotEmpty) {
          try {
            await Share.shareXFiles([XFile(savedPath)], text: 'Export report');
          } catch (_) {
            await Share.share(sb.toString(), subject: fileName);
          }
        }
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Export selesai${savedPath.isNotEmpty ? ': $savedPath' : ''}')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal export: $e')));
    } finally {
      setState(() => _loading = false);
    }
  }

  List<dynamic> _safeParseList(dynamic raw) {
    try {
      if (raw == null) return [];
      if (raw is String) {
        final d = jsonDecode(raw);
        if (d is Map && d.containsKey('data')) return d['data'] as List? ?? [];
        if (d is List) return d;
        return [];
      }
      if (raw is Map && raw.containsKey('data')) return raw['data'] as List? ?? [];
      if (raw is List) return raw;
      return [];
    } catch (e) {
      return [];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Export Report')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Produk collection (default: product)'),
            TextField(controller: _productsCollectionController),
            const SizedBox(height: 12),
            const Text('Transaksi collection (default: transactions)'),
            TextField(controller: _transactionsCollectionController),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _loading ? null : _exportReport,
                icon: const Icon(Icons.download),
                label: Text(_loading ? 'Memproses...' : 'Export CSV'),
              ),
            ),
            const SizedBox(height: 12),
            const Text('Hasil: CSV berisi bulan, total produk masuk, nilai (harga*qty), total produk keluar (dari transaksi), revenue transaksi.'),
          ],
        ),
      ),
    );
  }
}