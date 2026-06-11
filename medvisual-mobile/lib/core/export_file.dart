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
    // NOT: raw tek-tirnakli string icine '' yazilamadigindan (Dart bitisik
    // iki literal olarak birlestirir) pattern cift tirnakli yazildi; aksi
    // halde RFC 5987 "UTF-8''ad" bicimindeki kesme isaretleri ada dahil olur.
    final match = RegExp("filename\\*?=(?:UTF-8'')?\"?([^\";]+)\"?")
        .firstMatch(disposition);
    var name = match?.group(1)?.trim();
    if (name != null) {
      name = name.replaceFirst(RegExp("^'+"), '');
      if (name.isNotEmpty) return Uri.decodeFull(name);
    }
  }
  return fallback;
}
