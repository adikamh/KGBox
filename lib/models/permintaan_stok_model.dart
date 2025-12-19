class PermintaanStokModel {
  final String id;
  final String ownerid;
  final String permintaan_id;
  final String supplier_id;
  final String nama_agen;
  final String tanggal_permintaan;
  final String status;
  final String total_harga;
  final String staff_id;
  final String catatan;
  final List<dynamic> items;
  final String tanggal_dikirim;
  final String tanggal_diterima;
  final String created_at;
  final String updated_at;

  PermintaanStokModel({
    required this.id,
    required this.ownerid,
    required this.permintaan_id,
    required this.supplier_id,
    required this.nama_agen,
    required this.tanggal_permintaan,
    required this.status,
    required this.total_harga,
    required this.staff_id,
    required this.catatan,
    required this.items,
    required this.tanggal_dikirim,
    required this.tanggal_diterima,
    required this.created_at,
    required this.updated_at,
  });

  factory PermintaanStokModel.fromJson(Map data) {
    return PermintaanStokModel(
      id: data['_id']?.toString() ?? '',
      ownerid: data['ownerid']?.toString() ?? '',
      permintaan_id: data['permintaan_id']?.toString() ?? '',
      supplier_id: data['supplier_id']?.toString() ?? '',
      nama_agen: data['nama_agen']?.toString() ?? '',
      tanggal_permintaan: data['tanggal_permintaan']?.toString() ?? '',
      status: data['status']?.toString() ?? 'pending',
      total_harga: data['total_harga']?.toString() ?? '0',
      staff_id: data['staff_id']?.toString() ?? '',
      catatan: data['catatan']?.toString() ?? '',
      items: data['items'] as List<dynamic>? ?? [],
      tanggal_dikirim: data['tanggal_dikirim']?.toString() ?? '',
      tanggal_diterima: data['tanggal_diterima']?.toString() ?? '',
      created_at: data['created_at']?.toString() ?? '',
      updated_at: data['updated_at']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'ownerid': ownerid,
      'permintaan_id': permintaan_id,
      'supplier_id': supplier_id,
      'nama_agen': nama_agen,
      'tanggal_permintaan': tanggal_permintaan,
      'status': status,
      'total_harga': total_harga,
      'staff_id': staff_id,
      'catatan': catatan,
      'items': items,
      'tanggal_dikirim': tanggal_dikirim,
      'tanggal_diterima': tanggal_diterima,
      'created_at': created_at,
      'updated_at': updated_at,
    };
  }
}