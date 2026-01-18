import 'package:flutter/material.dart';
import 'package:KGbox/screens/stok_owner_screen.dart';

/// UI wrapper page for Stok Owner. The actual logic and list
/// implementation live in `stok_owner_screen.dart`.
class StokOwnerPage extends StatelessWidget {
  const StokOwnerPage({super.key});

  @override
  Widget build(BuildContext context) {
    // Return the screen widget which contains the full implementation.
    return const StokOwnerScreen();
  }
}
