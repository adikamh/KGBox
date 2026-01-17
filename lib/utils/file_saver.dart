import 'dart:typed_data';

// pintu masuk platform-specific
import 'file_saver_io.dart'
    if (dart.library.html) 'file_saver_web.dart'
    as impl;

Future<String> saveBytes(Uint8List bytes, String filename) =>
    impl.saveBytes(bytes, filename);
