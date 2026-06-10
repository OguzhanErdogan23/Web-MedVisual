import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../domain/review_state.dart';
import '../domain/sm2.dart';
import '../domain/study_models.dart';

/// Aralikli tekrar uclari. SM-2 otoritesi sunucudur; istemci yalnizca
/// grade gonderir, optimistic gosterim icin yerel [applySm2] kullanilir.
class StudyRepository {
  StudyRepository(this._dio);

  final Dio _dio;

  Future<DueResult> due({String? setId}) => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/study/due',
          queryParameters: {if (setId != null) 'set_id': setId},
        );
        final data = res.data ?? const <String, dynamic>{};
        final cards = (data['cards'] as List? ?? const [])
            .cast<Map<String, dynamic>>()
            .map(DueCard.fromApi)
            .toList(growable: false);
        return DueResult(
          cards: cards,
          totalDue: (data['total_due'] as num?)?.toInt() ?? cards.length,
          newCount: (data['new_count'] as num?)?.toInt() ?? 0,
        );
      });

  /// Cevabi sunucuya yazar; sunucunun hesapladigi yeni durum doner.
  Future<ReviewState> submitReview(String cardId, Grade grade) =>
      guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/study/reviews',
          data: {'card_id': cardId, 'grade': grade.index},
        );
        return ReviewState.fromJson(res.data!);
      });

  Future<StudyStats> stats() => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/study/stats');
        return StudyStats.fromJson(res.data!);
      });
}
