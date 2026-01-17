// ignore_for_file: unused_local_variable, unused_element

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:kgbox/pages/kelola_staff_page.dart';
import 'package:kgbox/screens/export_report_screen.dart';
import 'package:intl/intl.dart';
import 'package:kgbox/providers/auth_provider.dart';
import 'package:kgbox/screens/dashboard_owner_screen.dart';
// ignore: unused_import, undefined_shown_name
import 'package:kgbox/screens/dashboard_owner_screen.dart' as _controller show shareFile;
// ignore: duplicate_import
import 'package:kgbox/screens/export_report_screen.dart';
import 'package:provider/provider.dart';
import '../screens/dashboard_owner_screen.dart';
// ignore: unused_import, undefined_shown_name
import '../screens/dashboard_owner_screen.dart' as _controller show shareFile;
import 'package:kgbox/services/notification_owner_service.dart';
import 'package:kgbox/services/fcm_service.dart';

class DashboardOwnerPage extends StatefulWidget {
  final String userRole;
  final String userEmail;

  const DashboardOwnerPage({
    super.key,
    required this.userRole,
    this.userEmail = 'Dashboard Owner',
  });

  @override
  State<DashboardOwnerPage> createState() => _DashboardOwnerPageState();
}

class _DashboardOwnerPageState extends State<DashboardOwnerPage> {
  final DashboardOwnerController _controller = DashboardOwnerController();
  final TextEditingController _totalProdukController = TextEditingController(text: '1.200');
  final TextEditingController _barangMasukController = TextEditingController(text: '245');
  final TextEditingController _barangKeluarController = TextEditingController(text: '189');
  
  // ScrollControllers for chart scrolling
  late ScrollController _productFlowScrollController;
  late ScrollController _transactionChartScrollController;

  @override
  void initState() {
    super.initState();
    _productFlowScrollController = ScrollController();
    _transactionChartScrollController = ScrollController();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      // Initialize FCM for owner with permission request
      await FCMService.instance.initMessaging(context);
      
      await _controller.loadCounts(context);
      setState(() {});
    });
  }

  @override
  void dispose() {
    _productFlowScrollController.dispose();
    _transactionChartScrollController.dispose();
    _totalProdukController.dispose();
    _barangMasukController.dispose();
    _barangKeluarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _buildAppBar(),
      backgroundColor: Colors.white,
      body: _buildBody(),
      floatingActionButton: _buildExportButton(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0.6,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFF1E40AF),
              Color(0xFF059669),
            ],
          ),
        ),
      ),
      title: Text(
        widget.userEmail,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
      ),
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.refresh, color: Colors.white),
          onPressed: () async {
            await _controller.loadCounts(context);
            setState(() {});
          },
        ),
        _buildNotificationButton(),
        PopupMenuButton<int>(
          icon: const Icon(Icons.exit_to_app, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            PopupMenuItem<int>(
              value: 0,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.badge, size: 20, color: Color(0xFF1E40AF)),
                title: const Text('Role: Owner', overflow: TextOverflow.ellipsis),
              ),
            ),
            PopupMenuItem<int>(
              value: 2,
              child: ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.logout, size: 20, color: Colors.red),
                title: const Text('Logout', overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onSelected: (value) {
            if (value == 2) {
              _controller.logout(context);
            } else if (value == 1) {
              _controller.showSettings(context);
            }
          },
        ),
      ],
    );
  }

  Widget _buildBody() {
    return Container(
      color: Colors.white,
      child: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildTodaysSummary(context),
              const SizedBox(height: 24),
              _buildStaffAndTrackingFeatures(context),
              const SizedBox(height: 24),
              _buildFinancialOverview(context),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTodaysSummary(BuildContext context) {
    final today = DateTime.now();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildDatePill(today),
        const SizedBox(height: 20),
        _buildSummaryCard(),
      ],
    );
  }

  Widget _buildDatePill(DateTime today) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.calendar_today_rounded, size: 14, color: Color(0xFF6B7280)),
          const SizedBox(width: 6),
          Text(
            '${today.day} ${_controller.getMonthName(today.month)} ${today.year}',
            style: const TextStyle(
              fontSize: 12,
              color: Color(0xFF6B7280),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF1E40AF),
            Color(0xFF059669),
          ],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF667EEA).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // refresh moved to AppBar actions
          _buildTotalProdukSection(),
          const SizedBox(height: 16),
          _buildSmallStatsSection(),
        ],
      ),
    );
  }

  Widget _buildTotalProdukSection() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Total Produk',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 10),
              GestureDetector(
                onTap: () async {
                  await _controller.loadCounts(context);
                  setState(() {});
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _controller.totalProduk.toString(),
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.inventory_2_rounded, color: Colors.white),
        ),
      ],
    );
  }

  Widget _buildSmallStatsSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.2), width: 1),
      ),
      child: Row(
        children: [
          Expanded(
            child: _buildSmallStatCard(
              title: 'Barang Masuk',
              value: _controller.barangMasuk.toString(),
              icon: Icons.arrow_downward_rounded,
              color: const Color(0xFF66BB6A),
              note: 'Dari minggu lalu', // Tetap per minggu
              onTap: () async {
                await _controller.loadCounts(context);
                setState(() {});
              },
              isLoading: _controller.isLoadingCounts,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildSmallStatCard(
              title: 'Barang Keluar',
              value: _controller.barangKeluar.toString(),
              icon: Icons.arrow_upward_rounded,
              color: const Color(0xFFEF5350),
              note: 'Total semua', // Diubah menjadi total semua
              onTap: () async {
                await _controller.loadCounts(context);
                setState(() {});
              },
              isLoading: _controller.isLoadingCounts,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    String? note,
    required VoidCallback onTap,
    bool isLoading = false,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text(
                        value,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                if (note != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    note,
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white.withOpacity(0.8),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffAndTrackingFeatures(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Menu Utama',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87),
        ),
        const SizedBox(height: 16),
        _buildMainMenuRow(),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: _buildStoreButton()),
            const SizedBox(width: 12),
            Expanded(child: _buildStokButton()),
          ],
        ),
        const SizedBox(height: 24),
        _buildProductFlowChart(),
      ],
    );
  }

  Widget _buildMainMenuRow() {
    return Row(
      children: [
        _buildMenuCard(
          title: 'Kelola Staff',
          icon: Icons.person_rounded,
          color: const Color(0xFF06B6D4),
          onTap: () {
            final auth = Provider.of<AuthProvider>(context, listen: false);
            final user = auth.currentUser;
            if (user == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('User tidak tersedia')),
              );
              return;
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => KelolaStaffPage(
                      ownerId: user.ownerId ?? user.id,
                      ownerCompanyName: user.companyName ?? '',
                      currentUser: user,
                    ),
              ),
            );
          },
        ),
        const SizedBox(width: 12),
        _buildMenuCard(
          title: 'Lihat Produk',
          icon: Icons.inventory_2_rounded,
          color: const Color(0xFF059669),
          onTap: () => _controller.navigateToProductsScreen(context),
        ),
      ],
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 36, color: Colors.white),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStoreButton() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/pengiriman'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFFEA580C),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFEA580C).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.store, size: 28, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Toko',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStokButton() {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/stok'),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color.fromARGB(255, 92, 10, 199),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color.fromARGB(255, 92, 10, 199).withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inventory_2_rounded, size: 28, color: Colors.white),
            SizedBox(width: 12),
            Text(
              'Stok',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  
  Widget _buildProductFlowChart() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color.fromARGB(230, 255, 255, 255),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Alur Produk',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              TextButton(
                onPressed: () => _showProductFlowDialog(context),
                child: const Text(
                  'Lihat Detail',
                  style: TextStyle(
                    color: Color(0xFF3B82F6),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 350,
            child: _buildMiniProductFlowChart(),
          ),
          const SizedBox(height: 12),
          _buildChartLegends(),
        ],
      ),
    );
  }

  Widget _buildMiniProductFlowChart() {
    final ownerId = _getCurrentOwnerId();
    debugPrint('_buildMiniProductFlowChart: using dynamic data from controller');
    
    // Gunakan data yang sudah di-fetch secara dinamis di controller
    final productFlow = _controller.monthlyProductFlow;
    
    if (productFlow.isEmpty) {
      return const Center(
        child: SizedBox(
          height: 250,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    final inValues = productFlow.map((e) => (e['in'] as int?)?.toDouble() ?? 0.0).toList();
    final outValues = productFlow.map((e) => (e['out'] as int?)?.toDouble() ?? 0.0).toList();
    final months = productFlow.map((e) => e['month'] as String).toList();
    
    debugPrint('_buildMiniProductFlowChart: months=$months, inValues=$inValues, outValues=$outValues');
    
    final maxVal = [...inValues, ...outValues].fold<double>(1, (prev, e) => e > prev ? e : prev);

    return Container(
      height: 340,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _productFlowScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(12, (i) {
                              final inVal = inValues[i];
                              final outVal = outValues[i];
                              final inHeight = maxVal <= 0 ? 0.0 : (inVal / maxVal) * 50;
                              final outHeight = maxVal <= 0 ? 0.0 : (outVal / maxVal) * 50;
                              final totalHeight = (outHeight + inHeight).clamp(6.0, 80.0);

                              return SizedBox(
                                width: 70,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Container(
                                        width: 28,
                                        height: totalHeight,
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(2),
                                        ),
                                        child: Column(
                                          mainAxisAlignment: MainAxisAlignment.end,
                                          children: [
                                            if (outHeight > 0)
                                              Container(
                                                width: 28,
                                                height: outHeight.clamp(0, 50),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFFEF4444),
                                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFFEF4444).withOpacity(0.3),
                                                      blurRadius: 3,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            if (inHeight > 0)
                                              Container(
                                                width: 28,
                                                height: inHeight.clamp(0, 50),
                                                decoration: BoxDecoration(
                                                  color: const Color(0xFF10B981),
                                                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                                                  boxShadow: [
                                                    BoxShadow(
                                                      color: const Color(0xFF10B981).withOpacity(0.3),
                                                      blurRadius: 3,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: List.generate(12, (i) {
                            return SizedBox(
                              width: 70,
                              child: Center(
                                child: Text(
                                  months[i],
                                  style: const TextStyle(
                                    fontSize: 11,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ),
                // Left scroll indicator - CLICKABLE
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      _productFlowScrollController.animateTo(
                        _productFlowScrollController.offset - 200,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFFF9FAFB),
                            const Color(0xFFF9FAFB).withOpacity(0),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_left,
                          size: 28,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                // Right scroll indicator - CLICKABLE
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      _productFlowScrollController.animateTo(
                        _productFlowScrollController.offset + 200,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFFF9FAFB).withOpacity(0),
                            const Color(0xFFF9FAFB),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_right,
                          size: 28,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Divider(color: const Color(0xFFE5E7EB).withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildChartLegends() {
    // Gunakan data yang sudah di-fetch secara dinamis di controller
    int totalIn = _controller.totalProductIn;
    int totalOut = _controller.totalProductOut;
    
    debugPrint('_buildChartLegends: totalIn=$totalIn, totalOut=$totalOut');

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildChartLegendItem(
          const Color(0xFF10B981),
          'Masuk ($totalIn unit)',
        ),
        const SizedBox(width: 16),
        _buildChartLegendItem(
          const Color(0xFFEF4444),
          'Keluar ($totalOut unit)',
        ),
      ],
    );
  }

  String _getCurrentOwnerId() {
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';
      debugPrint('_getCurrentOwnerId: ownerId=$ownerId, user=$user');
      return ownerId;
    } catch (e) {
      debugPrint('_getCurrentOwnerId error: $e');
      return '';
    }
  }

  /// Build notification button dengan badge count
  Widget _buildNotificationButton() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final ownerId = auth.currentUser?.ownerId ?? auth.currentUser?.id ?? '';
    
    if (ownerId.isEmpty) {
      return IconButton(
        icon: const Icon(Icons.notifications_outlined, color: Colors.white),
        onPressed: () => _controller.showNotifications(context),
      );
    }

    return _NotificationButtonWidget(
      ownerId: ownerId,
      onPressed: () => _controller.showNotifications(context),
    );
  }

  Widget _buildChartLegendItem(Color color, String text) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 6),
        Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialOverview(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Performa Tahunan',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color.fromARGB(230, 255, 255, 255),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildFinancialHeader(),
              const SizedBox(height: 24),
              _buildTransactionChart(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialHeader() {
    final now = DateTime.now();
    final start = DateTime(now.year, now.month - 11, 1);
    final end = DateTime(now.year, now.month, 1);
    final rangeText = '${DateFormat('MMM yyyy').format(start)} - ${DateFormat('MMM yyyy').format(end)}';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Jumlah Transaksi Bulanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              rangeText,
              style: const TextStyle(
                fontSize: 14,
                color: Color(0xFF6B7280),
              ),
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFF3B82F6).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: [
              Icon(Icons.trending_up_rounded, size: 14, color: Color(0xFF3B82F6)),
              SizedBox(width: 4),
              Text(
                'Trend',
                style: TextStyle(
                  fontSize: 12,
                  color: Color(0xFF3B82F6),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTransactionChart() {
    final ownerId = _getCurrentOwnerId();
    debugPrint('_buildTransactionChart: using dynamic data from controller');
    
    // Gunakan data yang sudah di-fetch secara dinamis di controller
    final monthlyTransactions = _controller.monthlyTransactions;
    
    if (monthlyTransactions.isEmpty) {
      return Container(
        height: 350,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE5E7EB)),
        ),
        child: const Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    final maxTransactions = monthlyTransactions.map((d) => (d['transactions'] as int)).fold<int>(1, (a, b) => b > a ? b : a);

    return Container(
      height: 380,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                SingleChildScrollView(
                  controller: _transactionChartScrollController,
                  scrollDirection: Axis.horizontal,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 50.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisSize: MainAxisSize.min,
                            children: monthlyTransactions.map((item) {
                              final double heightRatio = (item['transactions'] as int) / (maxTransactions == 0 ? 1 : maxTransactions);
                              final barHeight = (150 * heightRatio).clamp(10.0, 150.0);
                              
                              return SizedBox(
                                width: 70,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 3.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    children: [
                                      Flexible(
                                        fit: FlexFit.loose,
                                        child: Padding(
                                          padding: const EdgeInsets.only(bottom: 4.0),
                                          child: Text(
                                            '${item['transactions']}',
                                            style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                              color: Color(0xFF6B7280),
                                            ),
                                            textAlign: TextAlign.center,
                                          ),
                                        ),
                                      ),
                                      Container(
                                        width: 40,
                                        height: barHeight,
                                        decoration: BoxDecoration(
                                          color: item['color'] as Color,
                                          borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
                                          boxShadow: [
                                            BoxShadow(
                                              color: (item['color'] as Color).withOpacity(0.3),
                                              blurRadius: 6,
                                              offset: const Offset(0, 3),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: monthlyTransactions.map((item) {
                            return SizedBox(
                              width: 70,
                              child: Center(
                                child: Text(
                                  item['month'],
                                  style: const TextStyle(
                                    fontSize: 10,
                                    color: Color(0xFF6B7280),
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                // Left scroll indicator - CLICKABLE
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      _transactionChartScrollController.animateTo(
                        _transactionChartScrollController.offset - 200,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFFF9FAFB),
                            const Color(0xFFF9FAFB).withOpacity(0),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_left,
                          size: 28,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
                // Right scroll indicator - CLICKABLE
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: GestureDetector(
                    onTap: () {
                      _transactionChartScrollController.animateTo(
                        _transactionChartScrollController.offset + 200,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeInOut,
                      );
                    },
                    child: Container(
                      width: 40,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.centerLeft,
                          end: Alignment.centerRight,
                          colors: [
                            const Color(0xFFF9FAFB).withOpacity(0),
                            const Color(0xFFF9FAFB),
                          ],
                        ),
                      ),
                      child: Center(
                        child: Icon(
                          Icons.chevron_right,
                          size: 28,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Divider(color: const Color(0xFFE5E7EB).withOpacity(0.5)),
          const SizedBox(height: 12),
          _buildChartSummary(monthlyTransactions),
        ],
      ),
    );
  }

  Widget _buildChartSummary([List<Map<String, dynamic>>? data]) {
    int total = 0;
    if (data != null) {
      total = data.map((d) => (d['transactions'] as int?) ?? 0).fold<int>(0, (a, b) => a + b);
    } else {
      total = _controller.totalTransactions;
    }

    // compute omzet (sum of 'total') if data provided
    double sumTotal = 0.0;
    if (data != null) {
      for (final d in data) {
        final t = d['total'];
        if (t is num) sumTotal += t.toDouble();
        else if (t is String) sumTotal += double.tryParse(t.replaceAll(',', '')) ?? 0.0;
      }
    }

    final currency = NumberFormat.currency(locale: 'id_ID', symbol: 'Rp', decimalDigits: 0);
    final omzetText = sumTotal > 0 ? currency.format(sumTotal) : '-';

        return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Total Transaksi: $total',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
            const SizedBox(height: 4),
            Text(
              'Omzet: $omzetText',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
            ),
          ],
        ),
      ],
    );
  }

  // Dialog methods
  // ignore: duplicate_ignore
  // ignore: unused_element
  Future<void> _showEditDialog(
    BuildContext context, {
    required TextEditingController controller,
    required String title,
  }) async {
    final TextEditingController editing = TextEditingController(text: controller.text);
    await showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: TextField(
            controller: editing,
            keyboardType: TextInputType.text,
            decoration: const InputDecoration(hintText: 'Masukkan nilai'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () {
                if (editing.text.trim().isNotEmpty) {
                  setState(() {
                    controller.text = editing.text.trim();
                  });
                }
                Navigator.of(context).pop();
              },
              child: const Text('Simpan'),
            ),
          ],
        );
      },
    );
  }

  void _showProductFlowDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: Container(
            padding: const EdgeInsets.all(24),
            constraints: const BoxConstraints(maxWidth: 800, maxHeight: 600),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDialogHeader(context, title: 'Detail Alur Produk'),
                const SizedBox(height: 16),
                  _buildDetailedChart(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogHeader(BuildContext context, {String title = ''}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    );
  }

  Widget _buildDetailedChart() {
    return FutureBuilder<Map<String, List<double>>>(
      future: _controller.fetchMonthlyTotals(_getCurrentOwnerId()),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(child: Text('Error: ${snap.error}'));
        }

        if (!snap.hasData) {
          return const Center(child: Text('Tidak ada data'));
        }

        final inTotals = snap.data!['in']!;
        final outTotals = snap.data!['out']!;
        [...inTotals, ...outTotals].fold<double>(1, (prev, e) => e > prev ? e : prev);

        // Replace detailed bar chart with a donut chart summary
        return Container(
          height: 300,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: FutureBuilder<int>(
            future: _controller.countRemainingStock(_getCurrentOwnerId()),
            builder: (context, stockSnap) {
              final ownerId = _getCurrentOwnerId();
              final remaining = stockSnap.data ?? 0;
              debugPrint('_buildDetailedChart: ownerId=$ownerId, stockSnap.state=${stockSnap.connectionState}, stockSnap.data=${stockSnap.data}');
              debugPrint('_buildDetailedChart: inTotals=$inTotals, outTotals=$outTotals, snap=${snap.data}');
              final totalIn = inTotals.map((e) => e.toInt()).fold(0, (a, b) => a + b);
              final totalOut = outTotals.map((e) => e.toInt()).fold(0, (a, b) => a + b);
              final segments = [totalIn.toDouble(), totalOut.toDouble(), remaining.toDouble()];
              final colors = [const Color(0xFF10B981), const Color(0xFFEF4444), const Color(0xFF3B82F6)];

              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 200,
                    height: 200,
                    child: CustomPaint(
                      painter: _DonutPainter(segments, colors),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$remaining', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 4),
                            const Text('Sisa Stok', style: TextStyle(fontSize: 14, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    alignment: WrapAlignment.center,
                    spacing: 12,
                    runSpacing: 6,
                    children: [
                      _buildChartLegendItem(const Color(0xFF10B981), 'Masuk ($totalIn)'),
                      _buildChartLegendItem(const Color(0xFFEF4444), 'Keluar ($totalOut)'),
                      _buildChartLegendItem(const Color(0xFF3B82F6), 'Sisa ($remaining)'),
                    ],
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildSummaryCards() {
    return FutureBuilder<Map<String, List<double>>>(
      future: _controller.fetchMonthlyTotals(_getCurrentOwnerId()),
      builder: (context, snap) {
        int totalIn = 0;
        int totalOut = 0;

        if (snap.hasData) {
          final inTotals = snap.data!['in']!;
          final outTotals = snap.data!['out']!;
          debugPrint('_buildSummaryCards: snap=${snap.data}, inTotals=$inTotals, outTotals=$outTotals');
          totalIn = inTotals.map((e) => e.toInt()).fold(0, (a, b) => a + b);
          totalOut = outTotals.map((e) => e.toInt()).fold(0, (a, b) => a + b);
        }

        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF3F4F6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: FutureBuilder<int>(
            future: _controller.countRemainingStock(_getCurrentOwnerId()),
            builder: (context, stockSnap) {
              final ownerId = _getCurrentOwnerId();
              final remaining = stockSnap.data ?? 0;
              debugPrint('_buildSummaryCards: ownerId=$ownerId, stockSnap.state=${stockSnap.connectionState}, remaining=$remaining');
              final total = (totalIn + totalOut + remaining) == 0
                  ? 1
                  : (totalIn + totalOut + remaining);

              final segments = [totalIn.toDouble(), totalOut.toDouble(), remaining.toDouble()];
              final colors = [const Color(0xFF10B981), const Color(0xFFEF4444), const Color(0xFF3B82F6)];

              return Row(
                children: [
                  SizedBox(
                    width: 140,
                    height: 140,
                    child: CustomPaint(
                      painter: _DonutPainter(segments, colors),
                      child: Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('$remaining', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const Text('Sisa Stok', style: TextStyle(fontSize: 12, color: Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildProductSummaryCard('Total Masuk', '$totalIn unit', Icons.arrow_downward_rounded, const Color(0xFF10B981)),
                        const SizedBox(height: 8),
                        _buildProductSummaryCard('Total Keluar', '$totalOut unit', Icons.arrow_upward_rounded, const Color(0xFFEF4444)),
                        const SizedBox(height: 8),
                        _buildProductSummaryCard('Sisa Stok', '$remaining unit', Icons.inventory_2_rounded, const Color(0xFF3B82F6)),
                      ],
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProductSummaryCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 24, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        Text(
          title,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }



  Widget _buildExportButton() {
    return FloatingActionButton.extended(
      backgroundColor: const Color(0xFF059669),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      onPressed: _handleExport,
      icon: const Icon(
        Icons.download_rounded,
        color: Colors.white,
        size: 24,
      ),
      label: const Text(
        'Export',
        style: TextStyle(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  void _handleExport() {
    if (!mounted) return;
    _showExportReportDialog();
  }

  void _showExportReportDialog() {
    final reports = [
      {
        'title': 'Laporan Keseluruhan Produk Tersedia',
        'icon': Icons.inventory_2,
        'action': 'available_products'
      },
      {
        'title': 'Laporan Keseluruhan Produk Kadaluarsa',
        'icon': Icons.warning_amber,
        'action': 'expired_products'
      },
      {
        'title': 'Laporan Order Pengiriman',
        'icon': Icons.local_shipping,
        'action': 'delivery_orders'
      },
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.file_download, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('Pilih Laporan'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: reports.length,
            itemBuilder: (context, index) {
              final report = reports[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    report['icon'] as IconData,
                    color: const Color(0xFF059669),
                  ),
                  title: Text(
                    report['title'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    Navigator.pop(context);
                    _showFormatSelectionDialog(report['action'] as String);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  void _showFormatSelectionDialog(String reportType) {
    final formats = [
      {'label': 'CSV (.csv)', 'value': 'csv', 'icon': Icons.description},
      {'label': 'PDF (.pdf)', 'value': 'pdf', 'icon': Icons.picture_as_pdf},
      {'label': 'Excel (.xlsx)', 'value': 'xlsx', 'icon': Icons.grid_on},
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.file_present, color: Color(0xFF059669)),
            SizedBox(width: 8),
            Text('Pilih Format File'),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: formats.length,
            itemBuilder: (context, index) {
              final format = formats[index];
              return Card(
                margin: const EdgeInsets.symmetric(vertical: 6),
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: ListTile(
                  leading: Icon(
                    format['icon'] as IconData,
                    color: const Color(0xFF059669),
                  ),
                  title: Text(
                    format['label'] as String,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    _performExport(reportType, format['value'] as String);
                  },
                ),
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal'),
          ),
        ],
      ),
    );
  }

  Future<void> _performExport(String reportType, String format) async {
    if (!mounted) return;

    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(
        content: SizedBox(
          height: 80,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Sedang mempersiapkan laporan...'),
            ],
          ),
        ),
      ),
    );

    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final user = auth.currentUser;
      final ownerId = user?.ownerId ?? user?.id ?? '';

      if (ownerId.isEmpty) {
        if (mounted) {
          Navigator.pop(context); // Close loading dialog
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Error: Owner ID tidak ditemukan')),
          );
        }
        return;
      }

      Map<String, dynamic> reportData = {};

      // Fetch data berdasarkan report type
      switch (reportType) {
        case 'available_products':
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ExportReportScreen(initialFormat: format, ownerId: ownerId)),
            );
          }
          return;
        case 'expired_products':
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ExportReportScreen(initialFormat: format, ownerId: ownerId, reportType: 'expired_products')),
            );
          }
          return;
        case 'delivery_orders':
          if (mounted) {
            Navigator.pop(context); // Close loading dialog
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => ExportReportScreen(ownerId: ownerId, reportType: 'delivery_orders')),
            );
          }
          return;
        case 'staff':
          reportData = await _controller.fetchStaffReport(ownerId);
          break;
        case 'suppliers':
          reportData = await _controller.fetchSuppliersReport(ownerId);
          break;
        case 'transactions':
          reportData = await _controller.fetchTransactionsReport(ownerId);
          break;
        case 'outgoing_items':
          reportData = await _controller.fetchOutgoingItemsReport(ownerId);
          break;
        case 'incoming_items':
          reportData = await _controller.fetchIncomingItemsReport(ownerId);
          break;
      }

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
      }

      if (reportData.isEmpty || reportData['type'] == 'Error') {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: ${reportData['error'] ?? 'Gagal mengambil data'}')),
          );
        }
        return;
      }

      // Export based on format
      String filePath = '';
      switch (format) {
        case 'csv':
          filePath = await _controller.exportToCSV(reportData);
          break;
        case 'pdf':
          filePath = await _controller.exportToPDF(reportData);
          break;
        case 'xlsx':
          filePath = await _controller.exportToXLSX(reportData);
          break;
      }

      if (mounted) {
        if (filePath.isNotEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Laporan berhasil diexport: $filePath'),
              duration: const Duration(seconds: 3),
              action: SnackBarAction(
                label: 'Bagikan',
                onPressed: () => _controller.shareFile(filePath),
              ),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Gagal menyimpan file')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }
}

// Top-level donut painter
class _DonutPainter extends CustomPainter {
  final List<double> segments;
  final List<Color> colors;

  _DonutPainter(this.segments, this.colors);

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = math.min(size.width, size.height) / 2.0;
    final strokeWidth = radius * 0.35;
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final total = segments.fold<double>(0, (p, e) => p + e);
    double startAngle = -math.pi / 2;
    for (var i = 0; i < segments.length; i++) {
      final seg = segments[i];
      final sweep = total <= 0 ? 0.0 : (seg / total) * 2 * math.pi;
      paint.color = colors[i % colors.length];
      canvas.drawArc(Rect.fromCircle(center: center, radius: radius - strokeWidth / 2), startAngle, sweep, false, paint);
      startAngle += sweep;
    }

    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius - strokeWidth - 2, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) {
    return oldDelegate.segments != segments || oldDelegate.colors != colors;
  }
}

// Widget untuk NotificationButton dengan badge
class _NotificationButtonWidget extends StatelessWidget {
  final VoidCallback onPressed;
  final String ownerId;

  const _NotificationButtonWidget({
    required this.onPressed,
    required this.ownerId,
  });

  @override
  Widget build(BuildContext context) {
    final notificationService = NotificationOwnerService();

    return StreamBuilder<int>(
      stream: _countUnreadNotificationsStream(ownerId, notificationService),
      builder: (context, snapshot) {
        final unreadCount = snapshot.data ?? 0;

        return Stack(
          alignment: Alignment.topRight,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_outlined, color: Colors.white),
              onPressed: onPressed,
            ),
            if (unreadCount > 0)
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.red.shade600,
                    shape: BoxShape.circle,
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                  child: Center(
                    child: Text(
                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        );
      },
    );
  }

  /// Stream yang memancarkan unread notification count
  Stream<int> _countUnreadNotificationsStream(
    String ownerId,
    NotificationOwnerService service,
  ) async* {
    while (true) {
      try {
        final count = await service.countUnreadNotifications(ownerId);
        yield count;
      } catch (e) {
        yield 0;
      }
      // Refresh setiap 5 detik
      await Future.delayed(const Duration(seconds: 5));
    }
  }
}