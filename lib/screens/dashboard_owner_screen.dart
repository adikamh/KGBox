import 'package:flutter/material.dart';
// ignore: unused_import
import '../pages/dashboard_owner_page.dart';

class DashboardOwnerController {
  // Data management
  final List<Map<String, dynamic>> _monthlyProductFlow = [
    {'month': 'Jan', 'in': 245, 'out': 189},
    {'month': 'Feb', 'in': 220, 'out': 175},
    {'month': 'Mar', 'in': 280, 'out': 195},
    {'month': 'Apr', 'in': 260, 'out': 210},
    {'month': 'Mei', 'in': 300, 'out': 230},
    {'month': 'Jun', 'in': 320, 'out': 250},
  ];

  final List<Map<String, dynamic>> _monthlyTransactions = [
    {'month': 'Jan', 'transactions': 1250, 'color': const Color(0xFF3B82F6)},
    {'month': 'Feb', 'transactions': 1380, 'color': const Color(0xFFEF4444)},
    {'month': 'Mar', 'transactions': 1450, 'color': const Color(0xFF10B981)},
    {'month': 'Apr', 'transactions': 1520, 'color': const Color(0xFFF59E0B)},
    {'month': 'Mei', 'transactions': 1600, 'color': const Color(0xFF8B5CF6)},
    {'month': 'Jun', 'transactions': 1680, 'color': const Color(0xFFEC4899)},
    {'month': 'Jul', 'transactions': 1350, 'color': const Color(0xFF14B8A6)},
    {'month': 'Agu', 'transactions': 1420, 'color': const Color(0xFFF97316)},
    {'month': 'Sep', 'transactions': 1700, 'color': const Color(0xFF6366F1)},
    {'month': 'Okt', 'transactions': 1750, 'color': const Color(0xFF84CC16)},
    {'month': 'Nov', 'transactions': 1480, 'color': const Color(0xFF06B6D4)},
    {'month': 'Des', 'transactions': 1750, 'color': const Color(0xFF8B5CF6)},
  ];

  static const int _maxTransactions = 2000;

  // Getters for UI
  List<Map<String, dynamic>> get monthlyProductFlow => _monthlyProductFlow;
  List<Map<String, dynamic>> get monthlyTransactions => _monthlyTransactions;
  int get maxTransactions => _maxTransactions;

  // Calculations
  int get totalProductIn {
    return _monthlyProductFlow.map((e) => e['in'] as int).reduce((a, b) => a + b);
  }

  int get totalProductOut {
    return _monthlyProductFlow.map((e) => e['out'] as int).reduce((a, b) => a + b);
  }

  int get remainingStock {
    return totalProductIn - totalProductOut;
  }

  int get totalTransactions {
    return _monthlyTransactions.map((e) => e['transactions'] as int).reduce((a, b) => a + b);
  }

  // Helper methods
  String getMonthName(int month) {
    switch (month) {
      case 1:
        return 'Januari';
      case 2:
        return 'Februari';
      case 3:
        return 'Maret';
      case 4:
        return 'April';
      case 5:
        return 'Mei';
      case 6:
        return 'Juni';
      case 7:
        return 'Juli';
      case 8:
        return 'Agustus';
      case 9:
        return 'September';
      case 10:
        return 'Oktober';
      case 11:
        return 'November';
      case 12:
        return 'Desember';
      default:
        return '';
    }
  }

  // Navigation methods
  void navigateToStaffScreen(BuildContext context) async {
    // Import your AddStaffScreen here
    // final result = await Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => const AddStaffScreen()),
    // );
    // if (result != null && result is Map) {
    //   ScaffoldMessenger.of(context).showSnackBar(
    //     SnackBar(content: Text('Karyawan ${result['username']} ditambahkan')),
    //   );
    // }
  }

  void navigateToProductsScreen(BuildContext context) {
    // Import your ListProductPage here
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => ListProductPage()),
    // );
  }

  void navigateToStoreScreen(BuildContext context) {
    // Import your RiwayatTokoPage here
    // Navigator.push(
    //   context,
    //   MaterialPageRoute(builder: (_) => const RiwayatTokoPage()),
    // );
  }

  void showNotifications(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Notifikasi belum diimplementasikan')),
    );
  }

  void showSettings(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Settings belum tersedia')),
    );
  }

  void logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/');
  }
}