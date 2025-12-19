import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class CatatBarangKeluarPage extends StatelessWidget {
  final TextEditingController namaTokoController;
  final TextEditingController alamatTokoController;
  final TextEditingController namaPemilikController;
  final TextEditingController noTeleponController;
  final List<Map<String, dynamic>> scannedProducts;
  final double total;
  final VoidCallback onScanPressed;
  final VoidCallback onSelectProductPressed;
  final VoidCallback onSubmitPressed;
  final Function(int, int) onQuantityChanged;
  final bool isLoading;

  const CatatBarangKeluarPage({
    super.key,
    required this.namaTokoController,
    required this.alamatTokoController,
    required this.namaPemilikController,
    required this.noTeleponController,
    required this.scannedProducts,
    required this.total,
    required this.onScanPressed,
    required this.onSelectProductPressed,
    required this.onSubmitPressed,
    required this.onQuantityChanged,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Catat Barang Keluar'),
        backgroundColor: const Color(0xFF2965C0),
        foregroundColor: Colors.white,
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // FORM DETAIL TOKO
                _buildTokoForm(),
                const SizedBox(height: 20),

                // TOMBOL SCAN
                _buildScanButton(),
                const SizedBox(height: 8),
                _buildSelectButton(),
                const SizedBox(height: 20),

                // LIST BARANG YANG SUDAH DI-SCAN
                if (scannedProducts.isNotEmpty) ...[
                  _buildSummaryCard(),
                  const SizedBox(height: 12),
                  _buildProductList(),
                  const SizedBox(height: 20),
                ],

                // TOMBOL SIMPAN
                _buildSubmitButton(),
                const SizedBox(height: 20),
              ],
            ),
          ),
          
          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF2965C0)),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTokoForm() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detail Customer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: namaTokoController,
            label: 'Nama Toko',
            hint: 'Contoh: Toko Sejahtera',
            icon: Icons.store,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: alamatTokoController,
            label: 'Alamat Toko',
            hint: 'Contoh: Jl. Merdeka No. 123',
            icon: Icons.location_on,
            maxLines: 2,
            keyboardType: TextInputType.streetAddress,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: namaPemilikController,
            label: 'Nama Pemilik',
            hint: 'Contoh: Budi Santoso',
            icon: Icons.person,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 12),
          _buildTextField(
            controller: noTeleponController,
            label: 'No Telepon',
            hint: 'Contoh: 081234567890',
            icon: Icons.phone,
            keyboardType: TextInputType.phone,
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey,
          ),
        ),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: const Color(0xFF2965C0)),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(
                color: Color(0xFF2965C0),
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey[50],
          ),
        ),
      ],
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onScanPressed,
        icon: const Icon(Icons.qr_code_2),
        label: const Text('Scan Barang'),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF2965C0),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onSelectProductPressed,
        icon: const Icon(Icons.list_alt),
        label: const Text('Pilih Produk'),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFF2965C0),
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryCard() {
    final formattedTotal = total.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFF2965C0).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF2965C0).withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${scannedProducts.length} barang',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2965C0),
            ),
          ),
          Text(
            'Total: Rp $formattedTotal',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2965C0),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: scannedProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final product = scannedProducts[index];
        return _buildScannedProductCard(index, product);
      },
    );
  }

  Widget _buildScannedProductCard(int index, Map<String, dynamic> product) {
    final harga = product['harga'] ?? 0;
    final jumlah = product['jumlah'] ?? 0;
    final hargaInt = harga is int ? harga : int.tryParse(harga.toString()) ?? 0;
    final jumlahInt = jumlah is int ? jumlah : int.tryParse(jumlah.toString()) ?? 0;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: const Color(0xFF2965C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.inventory_2,
              color: Color(0xFF2965C0),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['nama'] ?? 'Tanpa Nama',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${hargaInt.toStringAsFixed(0)} × $jumlahInt = Rp ${(hargaInt * jumlahInt).toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                if (product['id'] != null)
                  Text(
                    'ID: ${product['id']}',
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.grey,
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              InkWell(
                onTap: () => onQuantityChanged(index, jumlahInt - 1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.remove, size: 14, color: Colors.red),
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  jumlahInt.toString(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
              const SizedBox(width: 6),
              InkWell(
                onTap: () => onQuantityChanged(index, jumlahInt + 1),
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Icon(Icons.add, size: 14, color: Colors.green),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onSubmitPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              )
            : const Text(
                'Simpan Pengiriman',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }
}

// Scanner Page UI (Remains the same as before)
class ScannerPage extends StatelessWidget {
  final MobileScannerController controller;
  final Animation<double> scanLineAnim;
  final int scannedProductsCount;
  final Function(String) onBarcodeDetect;
  final VoidCallback onSwitchCamera;
  final VoidCallback onToggleTorch;

  const ScannerPage({
    super.key,
    required this.controller,
    required this.scanLineAnim,
    required this.scannedProductsCount,
    required this.onBarcodeDetect,
    required this.onSwitchCamera,
    required this.onToggleTorch,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Scan Barang', style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android),
            onPressed: onSwitchCamera,
          ),
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: onToggleTorch,
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Scanner
          MobileScanner(
            controller: controller,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isNotEmpty) {
                final raw = barcodes.first.rawValue;
                if (raw != null && raw.isNotEmpty) {
                  onBarcodeDetect(raw);
                }
              }
            },
          ),

          // BINGKAI SCAN
          Container(
            width: 280,
            height: 180,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(12),
            ),
          ),

          // ANIMASI GARIS MERAH
          AnimatedBuilder(
            animation: scanLineAnim,
            builder: (_, __) {
              return Positioned(
                top: MediaQuery.of(context).size.height / 2 - 90 + scanLineAnim.value,
                child: Container(
                  width: 260,
                  height: 2,
                  color: Colors.redAccent,
                ),
              );
            },
          ),

          // INFO TEXT
          Positioned(
            bottom: 120,
            child: Column(
              children: [
                Text(
                  "Arahkan kamera ke barcode",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "$scannedProductsCount item terscan",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.6),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}