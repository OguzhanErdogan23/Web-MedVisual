import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../domain/quiz.dart';

/// Quiz uclari (uretim documents repository'sindedir).
class QuizzesRepository {
  QuizzesRepository(this._dio);

  final Dio _dio;

  Future<List<Quiz>> list() => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/quizzes');
        final items = (res.data?['quizzes'] as List? ?? const [])
            .cast<Map<String, dynamic>>();
        return items.map(Quiz.fromJson).toList(growable: false);
      });

  /// Quiz + sorulari (istemci `generating` durumunu burada poll'lar).
  Future<Quiz> getById(String id) => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/quizzes/$id');
        return Quiz.fromJson(res.data!);
      });

  Future<void> delete(String id) =>
      guardApi(() => _dio.delete<void>('/quizzes/$id'));
}
