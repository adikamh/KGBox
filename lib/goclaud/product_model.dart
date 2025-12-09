class ProductModel {
   final String id;
   final String id_product;
   final String nama_product;
   final String kategori_product;
   final String jenis_product;
   final String gambar_product;
   final String tanggal_beli;
   final String harga_product;
   final String jumlah_produk;

   ProductModel({
      required this.id,
      required this.id_product,
      required this.nama_product,
      required this.kategori_product,
      required this.jenis_product,
      required this.gambar_product,
      required this.tanggal_beli,
      required this.harga_product,
      required this.jumlah_produk
   });

   factory ProductModel.fromJson(Map<String, dynamic> data) {
      return ProductModel(
         id: (data['_id'] ?? '').toString(),
         id_product: (data['id_product'] ?? '').toString(),
         nama_product: (data['nama_product'] ?? '').toString(),
         kategori_product: (data['kategori_product'] ?? '').toString(),
         jenis_product: (data['jenis_product'] ?? '').toString(),
         gambar_product: (data['gambar_product'] ?? '').toString(),
         tanggal_beli: (data['tanggal_beli'] ?? '').toString(),
         harga_product: (data['harga_product'] ?? '').toString(),
         jumlah_produk: (data['jumlah_produk'] ?? '').toString()
      );
   }
}