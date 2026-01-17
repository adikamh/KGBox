// ignore_for_file: prefer_interpolation_to_compose_strings, non_constant_identifier_names

import 'package:http/http.dart' as http;
import 'dart:convert';

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
    String tanggal_expired,
    String ownerid,
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
        'tanggal_expired': tanggal_expired,
        'ownerid': ownerid,
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

  //ini isi collection insert di gocloud
  Future insertOne(
    String token,
    String project,
    String collection,
    String appid,
    Map<String, dynamic> data,
  ) async {
    final String uri = 'https://api.247go.app/v5/insert/';
    try {
      final body = Map<String, String>.fromEntries(
        data.entries.map((e) => MapEntry(e.key, e.value?.toString() ?? '')),
      );
      body.addAll({
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid,
      });

      print('insertOne -> POST $uri');
      print('  body: $body');

      final response = await http
          .post(Uri.parse(uri), body: body)
          .timeout(const Duration(seconds: 15));

      print('insertOne response: ${response.statusCode}');
      print('  body: ${response.body}');

      //ini nge parse json biar gampang di baca
      try {
        final parsed = json.decode(response.body);
        return parsed;
      } catch (_) {
        return response.body;
      }
    } catch (e) {
      print('insertOne error: $e');
      rethrow;
    }
  }

  //ini method update collection di gocloud
  Future<bool> updateOne(
    String token,
    String project,
    String collection,
    String appid,
    String id,
    Map<String, dynamic> updateData,
  ) async {
    final String basePath = 'https://api.247go.app/v5/update_id/';

    // Ini fungsi bantu untuk coba satu request
    Future<bool> attempt(
      Uri uri, {
      Map<String, String>? formBody,
      Map<String, dynamic>? jsonBody,
      String method = 'POST',
      Map<String, String>? headers,
    }) async {
      try {
        http.Response resp;
        if (method == 'POST') {
          if (jsonBody != null) {
            headers ??= {'Content-Type': 'application/json'};
            resp = await http
                .post(uri, headers: headers, body: jsonEncode(jsonBody))
                .timeout(const Duration(seconds: 15));
            print('attempt POST JSON -> ${uri.toString()}');
            print('  json body: $jsonBody');
          } else {
            resp = await http
                .post(uri, body: formBody)
                .timeout(const Duration(seconds: 15));
            print('attempt POST form -> ${uri.toString()}');
            print('  form body: $formBody');
          }
        } else if (method == 'PUT') {
          if (jsonBody != null) {
            headers ??= {'Content-Type': 'application/json'};
            resp = await http
                .put(uri, headers: headers, body: jsonEncode(jsonBody))
                .timeout(const Duration(seconds: 15));
            print('attempt PUT JSON -> ${uri.toString()}');
            print('  json body: $jsonBody');
          } else {
            resp = await http
                .put(uri, body: formBody)
                .timeout(const Duration(seconds: 15));
            print('attempt PUT form -> ${uri.toString()}');
            print('  form body: $formBody');
          }
        } else {
          //manggil GET sebagai fallback
          resp = await http.get(uri).timeout(const Duration(seconds: 15));
          print('attempt GET -> ${uri.toString()}');
        }

        print('  status: ${resp.statusCode}');
        print('  body: ${resp.body}');

        // interpretasi respons sebagai sukses atau gagal dengan body bukan http doang
        if (resp.statusCode == 200) {
          try {
            final parsed = jsonDecode(resp.body);
            if (parsed is Map && parsed.containsKey('status')) {
              final s = parsed['status'];
              if (s == '1' || s == 1 || s == true) return true;
              // kondisi kalau gagal
              print('  server returned status != 1 (${parsed['status']})');
              return false;
            }
          } catch (_) {
            //kalau bukan json lanjut ke cek teks
          }

          final low = resp.body.toLowerCase();
          if (low.contains('success') ||
              low.contains('sukses') ||
              low.contains('ok'))
            return true;
        }
        return false;
      } catch (e) {
        print('  attempt exception: $e');
      }
      return false;
    }

    // Build canonical form and json bodies

    final canonicalForm = Map<String, String>.fromEntries(
      updateData.entries.map((e) => MapEntry(e.key, e.value?.toString() ?? '')),
    );
    canonicalForm.addAll({
      'token': token,
      'project': project,
      'collection': collection,
      'appid': appid,
      'id': id,
      'id_product': id,
    });

    final canonicalJson = Map<String, dynamic>.from(
      updateData.map((k, v) => MapEntry(k, v?.toString() ?? '')),
    );
    canonicalJson.addAll({
      'token': token,
      'project': project,
      'collection': collection,
      'appid': appid,
      'id': id,
      'id_product': id,
    });

    // Variant list: try combinations in order of likely success
    final attempts = <Future<bool> Function()>[
      // 1) POST form to /update_id/{collection} with appid
      () => attempt(
        Uri.parse(basePath + collection),
        formBody: canonicalForm,
        method: 'POST',
      ),
      // 2) POST JSON to /update_id/{collection} with appid
      () => attempt(
        Uri.parse(basePath + collection),
        jsonBody: canonicalJson,
        method: 'POST',
      ),
      // 3) POST form to /update_id/{collection} without appid
      () {
        final form = Map<String, String>.from(canonicalForm);
        form.remove('appid');
        return attempt(
          Uri.parse(basePath + collection),
          formBody: form,
          method: 'POST',
        );
      },
      // 4) POST JSON to /update_id/{collection} without appid
      () {
        final j = Map<String, dynamic>.from(canonicalJson);
        j.remove('appid');
        return attempt(
          Uri.parse(basePath + collection),
          jsonBody: j,
          method: 'POST',
        );
      },
      // 5) POST form to /update_id (generic) with appid+collection in body
      () {
        final form = Map<String, String>.from(canonicalForm);
        return attempt(Uri.parse(basePath), formBody: form, method: 'POST');
      },
      // 6) POST JSON to /update_id (generic)
      () =>
          attempt(Uri.parse(basePath), jsonBody: canonicalJson, method: 'POST'),
      // 7) PUT form to /update_id/{collection} (some servers expect PUT)
      () => attempt(
        Uri.parse(basePath + collection),
        formBody: canonicalForm,
        method: 'PUT',
      ),
      // 8) PUT JSON to /update_id/{collection}
      () => attempt(
        Uri.parse(basePath + collection),
        jsonBody: canonicalJson,
        method: 'PUT',
      ),
      // 9) Try POST form but use id field name '_id' instead of 'id'
      () {
        final f = Map<String, String>.from(canonicalForm);
        f['_id'] = f['id']!;
        f.remove('id');
        return attempt(
          Uri.parse(basePath + collection),
          formBody: f,
          method: 'POST',
        );
      },
      // 10) Try POST json with id field name '_id'
      () {
        final j = Map<String, dynamic>.from(canonicalJson);
        j['_id'] = j['id'];
        j.remove('id');
        return attempt(
          Uri.parse(basePath + collection),
          jsonBody: j,
          method: 'POST',
        );
      },
    ];

    for (var i = 0; i < attempts.length; i++) {
      print('updateOne: attempt ${i + 1}/${attempts.length}');
      try {
        final ok = await attempts[i]();
        if (ok) {
          print('updateOne: succeeded on attempt ${i + 1}');
          return true;
        }
      } catch (e) {
        print('updateOne attempt ${i + 1} raised: $e');
      }
    }

    print('updateOne: all attempts failed');
    return false;
  }

  Future updateId(
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
    String id,
  ) async {
    // Use documented endpoint: POST /v5/update_id/{collection} (form-data)
    final String uri = 'https://api.247go.app/v5/update_id/' + collection;

    try {
      final body = {
        'update_field': update_field,
        'update_value': update_value,
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid,
        'id': id,
        'id_product': id,
      };

      print('Calling updateId -> $uri');
      print('  body: $body');

      final response = await http
          .post(Uri.parse(uri), body: body)
          .timeout(const Duration(seconds: 15));

      print('  updateId status: ${response.statusCode}');
      print('  updateId body: ${response.body}');

      bool respIndicatesSuccess(http.Response resp) {
        if (resp.statusCode != 200) return false;
        try {
          final parsed = jsonDecode(resp.body);
          if (parsed is Map && parsed.containsKey('status')) {
            final s = parsed['status'];
            if (s == '1' || s == 1 || s == true) return true;
            return false;
          }
        } catch (_) {}
        final low = resp.body.toLowerCase();
        if (low.contains('success') ||
            low.contains('sukses') ||
            low.contains('ok'))
          return true;
        return false;
      }

      if (respIndicatesSuccess(response)) return true;

      // If form request failed or returned error, try a set of variants automatically
      try {
        final variants = <Future<bool> Function()>[
          // JSON retry with same uri
          () async {
            final jsonBody = body; // already map
            final jsonResp = await http
                .post(
                  Uri.parse(uri),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(jsonBody),
                )
                .timeout(const Duration(seconds: 15));
            print('  updateId JSON retry status: ${jsonResp.statusCode}');
            print('  updateId JSON retry body: ${jsonResp.body}');
            return respIndicatesSuccess(jsonResp);
          },
          // Form without appid
          () async {
            final f = Map<String, String>.from(body);
            f.remove('appid');
            final r = await http
                .post(Uri.parse(uri), body: f)
                .timeout(const Duration(seconds: 15));
            print(
              '  updateId form-no-appid status: ${r.statusCode} body: ${r.body}',
            );
            return respIndicatesSuccess(r);
          },
          // JSON without appid
          () async {
            final f = Map<String, String>.from(body);
            f.remove('appid');
            final jr = await http
                .post(
                  Uri.parse(uri),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode(f),
                )
                .timeout(const Duration(seconds: 15));
            print(
              '  updateId json-no-appid status: ${jr.statusCode} body: ${jr.body}',
            );
            return respIndicatesSuccess(jr);
          },
          // Try generic endpoint without collection in path
          () async {
            final genericUri = Uri.parse('https://api.247go.app/v5/update_id');
            final r = await http
                .post(genericUri, body: body)
                .timeout(const Duration(seconds: 15));
            print(
              '  updateId generic POST status: ${r.statusCode} body: ${r.body}',
            );
            return respIndicatesSuccess(r);
          },
          // Try using _id instead of id
          () async {
            final f = Map<String, String>.from(body);
            f['_id'] = f['id']!;
            f.remove('id');
            final r = await http
                .post(Uri.parse(uri), body: f)
                .timeout(const Duration(seconds: 15));
            print(
              '  updateId _id variant status: ${r.statusCode} body: ${r.body}',
            );
            return respIndicatesSuccess(r);
          },
        ];

        for (var i = 0; i < variants.length; i++) {
          try {
            final ok = await variants[i]();
            if (ok) return true;
          } catch (e) {
            print('  updateId variant ${i + 1} exception: $e');
          }
        }
      } catch (e) {
        print('  updateId variants exception: $e');
      }

      return false;
    } catch (e) {
      print('  Exception updateId: $e');
      return false;
    }
  }
  // HAPUS method updateId yang ini (baris 37-61) karena duplikat

  Future selectAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

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

  Future selectId(
    String token,
    String project,
    String collection,
    String appid,
    String id,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_id/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/id/' +
        id;

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

  Future selectWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

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

  Future selectOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

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

  Future selectWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

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

  Future selectWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

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

  Future selectWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/select_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

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

  Future removeAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

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

  Future removeId(
    String token,
    String project,
    String collection,
    String appid,
    String id,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_id/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/id/' +
        id;

    http.Response? response;
    try {
      response = await http
          .delete(Uri.parse(uri))
          .timeout(const Duration(seconds: 15));
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
      final respGet = await http
          .get(Uri.parse(uri))
          .timeout(const Duration(seconds: 15));
      if (respGet.statusCode == 200) return true;
      // Log for debugging
      if (response != null)
        print(
          'removeId DELETE failed: ${response.statusCode} ${response.body}',
        );
      print('removeId GET fallback: ${respGet.statusCode} ${respGet.body}');
    } catch (e) {
      print('removeId GET fallback exception: $e');
    }

    // Additional fallback: call remove_where to delete by id field (some APIs accept this)
    try {
      print('removeId: trying remove_where fallback for id=$id');
      final rmWhere = await removeWhere(
        token,
        project,
        collection,
        appid,
        'id',
        id,
      );
      print('remove_where result (id): $rmWhere');
      if (rmWhere) return true;

      // Try removing by supplier-specific field names if id fallback didn't work
      final rmWhereSupplierId = await removeWhere(
        token,
        project,
        collection,
        appid,
        'supplier_id',
        id,
      );
      print('remove_where result (supplier_id): $rmWhereSupplierId');
      if (rmWhereSupplierId) return true;

      final rmWhereUnderscoreId = await removeWhere(
        token,
        project,
        collection,
        appid,
        '_id',
        id,
      );
      print('remove_where result (_id): $rmWhereUnderscoreId');
      if (rmWhereUnderscoreId) return true;
    } catch (e) {
      print('removeId remove_where fallback exception: $e');
    }

    // Additional POST-based fallback: try collection-specific remove endpoint
    try {
      final postUri = 'https://api.247go.app/v5/remove_id/' + collection;
      final postBody = {
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid,
        'id': id,
      };
      print('removeId: trying POST fallback -> $postUri with body: $postBody');
      final respPost = await http
          .post(Uri.parse(postUri), body: postBody)
          .timeout(const Duration(seconds: 15));
      print('removeId POST fallback: ${respPost.statusCode} ${respPost.body}');
      if (respPost.statusCode == 200) {
        final lower = respPost.body.toLowerCase();
        if (lower.contains('success') ||
            lower.contains('remove') ||
            lower.contains('deleted') ||
            lower.contains('1')) {
          return true;
        }
      }
    } catch (e) {
      print('removeId POST fallback exception: $e');
    }

    // Additional fallback: try POST to generic remove_id endpoint (no collection in path)
    try {
      final postUri = 'https://api.247go.app/v5/remove_id';
      final postBody = {
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid,
        'id': id,
      };
      print(
        'removeId: trying generic POST fallback -> $postUri with body: $postBody',
      );
      final respPost = await http
          .post(Uri.parse(postUri), body: postBody)
          .timeout(const Duration(seconds: 15));
      print(
        'removeId generic POST fallback: ${respPost.statusCode} ${respPost.body}',
      );
      if (respPost.statusCode == 200) {
        final lower = respPost.body.toLowerCase();
        if (lower.contains('success') ||
            lower.contains('remove') ||
            lower.contains('deleted') ||
            lower.contains('1')) {
          return true;
        }
      }
    } catch (e) {
      print('removeId generic POST fallback exception: $e');
    }

    // Try POST to remove_where collection endpoint as some servers accept form POST for remove_where
    try {
      final postUri = 'https://api.247go.app/v5/remove_where/' + collection;
      final postBody = {
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid,
        'where_field': 'supplier_id',
        'where_value': id,
      };
      print(
        'removeId: trying POST remove_where fallback -> $postUri with body: $postBody',
      );
      final respPost = await http
          .post(Uri.parse(postUri), body: postBody)
          .timeout(const Duration(seconds: 15));
      print(
        'removeId POST remove_where fallback: ${respPost.statusCode} ${respPost.body}',
      );
      if (respPost.statusCode == 200) {
        final lower = respPost.body.toLowerCase();
        if (lower.contains('success') ||
            lower.contains('remove') ||
            lower.contains('deleted') ||
            lower.contains('1')) {
          return true;
        }
      }
    } catch (e) {
      print('removeId POST remove_where fallback exception: $e');
    }

    return false;
  }

  Future removeWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

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

  Future removeOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

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

  Future removeWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

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

  Future removeWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

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

  Future removeWhereNotIn(
    String token,
    String project,
    String collection,
    String appid,
    String wnotin_field,
    String wnotin_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/remove_where_not_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wnotin_field/' +
        wnotin_field +
        '/wnotin_value/' +
        wnotin_value;

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

  Future updateAll(
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_all/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

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

  Future updateWhere(
    String where_field,
    String where_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'where_field': where_field,
          'where_value': where_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );
      print('updateWhere -> $uri');
      print(
        '  form body: {where_field: $where_field, where_value: $where_value, update_field: $update_field, update_value: $update_value}',
      );
      print('  status: ${response.statusCode}');
      print('  body: ${response.body}');

      if (response.statusCode == 200) {
        return true;
      }

      // Retry with JSON payload
      try {
        final jsonBody = jsonEncode({
          'where_field': where_field,
          'where_value': where_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        });
        final jsonResp = await http
            .put(
              Uri.parse(uri),
              headers: {'Content-Type': 'application/json'},
              body: jsonBody,
            )
            .timeout(const Duration(seconds: 15));
        print('updateWhere JSON retry -> $uri');
        print('  json body: $jsonBody');
        print('  status: ${jsonResp.statusCode}');
        print('  body: ${jsonResp.body}');
        return jsonResp.statusCode == 200;
      } catch (e) {
        print('updateWhere JSON retry error: $e');
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateOrWhere(
    String or_where_field,
    String or_where_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_or_where/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'or_where_field': or_where_field,
          'or_where_value': or_where_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhereLike(
    String wlike_field,
    String wlike_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where_like/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'wlike_field': wlike_field,
          'wlike_value': wlike_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future updateWhereIn(
    String win_field,
    String win_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where_in/';

    try {
      // Try several variants and log responses to discover server expectation
      Future<bool> tryVariant(
        Map<String, dynamic> body, {
        Map<String, String>? headers,
        String method = 'PUT',
        String? urlOverride,
      }) async {
        final target = Uri.parse(urlOverride ?? uri);
        try {
          http.Response resp;
          if (method == 'PUT') {
            if (headers != null &&
                headers['Content-Type'] == 'application/json') {
              resp = await http
                  .put(target, headers: headers, body: jsonEncode(body))
                  .timeout(const Duration(seconds: 15));
              print('updateWhereIn PUT JSON -> ${target.toString()}');
              print('  json body: $body');
            } else {
              // convert values to strings for form body
              final form = Map<String, String>.fromEntries(
                body.entries.map(
                  (e) => MapEntry(e.key, e.value?.toString() ?? ''),
                ),
              );
              resp = await http
                  .put(target, body: form)
                  .timeout(const Duration(seconds: 15));
              print('updateWhereIn PUT form -> ${target.toString()}');
              print('  form body: $form');
            }
          } else {
            // fallback to POST
            if (headers != null &&
                headers['Content-Type'] == 'application/json') {
              resp = await http
                  .post(target, headers: headers, body: jsonEncode(body))
                  .timeout(const Duration(seconds: 15));
              print('updateWhereIn POST JSON -> ${target.toString()}');
              print('  json body: $body');
            } else {
              final form = Map<String, String>.fromEntries(
                body.entries.map(
                  (e) => MapEntry(e.key, e.value?.toString() ?? ''),
                ),
              );
              resp = await http
                  .post(target, body: form)
                  .timeout(const Duration(seconds: 15));
              print('updateWhereIn POST form -> ${target.toString()}');
              print('  form body: $form');
            }
          }

          print('  status: ${resp.statusCode}');
          print('  body: ${resp.body}');
          // interpret success via body
          try {
            final parsed = jsonDecode(resp.body);
            if (parsed is Map && parsed.containsKey('status')) {
              final s = parsed['status'];
              if (s == '1' || s == 1 || s == true) return true;
              return false;
            }
          } catch (_) {}
          final low = resp.body.toLowerCase();
          if (low.contains('success') ||
              low.contains('sukses') ||
              low.contains('ok'))
            return true;
        } catch (e) {
          print('updateWhereIn variant exception: $e');
        }
        return false;
      }

      // Prepare variants: win_value as CSV, as JSON array string, as bracketed JSON, with/without appid, as POST
      final csv = win_value;
      final jsonArray = jsonEncode(
        win_value
            .split(',')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toList(),
      );
      // ignore: unused_local_variable
      final bracketed = jsonArray; // same

      final baseBody = {
        'win_field': win_field,
        'win_value': csv,
        'update_field': update_field,
        'update_value': update_value,
        'token': token,
        'project': project,
        'collection': collection,
        'appid': appid,
      };

      // Try PUT form with CSV
      if (await tryVariant(baseBody, method: 'PUT')) return true;

      // Try PUT JSON with win_value as JSON array
      final bodyJsonArray = Map<String, dynamic>.from(baseBody);
      bodyJsonArray['win_value'] = jsonArray;
      if (await tryVariant(
        bodyJsonArray,
        headers: {'Content-Type': 'application/json'},
        method: 'PUT',
      ))
        return true;

      // Try POST form (some servers expect POST)
      if (await tryVariant(baseBody, method: 'POST')) return true;

      // Try POST JSON
      if (await tryVariant(
        bodyJsonArray,
        headers: {'Content-Type': 'application/json'},
        method: 'POST',
      ))
        return true;

      // Try without appid
      final withoutAppid = Map<String, dynamic>.from(baseBody);
      withoutAppid.remove('appid');
      if (await tryVariant(withoutAppid, method: 'PUT')) return true;

      // Try generic endpoint without trailing slash
      if (await tryVariant(
        baseBody,
        method: 'PUT',
        urlOverride: 'https://api.247go.app/v5/update_where_in',
      ))
        return true;

      return false;
    } catch (e) {
      print('updateWhereIn exception: $e');
      return false;
    }
  }

  Future updateWhereNotIn(
    String wnotin_field,
    String wnotin_value,
    String update_field,
    String update_value,
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri = 'https://api.247go.app/v5/update_where_not_in/';

    try {
      final response = await http.put(
        Uri.parse(uri),
        body: {
          'wnotin_field': wnotin_field,
          'wnotin_value': wnotin_value,
          'update_field': update_field,
          'update_value': update_value,
          'token': token,
          'project': project,
          'collection': collection,
          'appid': appid,
        },
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }

  Future firstAll(
    String token,
    String project,
    String collection,
    String appid,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_all/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid;

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

  Future firstWhere(
    String token,
    String project,
    String collection,
    String appid,
    String where_field,
    String where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/where_field/' +
        where_field +
        '/where_value/' +
        where_value;

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

  Future firstOrWhere(
    String token,
    String project,
    String collection,
    String appid,
    String or_where_field,
    String or_where_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_or_where/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/or_where_field/' +
        or_where_field +
        '/or_where_value/' +
        or_where_value;

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

  Future firstWhereLike(
    String token,
    String project,
    String collection,
    String appid,
    String wlike_field,
    String wlike_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_where_like/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/wlike_field/' +
        wlike_field +
        '/wlike_value/' +
        wlike_value;

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

  Future firstWhereIn(
    String token,
    String project,
    String collection,
    String appid,
    String win_field,
    String win_value,
  ) async {
    String uri =
        'https://api.247go.app/v5/first_where_in/token/' +
        token +
        '/project/' +
        project +
        '/collection/' +
        collection +
        '/appid/' +
        appid +
        '/win_field/' +
        win_field +
        '/win_value/' +
        win_value;

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
