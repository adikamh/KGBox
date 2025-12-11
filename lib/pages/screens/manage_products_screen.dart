import 'package:flutter/material.dart';
import '../../app.dart';
import 'AddProductScreen.dart';
import 'DetailProdukScreen.dart';
import '../../goclaud/resetapi.dart';
import '../../goclaud/config.dart';
import '../../goclaud/product_model.dart';
import 'dart:convert';
import 'package:intl/intl.dart';

class ManageProductsScreen extends StatefulWidget {
  final String userRole;
  const ManageProductsScreen({super.key, required this.userRole});

  // STATIC shared store (ValueNotifier) untuk menyimpan produk
  static final ValueNotifier<List<Map<String, dynamic>>> store = ValueNotifier<List<Map<String, dynamic>>>(
    [
      {
        'id': 'PRD001',
        'name': 'Chitato',
        'code': 'CH001',
        'category': 'Makanan',
        'brand': 'Chitato',
        'price': '15000',
        'stock': '50',
        'last_updated': '18 Des 2024 10:30',
        'status': 'active',
      },
      {
        'id': 'PRD002',
        'name': 'Coca Cola',
        'code': 'CC002',
        'category': 'Minuman',
        'brand': 'Coca-Cola',
        'price': '8000',
        'stock': '100',
        'last_updated': '17 Des 2024 14:45',
        'status': 'active',
      },
    ],
  );

  // Helper untuk menambah produk
  static void addProduct(Map<String, dynamic> p) {
    store.value = [p, ...store.value];
  }

  // Helper untuk menghapus produk
  static Future<void> removeById(String id) async {
    // Optimistic update
    store.value = store.value.where((e) => e['id'] != id).toList();

    // Hapus dari server
    try {
      final svc = DataService();
      await svc.removeId(token, project, collection, appid, id);
    } catch (_) {
      // Jika gagal, bisa reload dari server nanti
    }
  }

  // Format tanggal
  static String formatCurrentDateTime() {
    final now = DateTime.now();
    const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
    return '${now.day} ${months[now.month - 1]} ${now.year} ${now.hour}:${now.minute.toString().padLeft(2,'0')}';
  }

  @override
  State<ManageProductsScreen> createState() => _ManageProductsScreenState();
}

class _ManageProductsScreenState extends State<ManageProductsScreen> {
  List<Map<String, dynamic>> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'Semua';

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(ManageProductsScreen.store.value);
    ManageProductsScreen.store.addListener(_onRepoChanged);
    _searchController.addListener(_filterProducts);
    // Load dari server saat layar dibuka
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadProductsFromServer());
  }

  @override
  void dispose() {
    ManageProductsScreen.store.removeListener(_onRepoChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onRepoChanged() {
    setState(() {
      _filterProducts();
    });
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    final all = ManageProductsScreen.store.value;
    _filteredProducts = all.where((p) {
      final matchesSearch = p['name'].toLowerCase().contains(query) ||
          p['code'].toLowerCase().contains(query) ||
          (p['brand']?.toString() ?? '').toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'Semua' || p['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _navigateToAddProduct() async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddProdukScreen(
          userRole: widget.userRole,
        ),
      ),
    );

    // Jika produk berhasil ditambahkan (result = true), refresh dari server
    if (result == true && mounted) {
      _loadProductsFromServer();
    }
  }

  void _showDeleteConfirmation(Map<String, dynamic> product) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Konfirmasi Hapus'),
        content: Text('Apakah Anda yakin ingin menghapus produk "${product['name']}"?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Batal')),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await ManageProductsScreen.removeById(product['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Produk berhasil dihapus!'), 
                    backgroundColor: Colors.green
                  ),
                );
                // Refresh dari server untuk sinkronisasi
                _loadProductsFromServer();
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Method untuk memuat produk dari server
  Future<void> _loadProductsFromServer() async {
    try {
      final svc = DataService();
      final resp = await svc.selectAll(token, project, collection, appid);

      print('[goclaud.selectAll] raw resp: $resp');

      if (resp == null) {
        return;
      }

      dynamic decoded;
      try {
        decoded = json.decode(resp.toString());
      } catch (e) {
        print('[goclaud.selectAll] json.decode error: $e');
        return;
      }

      List<dynamic> listData = [];
      if (decoded is List) {
        listData = decoded;
      } else if (decoded is Map) {
        final map = decoded as Map<String, dynamic>;
        if (map['data'] is List) {
          listData = map['data'] as List<dynamic>;
        } else if (map['result'] is List) {
          listData = map['result'] as List<dynamic>;
        } else if (map['rows'] is List) {
          listData = map['rows'] as List<dynamic>;
        } else if (map['items'] is List) {
          listData = map['items'] as List<dynamic>;
        } else {
          final firstList = map.values.firstWhere(
            (v) => v is List,
            orElse: () => null,
          );
          if (firstList != null && firstList is List) {
            listData = firstList;
          }
        }
      }

      print('[goclaud.selectAll] parsed list length: ${listData.length}');
      print('[goclaud.selectAll] parsed data: $listData'); // Tambahkan log ini

      if (listData.isEmpty) {
        ManageProductsScreen.store.value = [];
        return;
      }

      // Mapping data sesuai dengan ProductModel yang baru
      final List<Map<String, dynamic>> mapped = listData.map<Map<String, dynamic>>((dynamic item) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(item as Map);
        final ProductModel pm = ProductModel.fromJson(data);

        return <String, dynamic>{
          'id': pm.id_product,
          'name': pm.nama_product,
          'code': pm.id_product,
          'category': pm.kategori_product.isNotEmpty ? pm.kategori_product : 'Umum',
          'brand': pm.merek_product,
          'price': pm.harga_product,
          'stock': pm.jumlah_produk,
          'last_updated': pm.tanggal_beli.isNotEmpty ? 
              _formatDateTimeFromServer(pm.tanggal_beli) : 
              ManageProductsScreen.formatCurrentDateTime(),
          'status': 'active',
          // keep original/raw data so detail view can show all fields
          'raw': data,
        };
      }).toList();

      // Update shared store
      ManageProductsScreen.store.value = mapped;
      
      if (mounted) {
        setState(() {
          _filterProducts();
        });
      }
    } catch (e, st) {
      print('[goclaud.selectAll] error: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Gagal memuat data: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Helper untuk format tanggal dari server
  String _formatDateTimeFromServer(String dateTimeStr) {
    try {
      // Coba parse format dari server, misal: "2024-12-18 10:30:00"
      final parts = dateTimeStr.split(' ');
      if (parts.isNotEmpty) {
        final dateParts = parts[0].split('-');
        if (dateParts.length >= 3) {
          final day = int.parse(dateParts[2]);
          const months = ['Jan','Feb','Mar','Apr','Mei','Jun','Jul','Agu','Sep','Okt','Nov','Des'];
          final month = months[int.parse(dateParts[1]) - 1];
          final year = dateParts[0];
          
          if (parts.length >= 2) {
            final timeParts = parts[1].split(':');
            if (timeParts.length >= 2) {
              return '$day $month $year ${timeParts[0]}:${timeParts[1]}';
            }
          }
          return '$day $month $year';
        }
      }
      return dateTimeStr; // Return as-is jika parsing gagal
    } catch (e) {
      return dateTimeStr;
    }
  }

  Widget _buildPlaceholderIcon(Map<String,dynamic> product) => Center(
    child: Icon(
      product['category']=='Makanan'?Icons.fastfood:Icons.local_drink,
      color: product['category']=='Makanan'?Colors.orange:Colors.blue,
      size: 30,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> products = ManageProductsScreen.store.value;
    final List<String> categories = [
      'Semua',
      ...products.map((p) => (p['category'] ?? '').toString())
        .where((s) => s.isNotEmpty)
        .toSet()
        
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Kelola Produk',
        showBackButton: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadProductsFromServer,
            tooltip: 'Refresh Data',
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _navigateToAddProduct,
            tooltip: 'Tambah Produk'
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Card(
              elevation: 2,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Cari produk...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.clear), 
                          onPressed: () {
                            _searchController.clear();
                            _filterProducts();
                          }
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: categories.map((c) => Padding(
                          padding: const EdgeInsets.only(right:8),
                          child: FilterChip(
                            label: Text(c),
                            selected: _selectedCategory==c,
                            onSelected: (s) => setState(() {
                              _selectedCategory = s?c:'Semua';
                              _filterProducts();
                            }),
                          ),
                        )).toList(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height:16),
            Expanded(
              child: Card(
                elevation:2,
                child: _filteredProducts.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.inventory_2_outlined, size:60, color: Colors.grey[400]),
                            const SizedBox(height:16),
                            Text(
                              _searchController.text.isEmpty 
                                ? 'Belum ada produk' 
                                : 'Tidak ada produk ditemukan',
                              style: TextStyle(fontSize:16, color:Colors.grey[600])
                            ),
                            const SizedBox(height:8),
                            if(_searchController.text.isEmpty)
                              ElevatedButton(
                                onPressed:_navigateToAddProduct, 
                                child: const Text('Tambah Produk Baru')
                              ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context,index){
                          final p = _filteredProducts[index];
                          final price = int.tryParse(p['price'] ?? '0') ?? 0;
                          final stock = int.tryParse(p['stock'] ?? '0') ?? 0;
                          
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal:12, vertical:6),
                            elevation:1,
                            child: InkWell(
                              onTap: () {
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => DetailProdukScreen(product: p),
                                  ),
                                );
                              },
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width:60,height:60,
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: _buildPlaceholderIcon(p),
                                ),
                                title: Text(
                                  p['name'], 
                                  style: const TextStyle(fontWeight:FontWeight.bold, fontSize:16)
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${p['code']} • ${p['category']} • ${p['brand']}',
                                      style: TextStyle(color:Colors.grey[600], fontSize:13)
                                    ),
                                    const SizedBox(height:4),
                                    Text(
                                      'Rp ${NumberFormat("#,###").format(price)} • Stok: $stock',
                                      style: TextStyle(fontSize:13, color:Colors.blue[700])
                                    ),
                                    const SizedBox(height:4),
                                    Text(
                                      'Update: ${p['last_updated']}', 
                                      style: TextStyle(fontSize:11, color:Colors.grey[500])
                                    ),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (_)=>[
                                    const PopupMenuItem(
                                      value:'delete', 
                                      child: Row(
                                        children:[
                                          Icon(Icons.delete,size:18,color:AppColors.danger), 
                                          SizedBox(width:8), 
                                          Text('Hapus', style:TextStyle(color:AppColors.danger))
                                        ]
                                      )
                                    ),
                                  ],
                                  onSelected: (v){
                                    if(v=='delete') _showDeleteConfirmation(p);
                                  },
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
