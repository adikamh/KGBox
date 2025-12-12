import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:kg_dns/goclaud/product_model.dart';
import 'package:kg_dns/goclaud/resetapi.dart';
import 'package:kg_dns/goclaud/config.dart';
import 'EditProdukScreen.dart';

class DetailProdukScreen extends StatelessWidget {
  final Map<String, dynamic> product;

  const DetailProdukScreen({super.key, required this.product});

  String _fmtPrice(String? p) {
    if (p == null) return '-';
    final v = int.tryParse(p) ?? 0;
    return 'Rp ${v.toString().replaceAllMapped(RegExp(r"\B(?=(\d{3})+(?!\d))"), (m) => '.')}';
  }

  @override
  Widget build(BuildContext context) {
    final Map<String, dynamic>? raw = product['raw'] is Map
        ? Map<String, dynamic>.from(product['raw'])
        : null;

    final code = raw?['id_product'] ?? product['code'] ?? '-';
    final name = raw?['nama_product'] ?? product['name'] ?? '-';
    final category = raw?['kategori_product'] ?? product['category'] ?? '-';
    final brand = raw?['merek_product'] ?? product['brand'] ?? '-';
    final tanggal = raw?['tanggal_beli'] ?? product['last_updated'] ?? '-';
    final price = raw?['harga_product'] ?? product['price'] ?? '-';
    final stock = raw?['jumlah_produk'] ?? product['stock'] ?? '-';

    // Ambil ID dari data yang benar (gunakan pola yang sama dengan EditProdukScreen)
    final docId = _extractDocId(product);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        title: const Text(
          'Detail Produk',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        backgroundColor: Colors.blue[700],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// ======= HEADER =======
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.blue[700]!,
                    Colors.blue[900]!,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: Icon(
                      category.toLowerCase().contains('minuman') 
                          ? Icons.local_drink_rounded 
                          : Icons.restaurant_rounded,
                      size: 40,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Kode: $code',
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white,
                        letterSpacing: 0.5,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            /// ======= BODY DETAIL =======
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.attach_money_rounded,
                          iconColor: Colors.green[600]!,
                          title: 'Harga',
                          value: _fmtPrice(price),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildInfoCard(
                          icon: Icons.inventory_rounded,
                          iconColor: Colors.orange[600]!,
                          title: 'Stok',
                          value: stock.toString(),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Card(
                    elevation: 0,
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(color: Colors.grey[200]!),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.blue[50],
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.blue[700],
                                  size: 20,
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Informasi Produk',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _buildDetailRow(Icons.category_rounded, 'Kategori', category),
                          const Divider(height: 32),
                          _buildDetailRow(Icons.business_rounded, 'Merek', brand),
                          const Divider(height: 32),
                          _buildDetailRow(Icons.calendar_today_rounded, 'Tanggal Beli', tanggal.toString()),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  /// ===== ACTION BUTTONS =====
                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EditProdukScreen(
                                    product: ProductModel(
                                      id: docId,  // ID GoCloud
                                      id_product: code,
                                      nama_product: name,
                                      kategori_product: category,
                                      merek_product: brand,
                                      tanggal_beli: tanggal,
                                      harga_product: price,
                                      jumlah_produk: stock.toString(),
                                    ),
                                  ),
                                ),
                              ).then((updatedProduct) {
                                if (updatedProduct != null && updatedProduct is ProductModel) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Produk berhasil diperbarui'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                  Navigator.pop(context, updatedProduct);
                                }
                              });
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue[700],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.edit_rounded, size: 20),
                            label: const Text(
                              'Edit',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: SizedBox(
                          height: 52,
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              // Tampilkan dialog konfirmasi
                              bool confirmDelete = await showDialog(
                                context: context,
                                builder: (context) => AlertDialog(
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  title: const Text('Konfirmasi Hapus'),
                                  content: Text('Apakah Anda yakin ingin menghapus produk "$name"?'),
                                  actions: [
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(false),
                                      child: const Text('Batal'),
                                    ),
                                    TextButton(
                                      onPressed: () => Navigator.of(context).pop(true),
                                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                                      child: const Text('Hapus'),
                                    ),
                                  ],
                                ),
                              ) ?? false;

                              if (!confirmDelete) return;

                              // Tampilkan loading indicator
                              showDialog(
                                context: context,
                                barrierDismissible: false,
                                builder: (context) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              try {
                                final dataService = DataService();
                                
                                // Debug log
                                print('=== DEBUG DELETE PRODUCT ===');
                                print('Product Name: $name');
                                print('GoCloud ID: $docId');
                                print('Token: $token');
                                print('Project: $project');
                                print('Collection: $collection');
                                print('App ID: $appid');

                                if (docId.isEmpty) {
                                  Navigator.of(context).pop(); // Tutup loading
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('ID produk tidak ditemukan'),
                                      backgroundColor: Colors.red,
                                      duration: Duration(seconds: 2),
                                    ),
                                  );
                                  return;
                                }

                                // Panggil API untuk menghapus produk
                                bool isDeleted = false;
                                try {
                                  isDeleted = await dataService.removeId(
                                    token,
                                    project,
                                    collection,
                                    appid,
                                    docId,
                                  );
                                  print('removeId primary result: $isDeleted');
                                } catch (e) {
                                  print('removeId primary exception: $e');
                                }

                                // If primary removeId didn't work, try fallback by id_product (product code)
                                if (!isDeleted) {
                                  try {
                                    print('Trying removeWhere by id_product: $code');
                                    final byCode = await dataService.removeWhere(
                                      token,
                                      project,
                                      collection,
                                      appid,
                                      'id_product',
                                      code.toString(),
                                    );
                                    print('removeWhere(id_product) result: $byCode');
                                    isDeleted = isDeleted || byCode;
                                  } catch (e) {
                                    print('removeWhere(id_product) exception: $e');
                                  }
                                }

                                // Another fallback: try removeWhere by 'id' field (some APIs store document id in 'id')
                                if (!isDeleted && docId.isNotEmpty) {
                                  try {
                                    print('Trying removeWhere by id: $docId');
                                    final byIdField = await dataService.removeWhere(
                                      token,
                                      project,
                                      collection,
                                      appid,
                                      'id',
                                      docId,
                                    );
                                    print('removeWhere(id) result: $byIdField');
                                    isDeleted = isDeleted || byIdField;
                                  } catch (e) {
                                    print('removeWhere(id) exception: $e');
                                  }
                                }

                                // Tutup loading indicator
                                Navigator.of(context).pop();

                                if (isDeleted) {
                                  // Tampilkan pesan sukses
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Produk "$name" berhasil dihapus'),
                                      backgroundColor: Colors.green,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );

                                  // Kembali ke halaman sebelumnya dengan status sukses
                                  Navigator.of(context).pop(true);
                                } else {
                                  // Tampilkan pesan error dan suggest manual troubleshooting
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Gagal menghapus produk (coba periksa ID atau koneksi)'),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 3),
                                    ),
                                  );
                                  print('Delete failed for docId="$docId", code="$code"');
                                }
                                          } catch (e) {
                                            // Tutup loading indicator jika ada error
                                            Navigator.of(context).pop();

                                            // Perhatikan platform web (CORS) — tampilkan panduan jika dijalankan di browser
                                            if (kIsWeb) {
                                              const corsMsg = 'Permintaan diblokir oleh browser (CORS).\n\nSolusi: aktifkan CORS pada API (Access-Control-Allow-Origin), atau panggil API melalui backend/proxy.';
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                const SnackBar(
                                                  content: Text('Gagal: Permintaan diblokir oleh browser (CORS)'),
                                                  backgroundColor: Colors.red,
                                                  duration: Duration(seconds: 4),
                                                ),
                                              );

                                              showDialog(
                                                context: context,
                                                builder: (_) => AlertDialog(
                                                  title: const Text('CORS Terdeteksi'),
                                                  content: const Text(corsMsg),
                                                  actions: [
                                                    TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('OK')),
                                                  ],
                                                ),
                                              );
                                            } else {
                                              // Tampilkan pesan error umum untuk mobile/desktop
                                              ScaffoldMessenger.of(context).showSnackBar(
                                                SnackBar(
                                                  content: Text('Error: $e'),
                                                  backgroundColor: Colors.red,
                                                  duration: const Duration(seconds: 2),
                                                ),
                                              );
                                            }
                                          }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.red[600],
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            icon: const Icon(Icons.delete_rounded, size: 20),
                            label: const Text(
                              'Hapus',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Fungsi untuk mengekstrak ID GoCloud dari data produk
  String _extractDocId(Map<String, dynamic> product) {
    // Coba ambil ID dari berbagai lokasi yang mungkin
    String? docId;

    // 1. Coba dari 'id' field langsung
    if (product['id'] != null && product['id'].toString().isNotEmpty) {
      docId = product['id'].toString();
    }
    // 2. Coba dari '_id' field (format GoCloud)
    else if (product['_id'] != null) {
      if (product['_id'] is String) {
        docId = product['_id'].toString();
      } else if (product['_id'] is Map && product['_id'].containsKey('\$oid')) {
        docId = product['_id']['\$oid'].toString();
      }
    }
    // 3. Coba dari 'raw' data
    else if (product['raw'] is Map) {
      final raw = product['raw'] as Map<String, dynamic>;
      if (raw['_id'] != null) {
        if (raw['_id'] is String) {
          docId = raw['_id'].toString();
        } else if (raw['_id'] is Map && raw['_id'].containsKey('\$oid')) {
          docId = raw['_id']['\$oid'].toString();
        }
      } else if (raw['id'] != null && raw['id'].toString().isNotEmpty) {
        docId = raw['id'].toString();
      }
    }

    // Debug log untuk memeriksa ID yang ditemukan
    print('=== DOC ID EXTRACTION ===');
    print('Product data: $product');
    print('Extracted docId: $docId');
    
    return docId ?? '';
  }

  Widget _buildInfoCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
  }) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey[200]!),
      ),
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              style: TextStyle(
                fontSize: 13,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, size: 18, color: Colors.grey[700]),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}