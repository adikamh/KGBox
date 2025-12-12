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
                    const SizedBox(height: 16),

                    // PRODUK KELUAR CARD - Enhanced
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(28.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Produk Keluar',
                                    style: TextStyle(
                                      fontSize: 18,
                                      color: Colors.grey[700],
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Hari Ini',
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[500],
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '$totalQty',
                                    style: const TextStyle(
                                      fontSize: 56,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF1A1A1A),
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Unit',
                                    style: TextStyle(
                                      fontSize: 15,
                                      color: Colors.grey[600],
                                      fontWeight: FontWeight.w500,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.all(24),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: [
                                    const Color.fromARGB(255, 41, 101, 192).withOpacity(0.1),
                                    const Color.fromARGB(255, 62, 163, 67).withOpacity(0.1),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.inventory_2_rounded,
                                size: 64,
                                color: Color.fromARGB(255, 41, 101, 192),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // STATISTIK PRODUK CARD - Enhanced
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.08),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 4,
                                height: 24,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Color.fromARGB(255, 41, 101, 192),
                                      Color.fromARGB(255, 62, 163, 67),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 12),
                              const Text(
                                'Statistik Produk',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Color(0xFF1A1A1A),
                                  letterSpacing: 0.3,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          GridView.count(
                            crossAxisCount: 3,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.95,
                            children: [
                              _buildStatCard(
                                icon: Icons.warning_amber_rounded,
                                value: '12',
                                label: 'Sisa\nproduk',
                                color: const Color(0xFFEF5350),
                              ),
                              _buildStatCard(
                                icon: Icons.trending_up_rounded,
                                value: '3',
                                label: 'Terlaris',
                                color: const Color(0xFF66BB6A),
                              ),
                              _buildStatCard(
                                icon: Icons.event_rounded,
                                value: '1',
                                label: 'Kadaluarsa',
                                color: const Color(0xFFFFCA28),
                              ),
                              _buildStatCard(
                                icon: Icons.bar_chart_rounded,
                                value: '0',
                                label: 'Suplier',
                                color: const Color(0xFF42A5F5),
                              ),
                              _buildStatCard(
                                icon: Icons.local_shipping_rounded,
                                value: '3',
                                label: 'Pengiriman',
                                color: const Color(0xFFFF7043),
                              ),
                              _buildStatCard(
                                icon: Icons.qr_code_scanner_rounded,
                                value: "",
                                label: "Scan\nBarcode",
                                color: const Color(0xFF78909C),
                                onTap: () async {
                                  final result = await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => const BarcodeScannerScreen(),
                                    ),
                                  );
                                  if (result != null) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text("Barcode: $result"),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Action Buttons Section - Fixed
                    Row(
                      children: [
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.add_circle_outline_rounded,
                            label: 'Tambah Produk',
                            iconColor: const Color.fromARGB(255, 41, 101, 192),
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
                        const SizedBox(width: 14),
                        Expanded(
                          child: _buildActionButton(
                            context,
                            icon: Icons.visibility_outlined,
                            label: 'Lihat Produk',
                            iconColor: const Color.fromARGB(255, 62, 163, 67),
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

                    const SizedBox(height: 14),

                    // Full Width Button - Enhanced
                    Container(
                      width: double.infinity,
                      height: 68,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(20),
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
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    const Color.fromARGB(255, 41, 101, 192).withOpacity(0.15),
                                    const Color.fromARGB(255, 62, 163, 67).withOpacity(0.15),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(
                                Icons.note_add_rounded,
                                size: 26,
                                color: Color.fromARGB(255, 41, 101, 192),
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Text(
                              'Catat Produk Keluar',
                              style: TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1A1A1A),
                                letterSpacing: 0.3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),
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
    required VoidCallback onPressed,
    required Color iconColor,
  }) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 28, color: iconColor),
                ),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: 0.1,
                    height: 1.2,
                  ),
                ),
              ],
            ),
          ),
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
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
                spreadRadius: 0,
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 22,
                ),
              ),
              const SizedBox(height: 6),
              if (value.isNotEmpty)
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: color,
                    height: 1.0,
                  ),
                ),
              if (value.isNotEmpty) const SizedBox(height: 3),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.visible,
                style: TextStyle(
                  fontSize: 9.5,
                  color: Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  height: 1.15,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}