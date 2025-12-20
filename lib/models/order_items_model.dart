class OrderItemsModel {
   final String id;
   final String ownerid;
   final String order_id;
   final String id_product;
   final String jumlah_produk;
   final String harga_satu_pack;
   final String subtotal;

   OrderItemsModel({
      required this.id,
      required this.ownerid,
      required this.order_id,
      required this.id_product,
      required this.jumlah_produk,
      required this.harga_satu_pack,
      required this.subtotal
   });

   factory OrderItemsModel.fromJson(Map data) {
    dynamic rawId = data['id'] ?? data['_id'] ?? '';
    String parsedId = '';
    if (rawId is Map) {
      if (rawId.containsKey('\$oid')) parsedId = rawId['\$oid'].toString();
      else if (rawId.containsKey(r'$oid')) parsedId = rawId[r'$oid'].toString();
      else parsedId = rawId.toString();
    } else {
      parsedId = rawId?.toString() ?? '';
    }
      return OrderItemsModel(
         id: parsedId,
         ownerid: data['ownerid'],
         order_id: data['order_id'],
         id_product: data['id_product'],
         jumlah_produk: data['jumlah_produk'],
         harga_satu_pack: data['harga_satu_pack'],
         subtotal: data['subtotal']
      );
   }

    Map<String, dynamic> toJson() {
        return {
          '_id': id,
          'ownerid': ownerid,
          'order_id': order_id,
          'id_product': id_product,
          'jumlah_produk': jumlah_produk,
          'harga_satu_pack': harga_satu_pack,
          'subtotal': subtotal
        };
    }
}