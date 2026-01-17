import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> saveFileBytes(Uint8List bytes, String filename, {String? mimeType}) async {
  try {
    // Try to save to Downloads directory on Android/iOS
    final directory = await _getDownloadDirectory();
    final file = File('${directory.path}/$filename');
    await file.create(recursive: true);
    await file.writeAsBytes(bytes);
    
    return file.path;
  } catch (e) {
    // Fallback to share dialog if saving fails
    try {
      // Save to temp directory first for sharing
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        text: 'Laporan: $filename',
      );
      
      return file.path;
    } catch (shareError) {
      // Last resort: save to temp directory
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.create(recursive: true);
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }
}

/// Get Downloads directory for saving files
Future<Directory> _getDownloadDirectory() async {
  final directory = await getExternalStorageDirectory();
  if (directory != null) {
    // On Android, use Downloads folder
    final downloadPath = Directory('${directory.path.split('/Android')[0]}/Download');
    if (!await downloadPath.exists()) {
      await downloadPath.create(recursive: true);
    }
    return downloadPath;
  }
  // Fallback for iOS and other platforms
  return await getApplicationDocumentsDirectory();
}
