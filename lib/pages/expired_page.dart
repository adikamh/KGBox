import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ExpiredPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final bool loading;

  const ExpiredPage({super.key, required this.items, required this.loading});

  @override
  State<ExpiredPage> createState() => _ExpiredPageState();
}

class _ExpiredPageState extends State<ExpiredPage> {
  String _query = '';
  String _sortBy = 'tanggal';
  bool _showCriticalOnly = false;

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    
    List<Map<String, dynamic>> categorizedItems = widget.items.map((item) {
      final p = item['full'] as Map<String, dynamic>? ?? {};
      final nama = p['nama_product'] ?? p['nama'] ?? 'Tanpa Nama';
      final expString = item['expired_at']?.toString() ?? '';
      
      DateTime? expDate;
      int daysUntilExpiry = 999;
      String category = 'Lebih dari Seminggu';
      Color statusColor = Colors.green;
      String statusText = 'Aman';
      
      try {
        expDate = DateTime.parse(expString);
        daysUntilExpiry = expDate.difference(now).inDays;
        
        if (daysUntilExpiry < 0) {
          category = 'Sudah Lewat';
          statusColor = Colors.red[700]!;
          statusText = 'LEWAT';
        } else if (daysUntilExpiry == 0) {
          category = 'Hari Ini';
          statusColor = Colors.red[800]!;
          statusText = 'KRITIS';
        } else if (daysUntilExpiry == 1) {
          category = 'Besok';
          statusColor = Colors.orange[600]!;
          statusText = 'WASPADA';
        } else if (daysUntilExpiry <= 3) {
          category = '3 Hari Lagi';
          statusColor = Colors.orange[400]!;
          statusText = 'PERHATIAN';
        } else if (daysUntilExpiry <= 7) {
          category = 'Minggu Ini';
          statusColor = Colors.amber[700]!;
          statusText = 'SEGERA';
        } else if (daysUntilExpiry <= 14) {
          category = 'Minggu Depan';
          statusColor = Colors.blue[600]!;
          statusText = 'AWAS';
        } else {
          category = 'Lebih dari Seminggu';
          statusColor = Colors.green[600]!;
          statusText = 'AMAN';
        }
      } catch (e) {
        category = 'Tanggal Tidak Valid';
        statusColor = Colors.grey;
        statusText = 'TIDAK VALID';
      }
      
      return {
        ...item,
        'nama': nama,
        'exp_date': expDate,
        'days_until': daysUntilExpiry,
        'category': category,
        'status_color': statusColor,
        'status_text': statusText,
        'formatted_date': _formatDate(expString),
      };
    }).toList();

    List<Map<String, dynamic>> filteredItems = categorizedItems.where((item) {
      final searchTerm = _query.toLowerCase();
      final nama = item['nama'].toString().toLowerCase();
      final category = item['category'].toString().toLowerCase();
      
      return _query.isEmpty || nama.contains(searchTerm) || category.contains(searchTerm);
    }).toList();

    if (_showCriticalOnly) {
      filteredItems = filteredItems.where((item) {
        final days = item['days_until'] as int;
        return days <= 7 || days < 0;
      }).toList();
    }

    filteredItems.sort((a, b) {
      if (_sortBy == 'nama') {
        return a['nama'].compareTo(b['nama']);
      } else if (_sortBy == 'waktu') {
        return (a['days_until'] as int).compareTo(b['days_until'] as int);
      } else {
        final aDate = a['exp_date'];
        final bDate = b['exp_date'];
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      }
    });

    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in filteredItems) {
      final category = item['category'];
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }

    int criticalCount = categorizedItems.where((item) {
      final days = item['days_until'] as int;
      return days <= 3 || days < 0;
    }).length;

    int warningCount = categorizedItems.where((item) {
      final days = item['days_until'] as int;
      return days > 3 && days <= 7;
    }).length;

    int safeCount = categorizedItems.where((item) {
      final days = item['days_until'] as int;
      return days > 7;
    }).length;

    int expiredCount = categorizedItems.where((item) {
      final days = item['days_until'] as int;
      return days < 0;
    }).length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: widget.loading
          ? _buildLoadingState()
          : Column(
              children: [
                _buildHeader(context),
                if (categorizedItems.isNotEmpty) ...[
                  _buildStatsCards(
                    categorizedItems.length,
                    criticalCount,
                    warningCount,
                    safeCount,
                    expiredCount,
                  ),
                ],
                _buildListHeader(filteredItems.length, criticalCount),
                Expanded(
                  child: filteredItems.isEmpty
                      ? _buildEmptyState()
                      : _buildProductList(groupedItems),
                ),
              ],
            ),
      floatingActionButton: criticalCount > 0
          ? FloatingActionButton.extended(
              onPressed: () => _handleCriticalProducts(criticalCount),
              icon: const Icon(Icons.warning_rounded),
              label: Text('$criticalCount KRITIS'),
              backgroundColor: Colors.red[700],
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red[700]!, Colors.red[500]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      'Produk Kedaluwarsa',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.filter_list_rounded, color: Colors.white),
                    onPressed: () => _showFilterOptions(context),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 50,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Icon(Icons.search_rounded, color: Colors.red[700]),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Cari produk...',
                          border: InputBorder.none,
                          hintStyle: TextStyle(color: Colors.grey[400]),
                        ),
                        onChanged: (v) => setState(() => _query = v),
                      ),
                    ),
                    if (_query.isNotEmpty)
                      GestureDetector(
                        onTap: () => setState(() => _query = ''),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.close_rounded, size: 16, color: Colors.grey),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatsCards(int total, int critical, int warning, int safe, int expired) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          _buildSmallStatCard('Total', '$total', Icons.inventory_2_rounded, Colors.blue[600]!),
          _buildSmallStatCard('Kritis', '$critical', Icons.warning_rounded, Colors.red[600]!),
          _buildSmallStatCard('Peringatan', '$warning', Icons.warning_amber_rounded, Colors.orange[600]!),
          _buildSmallStatCard('Aman', '$safe', Icons.check_circle_rounded, Colors.green[600]!),
          _buildSmallStatCard('Lewat', '$expired', Icons.error_rounded, Colors.red[800]!),
        ],
      ),
    );
  }

  Widget _buildSmallStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      width: 65,
      height: 65,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(
              icon,
              size: 14,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 9,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListHeader(int count, int critical) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            _showCriticalOnly ? 'Produk Kritis' : 'Semua Produk',
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: Colors.black87,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.red[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$count produk',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(Map<String, List<Map<String, dynamic>>> groupedItems) {
    List<String> sortedCategories = groupedItems.keys.toList();
    sortedCategories.sort((a, b) {
      List<String> priorityOrder = [
        'Sudah Lewat',
        'Hari Ini',
        'Besok',
        '3 Hari Lagi',
        'Minggu Ini',
        'Minggu Depan',
        'Lebih dari Seminggu',
        'Tanggal Tidak Valid'
      ];
      int aIndex = priorityOrder.indexOf(a);
      int bIndex = priorityOrder.indexOf(b);
      return aIndex.compareTo(bIndex);
    });

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
      itemCount: sortedCategories.length,
      itemBuilder: (context, categoryIndex) {
        final category = sortedCategories[categoryIndex];
        final itemsInCategory = groupedItems[category]!;
        final categoryColor = _getCategoryColor(category);
        
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [categoryColor.withOpacity(0.1), categoryColor.withOpacity(0.05)],
                  ),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(16),
                    topRight: Radius.circular(16),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: categoryColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        category,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: categoryColor,
                          fontSize: 15,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: categoryColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${itemsInCategory.length}',
                        style: TextStyle(
                          color: categoryColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(12),
                itemCount: itemsInCategory.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, itemIndex) {
                  final item = itemsInCategory[itemIndex];
                  return _buildProductItem(item);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProductItem(Map<String, dynamic> item) {
    final nama = item['nama'];
    final formattedDate = item['formatted_date'];
    final daysUntil = item['days_until'] as int;
    final statusColor = item['status_color'] as Color;
    final statusText = item['status_text'] as String;
    
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showProductDetail(item),
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [statusColor.withOpacity(0.8), statusColor],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: statusColor.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  daysUntil < 0
                      ? Icons.error_rounded
                      : daysUntil == 0
                          ? Icons.warning_rounded
                          : daysUntil <= 3
                              ? Icons.warning_amber_rounded
                              : Icons.calendar_today_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nama,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.event_rounded, size: 14, color: Colors.grey[600]),
                        const SizedBox(width: 4),
                        Text(
                          formattedDate,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            daysUntil < 0
                                ? '${daysUntil.abs()} hari yang lalu'
                                : '$daysUntil hari lagi',
                            style: TextStyle(
                              fontSize: 13,
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: statusColor.withOpacity(0.3)),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: Colors.grey[400]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: Colors.red[700]),
          const SizedBox(height: 16),
          Text(
            'Memeriksa tanggal kedaluwarsa...',
            style: TextStyle(color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.green[50],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_outline,
                size: 64,
                color: Colors.green[300],
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Semua Produk Aman',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _query.isNotEmpty
                  ? 'Pencarian "$_query" tidak ditemukan'
                  : _showCriticalOnly
                      ? 'Tidak ada produk dalam kondisi kritis'
                      : 'Belum ada produk yang akan kedaluwarsa',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            if (_query.isNotEmpty || _showCriticalOnly)
              SizedBox(
                width: 160,
                height: 48,
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _query = '';
                      _showCriticalOnly = false;
                    });
                  },
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text(
                    'Reset Filter',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Sudah Lewat':
        return Colors.red[700]!;
      case 'Hari Ini':
        return Colors.red[800]!;
      case 'Besok':
        return Colors.orange[600]!;
      case '3 Hari Lagi':
        return Colors.orange[400]!;
      case 'Minggu Ini':
        return Colors.amber[700]!;
      case 'Minggu Depan':
        return Colors.blue[600]!;
      case 'Lebih dari Seminggu':
        return Colors.green[600]!;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMM yyyy').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showFilterOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSB) {
            return Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey[300],
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(Icons.filter_list_rounded, color: Colors.red[700]),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Filter & Urutkan',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Urutkan berdasarkan:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 8,
                    children: [
                      FilterChip(
                        label: const Text('Tanggal'),
                        selected: _sortBy == 'tanggal',
                        selectedColor: Colors.red[100],
                        checkmarkColor: Colors.red[700],
                        onSelected: (selected) {
                          setStateSB(() => _sortBy = 'tanggal');
                          setState(() => _sortBy = 'tanggal');
                        },
                      ),
                      FilterChip(
                        label: const Text('Nama'),
                        selected: _sortBy == 'nama',
                        selectedColor: Colors.red[100],
                        checkmarkColor: Colors.red[700],
                        onSelected: (selected) {
                          setStateSB(() => _sortBy = 'nama');
                          setState(() => _sortBy = 'nama');
                        },
                      ),
                      FilterChip(
                        label: const Text('Waktu'),
                        selected: _sortBy == 'waktu',
                        selectedColor: Colors.red[100],
                        checkmarkColor: Colors.red[700],
                        onSelected: (selected) {
                          setStateSB(() => _sortBy = 'waktu');
                          setState(() => _sortBy = 'waktu');
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  SwitchListTile(
                    title: const Text('Tampilkan yang kritis saja'),
                    subtitle: const Text('≤ 7 hari atau sudah lewat'),
                    value: _showCriticalOnly,
                    activeThumbColor: Colors.red[700],
                    onChanged: (value) {
                      setStateSB(() => _showCriticalOnly = value);
                      setState(() => _showCriticalOnly = value);
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Terapkan',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void _showProductDetail(Map<String, dynamic> item) {
    final nama = item['nama'];
    final formattedDate = item['formatted_date'];
    final daysUntil = item['days_until'] as int;
    final statusColor = item['status_color'] as Color;
    final statusText = item['status_text'] as String;
    
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [statusColor.withOpacity(0.8), statusColor],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: statusColor.withOpacity(0.3),
                          blurRadius: 15,
                          spreadRadius: 3,
                        ),
                      ],
                    ),
                    child: Icon(
                      daysUntil < 0 ? Icons.error_rounded : Icons.inventory_2_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nama,
                          style: const TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            statusText,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Colors.grey[50]!, Colors.grey[100]!],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Tanggal Kedaluwarsa',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        Text(
                          formattedDate,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                      ],
                    ),
                    const Divider(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Sisa Waktu',
                          style: TextStyle(color: Colors.grey[600], fontSize: 13),
                        ),
                        Text(
                          daysUntil < 0
                              ? '${daysUntil.abs()} hari yang lalu'
                              : '$daysUntil hari lagi',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: statusColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        // Simple reminder action (placeholder)
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Pengingat dikirim.')),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.orange[700],
                        side: BorderSide(color: Colors.orange[200]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.notifications_rounded, size: 18),
                      label: const Text('Ingatkan', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final productId = (item['product_id'] ?? (item['full'] is Map ? (item['full']['id_product'] ?? item['full']['id']) : null) ?? '').toString();
                        if (productId.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('ID produk tidak tersedia')));
                          return;
                        }

                        final confirm = await showDialog<bool>(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Konfirmasi Hapus'),
                            content: const Text('Hapus master produk ini dari database? Tindakan ini tidak dapat dibatalkan.'),
                            actions: [
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, false), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]), child: const Text('Batal', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),)),
                              ElevatedButton(onPressed: () => Navigator.pop(ctx, true), style: ElevatedButton.styleFrom(backgroundColor: Colors.red[700]), child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),)),
                            ],
                          ),
                        );

                        if (confirm != true) return;

                        try {
                          final firestore = FirebaseFirestore.instance;
                          // delete master product
                          await firestore.collection('products').doc(productId).delete();
                          // delete associated barcodes (if any)
                          try {
                            final q = await firestore.collection('product_barcodes').where('productId', isEqualTo: productId).get();
                            for (final d in q.docs) {
                              await firestore.collection('product_barcodes').doc(d.id).delete();
                            }
                          } catch (_) {}

                          // remove from local list to update UI
                          setState(() {
                            widget.items.removeWhere((e) => (e['product_id'] ?? '').toString() == productId);
                          });

                          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produk dihapus')));
                          Navigator.pop(context);
                        } catch (e) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      icon: const Icon(Icons.delete_rounded, color: Colors.white),
                      label: const Text('Hapus Produk', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red[700],
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'TUTUP',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _handleCriticalProducts(int count) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            children: [
              Icon(Icons.warning_rounded, color: Colors.red[700], size: 28),
              const SizedBox(width: 12),
              const Text('Produk Kritis!'),
            ],
          ),
          content: Text(
            'Ada $count produk yang akan segera atau sudah kedaluwarsa. Segera lakukan tindakan!',
            style: TextStyle(color: Colors.grey[700]),
          ),
          actions: [
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                setState(() => _showCriticalOnly = true);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Tinjau Sekarang'),
            ),
          ],
        );
      },
    );
  }
}