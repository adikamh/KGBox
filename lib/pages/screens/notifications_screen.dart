import 'package:flutter/material.dart';
import '../../app.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifikasi'),
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
            // Critical Alerts
            Text(
              'Peringatan Kritis',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.warning_amber, color: Colors.orange[800]),
                      const SizedBox(width: 8),
                      Text(
                        'Peringatan Kritis',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange[800],
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildCriticalAlert(
                    '5 produk dengan stok sangat rendah (<3 unit)',
                    AppColors.danger,
                  ),
                  _buildCriticalAlert(
                    '2 produk mendekati expiry date',
                    Colors.orange,
                  ),
                  _buildCriticalAlert(
                    'Piutang > 30 hari: Rp 45.2 Jt',
                    Colors.purple,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Recent Financial Activities
            Text(
              'Aktivitas Finansial Terbaru',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 16),

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

  Widget _buildCriticalAlert(String message, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: color, fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }
}
