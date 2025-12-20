// lib/pages/barcode_scanner_page.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../screens/barcode_scanner_screen.dart';
// ignore: unused_import
import 'tambah_product_page.dart';

class BarcodeScannerPage extends StatefulWidget {
  final String userRole;
  
  const BarcodeScannerPage({
    super.key,
    required this.userRole,
  });

  @override
  State<BarcodeScannerPage> createState() => _BarcodeScannerPageState();
}

class _BarcodeScannerPageState extends State<BarcodeScannerPage>
    with SingleTickerProviderStateMixin {
  final BarcodeScannerScreen _controller = BarcodeScannerScreen();
  
  late AnimationController _animController;
  late Animation<double> _scanLineAnim;
  
  String? _lastDetectedBarcode;
  bool _showSuccessFeedback = false;
  final Map<String, int> _scannedCounts = {};

  @override
  void initState() {
    super.initState();
    
    // Initialize animation
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 180).animate(
      CurvedAnimation(
        parent: _animController,
        curve: Curves.easeInOut,
      ),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: _buildAppBar(),
      body: _buildScannerBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.black,
      iconTheme: const IconThemeData(color: Colors.white),
      title: const Text(
        "Scan Barcode",
        style: TextStyle(color: Colors.white),
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.flip_camera_android, color: Colors.white),
          onPressed: _controller.switchCamera,
        ),
        IconButton(
          icon: const Icon(Icons.flash_on, color: Colors.white),
          onPressed: _controller.toggleTorch,
        ),
        IconButton(
          icon: const Icon(Icons.check, color: Colors.white),
          tooltip: 'Selesai (kirim hasil)',
          onPressed: () {
            if (_scannedCounts.isEmpty) {
              Navigator.pop(context, null);
            } else {
              Navigator.pop(context, _scannedCounts);
            }
          },
        ),
        IconButton(
          icon: const Icon(Icons.clear, color: Colors.white),
          tooltip: 'Reset hasil scan',
          onPressed: () {
            setState(() {
              _scannedCounts.clear();
              _lastDetectedBarcode = null;
            });
          },
        ),
      ],
    );
  }

  Widget _buildScannerBody() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Scanner Camera
        _buildScannerView(),
        
        // Scan Frame
        _buildScanFrame(),
        
        // Scan Line Animation
        _buildScanLineAnimation(),
        
        // Instructions
        _buildInstructions(),
        
        // Success Feedback
        if (_showSuccessFeedback) _buildSuccessFeedback(),
      ],
    );
  }

  Widget _buildScannerView() {
    return MobileScanner(
      controller: _controller.controller,
      onDetect: (capture) async {
        await _controller.handleBarcodeDetection(
          context,
          capture,
          onBarcodeDetected: _onBarcodeDetected,
        );
      },
    );
  }

  Widget _buildScanFrame() {
    return Container(
      width: 280,
      height: 180,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.white, width: 3),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  Widget _buildScanLineAnimation() {
    return AnimatedBuilder(
      animation: _scanLineAnim,
      builder: (context, child) {
        return Positioned(
          top: MediaQuery.of(context).size.height / 2 - 90 + _scanLineAnim.value,
          child: Container(
            width: 260,
            height: 2,
            decoration: BoxDecoration(
              color: Colors.redAccent,
              boxShadow: [
                BoxShadow(
                  color: Colors.redAccent.withOpacity(0.8),
                  blurRadius: 8,
                  spreadRadius: 1,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildInstructions() {
    return Positioned(
      bottom: 120,
      child: Column(
        children: [
          Text(
            "Arahkan kamera ke barcode",
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Otomatis redirect ke Add Product",
            style: TextStyle(
              color: Colors.white.withOpacity(0.6),
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 16),
          if (_lastDetectedBarcode != null)
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                "Terakhir: ${_controller.formatBarcode(_lastDetectedBarcode!)}",
                style: const TextStyle(
                  color: Colors.green,
                  fontSize: 12,
                ),
              ),
            ),
          const SizedBox(height: 8),
          if (_scannedCounts.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.7),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: _scannedCounts.entries.map((e) {
                  return Text(
                    '${_controller.formatBarcode(e.key)} : ${e.value}',
                    style: const TextStyle(color: Colors.white, fontSize: 12),
                  );
                }).toList(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSuccessFeedback() {
    return Positioned.fill(
      child: Container(
        color: Colors.green.withOpacity(0.3),
        child: Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: Colors.green,
                  size: 48,
                ),
                const SizedBox(height: 16),
                const Text(
                  "Barcode Berhasil Di-scan!",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Mengarahkan ke Add Product...",
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.7),
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onBarcodeDetected(String barcode) {
    setState(() {
      _lastDetectedBarcode = barcode;
      _showSuccessFeedback = true;
      _scannedCounts[barcode] = (_scannedCounts[barcode] ?? 0) + 1;
    });
    
    // Hide success feedback after 1 second
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) {
        setState(() {
          _showSuccessFeedback = false;
        });
      }
    });
  }

  // ignore: unused_element
  void _navigateToAddProduct(String barcode) {
    // kept for compatibility but not used in multi-scan mode
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Barcode: $barcode\nNavigating to Add Product...'),
        duration: const Duration(seconds: 2),
      ),
    );
    Navigator.pop(context, barcode);
  }
}