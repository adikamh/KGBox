import 'dart:typed_data';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

Future<String> saveBytes(Uint8List bytes, String filename) async {
  try {
    // Try to save to Downloads directory on Android
    final downloadDir = await _getDownloadDirectory();
    final file = File('${downloadDir.path}/$filename');
    
    // Create directory if it doesn't exist
    await downloadDir.create(recursive: true);
    await file.writeAsBytes(bytes);
    
    return file.path;
  } catch (e) {
    // Fallback to share dialog if saving to Downloads fails
    try {
      // Save to temp directory first
      final tempDir = await getTemporaryDirectory();
      final file = File('${tempDir.path}/$filename');
      await file.writeAsBytes(bytes);
      
      // Determine MIME type based on filename
      String mimeType = 'application/octet-stream';
      if (filename.endsWith('.csv')) {
        mimeType = 'text/csv';
      } else if (filename.endsWith('.pdf')) {
        mimeType = 'application/pdf';
      } else if (filename.endsWith('.xlsx')) {
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      }
      
      // Share the file
      await Share.shareXFiles(
        [XFile(file.path, mimeType: mimeType)],
        text: 'Laporan: $filename',
      );
      
      return file.path;
    } catch (shareError) {
      // Last resort: save to app documents directory
      final docDir = await getApplicationDocumentsDirectory();
      final file = File('${docDir.path}/$filename');
      await file.writeAsBytes(bytes);
      return file.path;
    }
  }
}

/// Get Downloads directory
Future<Directory> _getDownloadDirectory() async {
  final externalDir = await getExternalStorageDirectory();
  
  if (externalDir != null && Platform.isAndroid) {
    // On Android, navigate to Downloads folder
    // getExternalStorageDirectory() returns something like /storage/emulated/0/Android/data/com.example.app/files
    // We need to go to /storage/emulated/0/Download
    final downloadPath = externalDir.path.split('/Android/data')[0] + '/Download';
    final downloadDir = Directory(downloadPath);
    
    if (!await downloadDir.exists()) {
      try {
        await downloadDir.create(recursive: true);
      } catch (e) {
        // If we can't create Downloads, return the external storage directory
        return externalDir;
      }
    }
    
    return downloadDir;
  }
  
  // Fallback for iOS and other platforms
  return await getApplicationDocumentsDirectory();
}
