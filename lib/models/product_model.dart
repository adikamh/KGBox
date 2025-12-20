// product_model.dart
class ProductModel {
  final String id;
  final String id_product;
  final String nama_product;
  final String kategori_product;
  final String merek_product;
  final String tanggal_beli;
  final String harga_product;
  final String jumlah_produk;
  final String tanggal_expired;
  final String ownerid;

  ProductModel({
    required this.id,
    required this.id_product,
    required this.nama_product,
    required this.kategori_product,
    required this.merek_product,
    required this.tanggal_beli,
    required this.harga_product,
    required this.jumlah_produk,
    required this.tanggal_expired,
    this.ownerid = '',
  });

  factory ProductModel.fromJson(Map data) {
    // Normalize id: server may return 'id', '_id' or an object like {'\$oid': '...'}
    dynamic rawId = data['id'] ?? data['_id'] ?? '';
    String parsedId = '';
    if (rawId is Map) {
      if (rawId.containsKey('\$oid')) {
        parsedId = rawId['\$oid'].toString();
      } else if (rawId.containsKey(r'$oid')) parsedId = rawId[r'$oid'].toString();
      else parsedId = rawId.toString();
    } else {
      parsedId = rawId?.toString() ?? '';
    }
    return ProductModel(
      id: parsedId,
      id_product: data['id_product'] ?? '',
      nama_product: data['nama_product'] ?? '',
      kategori_product: data['kategori_product'] ?? '',
      merek_product: data['merek_product'] ?? '',
      tanggal_beli: data['tanggal_beli'] ?? '',
      harga_product: data['harga_product'] ?? '0',
      jumlah_produk: data['jumlah_produk'] ?? '0',
      tanggal_expired: data['tanggal_expired'] ?? '',
      ownerid: data['ownerid'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'id_product': id_product,
      'nama_product': nama_product,
      'kategori_product': kategori_product,
      'merek_product': merek_product,
      'tanggal_beli': tanggal_beli,
      'harga_product': harga_product,
      'jumlah_produk': jumlah_produk,
      'tanggal_expired': tanggal_expired,
      'ownerid': ownerid,
    };
  }
}