// lib/screens/barcode_scanner_screen.dart
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class BarcodeScannerScreen {
  final MobileScannerController _controller = MobileScannerController();
  
  bool _isProcessing = false;
  String? _lastScannedCode;
  DateTime? _lastScannedAt;
  final int _debounceMs = 700;
  
  // Getters
  MobileScannerController get controller => _controller;
  bool get isProcessing => _isProcessing;
  
  // Initialize controller
  void initialize() {
    // Inisialisasi controller jika diperlukan
  }
  
  // Handle barcode detection
  Future<void> handleBarcodeDetection(
    BuildContext context,
    BarcodeCapture capture, {
    required Function(String) onBarcodeDetected,
  }) async {
    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isEmpty) return;

    final raw = barcodes.first.rawValue;
    if (raw == null || raw.isEmpty) return;

    final now = DateTime.now();

    // Debounce to avoid many frames producing duplicate counts.
    if (_lastScannedCode == raw && _lastScannedAt != null) {
      final diff = now.difference(_lastScannedAt!).inMilliseconds;
      if (diff < _debounceMs) return;
    }

    _lastScannedCode = raw;
    _lastScannedAt = now;
    _isProcessing = true;

    // Callback untuk barcode yang terdeteksi (do NOT navigate here)
    onBarcodeDetected(raw);

    // Small pause to avoid flooding and allow UI updates
    await Future.delayed(const Duration(milliseconds: 300));
    _isProcessing = false;
  }
  
  // Switch camera
  Future<void> switchCamera() async {
    try {
      await _controller.switchCamera();
    } catch (e) {
      print('Error switching camera: $e');
    }
  }
  
  // Toggle torch
  Future<void> toggleTorch() async {
    try {
      await _controller.toggleTorch();
    } catch (e) {
      print('Error toggling torch: $e');
    }
  }
  
  // Stop scanner
  Future<void> stopScanner() async {
    try {
      await _controller.stop();
    } catch (e) {
      print('Error stopping scanner: $e');
    }
  }
  
  // Start scanner
  Future<void> startScanner() async {
    try {
      await _controller.start();
    } catch (e) {
      print('Error starting scanner: $e');
    }
  }
  
  // Dispose resources
  Future<void> dispose() async {
    await _controller.dispose();
  }
  
  // Check if scanner is available
  bool isScannerAvailable() {
    return true; // You can add more checks here
  }
  
  // Validate barcode format
  bool isValidBarcode(String barcode) {
    if (barcode.isEmpty) return false;
    
    // Common barcode length validation
    final lengths = [8, 12, 13, 14];
    return lengths.contains(barcode.length);
  }
  
  // Format barcode for display
  String formatBarcode(String barcode) {
    if (barcode.length <= 8) return barcode;
    
    // Add spaces for readability (EAN-13: 1 23456 789012 3)
    if (barcode.length == 13) {
      return '${barcode.substring(0, 1)} ${barcode.substring(1, 7)} ${barcode.substring(7, 12)} ${barcode.substring(12)}';
    }
    
    return barcode;
  }
  
  // Get barcode type
  String getBarcodeType(Barcode barcode) {
    return barcode.type.name;
  }
}