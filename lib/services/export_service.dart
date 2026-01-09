import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';

// Conditional import: web vs io implementation
import 'export_impl_io.dart' if (dart.library.html) 'export_impl_web.dart' as _impl;

/// Export helper used by controllers. Provides cross-platform saving/downloading
/// of files. Use `saveText` for textual content (CSV) and `saveBytes` for
/// binary formats (PDF/XLSX).
class ExportService {
  /// Save a text file (e.g. CSV) and return the saved path or web indicator.
  static Future<String> saveText(String filename, String content, {String? mimeType}) async {
    final bytes = Uint8List.fromList(utf8.encode(content));
    return await _impl.saveFileBytes(bytes, filename, mimeType: mimeType ?? 'text/plain');
  }

  /// Save raw bytes (PDF/XLSX). Returns saved path or web indicator.
  static Future<String> saveBytes(String filename, Uint8List bytes, {String? mimeType}) async {
    return await _impl.saveFileBytes(bytes, filename, mimeType: mimeType ?? 'application/octet-stream');
  }
}
