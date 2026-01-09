import 'dart:typed_data';
import 'dart:html' as html;

Future<String> saveFileBytes(Uint8List bytes, String filename, {String? mimeType}) async {
  final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
  final url = html.Url.createObjectUrlFromBlob(blob);
  final anchor = html.AnchorElement(href: url)
    ..setAttribute('download', filename)
    ..click();
  html.Url.revokeObjectUrl(url);
  return 'web:$filename';
}
