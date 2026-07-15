import 'dart:io';

import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';

class FileSaver {
  static const _channel = MethodChannel('kasir_app/file_saver');

  /// Simpan file ke folder Documents publik di hape (luar container app).
  ///
  /// - Android 10+ (API 29+): pakai MediaStore → Documents/ publik.
  /// - Android 9 dan di bawah: tulis langsung ke /storage/emulated/0/Documents.
/// - Platform lain / jika MediaStore gagal: fallback ke app documents dir
///   (app files/exports) supaya tetap tersimpan.
  ///
  /// Mengembalikan path absolut (file path) atau content uri (Android 10+).
  static Future<String> saveToDocuments({
    required String fileName,
    required List<int> bytes,
    String mimeType = 'application/octet-stream',
  }) async {
    if (Platform.isAndroid) {
      try {
        final path = await _channel.invokeMethod<String>('saveToDocuments', {
          'name': fileName,
          'bytes': bytes,
          'mimeType': mimeType,
        });
        if (path != null && path.isNotEmpty) return path;
      } on PlatformException catch (_) {
        // jatuh ke fallback di bawah
      }
    }
    final dir = await getApplicationDocumentsDirectory();
    final exportDir = Directory('${dir.path}/exports');
    if (!await exportDir.exists()) await exportDir.create(recursive: true);
    final file = File('${exportDir.path}/$fileName');
    await file.writeAsBytes(bytes);
    return file.path;
  }
}
