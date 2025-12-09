import 'package:flutter/material.dart';
import '../../app.dart';

class FinancialActivitiesScreen extends StatelessWidget {
  const FinancialActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Aktivitas Finansial Terbaru'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InfoCard(
              title: 'Pembayaran dari Customer ABC',
              subtitle: 'Rp 75.5 Jt • Lunas',
              icon: Icons.payment,
              iconColor: Colors.green,
              time: 'Hari ini',
            ),

            const SizedBox(height: 12),

            InfoCard(
              title: 'Pembelian ke Supplier XYZ',
              subtitle: 'Rp 42.3 Jt • Inventory',
              icon: Icons.shopping_cart,
              iconColor: Colors.blue,
              time: 'Kemarin',
            ),

            const SizedBox(height: 12),

            InfoCard(
              title: 'Biaya Operasional',
              subtitle: 'Rp 12.8 Jt • Bulanan',
              icon: Icons.receipt,
              iconColor: Colors.orange,
              time: '2 hari lalu',
            ),
          ],
        ),
      ),
    );
  }
}
