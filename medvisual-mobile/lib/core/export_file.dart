import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

/// Disa aktarilan ikili dosya: ham baytlar + onerilen dosya adi.
class ExportFile {
  const ExportFile({required this.bytes, required this.filename});

  final List<int> bytes;
  final String filename;

  /// Baytlari gecici dizine yazar ve dosya yolunu doner (paylasim icin).
  Future<String> writeToTemp() async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsBytes(bytes, flush: true);
    return file.path;
  }
}

/// Content-Disposition basligindan dosya adini cikarir; yoksa [fallback].
String filenameFromResponse(Response<dynamic> res, {required String fallback}) {
  final disposition = res.headers.value('content-disposition');
  if (disposition != null) {
    final match = RegExp(r'filename\*?=(?:UTF-8'')?"?([^";]+)"?')
        .firstMatch(disposition);
    final name = match?.group(1)?.trim();
    if (name != null && name.isNotEmpty) return Uri.decodeFull(name);
  }
  return fallback;
}
