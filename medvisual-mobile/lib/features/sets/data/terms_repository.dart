import 'package:dio/dio.dart';

import '../../../core/api_client.dart';

/// Terim sozlugu uclari. Sonuc bellekte onbellege alinir (~736 terim).
class TermsRepository {
  TermsRepository(this._dio);

  final Dio _dio;
  List<String>? _cache;

  Future<List<String>> list() {
    final cached = _cache;
    if (cached != null) return Future.value(cached);
    return guardApi(() async {
      final res = await _dio.get<Map<String, dynamic>>('/terms');
      final terms = (res.data?['terms'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(growable: false);
      _cache = terms;
      return terms;
    });
  }

  /// Onceden yuklenmis terimler (yuklenmemisse bos).
  List<String> get cached => _cache ?? const [];
}
