class CustomerModel {
   final String id;
   final String ownerid;
   final String customer_id;
   final String nama_toko;
   final String nama_pemilik_toko;
   final String no_telepon_customer;
   final String alamat_toko;

   CustomerModel({
      required this.id,
      required this.ownerid,
      required this.customer_id,
      required this.nama_toko,
      required this.nama_pemilik_toko,
      required this.no_telepon_customer,
      required this.alamat_toko
   });

   factory CustomerModel.fromJson(Map data) {
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
      return CustomerModel(
         id: parsedId,
         ownerid: data['ownerid'],
         customer_id: data['customer_id'],
         nama_toko: data['nama_toko'],
         nama_pemilik_toko: data['nama_pemilik_toko'],
         no_telepon_customer: data['no_telepon_customer'],
         alamat_toko: data['alamat_toko']
      );
   }

   Map<String, dynamic> toJson() {
    return {
      'id': id,
      'ownerid': ownerid,
      'customer_id': customer_id,
      'nama_toko': nama_toko,
      'nama_pemilik_toko': nama_pemilik_toko,
      'no_telepon_customer': no_telepon_customer,
      'alamat_toko': alamat_toko
    };
  }
}
