import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import '../screens/addproductscreen.dart';

class BarcodeScannerScreen extends StatefulWidget {
  const BarcodeScannerScreen({super.key});

  @override
  State<BarcodeScannerScreen> createState() => _BarcodeScannerScreenState();
}

class _BarcodeScannerScreenState extends State<BarcodeScannerScreen>
    with SingleTickerProviderStateMixin {
  final MobileScannerController controller = MobileScannerController();

  bool _isProcessing = false;
  String? _lastScannedCode;

  late AnimationController _animController;
  late Animation<double> _scanLineAnim;

  @override
  void initState() {
    super.initState();

    // Animasi garis scan bergerak naik-turun
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _scanLineAnim = Tween<double>(begin: 0, end: 180).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    controller.dispose();
    _animController.dispose();
    super.dispose();
  }

  // 🔊 Audio saat scan sukses (10 detik full)
  Future<void> playBeepSound() async {
    try {
      // buat AudioPlayer baru setiap scan agar durasi full terdengar
      AudioPlayer player = AudioPlayer();
      await player.play(AssetSource('sounds/beep.mp3'));

      // otomatis dispose setelah selesai
      player.onPlayerComplete.listen((event) => player.dispose());
    } catch (e) {
      print("Error mainkan suara beep: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text("Scan Barcode", style: TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            icon: const Icon(Icons.flip_camera_android, color: Colors.white),
            onPressed: () => controller.switchCamera(),
          ),
          IconButton(
            icon: const Icon(Icons.flash_on, color: Colors.white),
            onPressed: () => controller.toggleTorch(),
          ),
        ],
      ),
      body: Stack(
        alignment: Alignment.center,
        children: [
          // Kamera & Scanner
          MobileScanner(
            controller: controller,
            onDetect: (capture) async {
              if (_isProcessing) return;

              final List<Barcode> barcodes = capture.barcodes;
              if (barcodes.isEmpty) return;

              final raw = barcodes.first.rawValue;
              if (raw == null || raw.isEmpty) return;

              // Hindari scan berulang
              if (_lastScannedCode == raw) return;

              _lastScannedCode = raw;
              _isProcessing = true;

              print("✔ Barcode Terdeteksi: $raw");

              await playBeepSound(); // mainkan beep 10 detik penuh

              if (!mounted) return;

              // Navigasi otomatis ke AddProdukScreen
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => AddProdukScreen(
                    barcode: raw,
                    userRole: "staff",
                  ),
                ),
              );
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
            animation: _scanLineAnim,
            builder: (_, __) {
              return Positioned(
                top: MediaQuery.of(context).size.height / 2 - 90 + _scanLineAnim.value,
                child: Container(
                  width: 260,
                  height: 2,
                  color: Colors.redAccent,
                ),
              );
            },
          ),

          // INFORMASI DI BAWAH
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
                  "Setelah scan, otomatis masuk ke Add Product",
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
