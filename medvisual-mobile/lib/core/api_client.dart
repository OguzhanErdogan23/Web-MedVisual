import 'package:dio/dio.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'config.dart';

/// API'den donen, kullaniciya gosterilebilir Turkce mesaj tasiyan hata.
class ApiException implements Exception {
  const ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Yetkili Dio istemcisi: her istege Supabase access token ekler.
/// Bazi uclar PDF sayfalarini tarar; bu yuzden uzun receive timeout kullanilir.
Dio buildApiClient() {
  final dio = Dio(
    BaseOptions(
      baseUrl: apiBaseUrl,
      connectTimeout: const Duration(seconds: 20),
      sendTimeout: const Duration(minutes: 5),
      receiveTimeout: const Duration(minutes: 5),
    ),
  );
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) {
        final token =
            Supabase.instance.client.auth.currentSession?.accessToken;
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
    ),
  );
  return dio;
}

/// Gecerli access token (gorsel URL'lerine `?token=` olarak eklenir;
/// `<img>`/Image.network basit kullanim icin baslik gonderemez).
String? currentAccessToken() =>
    Supabase.instance.client.auth.currentSession?.accessToken;

/// Kart gorsel adresini cozer: mutlak URL (Supabase Storage) aynen kalir,
/// goreli `/dip-images/...` yollarina API taban adresi + `?token=` eklenir.
String resolveImageUrl(String url) {
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  final token = currentAccessToken();
  final sep = url.contains('?') ? '&' : '?';
  return '$apiBaseUrl$url${token != null ? '${sep}token=$token' : ''}';
}

/// FastAPI `{"detail": ...}` govdesini okunabilir Turkce mesaja cevirir.
String readableApiError(Object error) {
  if (error is ApiException) return error.message;
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is String) return detail;
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) {
          return 'Gecersiz istek: ${first['msg']}';
        }
      }
      return detail.toString();
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.connectionError =>
        'Sunucuya ulasilamadi. API adresini ve agi kontrol edin.',
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'Istek zaman asimina ugradi. Lutfen tekrar deneyin.',
      DioExceptionType.badResponse =>
        'Sunucu hatasi (${error.response?.statusCode}). Lutfen tekrar deneyin.',
      _ => 'Beklenmeyen bir ag hatasi olustu.',
    };
  }
  return 'Beklenmeyen bir hata olustu.';
}

/// Repository cagrilarini sarar: tum hatalari tipli [ApiException]'a cevirir.
Future<T> guardApi<T>(Future<T> Function() run) async {
  try {
    return await run();
  } on ApiException {
    rethrow;
  } catch (e) {
    final status = e is DioException ? e.response?.statusCode : null;
    throw ApiException(readableApiError(e), statusCode: status);
  }
}
