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
      onError: (error, handler) async {
        // 401: token suresi dolmus olabilir — oturumu yenileyip istegi
        // BIR kez tekrarla; yenileme de basarisizsa oturumu kapat
        // (router refreshListenable giris ekranina yonlendirir).
        final status = error.response?.statusCode;
        final retried = error.requestOptions.extra['authRetried'] == true;
        if (status == 401 && !retried) {
          try {
            final auth = Supabase.instance.client.auth;
            final refreshed = await auth.refreshSession();
            final token = refreshed.session?.accessToken;
            if (token != null) {
              final opts = error.requestOptions;
              opts.headers['Authorization'] = 'Bearer $token';
              opts.extra['authRetried'] = true;
              final response = await dio.fetch<dynamic>(opts);
              return handler.resolve(response);
            }
          } catch (_) {
            // yenileme basarisiz: oturum gercekten gecersiz
            await Supabase.instance.client.auth.signOut();
          }
        }
        handler.next(error);
      },
    ),
  );
  return dio;
}

/// DIP taramasi (match) dakikalarca surebilir; varsayilan 5 dk receive
/// timeout bu cagrida yetmez. Cagri bazinda genis timeout secenegi.
Options longReceiveOptions() =>
    Options(receiveTimeout: const Duration(minutes: 30));

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
          return 'Geçersiz istek: ${first['msg']}';
        }
      }
      return detail.toString();
    }
    return switch (error.type) {
      DioExceptionType.connectionTimeout ||
      DioExceptionType.connectionError =>
        'Sunucuya ulaşılamadı. API adresini ve ağı kontrol edin.',
      DioExceptionType.receiveTimeout ||
      DioExceptionType.sendTimeout =>
        'İstek zaman aşımına uğradı. Lütfen tekrar deneyin.',
      DioExceptionType.badResponse =>
        'Sunucu hatası (${error.response?.statusCode}). Lütfen tekrar deneyin.',
      _ => 'Beklenmeyen bir ağ hatası oluştu.',
    };
  }
  return 'Beklenmeyen bir hata oluştu.';
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
