import 'package:cloud_firestore/cloud_firestore.dart';
// ignore: unused_import
import 'dart:io';

import 'package:csv/csv.dart';
import 'dart:typed_data';
import 'dart:convert';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:KGbox/utils/file_saver.dart';
import '../services/restapi.dart';
import '../services/config.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart';

/// Export report screen and Firestore report logic.
class ExportReportScreen extends StatefulWidget {
  final String? initialFormat; // 'csv'|'pdf'|'xlsx' or null
  final String? ownerId; // optional filter for barcodes
  final String reportType; // 'available_products' | 'expired_products' | 'delivery_orders'
  const ExportReportScreen({super.key, this.initialFormat, this.ownerId, this.reportType = 'available_products'});


  @override
  State<ExportReportScreen> createState() => _ExportReportScreenState();
}

class _ExportReportScreenState extends State<ExportReportScreen> {
  bool _loading = false;
  List<Map<String, dynamic>> _report = [];
  String? _pendingAutoExport;

  Future<void> _loadReport() async {
    setState(() => _loading = true);
    try {
      // TEST: First fetch customer data to debug
      await testFetchCustomers();
      
      if (widget.reportType == 'expired_products') {
        _report = await fetchExpiredProductsReport(widget.ownerId);
      } else if (widget.reportType == 'delivery_orders') {
        _report = await fetchDeliveryOrderReport(widget.ownerId);
      } else {
        _report = await fetchProductsReport(widget.ownerId);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
    } finally {
      setState(() => _loading = false);
      if (_pendingAutoExport != null) {
        final fmt = _pendingAutoExport;
        _pendingAutoExport = null;
        if (fmt == 'csv') await _exportCsv();
        else if (fmt == 'pdf') await _exportPdf();
        else if (fmt == 'xlsx') await _exportXlsx();
      }
    }
  }

  @override
  void initState() {
    super.initState();
    if (widget.initialFormat != null) {
      // store pending export, then load and export
      _pendingAutoExport = widget.initialFormat;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadReport();
      });
    }
  }

  Future<void> _exportCsv() async {
    if (_report.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final rows = <List<dynamic>>[];

    if (widget.reportType == 'delivery_orders') {
      // Columns for delivery orders report
      final headers = [
        'order_id',
        'customor_id',
        'nama_toko',
        'nama_pemilik_toko',
        'no_telepon_customer',
        'alamat_toko',
        'tanggal_order',
        'total_harga',
        'barang_yang_dibeli'
      ];
      rows.add(headers);

      for (final item in _report) {
        // Format items as readable string (product names with quantity)
        final itemsList = (item['items'] as List<dynamic>?) ?? [];
        final itemsStr = itemsList.isEmpty
            ? ''
            : itemsList.map((i) {
                if (i is! Map) return '';
                final nama = i['nama_barang'] ?? i['product_name'] ?? '';
                final qty = i['jumlah'] ?? 1;
                return '$nama (x$qty)';
              }).join('; ');
        
        rows.add([
          item['order_id'] ?? '',
          item['customor_id'] ?? '',
          item['nama_toko'] ?? '',
          item['nama_pemilik_toko'] ?? '',
          item['no_telepon_customer'] ?? '',
          item['alamat_toko'] ?? '',
          item['tanggal_order'] ?? '',
          item['total_harga'] ?? '',
          itemsStr,
        ]);
      }
    } else if (widget.reportType == 'expired_products') {
      // Build CSV rows for expired products report
      final headers = [
        'Product ID',
        'Nama',
        'Brand',
        'Kategori',
        'Harga',
        'Supplier',
        'Production Date',
        'Expired Date',
        'Jumlah Barcode',
        'List Barcodes (kode @ scannedAt)'
      ];

      rows.add(headers);

      for (final item in _report) {
        final barcodeEntries = (item['barcodes'] as List<dynamic>?) ?? [];
        final barcodeJoined = barcodeEntries.isEmpty
            ? ''
            : barcodeEntries.map((b) {
                final code = b['barcode'] ?? '';
                final scanned = b['scannedAt'] != null
                    ? (b['scannedAt'] is Timestamp
                        ? DateFormat('yyyy-MM-dd HH:mm:ss').format((b['scannedAt'] as Timestamp).toDate())
                        : b['scannedAt'].toString())
                    : '';
                return '$code @ $scanned';
              }).join(' | ');

        rows.add([
          item['product_id'] ?? '',
          item['nama'] ?? '',
          item['brand'] ?? '',
          item['category'] ?? '',
          _formatPrice(item['price']),
          item['supplierName'] ?? '',
          _formatDate(item['productionDate']),
          _formatDate(item['expiredDate']),
          barcodeEntries.length,
          barcodeJoined,
        ]);
      }
    } else {
      // Build CSV rows for available products report
      final headers = [
        'Product ID',
        'Nama',
        'Brand',
        'Kategori',
        'Harga',
        'Supplier',
        'Production Date',
        'Expired Date',
        'Jumlah Barcode',
        'List Barcodes (kode @ scannedAt)'
      ];

      rows.add(headers);

      for (final item in _report) {
        final barcodeEntries = (item['barcodes'] as List<dynamic>?) ?? [];
        final barcodeJoined = barcodeEntries.isEmpty
            ? ''
            : barcodeEntries.map((b) {
                final code = b['barcode'] ?? '';
                final scanned = b['scannedAt'] != null
                    ? (b['scannedAt'] is Timestamp
                        ? DateFormat('yyyy-MM-dd HH:mm:ss').format((b['scannedAt'] as Timestamp).toDate())
                        : b['scannedAt'].toString())
                    : '';
                return '$code @ $scanned';
              }).join(' | ');

        rows.add([
          item['product_id'] ?? '',
          item['nama'] ?? '',
          item['brand'] ?? '',
          item['category'] ?? '',
          _formatPrice(item['price']),
          item['supplierName'] ?? '',
          _formatDate(item['productionDate']),
          _formatDate(item['expiredDate']),
          barcodeEntries.length,
          barcodeJoined,
        ]);
      }
    }

    final csv = const ListToCsvConverter().convert(rows);

    // Generate filename based on report type
    String filename;
    if (widget.reportType == 'delivery_orders') {
      filename = 'laporan_order_pengiriman_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
    } else if (widget.reportType == 'expired_products') {
      filename = 'laporan_produk_kadaluarsa_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
    } else {
      filename = 'laporan_produk_${DateTime.now().toIso8601String().replaceAll(':', '-')}.csv';
    }

    // Save CSV using cross-platform saver (web download or local file)
    try {
      final bytes = Uint8List.fromList(utf8.encode(csv));
      final path = await saveBytes(bytes, filename);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Laporan disimpan: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan file: $e')));
    }
  }

  Future<void> _exportPdf() async {
    if (_report.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final pdf = pw.Document();
    
    if (widget.reportType == 'delivery_orders') {
      // PDF for delivery orders
      final headers = [
        'Order ID', 'Customer ID', 'Nama Toko', 'Nama Pemilik', 'Telepon', 'Alamat', 'Tanggal Order', 'Total Harga', 'Barang Dibeli'
      ];

      final data = <List<String>>[];
      for (final item in _report) {
        // Format items as readable string (product names with quantity)
        final itemsList = (item['items'] as List<dynamic>?) ?? [];
        final itemsStr = itemsList.isEmpty
            ? ''
            : itemsList.map((i) {
                if (i is! Map) return '';
                final nama = i['nama_barang'] ?? i['product_name'] ?? '';
                final qty = i['jumlah'] ?? 1;
                return '$nama (x$qty)';
              }).join('; ');
        
        data.add([
          item['order_id']?.toString() ?? '',
          item['customor_id']?.toString() ?? '',
          item['nama_toko']?.toString() ?? '',
          item['nama_pemilik_toko']?.toString() ?? '',
          item['no_telepon_customer']?.toString() ?? '',
          item['alamat_toko']?.toString() ?? '',
          _formatDate(item['tanggal_order']),
          _formatPrice(item['total_harga']),
          itemsStr,
        ]);
      }

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text('Laporan Order Pengiriman')),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ));
    } else {
      // PDF for products report
      final headers = [
        'Product ID', 'Nama', 'Brand', 'Kategori', 'Harga', 'Supplier', 'Production Date', 'Expired Date', 'Jumlah Barcode', 'List Barcodes'
      ];

      final data = <List<String>>[];
      for (final item in _report) {
        final barcodeEntries = (item['barcodes'] as List<dynamic>?) ?? [];
        final barcodeJoined = barcodeEntries.map((b) {
          final code = b['barcode'] ?? '';
          final scanned = b['scannedAt'] != null ? (b['scannedAt'] is Timestamp ? (b['scannedAt'] as Timestamp).toDate().toIso8601String() : b['scannedAt'].toString()) : '';
          return '$code @ $scanned';
        }).join(' | ');

        data.add([
          item['product_id']?.toString() ?? '',
          item['nama']?.toString() ?? '',
          item['brand']?.toString() ?? '',
          item['category']?.toString() ?? '',
          _formatPrice(item['price']),
          item['supplierName']?.toString() ?? '',
          _formatDate(item['productionDate']),
          _formatDate(item['expiredDate']),
          barcodeEntries.length.toString(),
          barcodeJoined,
        ]);
      }

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (context) => [
          pw.Header(level: 0, child: pw.Text(widget.reportType == 'expired_products' ? 'Laporan Produk Kadaluarsa' : 'Laporan Keseluruhan Produk')),
          pw.SizedBox(height: 8),
          pw.Table.fromTextArray(
            headers: headers,
            data: data,
            cellStyle: const pw.TextStyle(fontSize: 9),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
        ],
      ));
    }

    try {
      final bytes = await pdf.save();
      
      // Generate filename based on report type
      String filename;
      if (widget.reportType == 'delivery_orders') {
        filename = 'laporan_order_pengiriman_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf';
      } else if (widget.reportType == 'expired_products') {
        filename = 'laporan_produk_kadaluarsa_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf';
      } else {
        filename = 'laporan_produk_${DateTime.now().toIso8601String().replaceAll(':', '-')}.pdf';
      }
      
      final path = await saveBytes(bytes, filename);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('PDF disimpan: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan PDF: $e')));
    }
  }

  Future<void> _exportXlsx() async {
    if (_report.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No data to export')));
      return;
    }

    final excel = Excel.createExcel();
    
    if (widget.reportType == 'delivery_orders') {
      // Excel for delivery orders
      final sheet = excel['Laporan Order Pengiriman'];
      final headers = [
        'Order ID', 'Customer ID', 'Nama Toko', 'Nama Pemilik Toko', 'No Telepon Customer', 'Alamat Toko', 'Tanggal Order', 'Total Harga', 'Barang Yang Dibeli'
      ];
      sheet.appendRow(headers);

      for (final item in _report) {
        // Format items as readable string (product names with quantity)
        final itemsList = (item['items'] as List<dynamic>?) ?? [];
        final itemsStr = itemsList.isEmpty
            ? ''
            : itemsList.map((i) {
                if (i is! Map) return '';
                final nama = i['nama_barang'] ?? i['product_name'] ?? '';
                final qty = i['jumlah'] ?? 1;
                return '$nama (x$qty)';
              }).join('; ');
        
        sheet.appendRow([
          item['order_id']?.toString() ?? '',
          item['customor_id']?.toString() ?? '',
          item['nama_toko']?.toString() ?? '',
          item['nama_pemilik_toko']?.toString() ?? '',
          item['no_telepon_customer']?.toString() ?? '',
          item['alamat_toko']?.toString() ?? '',
          _formatDate(item['tanggal_order']),
          _formatPrice(item['total_harga']),
          itemsStr,
        ]);
      }
    } else {
      // Excel for products report
      final sheet = excel[widget.reportType == 'expired_products' ? 'Laporan Produk Kadaluarsa' : 'Laporan Produk'];
      final headers = [
        'Product ID', 'Nama', 'Brand', 'Kategori', 'Harga', 'Supplier', 'Production Date', 'Expired Date', 'Jumlah Barcode', 'List Barcodes'
      ];
      sheet.appendRow(headers);

      for (final item in _report) {
        final barcodeEntries = (item['barcodes'] as List<dynamic>?) ?? [];
        final barcodeJoined = barcodeEntries.map((b) {
          final code = b['barcode'] ?? '';
          final scanned = b['scannedAt'] != null ? (b['scannedAt'] is Timestamp ? (b['scannedAt'] as Timestamp).toDate().toIso8601String() : b['scannedAt'].toString()) : '';
          return '$code @ $scanned';
        }).join(' | ');

        sheet.appendRow([
          item['product_id']?.toString() ?? '',
          item['nama']?.toString() ?? '',
          item['brand']?.toString() ?? '',
          item['category']?.toString() ?? '',
          _formatPrice(item['price']),
          item['supplierName']?.toString() ?? '',
          _formatDate(item['productionDate']),
          _formatDate(item['expiredDate']),
          barcodeEntries.length,
          barcodeJoined,
        ]);
      }
    }

    try {
      final bytes = excel.encode();
      if (bytes == null) throw 'Failed to encode XLSX';
      
      // Generate filename based on report type
      String filename;
      if (widget.reportType == 'delivery_orders') {
        filename = 'laporan_order_pengiriman_${DateTime.now().toIso8601String().replaceAll(':', '-')}.xlsx';
      } else if (widget.reportType == 'expired_products') {
        filename = 'laporan_produk_kadaluarsa_${DateTime.now().toIso8601String().replaceAll(':', '-')}.xlsx';
      } else {
        filename = 'laporan_produk_${DateTime.now().toIso8601String().replaceAll(':', '-')}.xlsx';
      }
      
      final path = await saveBytes(Uint8List.fromList(bytes), filename);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Excel disimpan: $path')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menyimpan Excel: $e')));
    }
  }

  void _showFormatSelectionDialog() {
    final formats = [
      {'label': 'CSV (.csv)', 'value': 'csv'},
      {'label': 'PDF (.pdf)', 'value': 'pdf'},
      {'label': 'Excel (.xlsx)', 'value': 'xlsx'},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Row(
          children: [
            Icon(Icons.file_present, color: Theme.of(context).primaryColor),
            SizedBox(width: 8),
            Text('Pilih Format File'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: formats.length,
            itemBuilder: (context, index) {
              final format = formats[index];
              return Card(
                margin: EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: Icon(
                    index == 0 ? Icons.description : index == 1 ? Icons.picture_as_pdf : Icons.grid_on,
                    color: Theme.of(context).primaryColor,
                  ),
                  title: Text(format['label'] as String, style: TextStyle(fontWeight: FontWeight.w600)),
                  onTap: () {
                    Navigator.pop(context);
                    if (format['value'] == 'csv') {
                      _exportCsv();
                    } else if (format['value'] == 'pdf') {
                      _exportPdf();
                    } else if (format['value'] == 'xlsx') {
                      _exportXlsx();
                    }
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Batal', style: TextStyle(color: Theme.of(context).primaryColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildExportActionButton() {
    // If an initial format was provided, show single export button for that format
    final fmt = widget.initialFormat;
    String label = 'Export (CSV / PDF / XLSX)';
    IconData icon = Icons.download_outlined;
    VoidCallback? onPressed;

    if (fmt == 'csv') {
      label = 'Export CSV';
      icon = Icons.description;
      onPressed = _report.isEmpty ? null : _exportCsv;
    } else if (fmt == 'pdf') {
      label = 'Export PDF';
      icon = Icons.picture_as_pdf;
      onPressed = _report.isEmpty ? null : _exportPdf;
    } else if (fmt == 'xlsx') {
      label = 'Export Excel';
      icon = Icons.grid_on;
      onPressed = _report.isEmpty ? null : _exportXlsx;
    } else {
      // no initial format — show format chooser
      label = 'Export (CSV / PDF / XLSX)';
      icon = Icons.download_outlined;
      onPressed = _report.isEmpty ? null : _showFormatSelectionDialog;
    }

    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
    );
  }

  @override
  Widget build(BuildContext context) {
    String appBarTitle;
    switch (widget.reportType) {
      case 'expired_products':
        appBarTitle = 'Export - Produk Kadaluarsa';
        break;
      case 'delivery_orders':
        appBarTitle = 'Export - Order Pengiriman';
        break;
      default:
        appBarTitle = 'Export - Produk Tersedia';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(appBarTitle),
        backgroundColor: Theme.of(context).primaryColor,
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Statistik Laporan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Chip(
                          label: Text('${_report.length} Data'),
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                        ),
                      ],
                    ),
                    SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _loading ? null : _loadReport,
                            icon: Icon(Icons.refresh, size: 20),
                            label: Text(_loading ? 'Loading...' : 'Refresh Data'),
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: _buildExportActionButton(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 16),
            Expanded(
              child: _loading
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          CircularProgressIndicator(),
                          SizedBox(height: 16),
                          Text('Memuat data...', style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    )
                  : _report.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.inbox_outlined, size: 64, color: Colors.grey[400]),
                              SizedBox(height: 16),
                              Text(
                                'Tidak ada data',
                                style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Klik "Refresh Data" untuk memuat laporan',
                                style: TextStyle(color: Colors.grey[500]),
                              ),
                            ],
                          ),
                        )
                      : Card(
                          elevation: 2,
                          child: Column(
                            children: [
                              Padding(
                                padding: EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    Icon(Icons.list_alt, color: Theme.of(context).primaryColor),
                                    SizedBox(width: 8),
                                    Text(
                                      'Preview Data',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Divider(height: 0),
                              Expanded(
                                child: ListView.builder(
                                  itemCount: _report.length,
                                  itemBuilder: (context, i) {
                                    final item = _report[i];
                                    if (widget.reportType == 'delivery_orders') {
                                      final items = (item['items'] as List<dynamic>?) ?? [];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          child: Text((i + 1).toString()),
                                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                          foregroundColor: Theme.of(context).primaryColor,
                                        ),
                                        title: Text(
                                          item['order_id']?.toString() ?? 'Order ID tidak tersedia',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 4),
                                            Text(
                                              'Toko: ${item['nama_toko'] ?? item['customor_id'] ?? '-'}',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'Total: ${_formatPrice(item['total_harga'])} • Items: ${items.length}',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                                      );
                                    } else {
                                      final barcodes = (item['barcodes'] as List<dynamic>?) ?? [];
                                      return ListTile(
                                        leading: CircleAvatar(
                                          child: Text((i + 1).toString()),
                                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.1),
                                          foregroundColor: Theme.of(context).primaryColor,
                                        ),
                                        title: Text(
                                          item['nama'] ?? item['product_id'] ?? 'Produk tidak teridentifikasi',
                                          style: TextStyle(fontWeight: FontWeight.w600),
                                        ),
                                        subtitle: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            SizedBox(height: 4),
                                            Text(
                                              'Brand: ${item['brand'] ?? '-'} • Kategori: ${item['category'] ?? '-'}',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                            Text(
                                              'Barcode: ${barcodes.length} • Expired: ${_formatDate(item['expiredDate'])}',
                                              style: TextStyle(fontSize: 12),
                                            ),
                                          ],
                                        ),
                                        trailing: Icon(Icons.chevron_right, color: Colors.grey[400]),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fetches products and their barcodes from Firestore.
Future<List<Map<String, dynamic>>> fetchProductsReport([String? ownerId]) async {
  final firestore = FirebaseFirestore.instance;
  final productsSnap = await firestore.collection('products').get();
  final List<Map<String, dynamic>> report = [];

  for (final doc in productsSnap.docs) {
    final data = doc.data();
    final productIdField = data['productId'] ?? data['product_id'];
    final productIdentifier = (productIdField != null && productIdField.toString().isNotEmpty) ? productIdField.toString() : doc.id;

    final nama = data['name'] ?? data['nama'] ?? '';
    final brand = data['brand'] ?? '';
    final category = data['category'] ?? '';
    final price = data['price'] ?? data['harga'] ?? '';
    final supplierName = data['supplierName'] ?? data['supplier'] ?? '';
    final productionDate = _formatPossibleTimestamp(data['productionDate']);
    final expiredDate = _formatPossibleTimestamp(data['expiredDate']);

    // Try subcollection first
    List<Map<String, dynamic>> barcodes = [];
    try {
      final sub = await firestore.collection('products').doc(doc.id).collection('product_barcodes').get();
      if (sub.docs.isNotEmpty) {
        barcodes = sub.docs
            .where((d) => ownerId == null || ownerId.isEmpty || (d.data()['ownerId'] == ownerId))
            .map((d) {
          final ddata = d.data();
          return {
            'barcode': d.id,
            'scannedAt': ddata['scannedAt'],
          };
        }).toList();
      }
    } catch (_) {
      // ignore and try top-level collection below
    }

    // If no subcollection entries, try top-level collection with product_id
    if (barcodes.isEmpty) {
      try {
        Query<Map<String, dynamic>> q = firestore.collection('product_barcodes').where('productId', isEqualTo: productIdentifier);
        if (ownerId != null && ownerId.isNotEmpty) {
          q = q.where('ownerId', isEqualTo: ownerId);
        }
        QuerySnapshot<Map<String, dynamic>> top;
        try {
          top = await q.get();
        } catch (_) {
          q = firestore.collection('product_barcodes').where('product_id', isEqualTo: productIdentifier);
          if (ownerId != null && ownerId.isNotEmpty) {
            q = q.where('ownerId', isEqualTo: ownerId);
          }
          top = await q.get();
        }

        if (top.docs.isNotEmpty) {
          barcodes = top.docs.map((d) {
            final ddata = d.data();
            return {
              'barcode': d.id,
              'scannedAt': ddata['scannedAt'],
            };
          }).toList();
        }
      } catch (_) {
        // ignore
      }
    }

    report.add({
      'product_id': productIdentifier,
      'nama': nama,
      'brand': brand,
      'category': category,
      'price': price,
      'supplierName': supplierName,
      'productionDate': productionDate,
      'expiredDate': expiredDate,
      'barcodes': barcodes,
    });
  }

  return report;
}

/// Fetch products that are expired (expiry date before now).
Future<List<Map<String, dynamic>>> fetchExpiredProductsReport([String? ownerId]) async {
  final firestore = FirebaseFirestore.instance;
  final productsSnap = await firestore.collection('products').get();
  final List<Map<String, dynamic>> report = [];
  final now = DateTime.now();
  
  for (final doc in productsSnap.docs) {
    final data = doc.data();
    final owner = (data['ownerid'] ?? data['owner_id'] ?? data['ownerId'] ?? '').toString();
    if (ownerId != null && ownerId.isNotEmpty && owner != ownerId) continue;

    // try to find expiry value in various fields
    dynamic rawExpiredVal;
    final candidates = ['tanggal_kadaluarsa','exp_date','expiredDate','expired_date','expired_at','expired','tanggal_expired','expiredRaw'];
    for (final k in candidates) {
      if (data.containsKey(k) && data[k] != null && data[k].toString().isNotEmpty) {
        rawExpiredVal = data[k];
        break;
      }
    }

    DateTime? expDate = _parseExpiryValue(rawExpiredVal);
    if (expDate == null) {
      debugPrint('fetchExpiredProductsReport: product ${doc.id} has unparseable expiry: $rawExpiredVal');
    }

    if (expDate == null) continue; // no expiry info
    if (!expDate.isBefore(now)) continue; // not expired yet

    // gather barcodes (same logic as available report)
    final productIdField = data['productId'] ?? data['product_id'];
    final productIdentifier = (productIdField != null && productIdField.toString().isNotEmpty) ? productIdField.toString() : doc.id;

    List<Map<String, dynamic>> barcodes = [];
    try {
      final sub = await firestore.collection('products').doc(doc.id).collection('product_barcodes').get();
      if (sub.docs.isNotEmpty) {
        barcodes = sub.docs
            .where((d) => ownerId == null || ownerId.isEmpty || (d.data()['ownerId'] == ownerId))
            .map((d) {
          final ddata = d.data();
          return {
            'barcode': d.id,
            'scannedAt': ddata['scannedAt'],
          };
        }).toList();
      }
    } catch (_) {}

    if (barcodes.isEmpty) {
      try {
        Query<Map<String, dynamic>> q = firestore.collection('product_barcodes').where('productId', isEqualTo: productIdentifier);
        if (ownerId != null && ownerId.isNotEmpty) q = q.where('ownerId', isEqualTo: ownerId);
        QuerySnapshot<Map<String, dynamic>> top;
        try { top = await q.get(); }
        catch (_) {
          q = firestore.collection('product_barcodes').where('product_id', isEqualTo: productIdentifier);
          if (ownerId != null && ownerId.isNotEmpty) q = q.where('ownerId', isEqualTo: ownerId);
          top = await q.get();
        }
        if (top.docs.isNotEmpty) {
          barcodes = top.docs.map((d) => {'barcode': d.id, 'scannedAt': d.data()['scannedAt']}).toList();
        }
      } catch (_) {}
    }

    report.add({
      'product_id': productIdentifier,
      'nama': data['name'] ?? data['nama'] ?? '',
      'brand': data['brand'] ?? '',
      'category': data['category'] ?? '',
      'price': data['price'] ?? data['harga'] ?? '',
      'supplierName': data['supplierName'] ?? data['supplier'] ?? '',
      'productionDate': _formatPossibleTimestamp(data['productionDate']),
      'expiredDate': _formatPossibleTimestamp(expDate),
      'expiredRaw': rawExpiredVal?.toString() ?? '',
      'barcodes': barcodes,
    });
  }

  return report;
}

/// Fetch delivery orders via REST API (order_items + orders + customer)
Future<List<Map<String, dynamic>>> fetchDeliveryOrderReport([String? ownerId]) async {
  final api = DataService();
  try {
    debugPrint('=== fetchDeliveryOrderReport START ===');
    debugPrint('ownerId: $ownerId');

    // Fetch order_items for this owner
    dynamic oiRaw;
    List<dynamic> orderItemsList = [];

    // Try multiple owner-field variants
    final ownerFields = ['ownerid', 'ownerId', 'owner', 'owner_id'];
    for (final field in ownerFields) {
      try {
        debugPrint('Trying selectWhere(order_items, $field, $ownerId)...');
        oiRaw = await api.selectWhere(token, project, 'order_items', appid, field, ownerId ?? '');
        debugPrint('Response type: ${oiRaw.runtimeType}, value: $oiRaw');
        
        if (oiRaw != null) {
          // Parse the response
          if (oiRaw is String) {
            final parsed = jsonDecode(oiRaw);
            debugPrint('Parsed as: ${parsed.runtimeType}');
            if (parsed is List && parsed.isNotEmpty) {
              orderItemsList = parsed;
              debugPrint('✓ Got ${orderItemsList.length} order_items from list');
              break;
            } else if (parsed is Map && parsed['data'] is List && (parsed['data'] as List).isNotEmpty) {
              orderItemsList = parsed['data'];
              debugPrint('✓ Got ${orderItemsList.length} order_items from Map.data');
              break;
            }
          } else if (oiRaw is List && oiRaw.isNotEmpty) {
            orderItemsList = oiRaw;
            debugPrint('✓ Got ${orderItemsList.length} order_items directly as list');
            break;
          } else if (oiRaw is Map && oiRaw['data'] is List && (oiRaw['data'] as List).isNotEmpty) {
            orderItemsList = oiRaw['data'];
            debugPrint('✓ Got ${orderItemsList.length} order_items from direct Map.data');
            break;
          }
        }
      } catch (e) {
        debugPrint('✗ selectWhere order_items with field $field error: $e');
      }
    }

    debugPrint('After selectWhere attempts: ${orderItemsList.length} order_items');

    // If still empty, try selectAll and filter locally
    if (orderItemsList.isEmpty) {
      try {
        debugPrint('Trying selectAll(order_items)...');
        final allRaw = await api.selectAll(token, project, 'order_items', appid);
        debugPrint('selectAll response type: ${allRaw.runtimeType}');
        
        if (allRaw is String) {
          final parsed = jsonDecode(allRaw);
          if (parsed is List) orderItemsList = parsed;
          else if (parsed is Map && parsed['data'] is List) orderItemsList = parsed['data'];
        } else if (allRaw is List) orderItemsList = allRaw;
        else if (allRaw is Map && allRaw['data'] is List) orderItemsList = allRaw['data'];
        
        debugPrint('Got ${orderItemsList.length} total order_items');
      } catch (e) {
        debugPrint('✗ selectAll order_items error: $e');
      }

      // Filter by ownerId locally if needed
      if (orderItemsList.isNotEmpty && ownerId != null && ownerId.isNotEmpty) {
        debugPrint('Filtering ${orderItemsList.length} order_items by ownerId=$ownerId');
        orderItemsList = orderItemsList.where((raw) {
          if (raw is! Map) return false;
          final o = raw as Map<String, dynamic>;
          final ownerVal = (o['ownerid'] ?? o['ownerId'] ?? o['owner'] ?? o['owner_id'])?.toString() ?? '';
          return ownerVal == ownerId;
        }).toList();
        debugPrint('After filtering: ${orderItemsList.length} order_items');
      }
    }

    // Extract order IDs from order_items
    final orderIds = <String>{};
    for (final raw in orderItemsList) {
      if (raw is! Map) continue;
      final oid = raw['order_id'] ?? raw['orderId'] ?? raw['order'];
      if (oid != null) orderIds.add(oid.toString());
    }

    debugPrint('Extracted ${orderIds.length} unique order_ids: $orderIds');

    // Extract customer IDs and order data from order collection
    final orderMap = <String, Map<String, dynamic>>{};
    final customerIds = <String>{};
    
    debugPrint('Extracting customor_id from ${orderIds.length} order_ids...');
    
    // Fetch orders to get customor_id
    if (orderIds.isNotEmpty) {
      final ids = orderIds.toList();
      const batchSize = 50;
      
      for (var i = 0; i < ids.length; i += batchSize) {
        final batch = ids.sublist(i, (i + batchSize) > ids.length ? ids.length : i + batchSize);
        try {
          debugPrint('Fetching orders batch: $batch');
          final resp = await api.selectWhereIn(token, project, 'order', appid, 'order_id', batch.join(','));
          
          if (resp != null) {
            final raw = (resp is String) ? jsonDecode(resp) : resp;
            List<dynamic> ordersList = [];
            if (raw is List) ordersList = raw;
            else if (raw is Map && raw['data'] is List) ordersList = raw['data'];
            
            debugPrint('✓ Parsed ${ordersList.length} orders from batch');
            
            if (ordersList.isNotEmpty) {
              // Log first order to see all fields
              final firstOrder = ordersList[0];
              if (firstOrder is Map) {
                debugPrint('Sample order fields: ${firstOrder.keys.toList()}');
                debugPrint('Sample order data: $firstOrder');
              }
            }
            
            for (final o in ordersList) {
              if (o is Map) {
                final key = o['order_id']?.toString() ?? '';
                if (key.isNotEmpty) {
                  orderMap[key] = Map<String, dynamic>.from(o);
                  
                  // Extract customor_id (the typo field name in order collection)
                  final customorId = (o['customor_id'] ?? o['customor_id'] ?? o['customerId'])?.toString() ?? '';
                  debugPrint('✓ Order $key -> customor_id=$customorId');
                  
                  if (customorId.isNotEmpty) {
                    customerIds.add(customorId);
                  } else {
                    debugPrint('✗ Order $key has NO customor_id!');
                  }
                }
              }
            }
          }
        } catch (e) {
          debugPrint('✗ Orders batch error: $e');
        }
      }
    }
    
    debugPrint('Extracted ${customerIds.length} unique customor_ids: $customerIds');

    // Fetch customers by IDs
    final customerMap = <String, Map<String, dynamic>>{};
    if (customerIds.isNotEmpty) {
      final ids = customerIds.toList();
      const batchSize = 50;
      for (var i = 0; i < ids.length; i += batchSize) {
        final batch = ids.sublist(i, (i + batchSize) > ids.length ? ids.length : i + batchSize);
        try {
          debugPrint('Fetching customers batch with customor_id: $batch');
          final resp = await api.selectWhereIn(token, project, 'customer', appid, 'customor_id', batch.join(','));
          
          if (resp != null) {
            final raw = (resp is String) ? jsonDecode(resp) : resp;
            List<dynamic> custList = [];
            if (raw is List) custList = raw;
            else if (raw is Map && raw['data'] is List) custList = raw['data'];
            
            debugPrint('✓ Parsed ${custList.length} customers');
            
            if (custList.isNotEmpty) {
              // Log first customer to see all fields
              final firstCust = custList[0];
              if (firstCust is Map) {
                debugPrint('Sample customer fields: ${firstCust.keys.toList()}');
                debugPrint('Sample customer data: $firstCust');
              }
            }
            
            for (final c in custList) {
              if (c is Map) {
                final key = c['customor_id']?.toString() ?? c['id']?.toString() ?? '';
                if (key.isNotEmpty) {
                  customerMap[key] = Map<String, dynamic>.from(c);
                  debugPrint('✓ Customer $key loaded: nama_toko=${c['nama_toko']}, no_telepon=${c['no_telepon_customer']}');
                }
              }
            }
          }
        } catch (e) {
          debugPrint('✗ Customers batch error: $e');
        }
      }

      // If still empty, try fetching each customer individually with selectWhere
      if (customerMap.isEmpty && customerIds.isNotEmpty) {
        debugPrint('Batch returned empty, trying selectWhere for each customer...');
        for (final custId in customerIds) {
          try {
            debugPrint('Fetching individual customer: $custId');
            final resp = await api.selectWhere(token, project, 'customer', appid, 'customor_id', custId);
            debugPrint('Individual customer response: ${resp.runtimeType}');
            
            if (resp != null) {
              final raw = (resp is String) ? jsonDecode(resp) : resp;
              List<dynamic> custList = [];
              if (raw is List) custList = raw;
              else if (raw is Map && raw['data'] is List) custList = raw['data'];
              
              debugPrint('Parsed ${custList.length} customer records');
              
              for (final c in custList) {
                if (c is Map) {
                  final key = c['customor_id']?.toString() ?? c['id']?.toString() ?? '';
                  if (key.isNotEmpty) {
                    customerMap[key] = Map<String, dynamic>.from(c);
                    debugPrint('✓ selectWhere loaded customer $key: nama_toko=${c['nama_toko']}');
                  }
                }
              }
            }
          } catch (e) {
            debugPrint('✗ selectWhere customer error for $custId: $e');
          }
        }
      }
    }

    debugPrint('Loaded ${customerMap.length} customers into map');
    if (customerMap.isNotEmpty) {
      final firstCust = customerMap.values.first;
      debugPrint('Sample customer data keys: ${firstCust.keys.toList()}');
    }

    // Group order items by order ID
    final itemsByOrder = <String, List<Map<String, dynamic>>>{};
    for (final raw in orderItemsList) {
      if (raw is! Map) continue;
      final oid = (raw['order_id'] ?? raw['orderId'] ?? raw['order'])?.toString() ?? '';
      if (oid.isEmpty) continue;
      final item = {
        'id_produk': raw['product_id'] ?? raw['productId'] ?? raw['id_produk'] ?? '',
        'nama_barang': raw['product_name'] ?? raw['nama'] ?? raw['nama_barang'] ?? '',
        'jumlah': raw['jumlah_produk'] ?? raw['quantity'] ?? raw['jumlah'] ?? 1,
        'harga': raw['harga'] ?? raw['price'] ?? 0,
        'total_harga': raw['total_harga'] ?? raw['total_price'] ?? 0,
        'list_barcode': raw['list_barcode'] ?? raw['listBarcode'] ?? raw['barcodes'] ?? [],
      };
      itemsByOrder.putIfAbsent(oid, () => []).add(item);
    }

    debugPrint('Grouped ${itemsByOrder.length} order items');

    // Assemble final report
    final results = <Map<String, dynamic>>[];
    for (final oid in orderIds) {
      final orderData = orderMap[oid] ?? {};
      final custId = (orderData['customor_id'])?.toString() ?? '';
      final cust = customerMap[custId] ?? {};

      // Try to get tanggal_order and total from order_items if order collection is empty
      String tanggalOrder = orderData['tanggal_order'] ?? orderData['order_date'] ?? orderData['created_at'] ?? orderData['date'] ?? '';
      dynamic totalHarga = orderData['total_harga'] ?? orderData['total'] ?? orderData['total_price'] ?? orderData['grand_total'];
      
      // If still missing, try to get from order_items
      if (tanggalOrder.isEmpty || totalHarga == null) {
        final itemsForOrder = itemsByOrder[oid] ?? [];
        if (itemsForOrder.isNotEmpty) {
          final firstItem = itemsForOrder[0];
          if (tanggalOrder.isEmpty && firstItem['tanggal_order'] != null) {
            tanggalOrder = firstItem['tanggal_order'].toString();
          }
          // Calculate total from items if not found
          if (totalHarga == null || (totalHarga is num && totalHarga == 0)) {
            try {
              totalHarga = itemsForOrder.fold<num>(0, (sum, item) {
                final itemTotal = item['total_harga'];
                num val = 0;
                if (itemTotal is num) {
                  val = itemTotal;
                } else if (itemTotal is String) {
                  val = num.tryParse(itemTotal) ?? 0;
                }
                return sum + val;
              });
            } catch (e) {
              debugPrint('✗ Error calculating total from items: $e');
              totalHarga = 0;
            }
          }
        }
      }

      debugPrint('Building row: order_id=$oid, customor_id=$custId, cust_found=${cust.isNotEmpty}, nama_toko=${cust['nama_toko'] ?? 'EMPTY'}');

      results.add({
        'order_id': oid,
        'customor_id': custId,
        'nama_toko': cust['nama_toko'] ?? cust['store_name'] ?? cust['toko'] ?? cust['shop_name'] ?? cust['store'] ?? '',
        'nama_pemilik_toko': cust['nama_pemilik_toko'] ?? cust['owner_name'] ?? cust['pemilik'] ?? cust['pemilik_toko'] ?? cust['owner'] ?? cust['nama_pemilik'] ?? '',
        'no_telepon_customer': cust['no_telepon_customer'] ?? cust['no_telepon'] ?? cust['phone'] ?? cust['telepon'] ?? cust['phone_number'] ?? cust['no_hp'] ?? cust['nomor_telepon'] ?? '',
        'alamat_toko': cust['alamat_toko'] ?? cust['alamat'] ?? cust['address'] ?? cust['alamat_lengkap'] ?? '',
        'tanggal_order': tanggalOrder,
        'total_harga': totalHarga ?? 0,
        'items': itemsByOrder[oid] ?? [],
      });
    }

    debugPrint('=== fetchDeliveryOrderReport COMPLETE ===');
    debugPrint('Assembled ${results.length} final orders');
    
    return results;
  } catch (e) {
    debugPrint('=== fetchDeliveryOrderReport ERROR ===');
    debugPrint('final error: $e');
    return [];
  }
}

// Helper functions
DateTime? _parseExpiryValue(dynamic raw) {
  if (raw == null) return null;
  try {
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
    if (raw is double) return DateTime.fromMillisecondsSinceEpoch(raw.toInt());
    if (raw is String) {
      final s = raw.replaceAll('\u202F', ' ').trim();
      // Try ISO parse
      final iso = DateTime.tryParse(s);
      if (iso != null) return iso;

      // Common formats to try
      final formats = [
        'yyyy-MM-dd',
        'dd/MM/yyyy',
        'd MMMM y',
        'MMMM d, y',
        'MMMM d, y h:mm:ss a',
        'MMMM d, y h:mm a',
        'yyyy/MM/dd',
        'MM/dd/yyyy',
      ];

      for (final f in formats) {
        try {
          final dt = DateFormat(f, 'en_US').parse(s);
          return dt;
        } catch (_) {}
      }

      // Handle strings like "January 3, 2026 at 2:02:13 AM UTC+7"
      final parts = s.split(RegExp(r'\bat\b', caseSensitive: false));
      if (parts.isNotEmpty) {
        final datePart = parts[0].trim();
        var timePart = parts.length > 1 ? parts[1].trim() : '';
        final tzMatch = RegExp(r'UTC([+-]\d{1,2})').firstMatch(timePart);
        int tzOffset = 0;
        if (tzMatch != null) {
          tzOffset = int.tryParse(tzMatch.group(1) ?? '0') ?? 0;
          timePart = timePart.replaceAll(RegExp(r'UTC[+-]\d{1,2}'), '').trim();
        }
        final combined = '$datePart $timePart'.trim();
        try {
          final df = DateFormat('MMMM d, y h:mm:ss a', 'en_US');
          var parsed = df.parse(combined);
          if (tzMatch != null) parsed = parsed.subtract(Duration(hours: tzOffset)).toLocal();
          return parsed;
        } catch (_) {
          try {
            final df2 = DateFormat('MMMM d, y h:mm a', 'en_US');
            var parsed2 = df2.parse(combined);
            if (tzMatch != null) parsed2 = parsed2.subtract(Duration(hours: tzOffset)).toLocal();
            return parsed2;
          } catch (_) {}
        }
      }
    }
  } catch (_) {}
  return null;
}

String _formatPossibleTimestamp(dynamic v) {
  if (v == null) return '';
  if (v is Timestamp) return v.toDate().toIso8601String();
  if (v is DateTime) return v.toIso8601String();
  return v.toString();
}

String _formatDate(dynamic v) {
  if (v == null) return '';
  DateTime? dt;
  if (v is Timestamp) dt = v.toDate();
  else if (v is DateTime) dt = v;
  else {
    try {
      dt = DateTime.parse(v.toString());
    } catch (_) {
      return v.toString();
    }
  }
  return DateFormat('yyyy-MM-dd').format(dt);
}

String _formatPrice(dynamic v) {
  if (v == null) return '';
  try {
    if (v is num) {
      final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
      return fmt.format(v);
    }
    final parsed = double.tryParse(v.toString());
    if (parsed != null) {
      final fmt = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
      return fmt.format(parsed);
    }
    return v.toString();
  } catch (_) {
    return v.toString();
  }
}

/// Test function: Fetch and print customer collection data
Future<void> testFetchCustomers() async {
  final api = DataService();
  try {
    debugPrint('=== TEST: Fetching customers ===');
    
    // Try selectAll first
    final resp = await api.selectAll(token, project, 'customer', appid);
    debugPrint('selectAll response type: ${resp.runtimeType}');
    
    List<dynamic> custList = [];
    if (resp is String) {
      final parsed = jsonDecode(resp);
      if (parsed is List) custList = parsed;
      else if (parsed is Map && parsed['data'] is List) custList = parsed['data'];
    } else if (resp is List) {
      custList = resp;
    } else if (resp is Map && resp['data'] is List) {
      custList = resp['data'];
    }
    
    debugPrint('✓ Got ${custList.length} customers total');
    
    if (custList.isNotEmpty) {
      debugPrint('First 3 customers:');
      for (var i = 0; i < (custList.length > 3 ? 3 : custList.length); i++) {
        final c = custList[i];
        debugPrint('Customer $i:');
        debugPrint('  Fields: ${(c as Map).keys.toList()}');
        debugPrint('  Data: $c');
      }
    }
  } catch (e) {
    debugPrint('✗ Error testing customers: $e');
  }
}