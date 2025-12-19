import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class LogoutScreen extends StatelessWidget {
  const LogoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 20),
            const Text(
              'Sedang logout...',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 10),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Batal logout
              },
              child: const Text('Batal'),
            ),
          ],
        ),
      ),
    );
  }
}

// Function untuk menampilkan konfirmasi logout
Future<bool?> showLogoutConfirmation(BuildContext context) async {
  return await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.logout, color: Colors.orange),
          SizedBox(width: 10),
          Text('Konfirmasi Logout'),
        ],
      ),
      content: const Text('Apakah Anda yakin ingin logout dari akun ini?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false), // Batal
          child: const Text('Batal'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true), // Konfirmasi
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          child: const Text('Logout'),
        ),
      ],
    ),
  );
}

// Function untuk menampilkan logout success dialog
void showLogoutSuccessDialog(BuildContext context) {
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text('Logout Berhasil'),
        ],
      ),
      content: const Text('Anda telah berhasil logout dari akun.'),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Navigasi ke halaman login
            Navigator.pushNamedAndRemoveUntil(
              context,
              '/login',
              (route) => false,
            );
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

// Reusable success dialog with green check
Future<void> showSuccessDialog(
  BuildContext context, {
  String title = 'Berhasil',
  required String message,
  VoidCallback? onOk,
  bool barrierDismissible = false,
}) async {
  await showDialog(
    context: context,
    barrierDismissible: barrierDismissible,
    builder: (context) => AlertDialog(
      title: Row(
        children: const [
          Icon(Icons.check_circle, color: Colors.green),
          SizedBox(width: 10),
          Text('Berhasil'),
        ],
      ),
      content: Text(message),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            if (onOk != null) onOk();
          },
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

// Function untuk menampilkan logout error dialog
void showLogoutErrorDialog(BuildContext context, String error) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: const Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red),
          SizedBox(width: 10),
          Text('Gagal Logout'),
        ],
      ),
      content: Text(error),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

// Main function untuk handle logout
Future<void> handleLogout(BuildContext context) async {
  final authProvider = Provider.of<AuthProvider>(context, listen: false);
  final navigator = Navigator.of(context);

  // Tampilkan konfirmasi logout
  final shouldLogout = await showLogoutConfirmation(navigator.context);

  if (shouldLogout != true) {
    return; // User membatalkan logout
  }

  // Tampilkan loading screen (non-blocking)
  navigator.push(
    MaterialPageRoute(
      builder: (ctx) => const LogoutScreen(),
    ),
  );

  try {
    // Eksekusi logout
    await authProvider.logout();

    // Delay untuk efek visual
    await Future.delayed(const Duration(milliseconds: 500));

    // Tutup loading screen
    navigator.pop();

    // Tampilkan success dialog
    showLogoutSuccessDialog(navigator.context);

  } catch (e) {
    // Tampilkan error dialog
    // Tutup loading screen jika masih terbuka
    try {
      navigator.pop();
    } catch (_) {}

    showLogoutErrorDialog(navigator.context, 'Terjadi kesalahan: ${e.toString()}');
  }
}