import 'package:flutter/material.dart';
import '../../app.dart';
import 'AddProductScreen.dart';
import '../../goclaud/resetapi.dart'; /
import '../../goclaud/config.dart';
import '../../goclaud/product_model.dart'; 
import 'dart:convert';

class ManageProductsScreen extends StatefulWidget {
  final String userRole;
  const ManageProductsScreen({super.key, required this.userRole});

  // STATIC shared store (ValueNotifier) untuk menyimpan produk yang bisa diakses global
  static final ValueNotifier<List<Map<String, dynamic>>> store = ValueNotifier<List<Map<String, dynamic>>>(
    [
      {
        'id': 'PRD001',
        'name': 'Chitato',
        'code': 'CH001',
        'category': 'Makanan',
        'jenis': 'Snack',
        'has_image': false,
        'image_url': '',
        'last_updated': '18 Des 2024 10:30',
        'status': 'active',
      },
      {
        'id': 'PRD002',
        'name': 'Coca Cola',
        'code': 'CC002',
        'category': 'Minuman',
        'jenis': 'Minuman Ringan',
        'has_image': false,
        'image_url': '',
        'last_updated': '17 Des 2024 14:45',
        'status': 'active',
      },
    ],
  );

  // static helper untuk menambah / hapus agar file lain tidak mengutak-atik ValueNotifier langsung
  static void addProduct(Map<String, dynamic> p) {
    store.value = [p, ...store.value];
  }

  // ubah removeById supaya juga memanggil API (async)
  static Future<void> removeById(String id) async {
    // update lokal segera (optimistic)
    store.value = store.value.where((e) => e['id'] != id).toList();

    // coba hapus di server, jika perlu-tangani error (saat ini diabaikan)
    try {
      final svc = DataService();
      await svc.removeId(token, project, collection, appid, id);
    } catch (_) {
      // Jika gagal, bisa reload dari server nanti atau beri feedback
    }
  }

  // Tambahkan fungsi publik untuk format tanggal/waktu yanSg bisa dipakai oleh layar lain
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
          p['jenis'].toLowerCase().contains(query);
      final matchesCategory =
          _selectedCategory == 'Semua' || p['category'] == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();
  }

  void _navigateToAddProduct() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddProdukScreen(
          userRole: widget.userRole,
          onProductAdded: (p) => ManageProductsScreen.addProduct(p),
        ),
      ),
    );
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
              Navigator.pop(context); // tutup dialog segera
              await ManageProductsScreen.removeById(product['id']);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Produk berhasil dihapus!'), backgroundColor: Colors.green),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
  }

  // Tambahkan method untuk memuat produk dari server
  Future<void> _loadProductsFromServer() async {
    try {
      final svc = DataService();
      final resp = await svc.selectAll(token, project, collection, appid);

      // debug: tampilkan respons mentah di console untuk inspeksi
      // (hapus/komentari setelah masalah ditemukan)
      print('[goclaud.selectAll] raw resp: ${resp.runtimeType} -> $resp');

      if (resp == null) {
        return;
      }

      dynamic decoded;
      try {
        decoded = json.decode(resp.toString());
      } catch (e) {
        // tidak bisa decode JSON -> keluar
        print('[goclaud.selectAll] json.decode error: $e');
        return;
      }

      // kemungkinan bentuk respons:
      // 1) List (langsung array of objects)
      // 2) Map dengan field 'data' / 'result' / 'rows' / 'items' yang berisi list
      List<dynamic> listData = [];
      if (decoded is List) {
        listData = decoded;
      } else if (decoded is Map) {
        // coba beberapa kunci umum
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
          // jika tidak menemukan, ambil first value yang bertipe List
          final firstList = map.values.firstWhere(
            (v) => v is List,
            orElse: () => null,
          );
          if (firstList != null && firstList is List) {
            listData = firstList;
          }
        }
      }

      // debug: tampilkan ukuran list yang ditemukan
      print('[goclaud.selectAll] parsed list length: ${listData.length}');

      if (listData.isEmpty) {
        // tidak ada data di server; jika ingin sinkron penuh bisa kosongkan store:
        // ManageProductsScreen.store.value = [];
        return;
      }

      final List<Map<String, dynamic>> mapped = listData.map<Map<String, dynamic>>((dynamic item) {
        final Map<String, dynamic> data = Map<String, dynamic>.from(item as Map);
        final ProductModel pm = ProductModel.fromJson(data);

        return <String, dynamic>{
          'id': pm.id_product,
          'name': pm.nama_product,
          'code': pm.id_product,
          'category': pm.kategori_product.isNotEmpty ? pm.kategori_product : 'Umum',
          'jenis': pm.jenis_product,
          'has_image': pm.gambar_product.isNotEmpty,
          'image_url': pm.gambar_product,
          'last_updated': pm.tanggal_beli.isNotEmpty ? pm.tanggal_beli : ManageProductsScreen.formatCurrentDateTime(),
          'status': 'active',
        };
      }).toList();

      // update shared store dengan data server (replace) dan update UI
      ManageProductsScreen.store.value = mapped;
      if (mounted) {
        setState(() {
          _filterProducts();
        });
      }
    } catch (e, st) {
      print('[goclaud.selectAll] unexpected error: $e\n$st');
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
      ...products.map((p) => (p['category'] ?? '').toString()).where((s) => s.isNotEmpty).toSet().toList()
    ];

    return Scaffold(
      appBar: CustomAppBar(
        title: 'Kelola Produk',
        showBackButton: true,
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: _navigateToAddProduct, tooltip: 'Tambah Produk'),
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
                        suffixIcon: IconButton(icon: const Icon(Icons.clear), onPressed: ()=>_searchController.clear()),
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
                            Text('Tidak ada produk ditemukan', style: TextStyle(fontSize:16,color:Colors.grey[600])),
                            const SizedBox(height:8),
                            if(_searchController.text.isEmpty)
                              ElevatedButton(onPressed:_navigateToAddProduct, child: const Text('Tambah Produk Baru')),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _filteredProducts.length,
                        itemBuilder: (context,index){
                          final p = _filteredProducts[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(horizontal:12, vertical:6),
                            elevation:1,
                            child: InkWell(
                              onTap: ()=>_showDeleteConfirmation(p),
                              borderRadius: BorderRadius.circular(12),
                              child: ListTile(
                                contentPadding: const EdgeInsets.all(16),
                                leading: Container(
                                  width:60,height:60,
                                  decoration: BoxDecoration(
                                    color: p['has_image']?Colors.transparent:Colors.blue.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: p['has_image'] && p['image_url']!=null && p['image_url'].isNotEmpty
                                      ? Image.network(p['image_url'],fit:BoxFit.cover, errorBuilder:(c,e,s)=>_buildPlaceholderIcon(p))
                                      : _buildPlaceholderIcon(p),
                                ),
                                title: Text(p['name'], style: const TextStyle(fontWeight:FontWeight.bold,fontSize:16)),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('${p['code']} • ${p['category']}', style: TextStyle(color:Colors.grey[600], fontSize:13)),
                                    const SizedBox(height:4),
                                    Text('Update: ${p['last_updated']}', style: TextStyle(fontSize:11, color:Colors.grey[500])),
                                  ],
                                ),
                                trailing: PopupMenuButton(
                                  itemBuilder: (_)=>[
                                    const PopupMenuItem(value:'edit', child: Row(children:[Icon(Icons.edit,size:18), SizedBox(width:8), Text('Edit')])),
                                    const PopupMenuItem(value:'delete', child: Row(children:[Icon(Icons.delete,size:18,color:AppColors.danger), SizedBox(width:8), Text('Hapus', style:TextStyle(color:AppColors.danger))])),
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
