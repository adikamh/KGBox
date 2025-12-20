import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ExpiredPage extends StatefulWidget {
  final List<Map<String, dynamic>> items;
  final bool loading;

  const ExpiredPage({super.key, required this.items, required this.loading});

  @override
  State<ExpiredPage> createState() => _ExpiredPageState();
}

class _ExpiredPageState extends State<ExpiredPage> {
  String _query = '';
  String _sortBy = 'tanggal'; // 'tanggal', 'nama', 'waktu'
  bool _showCriticalOnly = false;
  
  // ignore: unused_field
  final Map<int, String> _timeCategories = {
    0: 'Hari Ini',
    1: 'Besok',
    2: '3 Hari Lagi',
    3: 'Minggu Ini',
    4: 'Minggu Depan',
    5: 'Lebih dari Seminggu'
  };

  @override
  Widget build(BuildContext context) {
    DateTime now = DateTime.now();
    
    // Kategorikan items berdasarkan waktu kedaluwarsa
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
          statusColor = Colors.red;
          statusText = 'LEWAT';
        } else if (daysUntilExpiry == 0) {
          category = 'Hari Ini';
          statusColor = Colors.red.shade800;
          statusText = 'KRITIS';
        } else if (daysUntilExpiry == 1) {
          category = 'Besok';
          statusColor = Colors.orange;
          statusText = 'WASPADA';
        } else if (daysUntilExpiry <= 3) {
          category = '3 Hari Lagi';
          statusColor = Colors.orange.shade300;
          statusText = 'PERHATIAN';
        } else if (daysUntilExpiry <= 7) {
          category = 'Minggu Ini';
          statusColor = Colors.yellow.shade700;
          statusText = 'SEGERA';
        } else if (daysUntilExpiry <= 14) {
          category = 'Minggu Depan';
          statusColor = Colors.blue;
          statusText = 'AWAS';
        } else {
          category = 'Lebih dari Seminggu';
          statusColor = Colors.green;
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

    // Filter berdasarkan pencarian
    List<Map<String, dynamic>> filteredItems = categorizedItems.where((item) {
      final searchTerm = _query.toLowerCase();
      final nama = item['nama'].toString().toLowerCase();
      final category = item['category'].toString().toLowerCase();
      
      return _query.isEmpty || 
             nama.contains(searchTerm) || 
             category.contains(searchTerm);
    }).toList();

    // Filter critical items only jika toggle aktif
    if (_showCriticalOnly) {
      filteredItems = filteredItems.where((item) {
        final days = item['days_until'] as int;
        return days <= 7 || days < 0;
      }).toList();
    }

    // Sorting
    filteredItems.sort((a, b) {
      if (_sortBy == 'nama') {
        return a['nama'].compareTo(b['nama']);
      } else if (_sortBy == 'waktu') {
        return (a['days_until'] as int).compareTo(b['days_until'] as int);
      } else {
        // default sort by tanggal
        final aDate = a['exp_date'];
        final bDate = b['exp_date'];
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return aDate.compareTo(bDate);
      }
    });

    // Kelompokkan berdasarkan kategori
    Map<String, List<Map<String, dynamic>>> groupedItems = {};
    for (var item in filteredItems) {
      final category = item['category'];
      if (!groupedItems.containsKey(category)) {
        groupedItems[category] = [];
      }
      groupedItems[category]!.add(item);
    }

    // Hitung statistik
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
      appBar: AppBar(
        title: const Text('Produk Kedaluwarsa'),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list),
            onPressed: () {
              showModalBottomSheet(
                context: context,
                builder: (context) {
                  return StatefulBuilder(
                    builder: (context, setStateSB) {
                      return Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Filter & Urutkan',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 20),
                            const Text('Urutkan berdasarkan:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              children: [
                                FilterChip(
                                  label: const Text('Tanggal'),
                                  selected: _sortBy == 'tanggal',
                                  onSelected: (selected) {
                                    setStateSB(() => _sortBy = 'tanggal');
                                    setState(() => _sortBy = 'tanggal');
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Nama'),
                                  selected: _sortBy == 'nama',
                                  onSelected: (selected) {
                                    setStateSB(() => _sortBy = 'nama');
                                    setState(() => _sortBy = 'nama');
                                  },
                                ),
                                FilterChip(
                                  label: const Text('Waktu'),
                                  selected: _sortBy == 'waktu',
                                  onSelected: (selected) {
                                    setStateSB(() => _sortBy = 'waktu');
                                    setState(() => _sortBy = 'waktu');
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            SwitchListTile(
                              title: const Text('Tampilkan yang kritis saja'),
                              subtitle: const Text('≤ 7 hari atau sudah lewat'),
                              value: _showCriticalOnly,
                              onChanged: (value) {
                                setStateSB(() => _showCriticalOnly = value);
                                setState(() => _showCriticalOnly = value);
                              },
                            ),
                            const SizedBox(height: 20),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Terapkan'),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                },
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(25),
              ),
              child: TextField(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.search, color: Colors.red),
                  hintText: 'Cari produk kadaluarsa...',
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  suffixIcon: _query.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, color: Colors.grey),
                          onPressed: () => setState(() => _query = ''),
                        )
                      : null,
                ),
                onChanged: (v) => setState(() => _query = v),
              ),
            ),
          ),

          // Statistik Cards
          if (!widget.loading && categorizedItems.isNotEmpty)
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  _buildStatCard(
                    context,
                    'Total',
                    categorizedItems.length.toString(),
                    Icons.inventory,
                    Colors.blue,
                  ),
                  _buildStatCard(
                    context,
                    'Kritis',
                    '$criticalCount',
                    Icons.warning,
                    Colors.red,
                    criticalCount > 0,
                  ),
                  _buildStatCard(
                    context,
                    'Peringatan',
                    '$warningCount',
                    Icons.warning_amber,
                    Colors.orange,
                    warningCount > 0,
                  ),
                  _buildStatCard(
                    context,
                    'Aman',
                    '$safeCount',
                    Icons.check_circle,
                    Colors.green,
                  ),
                  _buildStatCard(
                    context,
                    'Lewat',
                    '$expiredCount',
                    Icons.error,
                    Colors.red.shade800,
                    expiredCount > 0,
                  ),
                ],
              ),
            ),

          // Timeline Legend
          if (!widget.loading && filteredItems.isNotEmpty)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTimelineDot('Sudah Lewat', Colors.red),
                  _buildTimelineDot('Hari Ini', Colors.red.shade800),
                  _buildTimelineDot('≤3 Hari', Colors.orange),
                  _buildTimelineDot('≤1 Minggu', Colors.yellow.shade700),
                  _buildTimelineDot('Aman', Colors.green),
                ],
              ),
            ),

          // List Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _showCriticalOnly ? 'Produk Kritis ($criticalCount)' : 'Semua Produk',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.blueGrey,
                  ),
                ),
                Text(
                  '${filteredItems.length} ditemukan',
                  style: const TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),

          // Main Content
          Expanded(
            child: widget.loading
                ? _buildLoadingState()
                : filteredItems.isEmpty
                    ? _buildEmptyState()
                    : _buildProductList(groupedItems),
          ),
        ],
      ),
      floatingActionButton: criticalCount > 0
          ? FloatingActionButton.extended(
              onPressed: () {
                // Aksi untuk menangani produk kritis
                _handleCriticalProducts(criticalCount);
              },
              icon: const Icon(Icons.warning),
              label: Text('$criticalCount KRITIS'),
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            )
          : null,
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String value, IconData icon, Color color, [bool highlight = false]) {
    return Container(
      margin: const EdgeInsets.only(right: 8),
      child: Card(
        color: highlight ? color.withOpacity(0.1) : null,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 24),
              const SizedBox(height: 8),
              Text(
                value,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTimelineDot(String label, Color color) {
    return Column(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Memeriksa tanggal kedaluwarsa...'),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.calendar_today,
            size: 80,
            color: Colors.green.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Tidak ada produk kedaluwarsa',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey,
            ),
          ),
          if (_showCriticalOnly)
            const Padding(
              padding: EdgeInsets.only(top: 8.0),
              child: Text(
                'Semua produk dalam kondisi aman',
                style: TextStyle(color: Colors.green),
              ),
            ),
          if (_query.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'Pencarian: "$_query" tidak ditemukan',
                style: const TextStyle(color: Colors.grey),
              ),
            ),
          const SizedBox(height: 20),
          ElevatedButton.icon(
            onPressed: () {
              setState(() {
                _query = '';
                _showCriticalOnly = false;
              });
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reset Filter'),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(Map<String, List<Map<String, dynamic>>> groupedItems) {
    List<String> sortedCategories = groupedItems.keys.toList();
    sortedCategories.sort((a, b) {
      // Urutkan berdasarkan prioritas: sudah lewat -> hari ini -> besok -> dll
      List<String> priorityOrder = ['Sudah Lewat', 'Hari Ini', 'Besok', '3 Hari Lagi', 'Minggu Ini', 'Minggu Depan', 'Lebih dari Seminggu', 'Tanggal Tidak Valid'];
      int aIndex = priorityOrder.indexOf(a);
      int bIndex = priorityOrder.indexOf(b);
      return aIndex.compareTo(bIndex);
    });

    return ListView.builder(
      padding: const EdgeInsets.only(bottom: 80),
      itemCount: sortedCategories.length,
      itemBuilder: (context, categoryIndex) {
        final category = sortedCategories[categoryIndex]; // PERBAIKAN: sortedCategories bukan sortedCategory
        final itemsInCategory = groupedItems[category]!;
        
        Color categoryColor = _getCategoryColor(category);
        
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: BorderSide(color: categoryColor.withOpacity(0.2), width: 1),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category Header
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: categoryColor.withOpacity(0.1),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    topRight: Radius.circular(12),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
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
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Chip(
                      label: Text('${itemsInCategory.length} item'),
                      backgroundColor: categoryColor.withOpacity(0.2),
                      labelStyle: TextStyle(color: categoryColor),
                    ),
                  ],
                ),
              ),
              
              // Items List
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                padding: const EdgeInsets.all(8),
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
    
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: statusColor.withOpacity(0.1),
          border: Border.all(color: statusColor),
        ),
        child: Center(
          child: daysUntil < 0
              ? const Icon(Icons.error, color: Colors.red, size: 20)
              : daysUntil == 0
                ? const Icon(Icons.warning, color: Colors.red, size: 20)
                : daysUntil <= 3
                  ? const Icon(Icons.warning_amber, color: Colors.orange, size: 20)
                  : const Icon(Icons.calendar_today, color: Colors.blue, size: 20),
        ),
      ),
      title: Text(
        nama,
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 4),
          Text('Kadaluarsa: $formattedDate'),
          const SizedBox(height: 4),
          Row(
            children: [
              if (daysUntil < 0)
                Text(
                  '${daysUntil.abs()} hari yang lalu',
                  style: const TextStyle(color: Colors.red),
                )
              else
                Text(
                  '$daysUntil hari lagi',
                  style: TextStyle(
                    color: daysUntil <= 7 ? Colors.orange : Colors.green,
                  ),
                ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: statusColor),
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
      trailing: IconButton(
        icon: Icon(Icons.more_vert, color: Colors.grey.shade600),
        onPressed: () => _showProductActions(item),
      ),
      onTap: () => _showProductDetail(item),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'Sudah Lewat':
        return Colors.red;
      case 'Hari Ini':
        return Colors.red.shade800;
      case 'Besok':
      case '3 Hari Lagi':
        return Colors.orange;
      case 'Minggu Ini':
        return Colors.yellow.shade700;
      case 'Minggu Depan':
        return Colors.blue;
      case 'Lebih dari Seminggu':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _formatDate(String dateString) {
    try {
      final date = DateTime.parse(dateString);
      return DateFormat('dd MMMM yyyy', 'id_ID').format(date);
    } catch (e) {
      return dateString;
    }
  }

  void _showProductDetail(Map<String, dynamic> item) {
    final nama = item['nama'];
    final formattedDate = item['formatted_date'];
    final daysUntil = item['days_until'] as int;
    final statusColor = item['status_color'] as Color;
    
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: statusColor.withOpacity(0.1),
                      border: Border.all(color: statusColor, width: 2),
                    ),
                    child: Center(
                      child: daysUntil < 0
                          ? const Icon(Icons.error, color: Colors.red, size: 30)
                          : const Icon(Icons.inventory, color: Colors.blue, size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      nama,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Status:'),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              item['status_text'],
                              style: TextStyle(
                                color: statusColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tanggal Kedaluwarsa:'),
                          Text(
                            formattedDate,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const Divider(height: 20),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Sisa Waktu:'),
                          Text(
                            daysUntil < 0
                                ? '${daysUntil.abs()} hari yang lalu'
                                : '$daysUntil hari lagi',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: daysUntil <= 3 ? Colors.red : Colors.green,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Tindakan:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildActionButton(Icons.delete, 'Buang', Colors.red),
                  _buildActionButton(Icons.edit, 'Ubah Tanggal', Colors.blue),
                  _buildActionButton(Icons.notifications, 'Ingatkan', Colors.orange),
                ],
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'TUTUP',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton(IconData icon, String label, Color color) {
    return Column(
      children: [
        IconButton(
          icon: Icon(icon),
          color: color,
          onPressed: () {},
        ),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 12),
        ),
      ],
    );
  }

  void _showProductActions(Map<String, dynamic> item) {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.blue),
                title: const Text('Ubah Tanggal Kadaluwarsa'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.red),
                title: const Text('Buang Produk'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.notifications, color: Colors.orange),
                title: const Text('Atur Pengingat'),
                onTap: () {},
              ),
              ListTile(
                leading: const Icon(Icons.share, color: Colors.green),
                title: const Text('Bagikan Info'),
                onTap: () {},
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Batal'),
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
          title: const Row(
            children: [
              Icon(Icons.warning, color: Colors.red),
              SizedBox(width: 10),
              Text('Produk Kritis!'),
            ],
          ),
          content: Text('Ada $count produk yang akan segera atau sudah kedaluwarsa. Segera lakukan tindakan!'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Nanti'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // Aksi untuk menangani produk kritis
              },
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              child: const Text('Tinjau Sekarang'),
            ),
          ],
        );
      },
    );
  }
}