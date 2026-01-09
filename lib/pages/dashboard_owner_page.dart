// ignore_for_file: unused_local_variable, unused_element

import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:kgbox/pages/kelola_staff_page.dart';
import 'package:intl/intl.dart';
import 'package:kgbox/providers/auth_provider.dart';
import 'package:provider/provider.dart';
import '../screens/dashboard_owner_screen.dart';

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

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await _controller.loadCounts(context);
      setState(() {});
    });
  }

  @override
  void dispose() {
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
        IconButton(
          icon: const Icon(Icons.notifications_outlined, color: Colors.white),
          onPressed: () => _controller.showNotifications(context),
        ),
        PopupMenuButton<int>(
          icon: const Icon(Icons.exit_to_app, color: Colors.white),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          itemBuilder: (context) => [
            PopupMenuItem<int>(
              value: 0,
              child: Row(
                children: [
                  const Icon(Icons.badge, size: 20, color: Color(0xFF1E40AF)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Role: ${widget.userRole}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 1,
              child: Row(
                children: [
                  const Icon(Icons.settings, size: 20, color: Color(0xFF059669)),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Settings',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 2,
              child: Row(
                children: [
                  const Icon(Icons.logout, size: 20, color: Colors.red),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Logout',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
            height: 150,
            child: _buildMiniProductFlowChart(),
          ),
          const SizedBox(height: 8),
          _buildChartLegends(),
        ],
      ),
    );
  }

  Widget _buildMiniProductFlowChart() {
    final ownerId = _getCurrentOwnerId();
    debugPrint('_buildMiniProductFlowChart: calling fetchMonthlyTotals with ownerId=$ownerId');
    return FutureBuilder<Map<String, List<double>>>(
      future: _controller.fetchMonthlyTotals(ownerId),
      builder: (context, snap) {
        debugPrint('_buildMiniProductFlowChart: state=${snap.connectionState}, hasData=${snap.hasData}, hasError=${snap.hasError}');
        if (snap.hasError) {
          debugPrint('_buildMiniProductFlowChart error: ${snap.error}');
        }
        
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));
        }

        if (!snap.hasData) {
          return const Center(child: Text('Tidak ada data', style: TextStyle(fontSize: 12)));
        }

        final inTotals = snap.data!['in']!;
        final outTotals = snap.data!['out']!;
        final months = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];
        
        debugPrint('_buildMiniProductFlowChart: inTotals=$inTotals, outTotals=$outTotals');
        
        final maxVal = [...inTotals, ...outTotals].fold<double>(1, (prev, e) => e > prev ? e : prev);

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: List.generate(12, (i) {
            final inVal = inTotals[i];
            final outVal = outTotals[i];
            final inHeight = maxVal <= 0 ? 0.0 : (inVal / maxVal) * 60;
            final outHeight = maxVal <= 0 ? 0.0 : (outVal / maxVal) * 60;

            return Expanded(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final maxBarHeight = constraints.maxHeight - 18; // ruang label bulan

                  return Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      if (outHeight > 0)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: outHeight.clamp(0, maxBarHeight),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444),
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                          ),
                        ),
                      if (inHeight > 0)
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 2),
                          height: inHeight.clamp(0, maxBarHeight),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981),
                            borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                          ),
            ),
                      const SizedBox(height: 4),
                      SizedBox(
                        height: 14,
                        child: Text(
                          months[i],
                          style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  );
                },
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildChartLegends() {
    return FutureBuilder<Map<String, List<double>>>(
      future: _controller.fetchMonthlyTotals(_getCurrentOwnerId()),
      builder: (context, snap) {
        int totalIn = 0;
        int totalOut = 0;
        
        if (snap.hasData) {
          final inTotals = snap.data!['in']!;
          final outTotals = snap.data!['out']!;
          totalIn = inTotals.map((e) => e.toInt()).reduce((a, b) => a + b);
          totalOut = outTotals.map((e) => e.toInt()).reduce((a, b) => a + b);
        }

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
      },
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

    return FutureBuilder<List<dynamic>>(
      future: Future.wait([_controller.fetchFinancialMonthlyTotals(ownerId), _controller.fetchTotalCustomers(ownerId)]),
      builder: (context, snap) {
        if (snap.hasError) return Center(child: Text('Gagal memuat data: ${snap.error}'));
        if (!snap.hasData) return const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)));

        final data = (snap.data![0] ?? []) as List<Map<String, dynamic>>;
        final uniqueCustomers = (snap.data![1] ?? 0) as int;
        final maxTransactions = data.map((d) => (d['transactions'] as int)).fold<int>(1, (a, b) => b > a ? b : a);

        return Container(
          height: 250,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Column(
            children: [
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: data.map((item) {
                    final double heightRatio = (item['transactions'] as int) / (maxTransactions == 0 ? 1 : maxTransactions);
                    return Expanded(
                      child: Column(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Flexible(
                              fit: FlexFit.loose,
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 4),
                                child: FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    '${item['transactions']}',
                                    style: const TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 2),
                            height: (120 * heightRatio).clamp(8.0, 120.0),
                            decoration: BoxDecoration(
                              color: item['color'] as Color,
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                              gradient: LinearGradient(
                                begin: Alignment.topCenter,
                                end: Alignment.bottomCenter,
                                colors: [
                                  (item['color'] as Color).withOpacity(0.9),
                                  (item['color'] as Color).withOpacity(0.7),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            item['month'],
                            style: const TextStyle(
                              fontSize: 10,
                              color: Color(0xFF6B7280),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 12),
              Divider(color: const Color(0xFFE5E7EB).withOpacity(0.5)),
              const SizedBox(height: 8),
              _buildChartSummary(data, uniqueCustomers),
            ],
          ),
        );
      },
    );
  }

  Widget _buildChartSummary([List<Map<String, dynamic>>? data, int uniqueCustomers = 0]) {
    int total = 0;
    if (data != null) {
      total = data.map((d) => d['transactions'] as int).fold<int>(0, (a, b) => a + b);
    } else {
      total = _controller.totalTransactions;
    }
    final maxTx = uniqueCustomers > 0 ? uniqueCustomers : _controller.maxTransactions;

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
            Text(
              'Total Customer: $maxTx',
              style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data sedang diekspor...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implement actual export functionality
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