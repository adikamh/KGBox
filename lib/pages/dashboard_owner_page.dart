import 'package:flutter/material.dart';
import 'package:kgbox/pages/kelola_staff_page.dart';
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
                  Text('Role: ${widget.userRole}'),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 1,
              child: const Row(
                children: [
                  Icon(Icons.settings, size: 20, color: Color(0xFF059669)),
                  SizedBox(width: 8),
                  Text('Settings'),
                ],
              ),
            ),
            PopupMenuItem<int>(
              value: 2,
              child: const Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout'),
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
                  'Diagram Produk Masuk/Keluar',
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
    final data = _controller.monthlyProductFlow;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: data.map((item) {
        final double inRatio = (item['in'] as num) / 500.0;
        final double outRatio = (item['out'] as num) / 500.0;
        return Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 60 * outRatio.clamp(0.05, 1.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(2)),
                ),
              ),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 2),
                height: 60 * inRatio.clamp(0.05, 1.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.9),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(2)),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                item['month'],
                style: const TextStyle(fontSize: 10, color: Color(0xFF6B7280)),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildChartLegends() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _buildChartLegendItem(
          const Color(0xFF10B981),
          'Masuk (${_controller.totalProductIn} unit)',
        ),
        const SizedBox(width: 16),
        _buildChartLegendItem(
          const Color(0xFFEF4444),
          'Keluar (${_controller.totalProductOut} unit)',
        ),
      ],
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
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Jumlah Transaksi Bulanan',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            SizedBox(height: 4),
            Text(
              'Januari - Desember 2024',
              style: TextStyle(
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
    final data = _controller.monthlyTransactions;
    final maxTransactions = _controller.maxTransactions;

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
              children: data.map((data) {
                final double heightRatio = (data['transactions'] as num) / maxTransactions;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(bottom: 4),
                        child: Text(
                          '${data['transactions']}',
                          style: const TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF6B7280),
                          ),
                        ),
                      ),
                      Container(
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        height: (120 * heightRatio).clamp(8.0, 120.0),
                        decoration: BoxDecoration(
                          color: data['color'] as Color,
                          borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              (data['color'] as Color).withOpacity(0.9),
                              (data['color'] as Color).withOpacity(0.7),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        data['month'],
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
          _buildChartSummary(),
        ],
      ),
    );
  }

  Widget _buildChartSummary() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Total: ${_controller.totalTransactions}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
        Text(
          'Max: ${_controller.maxTransactions}',
          style: const TextStyle(fontSize: 12, color: Color(0xFF6B7280)),
        ),
      ],
    );
  }

  // Dialog methods
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
                _buildDialogHeader(context),
                const SizedBox(height: 16),
                _buildDetailedChart(),
                const SizedBox(height: 20),
                _buildSummaryCards(),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDialogHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text(
          'Diagram Produk Masuk/Keluar',
          style: TextStyle(
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
    final data = _controller.monthlyProductFlow;
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: data.map((item) {
          final double inRatio = (item['in'] as num) / 500.0;
          final double outRatio = (item['out'] as num) / 500.0;
          return Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  margin: const EdgeInsets.only(bottom: 2),
                  child: Text(
                    '${item['in']}',
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF10B981),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: (150 * outRatio).clamp(8.0, 150.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFFEF4444).withOpacity(0.9),
                        const Color(0xFFEF4444).withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${item['out']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: (150 * inRatio).clamp(8.0, 150.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(4)),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        const Color(0xFF10B981).withOpacity(0.9),
                        const Color(0xFF10B981).withOpacity(0.7),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '${item['in']}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  item['month'],
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF6B7280),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCards() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildProductSummaryCard(
            'Total Masuk',
            '${_controller.totalProductIn} unit',
            Icons.arrow_downward_rounded,
            const Color(0xFF10B981),
          ),
          _buildProductSummaryCard(
            'Total Keluar',
            '${_controller.totalProductOut} unit',
            Icons.arrow_upward_rounded,
            const Color(0xFFEF4444),
          ),
          _buildProductSummaryCard(
            'Sisa Stok',
            '${_controller.remainingStock} unit',
            Icons.inventory_2_rounded,
            const Color(0xFF3B82F6),
          ),
        ],
      ),
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Data sedang diekspor...'),
        duration: Duration(seconds: 2),
      ),
    );
    // TODO: Implement actual export functionality
  }
}