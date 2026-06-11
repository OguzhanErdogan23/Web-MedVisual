import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/export_file.dart';
import '../../../core/offline_cache.dart';
import '../domain/quiz.dart';

/// Quiz uclari (uretim documents repository'sindedir).
class QuizzesRepository {
  QuizzesRepository(this._dio);

  final Dio _dio;

  Future<List<Quiz>> list() async {
    final data = await cachedJson('quizzes', () => guardApi(() async {
          final res = await _dio.get<Map<String, dynamic>>('/quizzes');
          return res.data ?? const <String, dynamic>{};
        }));
    final items =
        (data['quizzes'] as List? ?? const []).cast<Map<String, dynamic>>();
    return items.map(Quiz.fromJson).toList(growable: false);
  }

  /// Quiz + sorulari. Cevrimdisi: daha once acilan quiz cache'ten doner.
  Future<Quiz> getById(String id) async {
    final data = await cachedJson('quiz.$id', () => guardApi(() async {
          final res = await _dio.get<Map<String, dynamic>>('/quizzes/$id');
          return res.data!;
        }));
    return Quiz.fromJson(data);
  }

  Future<void> delete(String id) =>
      guardApi(() => _dio.delete<void>('/quizzes/$id'));

  Future<Quiz> rename(String id, String title) => guardApi(() async {
        final res = await _dio.patch<Map<String, dynamic>>(
          '/quizzes/$id',
          data: {'title': title},
        );
        return Quiz.fromJson(res.data!);
      });

  /// Quizi secilen formatta disa aktarir; ham bayt + dosya adini doner.
  Future<ExportFile> export(String id, String format) => guardApi(() async {
        final res = await _dio.get<List<int>>(
          '/quizzes/$id/export',
          queryParameters: {'format': format},
          options: Options(responseType: ResponseType.bytes),
        );
        return ExportFile(
          bytes: res.data ?? const [],
          filename: filenameFromResponse(res, fallback: 'quiz.$format'),
        );
      });
}
