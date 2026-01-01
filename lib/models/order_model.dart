class OrderModel {
   final String id;
   final String ownerid;
   final String id_product;
   final String customor_id;
   final String tanggal_order;
   final String total_harga;
   final String id_staff;
   final String order_id;

   OrderModel({
      required this.id,
      required this.ownerid,
      required this.id_product,
      required this.customor_id,
      required this.tanggal_order,
      required this.total_harga,
      required this.id_staff,
      required this.order_id
   });
    
   factory OrderModel.fromJson(Map data) {
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
      return OrderModel(
         id: parsedId,
         ownerid: data['ownerid'],
         id_product: data['id_product'],
         customor_id: data['customor_id'],
         tanggal_order: data['tanggal_order'],
         total_harga: data['total_harga'],
         id_staff: data['id_staff'],
         order_id: data['order_id']
      );
   }

    Map<String, dynamic> toJson() {
        return {
          '_id': id,
          'ownerid': ownerid,
          'id_product': id_product,
          'customor_id': customor_id,
          'tanggal_order': tanggal_order,
          'total_harga': total_harga,
          'id_staff': id_staff,
          'order_id': order_id
        };
    }
}

