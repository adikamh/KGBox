import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveFileBytes(Uint8List bytes, String filename, {String? mimeType}) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/$filename');
  await file.create(recursive: true);
  await file.writeAsBytes(bytes);
  return file.path;
}
