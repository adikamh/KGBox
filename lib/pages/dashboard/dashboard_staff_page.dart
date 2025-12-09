import 'package:flutter/material.dart';
import 'package:kg_dns/pages/screens/barcode_scanner_screens.dart';
import 'package:kg_dns/pages/screens/manage_products_screen.dart';

import '../../app.dart';
import '../screens/notifications_screen.dart';
import '../screens/AddProductScreen.dart';
import '../screens/product_out_screen.dart';

class DashboardStaffPage extends StatefulWidget {
  final String userRole;
  const DashboardStaffPage({Key? key, required this.userRole}) : super(key: key);

  @override
  _DashboardStaffPageState createState() => _DashboardStaffPageState();
}

class _DashboardStaffPageState extends State<DashboardStaffPage> {
  final List<Map<String, dynamic>> _todaysOut = [
    {"name": "Produk A", "qty": 3, "note": "Penjualan"},
    {"name": "Produk B", "qty": 1, "note": "Retur"},
    {"name": "Produk C", "qty": 5, "note": "Pengiriman"},
  ];

  @override
  Widget build(BuildContext context) {
    final totalQty = _todaysOut.fold<int>(0, (s, e) => s + (e['qty'] as int));
    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(primary: const Color.fromARGB(255, 41, 101, 192)),
        appBarTheme: theme.appBarTheme.copyWith(backgroundColor: AppColors.success),
      ),
      child: Scaffold(
        appBar: CustomAppBar(
          title: 'Dashboard Staff',
          showBackButton: false,
          actions: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NotificationsScreen()),
                );
              },
            ),
            PopupMenuButton(
              icon: const Icon(Icons.exit_to_app),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                PopupMenuItem(
                  child: Row(
                    children: [
                      const Icon(Icons.badge, size: 20, color: Colors.green),
                      const SizedBox(width: 8),
                      Text('Role: ${widget.userRole}'),
                    ],
                  ),
                ),
                const PopupMenuItem(
                  child: Row(
                    children: [
                      Icon(Icons.settings, size: 20, color: Colors.grey),
                      SizedBox(width: 8),
                      Text('Settings'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  child: const Text('Logout'),
                  onTap: () {
                    Navigator.pushReplacementNamed(context, '/');
                  },
                ),
              ],
            ),
          ],
        ),
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color.fromARGB(255, 41, 101, 192),
                Color.fromARGB(255, 62, 163, 67),
              ],
            ),
          ),
          child: SafeArea(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),

                    // PRODUK KELUAR CARD
                    Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Color.fromARGB(255, 255, 255, 255),
                            Color.fromARGB(255, 255, 255, 255),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.3),
                            blurRadius: 15,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Produk Keluar',
                                    style: TextStyle(
                                      fontSize: 16,
                                      color: Color.fromARGB(179, 0, 0, 0),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const Text(
                                    'Hari Ini',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(153, 0, 0, 0),
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  Text(
                                    '$totalQty',
                                    style: const TextStyle(
                                      fontSize: 48,
                                      fontWeight: FontWeight.bold,
                                      color: Color.fromARGB(255, 0, 0, 0),
                                    ),
                                  ),
                                  const Text(
                                    'Unit',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Color.fromARGB(179, 0, 0, 0),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: const Color.fromARGB(255, 0, 0, 0).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Icon(
                                Icons.inventory_2_outlined,
                                size: 56,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 32),

                    // STATISTIK PRODUK CARD
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Statistik Produk',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.85,
                            children: [
                              _buildStatCard(
                                icon: Icons.warning_amber_rounded,
                                value: '12',
                                label: 'Sisa produk',
                                color: const Color.fromARGB(255, 245, 11, 11),
                              ),
                              _buildStatCard(
                                icon: Icons.trending_up_rounded,
                                value: '3',
                                label: 'Terlaris',
                                color: const Color.fromARGB(255, 50, 236, 44),
                              ),
                              _buildStatCard(
                                icon: Icons.event_rounded,
                                value: '1',
                                label: 'Kadaluarsa',
                                color: const Color.fromARGB(255, 255, 238, 0),
                              ),
                              _buildStatCard(
                                icon: Icons.bar_chart_rounded,
                                value: '0',
                                label: 'Suplier',
                                color: const Color.fromARGB(255, 16, 103, 185),
                              ),
                              _buildStatCard(
                                icon: Icons.local_shipping_rounded,
                                value: '3',
                                label: 'Pengiriman',
                                color: const Color.fromARGB(255, 248, 154, 12),
                              ),
                              _buildStatCard(
                                icon: Icons.barcode_reader,
                                value: "",
                                label: "Scan Barcode",
                                color: Colors.blueGrey,
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BarcodeScannerScreen(),
                                    ),
                                  );
                                  if (result != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text("Barcode: $result")),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),
                    const SizedBox(height: 16),

                    // Row Buttons
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.add_circle_outline,
                            label: 'Tambah',
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 255, 255, 255),
                                Color.fromARGB(255, 255, 255, 255),
                              ],
                            ),
                            iconColor: const Color.fromARGB(255, 0, 0, 0),
                            textColor: const Color.fromARGB(255, 0, 0, 0),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AddProdukScreen(
                                    userRole: widget.userRole,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.visibility_outlined,
                            label: 'Lihat',
                            gradient: const LinearGradient(
                              colors: [
                                Color.fromARGB(255, 255, 255, 255),
                                Color.fromARGB(255, 255, 255, 255),
                              ],
                            ),
                            iconColor: const Color.fromARGB(255, 0, 0, 0),
                            textColor: const Color.fromARGB(255, 0, 0, 0),
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ManageProductsScreen(userRole: widget.userRole),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // Full Width Button
                    Container(
                      width: double.infinity,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            Color.fromARGB(255, 255, 255, 255),
                            Color.fromARGB(255, 255, 255, 255),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4CAF50).withOpacity(0.4),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ProductOutScreen(userRole: widget.userRole),
                            ),
                          );
                        },
                        child: const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.note_add_outlined, size: 24, color: Color.fromARGB(255, 0, 0, 0)),
                            SizedBox(width: 12),
                            Text(
                              'Catat Produk',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color.fromARGB(255, 0, 0, 0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    required Gradient gradient,
    required VoidCallback onPressed,
    Color iconColor = Colors.white,
    Color textColor = Colors.white,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        gradient: gradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: onPressed,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: iconColor),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(0.3),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 4,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                icon,
                color: color,
                size: 22,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 10,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}