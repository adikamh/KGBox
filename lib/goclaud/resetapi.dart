// ignore_for_file: prefer_interpolation_to_compose_strings, non_constant_identifier_names

import 'package:http/http.dart' as http;

class DataService {
   Future insertProduct(
      String appid,
      String id_product,
      String nama_product,
      String kategori_product,
      String merek_product,
      String tanggal_beli,
      String harga_product,
      String jumlah_produk,
   ) async {
      String uri = 'https://api.247go.app/v5/insert/';

      try {
         final body = {
            'token': '692d4cc817f27e9e52858cf8',
            'project': 'kgbox',
            'collection': 'product',
            'appid': appid,
            'id_product': id_product,
            'nama_product': nama_product,
            'kategori_product': kategori_product,
            'merek_product': merek_product,
            'tanggal_beli': tanggal_beli,
            'harga_product': harga_product,
            'jumlah_produk': jumlah_produk,
         };

         print('Mengirim data ke API: $body');
         final response = await http.post(Uri.parse(uri), body: body);

         print('Respons dari API: ${response.statusCode} - ${response.body}');
         if (response.statusCode == 200) {
            return response.body;
         } else {
            throw Exception('Failed to insert product: ${response.body}');
         }
      } catch (e) {
         print('Error saat mengirim data ke API: $e');
         throw Exception('Error: $e');
      }
   }

   Future updateId(String update_field, String update_value, String token, 
         String project, String collection, String appid, String id) async {
      // Use documented endpoint: POST /v5/update_id/product (form-data)
      final String uri = 'https://api.247go.app/v5/update_id/product';

      try {
         final body = {
               'update_field': update_field,
               'update_value': update_value,
               'token': token,
               'project': project,
               'collection': collection,
               'appid': appid,
               'id': id
         };

         print('Calling updateId -> $uri');
         print('  body: $body');

         final response = await http.post(Uri.parse(uri), body: body).timeout(const Duration(seconds: 15));

         print('  updateId status: ${response.statusCode}');
         print('  updateId body: ${response.body}');

         if (response.statusCode == 200) {
            final lower = response.body.toLowerCase();
            if (lower.contains('error') || lower.contains('failed')) {
               print('  updateId returned error in body');
               return false;
            }
            return true;
         } else {
            return false;
         }
      } catch (e) {
         print('  Exception updateId: $e');
         return false;
      }
   }
   // HAPUS method updateId yang ini (baris 37-61) karena duplikat
   
   Future selectAll(String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/select_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectId(String token, String project, String collection, String appid, String id) async {
      String uri = 'https://api.247go.app/v5/select_id/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/id/' + id;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
      String uri = 'https://api.247go.app/v5/select_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
      String uri = 'https://api.247go.app/v5/select_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
      String uri = 'https://api.247go.app/v5/select_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
      String uri = 'https://api.247go.app/v5/select_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future selectWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
      String uri = 'https://api.247go.app/v5/select_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future removeAll(String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/remove_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future removeId(String token, String project, String collection, String appid, String id) async {
      String uri = 'https://api.247go.app/v5/remove_id/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/id/' + id;

         http.Response? response;
         try {
            response = await http.delete(Uri.parse(uri)).timeout(const Duration(seconds: 15));
         } catch (e) {
            // Capture delete exception but continue to fallbacks
            print('removeId DELETE exception: $e');
            response = null;
         }

         // If DELETE returned 200 treat as success
         if (response != null && response.statusCode == 200) {
            return true;
         }

         // Fallback: some servers expect GET for this endpoint — try GET and treat 200 as success
         try {
            final respGet = await http.get(Uri.parse(uri)).timeout(const Duration(seconds: 15));
            if (respGet.statusCode == 200) return true;
            // Log for debugging
            if (response != null) print('removeId DELETE failed: ${response.statusCode} ${response.body}');
            print('removeId GET fallback: ${respGet.statusCode} ${respGet.body}');
         } catch (e) {
            print('removeId GET fallback exception: $e');
         }

         // Additional fallback: call remove_where to delete by id field (some APIs accept this)
         try {
            print('removeId: trying remove_where fallback for id=$id');
            final rmWhere = await removeWhere(token, project, collection, appid, 'id', id);
            print('remove_where result: $rmWhere');
            if (rmWhere) return true;
         } catch (e) {
            print('removeId remove_where fallback exception: $e');
         }

         // Additional POST-based fallback: some APIs accept form POST to /v5/remove_id/product
         try {
            final postUri = 'https://api.247go.app/v5/remove_id/product';
            final postBody = {
              'token': token,
              'project': project,
              'collection': collection,
              'appid': appid,
              'id': id,
            };
            print('removeId: trying POST fallback -> $postUri with body: $postBody');
            final respPost = await http.post(Uri.parse(postUri), body: postBody).timeout(const Duration(seconds: 15));
            print('removeId POST fallback: ${respPost.statusCode} ${respPost.body}');
            if (respPost.statusCode == 200) {
              final lower = respPost.body.toLowerCase();
              if (lower.contains('success') || lower.contains('remove') || lower.contains('deleted') || lower.contains('1')) {
                return true;
              }
            }
         } catch (e) {
            print('removeId POST fallback exception: $e');
         }

         return false;
   }

   Future removeWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
      String uri = 'https://api.247go.app/v5/remove_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future removeOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
      String uri = 'https://api.247go.app/v5/remove_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future removeWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
      String uri = 'https://api.247go.app/v5/remove_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future removeWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
      String uri = 'https://api.247go.app/v5/remove_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future removeWhereNotIn(String token, String project, String collection, String appid, String wnotin_field, String wnotin_value) async {
      String uri = 'https://api.247go.app/v5/remove_where_not_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wnotin_field/' + wnotin_field + '/wnotin_value/' + wnotin_value;

      try {
         final response = await http.delete(Uri.parse(uri));

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         // Print error here
         return false;
      }
   }

   Future updateAll(String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_all/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   // Method updateId sudah di atas (line 37)

   Future updateWhere(String where_field, String where_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_where/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'where_field': where_field,
             'where_value': where_value,
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   Future updateOrWhere(String or_where_field, String or_where_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_or_where/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'or_where_field': or_where_field,
             'or_where_value': or_where_value,
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   Future updateWhereLike(String wlike_field, String wlike_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_where_like/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'wlike_field': wlike_field,
             'wlike_value': wlike_value,
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   Future updateWhereIn(String win_field, String win_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_where_in/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'win_field': win_field,
             'win_value': win_value,
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   Future updateWhereNotIn(String wnotin_field, String wnotin_value, String update_field, String update_value, String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/update_where_not_in/';

      try {
         final response = await http.put(Uri.parse(uri),body: {
             'wnotin_field': wnotin_field,
             'wnotin_value': wnotin_value,
             'update_field': update_field,
             'update_value': update_value,
             'token': token,
             'project': project,
             'collection': collection,
             'appid': appid
         });

         if (response.statusCode == 200) {
            return true;
         } else {
            return false;
         }
      } catch (e) {
         return false;
      }
   }

   Future firstAll(String token, String project, String collection, String appid) async {
      String uri = 'https://api.247go.app/v5/first_all/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future firstWhere(String token, String project, String collection, String appid, String where_field, String where_value) async {
      String uri = 'https://api.247go.app/v5/first_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/where_field/' + where_field + '/where_value/' + where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future firstOrWhere(String token, String project, String collection, String appid, String or_where_field, String or_where_value) async {
      String uri = 'https://api.247go.app/v5/first_or_where/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/or_where_field/' + or_where_field + '/or_where_value/' + or_where_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future firstWhereLike(String token, String project, String collection, String appid, String wlike_field, String wlike_value) async {
      String uri = 'https://api.247go.app/v5/first_where_like/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/wlike_field/' + wlike_field + '/wlike_value/' + wlike_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }

   Future firstWhereIn(String token, String project, String collection, String appid, String win_field, String win_value) async {
      String uri = 'https://api.247go.app/v5/first_where_in/token/' + token + '/project/' + project + '/collection/' + collection + '/appid/' + appid + '/win_field/' + win_field + '/win_value/' + win_value;

      try {
         final response = await http.get(Uri.parse(uri));

         if (response.statusCode == 200) {
            return response.body;
         } else {
            // Return an empty array
            return '[]';
         }
      } catch (e) {
         // Print error here
         return '[]';
      }
   }
}