class SuppliersModel {
   final String id;
   final String ownerid;
   final String supplier_id;
   final String nama_perusahaan;
   final String nama_agen;
   final String no_telepon_agen;
   final String alamat_perusahaan;

   SuppliersModel({
      required this.id,
      required this.ownerid,
      required this.supplier_id,
      required this.nama_perusahaan,
      required this.nama_agen,
      required this.no_telepon_agen,
      required this.alamat_perusahaan
   });

   factory SuppliersModel.fromJson(Map data) {
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
      return SuppliersModel(
         id: parsedId,
         ownerid: data['ownerid'],
         supplier_id: data['supplier_id'],
         nama_perusahaan: data['nama_perusahaan'],
         nama_agen: data['nama_agen'],
         no_telepon_agen: data['no_telepon_agen'],
         alamat_perusahaan: data['alamat_perusahaan']
      );
   }
    Map<String, dynamic> toJson() {
        return {
          '_id': id,
          'ownerid': ownerid,
          'supplier_id': supplier_id,
          'nama_perusahaan': nama_perusahaan,
          'nama_agen': nama_agen,
          'no_telepon_agen': no_telepon_agen,
          'alamat_perusahaan': alamat_perusahaan
        };
    }
}