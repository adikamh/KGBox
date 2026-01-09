import 'dart:convert';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/config.dart';
import '../services/restapi.dart';
import '../pages/catat_barang_keluar_page.dart';
import '../providers/auth_provider.dart';

class CatatBarangKeluarScreen extends StatefulWidget {
  const CatatBarangKeluarScreen({super.key});

  @override
  State<CatatBarangKeluarScreen> createState() => _CatatBarangKeluarScreenState();
}

class _CatatBarangKeluarScreenState extends State<CatatBarangKeluarScreen> {
  final TextEditingController _namaTokoController = TextEditingController();
  final TextEditingController _alamatTokoController = TextEditingController();
  final TextEditingController _namaPemilikController = TextEditingController();
  final TextEditingController _noTeleponController = TextEditingController();

  List<Map<String, dynamic>> _scannedProducts = [];
  List<Map<String, dynamic>> _allProducts = [];
  bool _isLoading = false;
  String ownerId = '';
  String staffId = '';

  @override
  void initState() {
    super.initState();
    _loadAllProducts();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Initialize ownerId and staffId from AuthProvider
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      ownerId = user?.ownerId ?? user?.id ?? '';
      staffId = user?.id ?? '';
    } catch (_) {}
  }

  Future<void> _loadAllProducts() async {
    try {
      final api = DataService();
      // Load products from the `product` collection
      final result = await api.selectAll(token, project, 'product', appid).timeout(const Duration(seconds: 15));
      debugPrint('selectAll product raw result: $result');

      final Map<String, dynamic> jsonResponse = json.decode(result);
      List<dynamic> data = jsonResponse['data'] ?? [];

      // If REST reports invalid collection or no data, fallback to Firestore `products` + `product_barcodes`
      if ((jsonResponse['status']?.toString() == '0' && jsonResponse['message']?.toString().toLowerCase().contains('not a valid collection') == true) || data.isEmpty) {
        debugPrint('REST selectAll failed or empty; falling back to Firestore products and product_barcodes');
        try {
          final firestore = FirebaseFirestore.instance;
          final prodSnap = await firestore.collection('products').get();
          final barcodeSnap = await firestore.collection('product_barcodes').get();

          debugPrint('Firestore products count=${prodSnap.size}, product_barcodes count=${barcodeSnap.size}');

          // build mapping productId -> list of barcodes
          final Map<String, List<String>> prodToBarcodes = {};
          for (final doc in barcodeSnap.docs) {
            final map = doc.data();
            final barcode = doc.id.toString();
            final mappedId = (map['productId'] ?? map['product_id'] ?? map['id_product'] ?? map['product'] ?? map['master_id'] ?? '').toString();
            if (mappedId.isNotEmpty) {
              prodToBarcodes.putIfAbsent(mappedId, () => []).add(barcode);
            } else if (map.containsKey('barcode')) {
              final mid = map['barcode'].toString();
              prodToBarcodes.putIfAbsent(mid, () => []).add(barcode);
            }
          }


          data = prodSnap.docs.map((d) => {...d.data(), '_docId': d.id}).toList();

          // debug sample (stringify values to avoid Timestamp encoding errors)
          for (var i = 0; i < min(5, prodSnap.docs.length); i++) {
            final m = prodSnap.docs[i].data().map((k, v) => MapEntry(k, v?.toString()));
            debugPrint('products sample[${i}]=${json.encode(m)}');
          }
          for (var i = 0; i < min(5, barcodeSnap.docs.length); i++) {
            final m = barcodeSnap.docs[i].data().map((k, v) => MapEntry(k, v?.toString()));
            debugPrint('product_barcodes sample[${i}]=${json.encode(m)} (id=${barcodeSnap.docs[i].id})');
          }

          // attach barcodes from mapping where possible
          for (final item in data) {
            final pid = (item['id_product'] ?? item['id'] ?? item['_id'] ?? item['_docId'] ?? '').toString();
            final barlist = prodToBarcodes[pid] ?? <String>[];
            if (barlist.isNotEmpty) {
              item['list_barcode'] = barlist;
            }
          }
        } catch (e) {
          debugPrint('Firestore fallback failed: $e');
        }
      }

      final mapped = data.map<Map<String, dynamic>>((p) {
        // normalize id: try several common fields
        final rawId = p['id_product'] ?? p['id'] ?? p['_id'] ?? p['_docId'] ?? '';
        final parsedId = rawId is Map ? (rawId['\$oid'] ?? rawId['oid'] ?? rawId.toString()) : rawId.toString();
        // Normalize barcode(s): single barcode field or list in `list_barcode`
        List<String> barcodes = [];
        final rawListBarcode = p['list_barcode'] ?? p['list_barcode_json'] ?? p['barcodes'];
        if (rawListBarcode != null) {
          if (rawListBarcode is List) {
            barcodes = rawListBarcode.map((e) => e.toString()).toList();
          } else if (rawListBarcode is String) {
            final s = rawListBarcode.trim();
            try {
              final parsed = json.decode(s);
              if (parsed is List) barcodes = parsed.map((e) => e.toString()).toList();
              else barcodes = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            } catch (_) {
              barcodes = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            }
          }
        }
        final barcodeField = p['barcode'] ?? p['kode'] ?? p['id_product'] ?? (barcodes.isNotEmpty ? barcodes.first : parsedId);
        final nama = p['nama_product'] ?? p['nama'] ?? p['name'] ?? 'Tidak ada nama';
        final kategori = p['kategori_product'] ?? p['kategori'] ?? 'Umum';
        final harga = int.tryParse(p['price']?.toString() ?? p['harga_product']?.toString() ?? p['harga']?.toString() ?? '0') ?? 0;
        final stok = int.tryParse(p['jumlah_produk']?.toString() ?? p['stok']?.toString() ?? '0') ?? 0;
        final productOwner = p['ownerId'] ?? p['ownerid'] ?? '';

        return {
          'id': parsedId,
          'id_product': p['id_product'] ?? parsedId,
          'barcode': barcodeField?.toString(),
          'barcodes': barcodes,
          'nama': nama,
          'kategori': kategori,
          'harga': harga,
          'stok': stok,
          'ownerId': productOwner,
          'ownerid': productOwner,
          'full': p,
        };
      }).toList();

      if (mounted) {
        setState(() {
          _allProducts = mapped;
        });
      }

      debugPrint('Loaded ${_allProducts.length} products');
    } catch (e) {
      debugPrint("Error loading products: $e");
    }
  }

  void openScanner(BuildContext context) {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Membuka scanner...'), duration: Duration(milliseconds: 500)),
      );
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (ctx) => ScannerScreen(
            allProducts: _allProducts,
            scannedProducts: _scannedProducts,
            ownerId: ownerId,
            onProductsChanged: (updatedProducts) {
              if (mounted) {
                setState(() {
                  _scannedProducts = updatedProducts;
                });
              }
            },
          ),
        ),
      ).catchError((e) {
        debugPrint('Navigator push error: $e');
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka scanner: $e')));
      });
    } catch (e) {
      debugPrint('openScanner exception: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal membuka scanner: $e')));
    }
  }

  double calculateTotal() {
    return _scannedProducts.fold<double>(
      0,
      (sum, p) {
        final harga = p['harga'] ?? 0;
        final jumlah = p['jumlah'] ?? 0;
        return sum + ((harga is int ? harga : int.tryParse(harga.toString()) ?? 0) *
                      (jumlah is int ? jumlah : int.tryParse(jumlah.toString()) ?? 0));
      },
    );
  }

  Future<void> _submitForm(BuildContext context) async {
    // Validasi input
    if (_namaTokoController.text.isEmpty ||
        _alamatTokoController.text.isEmpty ||
        _namaPemilikController.text.isEmpty ||
        _noTeleponController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Lengkapi semua field customer'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_scannedProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Minimal scan 1 barang'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Confirmation dialog with item summary before proceeding (this will reduce stock)
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final totalHarga = calculateTotal();
        String formatRp(num value) {
          final v = value.toInt().toString();
          return v.replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.');
        }

        return AlertDialog(
          title: const Text('Konfirmasi Pengiriman'),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Periksa daftar barang yang akan dikirim:'),
                const SizedBox(height: 12),
                Expanded(
                  child: ListView.separated(
                    itemCount: _scannedProducts.length,
                    separatorBuilder: (_, __) => const Divider(height: 8),
                    itemBuilder: (context, i) {
                      final p = _scannedProducts[i];
                      final nama = p['nama'] ?? 'Tidak ada nama';
                      final jumlah = (p['jumlah'] is int) ? p['jumlah'] as int : int.tryParse(p['jumlah']?.toString() ?? '0') ?? 0;
                      final harga = (p['harga'] is int) ? p['harga'] as int : int.tryParse(p['harga']?.toString() ?? '0') ?? 0;
                      final subtotal = harga * jumlah;
                      return Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(child: Text('$nama × $jumlah')),
                          Text('Rp ${formatRp(subtotal)}'),
                        ],
                      );
                    },
                  ),
                ),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('Rp ${formatRp(totalHarga)}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Batal')),
            ElevatedButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Ya, Simpan')),
          ],
        );
      },
    );

    if (confirmed != true) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final api = DataService();
      
      // 1. Generate Customer ID
      final customerId = 'CUST${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}';
      
      // 2. Simpan ke Customer
      // Build customer payload with exact field names
      final customerMap = {
        'ownerid': ownerId,
        'customer_id': customerId,
        'nama_toko': _namaTokoController.text.trim(),
        'nama_pemilik_toko': _namaPemilikController.text.trim(),
        'no_telepon_customer': _noTeleponController.text.trim(),
        'alamat_toko': _alamatTokoController.text.trim(),
      };
      // Print payload sent to gocloud for debugging
      debugPrint('Sending customer payload: ${json.encode(customerMap)}');

      // insert customer and validate response
      final customerResult = await api.insertOne(
        token,
        project,
        'customer',
        appid,
        customerMap,
      );
      debugPrint('insert customer result: $customerResult');
      try {
        if (customerResult == null) throw Exception('Empty response from insert customer');
        if (customerResult is Map) {
          final st = customerResult['status'];
          if (st != null && st.toString() != '1' && st != 1) throw Exception('insert customer failed: $customerResult');
        } else if (customerResult is String) {
          final low = customerResult.toLowerCase();
          if (low.contains('error') || low.contains('failed')) throw Exception('insert customer failed: $customerResult');
        }
      } catch (e) {
        debugPrint('Customer insert validation error: $e');
        throw e;
      }
      
      // 3. Generate Order ID
      final orderId = 'ORD${DateTime.now().millisecondsSinceEpoch}${Random().nextInt(1000)}';
      final totalHarga = calculateTotal();

      // Build id_product string as comma-separated product ids (optional)
      final productIds = _scannedProducts.map((p) => (p['id'] ?? p['id_product'] ?? '').toString()).where((s) => s.isNotEmpty).toSet().join(',');

      // 4. Simpan ke Order (match OrderModel fields)
      final orderMap = {
        'ownerid': ownerId,
        'id_product': productIds,
        'customor_id': customerId,
        'tanggal_order': DateTime.now().toIso8601String(),
        'total_harga': totalHarga.toString(),
        'id_staff': staffId,
        'order_id': orderId,
      };

      // Print payload sent to gocloud for debugging
      debugPrint('Sending order payload: ${json.encode(orderMap)}');

      final orderResult = await api.insertOne(
        token,
        project,
        'order',
        appid,
        orderMap,
      );
      debugPrint('insert order result: $orderResult');
      try {
        if (orderResult == null) throw Exception('Empty response from insert order');
        if (orderResult is Map) {
          final st = orderResult['status'];
          if (st != null && st.toString() != '1' && st != 1) throw Exception('insert order failed: $orderResult');
        } else if (orderResult is String) {
          final low = orderResult.toLowerCase();
          if (low.contains('error') || low.contains('failed')) throw Exception('insert order failed: $orderResult');
        }
      } catch (e) {
        debugPrint('Order insert validation error: $e');
        throw e;
      }
      
      // 5. Simpan ke Order Items
      for (final product in _scannedProducts) {
        final productId = product['id'] ?? '';
        final jumlah = product['jumlah'] ?? 1;
        final hargaSatuan = product['harga'] ?? 0;
        final productName = product['name'] ?? product['nama'] ?? '';
        
        final barcodeList = (product['scanned_barcodes'] is List) ? List<String>.from(product['scanned_barcodes']) : <String>[];
        final barcodeCount = barcodeList.isNotEmpty ? barcodeList.length : (jumlah is int ? jumlah : int.tryParse(jumlah.toString()) ?? 0);
        final unitPrice = (hargaSatuan is int) ? hargaSatuan : int.tryParse(hargaSatuan.toString()) ?? 0;
        final totalHargaItem = barcodeCount * unitPrice;
        
        // Format current date time for tanggal_order_items
        final now = DateTime.now();
        final tanggalOrderItems = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')} '
            '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}';

        final orderItemMap = {
          'ownerid': ownerId,
          'order_id': orderId,
          'id_product': productId,
          'jumlah_produk': barcodeCount.toString(),
          'list_barcode': json.encode(barcodeList),
          'harga': unitPrice.toString(),
          'total_harga': totalHargaItem.toString(),
          'tanggal_order_items': tanggalOrderItems,
          'nama_produk': productName,
        };

        // Print payload sent to gocloud for debugging
        debugPrint('Sending order_items payload: ${json.encode(orderItemMap)}');

        final orderItemResult = await api.insertOne(
          token,
          project,
          'order_items',
          appid,
          orderItemMap,
        );
        debugPrint('insert order_item result: $orderItemResult');
        try {
          if (orderItemResult == null) throw Exception('Empty response from insert order_items');
          if (orderItemResult is Map) {
            final st = orderItemResult['status'];
            if (st != null && st.toString() != '1' && st != 1) throw Exception('insert order_items failed: $orderItemResult');
          } else if (orderItemResult is String) {
            final low = orderItemResult.toLowerCase();
            if (low.contains('error') || low.contains('failed')) throw Exception('insert order_items failed: $orderItemResult');
          }
        } catch (e) {
          debugPrint('OrderItems insert validation error: $e');
          throw e;
        }
        
        // 6. Keep order_items record (store barcodes), then remove mapping docs in Firestore and update stock
        final removedBarcodes = (product['scanned_barcodes'] is List)
            ? List<String>.from(product['scanned_barcodes'])
            : <String>[];

        // Delete mapping documents in Firestore so barcode is no longer mapped (reduces available stock)
        try {
          final firestore = FirebaseFirestore.instance;
          for (final b in removedBarcodes) {
            final code = b.toString().trim();
            if (code.isEmpty) continue;
            try {
              // attempt delete by doc id first
              final ref1 = firestore.collection('product_barcodes').doc(code);
              final snap1 = await ref1.get();
              if (snap1.exists) {
                await ref1.delete();
                debugPrint('Deleted mapping doc product_barcodes/$code (by id)');
                continue;
              }

              final ref2 = firestore.collection('product_barcodes').doc(code);
              final snap2 = await ref2.get();
              if (snap2.exists) {
                await ref2.delete();
                debugPrint('Deleted mapping doc product_barcodes/$code (by id)');
                continue;
              }

              // If doc id is not the barcode, try querying by fields like `barcode` or `code`
              final q1 = await firestore.collection('product_barcodes').where('barcode', isEqualTo: code).get();
              for (final doc in q1.docs) {
                await doc.reference.delete();
                debugPrint('Deleted product_barcodes/${doc.id} (by field barcode)');
              }

              final q2 = await firestore.collection('product_barcodes').where('product', isEqualTo: code).get();
              for (final doc in q2.docs) {
                await doc.reference.delete();
                debugPrint('Deleted product_barcodes/${doc.id} (by field product)');
              }

              // Some mappings might store code in field `code` — try common alternative
              final q3 = await firestore.collection('product_barcodes').where('code', isEqualTo: code).get();
              for (final doc in q3.docs) {
                await doc.reference.delete();
                debugPrint('Deleted product_barcodes/${doc.id} (by field code)');
              }
            } catch (e) {
              debugPrint('Failed deleting mapping for $b: $e');
            }
          }
        } catch (e) {
          debugPrint('Error deleting mapping docs: $e');
        }

        // Finally update product stock and barcode list on server/Firestore
        await _updateProductStock(productId, jumlah, removedBarcodes);
      }
      
      // Success
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Pengiriman ke ${_namaTokoController.text} dengan ${_scannedProducts.length} item berhasil disimpan',
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );

      // Reset form
      _resetForm();
      
    } catch (e) {
      debugPrint("Error submitting form: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Gagal menyimpan: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 3),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _updateProductStock(String productId, int jumlahKeluar, [List<String>? removedBarcodes]) async {
    try {
      final api = DataService();

      // Prefer fetching by id if possible
      dynamic res;
      try {
        res = await api.selectId(token, project, 'product', appid, productId).timeout(const Duration(seconds: 15));
      } catch (_) {
        // fallback to selectAll and search
        res = await api.selectAll(token, project, 'product', appid).timeout(const Duration(seconds: 15));
      }

      if (res == null) return;

      Map<String, dynamic> respMap;
      try {
        respMap = (res is String) ? json.decode(res) as Map<String, dynamic> : (res as Map<String, dynamic>);
      } catch (e) {
        debugPrint('Failed to parse product select response: $e');
        return;
      }

      final List<dynamic> data = respMap['data'] ?? [];
      if (data.isEmpty) return;

      // If selectId returned a single item, it will be in data[0]
      final product = data.firstWhere((p) {
        final idProduct = (p['id_product'] ?? p['id'] ?? p['_id'] ?? '').toString();
        return idProduct == productId || (p['_id'] ?? p['id'] ?? '').toString() == productId;
      }, orElse: () => data[0]);

      if (product == null) return;

      // Normalize existing barcode list which might be stored as JSON string or a list
      final rawList = product['list_barcode'] ?? product['list_barcode_json'] ?? product['barcode_list'] ?? product['barcode'] ?? product['kode'];
      List<String> barcodes = [];
      if (rawList is List) {
        barcodes = rawList.map((e) => e.toString()).toList();
      } else if (rawList is String) {
        final s = rawList.trim();
        // Try JSON decode first
        try {
          final parsed = json.decode(s);
          if (parsed is List) barcodes = parsed.map((e) => e.toString()).toList();
          else barcodes = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        } catch (_) {
          barcodes = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
        }
      }

      // Normalize and remove scanned barcodes (if provided)
      final List<String> removed = (removedBarcodes ?? []).map((e) => e.toString().trim()).where((s) => s.isNotEmpty).toList();
      if (removed.isNotEmpty) {
        for (final b in removed) {
          barcodes.removeWhere((x) => x.toString().trim() == b);
        }
      }

      // Compute new stock from remaining barcodes (fallback to jumlah_produk if absent)
      final intFromField = int.tryParse(product['jumlah_produk']?.toString() ?? '') ?? barcodes.length;
      final newStock = barcodes.isNotEmpty ? barcodes.length : (intFromField - jumlahKeluar).clamp(0, 1 << 30);

      final idToUpdate = (product['_id'] ?? product['id'] ?? product['id_product'] ?? '').toString();
      final updateMap = <String, dynamic>{
        'jumlah_produk': newStock.toString(),
        'list_barcode': json.encode(barcodes),
      };

      // First, attempt to update Firestore directly to remove scanned barcodes and set new stock
      try {
        final firestore = FirebaseFirestore.instance;
        DocumentReference<Map<String, dynamic>>? docRef;
        DocumentSnapshot<Map<String, dynamic>>? snap;

        // Try productId as doc id in common collections
        try {
          docRef = firestore.collection('products').doc(productId);
          snap = await docRef.get();
          if (!snap.exists) {
            docRef = firestore.collection('product').doc(productId);
            snap = await docRef.get();
          }
        } catch (_) {
          snap = null;
        }

        // If not found, try idToUpdate as fallback doc id
        if ((snap == null || !snap.exists) && idToUpdate.isNotEmpty) {
          try {
            docRef = firestore.collection('products').doc(idToUpdate);
            snap = await docRef.get();
            if (!snap.exists) {
              docRef = firestore.collection('product').doc(idToUpdate);
              snap = await docRef.get();
            }
          } catch (_) {
            snap = null;
          }
        }

        if (snap != null && snap.exists && docRef != null) {
          final data = snap.data() ?? {};
          final rawListFs = data['list_barcode'] ?? data['barcodes'] ?? data['barcode'] ?? data['list_barcode_json'];

          if (rawListFs is List) {
            // Read-modify-write: build a normalized list, remove scanned barcodes, then write back
            List<String> fsBarcodes = rawListFs.map((e) => e.toString()).toList();
            debugPrint('Firestore before update (list_barcode): ${fsBarcodes}');
            if (removed.isNotEmpty) {
              fsBarcodes.removeWhere((x) => removed.contains(x.toString().trim()));
            }
            debugPrint('Firestore after update (list_barcode): ${fsBarcodes}');
            await docRef.update({'list_barcode': fsBarcodes, 'jumlah_produk': newStock});
          } else if (rawListFs is String) {
            // Parse string list, remove items, and write back as JSON string
            List<String> fsBarcodes = [];
            final s = rawListFs.toString();
            try {
              final parsed = json.decode(s);
              if (parsed is List) fsBarcodes = parsed.map((e) => e.toString()).toList();
              else fsBarcodes = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            } catch (_) {
              fsBarcodes = s.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            }

            if (removed.isNotEmpty) {
              for (final b in removed) {
                fsBarcodes.removeWhere((x) => x.toString().trim() == b);
              }
            }

            await docRef.update({'list_barcode': json.encode(fsBarcodes), 'jumlah_produk': newStock.toString()});
          } else {
            // No barcode array present; just update jumlah_produk
            await docRef.update({'jumlah_produk': newStock});
          }
        }
      } catch (e) {
        debugPrint('Failed Firestore update: $e');
      }

      // Try updateOne (update by id with map) to keep REST in sync
      try {
        await api.updateOne(token, project, 'product', appid, idToUpdate, updateMap);
      } catch (e) {
        // fallback to updating fields individually
        try {
          await api.updateId('jumlah_produk', newStock.toString(), token, project, 'product', appid, idToUpdate);
          await api.updateId('list_barcode', json.encode(barcodes), token, project, 'product', appid, idToUpdate);
        } catch (e2) {
          debugPrint('Failed fallback updates: $e2');
        }
      }
    } catch (e) {
      debugPrint("Error updating stock: $e");
    }
  }

  void _resetForm() {
    _namaTokoController.clear();
    _alamatTokoController.clear();
    _namaPemilikController.clear();
    _noTeleponController.clear();
    setState(() {
      _scannedProducts = [];
    });
  }

  void updateProductQuantity(int index, int newQuantity) {
    if (newQuantity > 0) {
      setState(() {
        _scannedProducts[index]['jumlah'] = newQuantity;
      });
    } else {
      setState(() {
        _scannedProducts.removeAt(index);
      });
    }
  }

  @override
  void dispose() {
    _namaTokoController.dispose();
    _alamatTokoController.dispose();
    _namaPemilikController.dispose();
    _noTeleponController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CatatBarangKeluarPage(
      namaTokoController: _namaTokoController,
      alamatTokoController: _alamatTokoController,
      namaPemilikController: _namaPemilikController,
      noTeleponController: _noTeleponController,
      scannedProducts: _scannedProducts,
      total: calculateTotal(),
      onScanPressed: () => openScanner(context),
        onSelectProductPressed: () => openProductPicker(context),
      onSubmitPressed: () => _submitForm(context),
      onQuantityChanged: updateProductQuantity,
      isLoading: _isLoading,
    );
  }

  Future<void> openProductPicker(BuildContext context) async {
    // Ensure product cache is loaded before showing picker
    if (_allProducts.isEmpty) {
      try {
        await _loadAllProducts();
      } catch (e) {
        debugPrint('openProductPicker: _loadAllProducts threw: $e');
      }
    }

    if (_allProducts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Gagal memuat produk. Coba lagi.'),
          action: SnackBarAction(
            label: 'Muat Ulang',
            onPressed: () async {
              try {
                await _loadAllProducts();
                if (mounted) setState(() {});
                if (_allProducts.isNotEmpty) openProductPicker(context);
              } catch (e) {
                debugPrint('Retry loadAllProducts failed: $e');
              }
            },
          ),
        ),
      );
      return;
    }

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.7,
          minChildSize: 0.4,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, controller) {
            // Build a flattened list of barcode entries: one entry per barcode
            final List<Map<String, dynamic>> barcodeEntries = [];
            for (final p in _allProducts) {
              // Filter by owner - skip if product has owner and it doesn't match
              final productOwner = (p['ownerId'] ?? p['ownerid'] ?? '').toString().trim();
              if (productOwner.isNotEmpty && productOwner != ownerId) {
                debugPrint('Skipping product (owner mismatch): owner=$productOwner, current=$ownerId');
                continue;
              }
              
              final idProd = (p['id'] ?? p['id_product'] ?? '').toString();
              final nama = p['nama']?.toString() ?? 'Tanpa Nama';
              final stok = p['stok'] is int ? p['stok'] as int : int.tryParse(p['stok']?.toString() ?? '0') ?? 0;
              final harga = p['harga'] ?? 0;

              final List<String> barcodes = [];
              try {
                if (p['barcodes'] is List) barcodes.addAll(List<String>.from(p['barcodes'].map((e) => e.toString())));
                else if (p['barcode'] != null) barcodes.add(p['barcode'].toString());
              } catch (_) {}

              if (barcodes.isEmpty) {
                // still add one entry with fallback barcode equal to product id
                barcodeEntries.add({
                  'productId': idProd,
                  'nama': nama,
                  'barcode': (p['barcode'] ?? idProd).toString(),
                  'stok': stok,
                  'harga': harga,
                });
              } else {
                for (final b in barcodes) {
                  barcodeEntries.add({
                    'productId': idProd,
                    'nama': nama,
                    'barcode': b.toString(),
                    'stok': stok,
                    'harga': harga,
                  });
                }
              }
            }

            // preserve selected barcodes across rebuilds of the inner StatefulBuilder
            final Map<String, bool> selectedBarcodes = {};

            return StatefulBuilder(
              builder: (context, setModalState) {
                Widget buildBarcodeItem(int index) {
                  final e = barcodeEntries[index];
                  final barcode = e['barcode']?.toString() ?? '';
                  final nama = e['nama']?.toString() ?? 'Tanpa Nama';
                  final harga = e['harga'] ?? 0;

                  final isChecked = selectedBarcodes[barcode] == true;

                  return CheckboxListTile(
                    value: isChecked,
                    onChanged: (v) => setModalState(() => selectedBarcodes[barcode] = v == true),
                    title: Text(nama),
                    subtitle: Text('Barcode: $barcode • Rp ${harga.toString()}'),
                    controlAffinity: ListTileControlAffinity.leading,
                  );
                }

                if (barcodeEntries.isEmpty) {
                  return Center(child: Padding(padding: const EdgeInsets.all(16.0), child: Text('Tidak ada data barcode')));
                }

                return Container(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    children: [
                      Container(
                        height: 6,
                        width: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text('Pilih Produk Manual', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 12),
                      Expanded(
                        child: ListView.separated(
                          controller: controller,
                          itemCount: barcodeEntries.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, index) => buildBarcodeItem(index),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Tutup'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: () {
                                // Collect selected barcodes grouped by productId
                                final Map<String, List<String>> grouped = {};
                                selectedBarcodes.forEach((barcode, sel) {
                                  if (sel != true) return;
                                  final entry = barcodeEntries.firstWhere((e) => (e['barcode']?.toString() ?? '') == barcode, orElse: () => {});
                                  if (entry.isEmpty) return;
                                  final pid = (entry['productId'] ?? '').toString();
                                  grouped.putIfAbsent(pid, () => []).add(barcode);
                                });

                                // Add grouped selections into _scannedProducts
                                setState(() {
                                  grouped.forEach((pid, barlist) {
                                    if (pid.isEmpty) return;
                                    final prod = _allProducts.firstWhere((p) => (p['id']?.toString() ?? p['id_product']?.toString() ?? '') == pid, orElse: () => {});
                                    if (prod.isEmpty) return;
                                    final existingIndex = _scannedProducts.indexWhere((e) => (e['id'] ?? e['id_product'])?.toString() == pid);
                                    if (existingIndex >= 0) {
                                      final current = (_scannedProducts[existingIndex]['jumlah'] is int)
                                          ? _scannedProducts[existingIndex]['jumlah'] as int
                                          : int.tryParse(_scannedProducts[existingIndex]['jumlah']?.toString() ?? '0') ?? 0;
                                      _scannedProducts[existingIndex]['jumlah'] = current + barlist.length;
                                      final list = ( _scannedProducts[existingIndex]['scanned_barcodes'] as List?) ?? <String>[];
                                      list.addAll(barlist);
                                      _scannedProducts[existingIndex]['scanned_barcodes'] = list;
                                    } else {
                                      _scannedProducts.add({
                                        'id': pid,
                                        'nama': prod['nama'],
                                        'kategori': prod['kategori'],
                                        'harga': prod['harga'],
                                        'stok': prod['stok'],
                                        'full': prod['full'] ?? prod,
                                        'jumlah': barlist.length,
                                        'scanned_barcodes': barlist,
                                      });
                                    }
                                });
                                });

                                Navigator.pop(context);
                              },
                              child: const Text('Tambahkan Terpilih'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }
}

// Scanner Screen Logic
class ScannerScreen extends StatefulWidget {
  final List<Map<String, dynamic>> allProducts;
  final List<Map<String, dynamic>> scannedProducts;
  final String ownerId;
  final Function(List<Map<String, dynamic>>) onProductsChanged;

  const ScannerScreen({
    required this.allProducts,
    required this.scannedProducts,
    required this.ownerId,
    required this.onProductsChanged,
    super.key,
  });

  @override
  State<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> 
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();
  bool _isProcessing = false;
  String? _lastScannedCode;

  late AnimationController _animController;
  late Animation<double> _scanLineAnim;
  // Buffer for scanned barcodes to be processed later
  final List<String> _pendingBarcodes = [];

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 180).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  void onBarcodeDetect(String barcode) async {
    final code = barcode.trim();
    debugPrint('Scanner: scanned code="$code"');
    if (code.isEmpty) return;
    if (_isProcessing) return;
    if (_lastScannedCode == code) return;

    _lastScannedCode = code;
    _isProcessing = true;

    // Buffer mode: collect barcodes first, resolve later when user taps Process
    if (!_pendingBarcodes.contains(code)) {
      _pendingBarcodes.add(code);
      debugPrint('Buffered barcode: $code (pending=${_pendingBarcodes.length})');
      HapticFeedback.mediumImpact();
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Barcode ditambahkan ke buffer (${_pendingBarcodes.length})')));
    } else {
      HapticFeedback.vibrate();
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Barcode sudah ada di buffer')));
    }

    // allow next scan shortly
    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) {
        setState(() {
          _lastScannedCode = null;
          _isProcessing = false;
        });
      }
    });

    return;

        // Cari produk berdasarkan berbagai kemungkinan field (id_product, _id, id, barcode, kode, nama)
  }

  void switchCamera() {
    controller.switchCamera();
  }

  void toggleTorch() {
    controller.toggleTorch();
  }

  Future<void> _processPendingBarcodes() async {
    if (_pendingBarcodes.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tidak ada barcode di buffer')));
      return;
    }

    final Map<String, List<String>> mapped = {};
    final List<String> unmapped = [];

    // Resolve productId for each barcode via Firestore mapping
    for (final code in List<String>.from(_pendingBarcodes)) {
      try {
        final doc = await FirebaseFirestore.instance.collection('product_barcodes').doc(code).get();
        if (doc.exists) {
          final m = doc.data() ?? {};
          final mappedId = (m['productId'] ?? m['product_id'] ?? m['id_product'] ?? m['master_id'] ?? m['id'] ?? '').toString();
          if (mappedId.isNotEmpty) {
            mapped.putIfAbsent(mappedId, () => []).add(code);
            continue;
          }
        }
        unmapped.add(code);
      } catch (e) {
        unmapped.add(code);
      }
    }

    final api = DataService();

    // For each mapped productId, fetch master and add grouped product
    for (final entry in mapped.entries) {
      final mappedId = entry.key;
      final codes = entry.value;

      Map<String, dynamic>? pm;
      // try local cache
      final local = widget.allProducts.firstWhere((p) {
        final pid = (p['id'] ?? p['id_product'] ?? p['full']?['_id'] ?? '').toString();
        final pidNorm = pid.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
        final mappedNorm = mappedId.replaceAll(RegExp(r'[^0-9a-zA-Z]'), '').toLowerCase();
        return pid == mappedId || pidNorm == mappedNorm;
      }, orElse: () => <String, dynamic>{});

      if (local.isNotEmpty) {
        pm = local['full'] as Map<String, dynamic>? ?? local;
      }

      if (pm == null) {
        // try REST
        try {
          final selRes = await api.selectWhere(token, project, 'product', appid, 'id_product', mappedId).timeout(const Duration(seconds: 10));
          if (selRes != null) {
            final Map<String, dynamic> parsed = (selRes is String) ? json.decode(selRes) as Map<String, dynamic> : (selRes as Map<String, dynamic>);
            final List<dynamic> d = parsed['data'] ?? [];
            if (d.isNotEmpty) pm = d[0] as Map<String, dynamic>;
          }
        } catch (_) {}
      }

      if (pm == null) {
        // try Firestore products collection by doc id
        try {
          final doc = await FirebaseFirestore.instance.collection('products').doc(mappedId).get();
          if (doc.exists) pm = doc.data();
        } catch (_) {}
      }

      if (pm == null) {
        // try fallback collection 'product'
        try {
          final doc = await FirebaseFirestore.instance.collection('product').doc(mappedId).get();
          if (doc.exists) pm = doc.data();
        } catch (_) {}
      }

      if (pm != null) {
        // normalize
        List<String> barcodes = [];
        final rawListBarcode = pm['list_barcode'] ?? pm['list_barcode_json'] ?? pm['barcodes'] ?? pm['barcode'];
        if (rawListBarcode != null) {
          if (rawListBarcode is List) barcodes = rawListBarcode.map((e) => e.toString()).toList();
          else if (rawListBarcode is String) {
            try {
              final parsed = json.decode(rawListBarcode);
              if (parsed is List) barcodes = parsed.map((e) => e.toString()).toList();
              else barcodes = rawListBarcode.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            } catch (_) {
              barcodes = rawListBarcode.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
            }
          }
        }

        final parsedId = (pm['productId'] ?? pm['id_product'] ?? pm['id'] ?? pm['_id'] ?? mappedId).toString();
        final nama = pm['nama_product'] ?? pm['nama'] ?? pm['name'] ?? pm['title'] ?? 'Tidak ada nama';
        final kategori = pm['category'] ?? pm['kategori_product'] ?? pm['kategori'] ?? 'Umum';
        final harga = int.tryParse(pm['price']?.toString() ?? pm['harga_product']?.toString() ?? pm['harga']?.toString() ?? '0') ?? 0;
        final stok = int.tryParse(pm['jumlah_produk']?.toString() ?? pm['stok']?.toString() ?? '0') ?? 0;

        final masterObj = {
          'id': parsedId,
          'id_product': pm['id_product'] ?? parsedId,
          'barcode': pm['barcode'] ?? (barcodes.isNotEmpty ? barcodes.first : parsedId),
          'barcodes': barcodes,
          'nama': nama,
          'kategori': kategori,
          'harga': harga,
          'stok': stok,
          'full': pm,
        };

        // add or update scannedProducts
        setState(() {
          final existingIndex = widget.scannedProducts.indexWhere((p) => (p['id'] ?? p['id_product'])?.toString() == parsedId);
          if (existingIndex >= 0) {
            final current = (widget.scannedProducts[existingIndex]['jumlah'] ?? 0) as int;
            widget.scannedProducts[existingIndex]['jumlah'] = current + codes.length;
            final list = (widget.scannedProducts[existingIndex]['scanned_barcodes'] as List?) ?? <String>[];
            list.addAll(codes);
            widget.scannedProducts[existingIndex]['scanned_barcodes'] = list;
          } else {
            widget.scannedProducts.add({
              ...masterObj,
              'jumlah': codes.length,
              'scanned_barcodes': codes,
            });
          }
        });
      } else {
        // mark these codes as unmapped
        unmapped.addAll(codes);
      }
    }

    // Clear processed barcodes
    _pendingBarcodes.clear();
    widget.onProductsChanged(List.from(widget.scannedProducts));

    if (unmapped.isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Beberapa barcode belum dipetakan: ${unmapped.take(5).join(", ")}')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Semua barcode diproses')));
    }
  }

  @override
  void dispose() {
    controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ScannerPage(
          controller: controller,
          scanLineAnim: _scanLineAnim,
          scannedProductsCount: widget.scannedProducts.length,
          onBarcodeDetect: onBarcodeDetect,
          onSwitchCamera: switchCamera,
          onToggleTorch: toggleTorch,
        ),
        Positioned(
          bottom: 24,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              FloatingActionButton.small(
                heroTag: 'process_pending',
                onPressed: _processPendingBarcodes,
                tooltip: 'Proses (${_pendingBarcodes.length})',
                child: const Icon(Icons.play_arrow),
              ),
              const SizedBox(height: 8),
              FloatingActionButton.small(
                heroTag: 'view_pending',
                onPressed: () {
                  showDialog<void>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Pending Barcodes'),
                      content: SizedBox(
                        width: double.maxFinite,
                        child: SingleChildScrollView(
                          child: Text(_pendingBarcodes.isNotEmpty ? _pendingBarcodes.join('\n') : '(kosong)'),
                        ),
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Tutup')),
                      ],
                    ),
                  );
                },
                tooltip: 'Lihat (${_pendingBarcodes.length})',
                child: const Icon(Icons.list),
              ),
            ],
          ),
        ),
      ],
    );
  }
}