import 'dart:async';

import 'package:flutter/material.dart';
import '../screens/dashboard_staff_screen.dart';

class DashboardStaffPage extends StatefulWidget {
  final String userRole;
  
  const DashboardStaffPage({
    super.key,
    required this.userRole,
  });

  @override
  State<DashboardStaffPage> createState() => _DashboardStaffPageState();
}

class _DashboardStaffPageState extends State<DashboardStaffPage> with WidgetsBindingObserver {
  final DashboardStaffScreen _controller = DashboardStaffScreen();
  int _selectedBottomIndex = 0;
  Timer? _refreshTimer;
  bool _isRefreshing = false;
  late DateTime _lastAppResumeTime;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _initializeData();
    _startAutoRefreshTimer();
    _lastAppResumeTime = DateTime.now();
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    if (state == AppLifecycleState.resumed) {
      // App kembali aktif, refresh data jika sudah lebih dari 1 menit
      final now = DateTime.now();
      if (now.difference(_lastAppResumeTime) > const Duration(minutes: 1)) {
        _refreshData();
      }
      _lastAppResumeTime = now;
    }
  }

  void _startAutoRefreshTimer() {
    // Refresh setiap 5 menit
    _refreshTimer = Timer.periodic(const Duration(minutes: 5), (timer) {
      if (mounted) {
        _refreshData();
      }
    });
  }

  Future<void> _initializeData() async {
    // Run refresh after first frame so context is available for ownerId lookups
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!mounted) return;
      setState(() => _isRefreshing = true);
      try {
        await _controller.refreshAll(context);
      } catch (e) {
        debugPrint('Error initializing data: $e');
      } finally {
        if (mounted) setState(() => _isRefreshing = false);
      }
    });
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;
    
    setState(() => _isRefreshing = true);
    try {
      await _controller.smartRefresh(context);
    } catch (e) {
      debugPrint('Error refreshing data: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDarkMode = theme.brightness == Brightness.dark;

    return Theme(
      data: theme.copyWith(
        colorScheme: theme.colorScheme.copyWith(
          primary: const Color(0xFF2965C0),
        ),
        appBarTheme: theme.appBarTheme.copyWith(
          backgroundColor: const Color(0xFF2965C0),
        ),
      ),
      child: Scaffold(
        appBar: _buildAppBar(context),
        body: _buildBody(context, isDarkMode),
        bottomNavigationBar: _buildBottomNavigationBar(),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(BuildContext context) {
    return AppBar(
      title: const Text('Dashboard Staff'),
      automaticallyImplyLeading: false,
      foregroundColor: Colors.white,
      flexibleSpace: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Color.fromARGB(255, 52, 133, 255),
              Color(0xFF2965C0),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
      ),
      actions: [
        if (_isRefreshing)
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          )
        else
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _refreshData(),
            tooltip: 'Refresh',
          ),
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () => _controller.navigateToNotifications(context),
        ),
        PopupMenuButton(
          icon: const Icon(Icons.exit_to_app),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
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
              child: const Row(
                children: [
                  Icon(Icons.logout, size: 20, color: Colors.red),
                  SizedBox(width: 8),
                  Text('Logout'),
                ],
              ),
              onTap: () => _controller.logout(context),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBody(BuildContext context, bool isDarkMode) {
    return Container(
      color: isDarkMode ? const Color(0xFF1A1A1A) : Colors.white,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildDatePill(),
                    const SizedBox(height: 12),
                    _buildProdukKeluarCard(),
                    const SizedBox(height: 12),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await _refreshData();
                        },
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(),
                          child: _buildStatistikProduk(context, isDarkMode),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDatePill() {
    final today = DateTime.now();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_today_rounded,
            size: 14,
            color: Color(0xFF6B7280),
          ),
          const SizedBox(width: 6),
          Text(
            '${today.day} ${_controller.getMonthName(today.month)} ${today.year}',
            style: const TextStyle(
              fontSize: 12,
              color: Colors.black,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (_isRefreshing) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildProdukKeluarCard() {
    final totalQty = _controller.getTotalQuantity();
    
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF2962FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Produk Keluar',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: () => _refreshData(),
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Icon(
                            Icons.refresh,
                            size: 14,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Hari Ini',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    transitionBuilder: (child, animation) {
                      return ScaleTransition(
                        scale: animation,
                        child: child,
                      );
                    },
                    child: Text(
                      '$totalQty',
                      key: ValueKey<int>(totalQty),
                      style: const TextStyle(
                        fontSize: 40,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${_controller.pengirimanCount} Transaksi',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.inventory_2_rounded,
                size: 44,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatistikProduk(BuildContext context, bool isDarkMode) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDarkMode ? 0.3 : 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
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
                  color: const Color(0xFF2965C0),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Statistik Produk',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                'Updated: ${TimeOfDay.now().format(context)}',
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _buildStatGrid(context),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context) {
    return GridView.count(
      crossAxisCount: 3,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 14,
      crossAxisSpacing: 12,
      childAspectRatio: 0.85,
      children: [
        _buildStatCard(
          icon: Icons.warning_amber_rounded,
          value: _controller.lowStockCount.toString(),
          label: 'Sisa\nproduk',
          color: const Color(0xFFEF5350),
          onPressed: () => Navigator.pushNamed(context, '/stok_produk'),
        ),
        _buildStatCard(
          icon: Icons.trending_up_rounded,
          value: _controller.bestSellerCount.toString(),
          label: 'Terlaris',
          color: const Color(0xFF66BB6A),
          onPressed: () => Navigator.pushNamed(context, '/bestseller'),
        ),
        _buildStatCard(
          icon: Icons.event_rounded,
          value: _controller.expiredCount.toString(),
          label: 'Kadaluarsa',
          color: const Color(0xFFFFCA28),
          onPressed: () => Navigator.pushNamed(context, '/expired'),
        ),
        _buildStatCard(
          icon: Icons.bar_chart_rounded,
          value: _controller.supplierCount.toString(),
          label: 'Suplier',
          color: const Color(0xFF42A5F5),
          onPressed: () => Navigator.pushNamed(context, '/supplier'),
        ),
        _buildStatCard(
          icon: Icons.local_shipping_rounded,
          value: _controller.pengirimanCount.toString(),
          label: 'Pengiriman',
          color: const Color(0xFFFF7043),
          onPressed: () => Navigator.pushNamed(context, '/pengiriman'),
        ),
        _buildStatCard(
          icon: Icons.note_add_rounded,
          value: _controller.getTotalQuantity().toString(),
          label: 'Produk\nKeluar',
          color: const Color.fromARGB(255, 111, 111, 111),
          onPressed: () {
            _controller.navigateToProductOut(context);
            // Refresh data setelah kembali dari catat barang keluar
            Future.delayed(const Duration(seconds: 2), () {
              if (mounted) _refreshData();
            });
          },
        ),
      ],
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    VoidCallback? onPressed,
  }) {
    final isDarkMode = Theme.of(context).brightness == Brightness.dark;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          decoration: BoxDecoration(
            color: isDarkMode ? const Color(0xFF2A2A2A) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: color.withOpacity(0.2),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(isDarkMode ? 0.15 : 0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          padding: const EdgeInsets.symmetric(
            vertical: 6,
            horizontal: 6,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              if (value.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    child: Text(
                      value,
                      key: ValueKey<String>(value),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                ),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 9,
                  color: isDarkMode ? Colors.grey[300] : Colors.grey[700],
                  fontWeight: FontWeight.w600,
                  height: 1.0,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 20,
            vertical: 12,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _buildBottomNavItem(
                icon: Icons.add_circle_outline,
                label: 'Tambah Produk',
                index: 0,
                onTap: () async {
                  _controller.navigateToAddProduct(
                    context,
                    widget.userRole,
                  );
                  // Refresh data setelah kembali dari add product
                  await Future.delayed(const Duration(seconds: 2));
                  if (mounted) _refreshData();
                },
              ),
              _buildCenterScanButton(),
              _buildBottomNavItem(
                icon: Icons.visibility_outlined,
                label: 'Lihat Produk',
                index: 1,
                isBlue: true,
                onTap: () => _controller.navigateToViewProducts(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCenterScanButton() {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      child: Material(
        elevation: 8,
        borderRadius: BorderRadius.circular(30),
        color: const Color.fromARGB(255, 41, 101, 192),
        child: InkWell(
          onTap: () => _controller.navigateToBarcodeScanner(context),
          borderRadius: BorderRadius.circular(30),
          child: Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(30),
            ),
            child: const Icon(
              Icons.barcode_reader,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavItem({
    required IconData icon,
    required String label,
    required int index,
    required VoidCallback onTap,
    bool isBlue = false,
  }) {
    final isSelected = _selectedBottomIndex == index;
    final color = isBlue ? const Color.fromARGB(255, 41, 101, 192) : 
                  (isSelected ? const Color.fromARGB(255, 41, 101, 192) : Colors.grey);
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: color,
              size: 26,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: color,
                fontWeight: isBlue || isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}