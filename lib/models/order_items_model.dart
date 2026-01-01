class OrderItemsModel {
   final String id;
   final String ownerid;
   final String order_id;
   final String id_product;
   final String jumlah_produk;
   final String list_barcode;
   final String harga;
   final String total_harga;

   OrderItemsModel({
      required this.id,
      required this.ownerid,
      required this.order_id,
      required this.id_product,
      required this.jumlah_produk,
      required this.list_barcode,
      required this.harga,
      required this.total_harga
   });

   factory OrderItemsModel.fromJson(Map data) {
      return OrderItemsModel(
         id: data['id'],
         ownerid: data['ownerid'],
         order_id: data['order_id'],
         id_product: data['id_product'],
         jumlah_produk: data['jumlah_produk'],
         list_barcode: data['list_barcode'],
         harga: data['harga'],
         total_harga: data['total_harga']
      );
   }
}