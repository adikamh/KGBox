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
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Content Section
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // FORM DETAIL TOKO
                      _buildTokoForm(),
                      const SizedBox(height: 24),

                      // TOMBOL SCAN
                      _buildScanButton(),
                      const SizedBox(height: 12),
                      _buildSelectButton(),
                      const SizedBox(height: 24),

                      // LIST BARANG YANG SUDAH DI-SCAN
                      if (scannedProducts.isNotEmpty) ...[
                        _buildSummaryHeader(),
                        const SizedBox(height: 16),
                        _buildProductList(),
                        const SizedBox(height: 24),
                      ],

                      // TOMBOL SIMPAN
                      _buildSubmitButton(),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Loading Overlay
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      elevation: 0,
      flexibleSpace: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.blue[700]!, Colors.blue[500]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      foregroundColor: Colors.white,
      title: const Text(
        'Catat Barang Keluar',
        style: TextStyle(fontWeight: FontWeight.w600),
      ),
      centerTitle: true,
    );
  }

  Widget _buildSummaryHeader() {
    final formattedTotal = total.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.blue[100]!),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${scannedProducts.length} barang',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
          Text(
            'Total Rp $formattedTotal',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.blue[700],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTokoForm() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.store_rounded,
                  size: 20,
                  color: Colors.blue[700],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Detail Customer',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          _buildTextField(
            controller: namaTokoController,
            label: 'Nama Toko',
            hint: 'Contoh: Toko Sejahtera',
            icon: Icons.store,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: alamatTokoController,
            label: 'Alamat Toko',
            hint: 'Contoh: Jl. Merdeka No. 123',
            icon: Icons.location_on,
            maxLines: 2,
            keyboardType: TextInputType.streetAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: namaPemilikController,
            label: 'Nama Pemilik',
            hint: 'Contoh: Budi Santoso',
            icon: Icons.person,
            keyboardType: TextInputType.text,
          ),
          const SizedBox(height: 16),
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
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: Colors.grey[400]),
            prefixIcon: Icon(icon, color: Colors.blue[700], size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: Colors.blue[700]!,
                width: 2,
              ),
            ),
            filled: true,
            fillColor: Colors.grey[50],
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          style: TextStyle(color: Colors.grey[800]),
        ),
      ],
    );
  }

  Widget _buildScanButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onScanPressed,
        icon: const Icon(Icons.qr_code_2, size: 22),
        label: const Text(
          'Scan Barang',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue[700],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
    );
  }

  Widget _buildSelectButton() {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: onSelectProductPressed,
        icon: const Icon(Icons.list_alt, size: 22),
        label: const Text(
          'Pilih Produk',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.blue[700],
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          side: BorderSide(color: Colors.blue[700]!, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildProductList() {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: scannedProducts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Row(
        children: [
          // Icon
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.shopping_bag_rounded,
              color: Colors.blue[700],
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          // Product Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product['nama'] ?? 'Tanpa Nama',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                    color: Colors.grey[800],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'Rp ${hargaInt.toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')} × $jumlahInt = Rp ${(hargaInt * jumlahInt).toString().replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]}.')}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                if (product['id'] != null)
                  Text(
                    'ID: ${product['id']}',
                    style: TextStyle(
                      fontSize: 9,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          // Quantity Controls
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Row(
              children: [
                InkWell(
                  onTap: jumlahInt > 1
                      ? () => onQuantityChanged(index, jumlahInt - 1)
                      : null,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(6),
                        bottomLeft: Radius.circular(6),
                      ),
                    ),
                    child: Icon(Icons.remove, size: 11, color: Colors.red[600]),
                  ),
                ),
                SizedBox(
                  width: 30,
                  child: Center(
                    child: Text(
                      jumlahInt.toString(),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () => onQuantityChanged(index, jumlahInt + 1),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: Colors.green[50],
                      borderRadius: const BorderRadius.only(
                        topRight: Radius.circular(6),
                        bottomRight: Radius.circular(6),
                      ),
                    ),
                    child: Icon(Icons.add, size: 11, color: Colors.green[600]),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isLoading ? null : onSubmitPressed,
        icon: const Icon(Icons.check_rounded, size: 22),
        label: Text(
          isLoading ? 'Memproses...' : 'Simpan Pengiriman',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.green[600],
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
          disabledBackgroundColor: Colors.grey[400],
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
        elevation: 0,
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Scan Barang',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android_rounded),
            onPressed: onSwitchCamera,
            tooltip: 'Tukar Kamera',
          ),
          IconButton(
            icon: const Icon(Icons.flash_on_rounded),
            onPressed: onToggleTorch,
            tooltip: 'Flash',
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Scanner Camera
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

          // Scan Frame
          Container(
            width: 280,
            height: 220,
            decoration: BoxDecoration(
              border: Border.all(color: Colors.white, width: 3),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
                  blurRadius: 20,
                  spreadRadius: 10,
                ),
              ],
            ),
          ),

          // Animated Scan Line
          AnimatedBuilder(
            animation: scanLineAnim,
            builder: (_, __) {
              return Positioned(
                top: MediaQuery.of(context).size.height / 2 - 110 + (scanLineAnim.value * 220),
                child: Container(
                  width: 274,
                  height: 2,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.red.withOpacity(0),
                        Colors.red,
                        Colors.red.withOpacity(0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red,
                        blurRadius: 10,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                ),
              );
            },
          ),

          // Corner Indicators
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 110,
            left: MediaQuery.of(context).size.width / 2 - 140,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white, width: 3),
                  left: BorderSide(color: Colors.white, width: 3),
                ),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            top: MediaQuery.of(context).size.height / 2 - 110,
            right: MediaQuery.of(context).size.width / 2 - 140,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.white, width: 3),
                  right: BorderSide(color: Colors.white, width: 3),
                ),
                borderRadius: const BorderRadius.only(
                  topRight: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 2 - 110,
            left: MediaQuery.of(context).size.width / 2 - 140,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white, width: 3),
                  left: BorderSide(color: Colors.white, width: 3),
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: MediaQuery.of(context).size.height / 2 - 110,
            right: MediaQuery.of(context).size.width / 2 - 140,
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.white, width: 3),
                  right: BorderSide(color: Colors.white, width: 3),
                ),
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(12),
                ),
              ),
            ),
          ),

          // Info Section
          Positioned(
            bottom: 60,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.2),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        "Arahkan kamera ke barcode",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "$scannedProductsCount item terscan",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 13,
                        ),
                      ),
                    ],
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