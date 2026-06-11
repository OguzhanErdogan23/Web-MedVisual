import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/offline_cache.dart';
import '../domain/review_state.dart';
import '../domain/sm2.dart';
import '../domain/study_history.dart';
import '../domain/study_models.dart';

/// Aralikli tekrar uclari. SM-2 otoritesi sunucudur; istemci yalnizca
/// grade gonderir, optimistic gosterim icin yerel [applySm2] kullanilir.
///
/// Cevrimdisi destek: due/stats/history son basarili yanitlari cache'ten
/// dondurur; sunucuya yazilamayan notlar outbox'a kuyruklanir ve baglanti
/// gelince [syncOutbox] ile gonderilir.
class StudyRepository {
  StudyRepository(this._dio);

  final Dio _dio;

  /// [mode] 'cram' ise vade filtresi olmadan TUM kartlar doner
  /// (serbest calisma; notlar sunucuya yazilmaz).
  Future<DueResult> due({String? setId, String mode = 'due'}) async {
    final data = await cachedJson(
      'due.${setId ?? 'all'}.$mode',
      () => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>(
          '/study/due',
          queryParameters: {
            if (setId != null) 'set_id': setId,
            if (mode != 'due') 'mode': mode,
          },
        );
        return res.data ?? const <String, dynamic>{};
      }),
    );
    final cards = (data['cards'] as List? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(DueCard.fromApi)
        .toList(growable: false);
    return DueResult(
      cards: cards,
      totalDue: (data['total_due'] as num?)?.toInt() ?? cards.length,
      newCount: (data['new_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Cevabi sunucuya yazar; sunucunun hesapladigi yeni durum doner.
  /// Baglanti yoksa not outbox'a kuyruklanir ve null doner (kayip yok).
  Future<ReviewState?> submitReview(String cardId, Grade grade) async {
    try {
      return await guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/study/reviews',
          data: {'card_id': cardId, 'grade': grade.index},
        );
        return ReviewState.fromJson(res.data!);
      });
    } on ApiException catch (e) {
      if (e.statusCode != null) rethrow; // gercek sunucu hatasi: kuyruga alma
      await outboxAppend({'card_id': cardId, 'grade': grade.index});
      return null;
    }
  }

  /// Bekleyen cevrimdisi notlari gonderir; gonderilen sayisini dondurur.
  /// Ilk baglanti hatasinda durur (cevrimdisiyken timeout yigilmasin).
  Future<int> syncOutbox() async {
    final pending = await outboxPending();
    if (pending.isEmpty) return 0;
    var sent = 0;
    final remaining = <Map<String, dynamic>>[];
    for (var i = 0; i < pending.length; i++) {
      try {
        await guardApi(() =>
            _dio.post<Map<String, dynamic>>('/study/reviews', data: pending[i]));
        sent++;
      } on ApiException catch (e) {
        remaining.add(pending[i]);
        if (e.statusCode == null) {
          remaining.addAll(pending.sublist(i + 1));
          break;
        }
      }
    }
    await outboxReplace(remaining);
    return sent;
  }

  Future<StudyStats> stats() async {
    final data = await cachedJson('stats', () => guardApi(() async {
          final res = await _dio.get<Map<String, dynamic>>('/study/stats');
          return res.data!;
        }));
    return StudyStats.fromJson(data);
  }

  Future<StudyHistory> history({int days = 14}) async {
    final data = await cachedJson('history.$days', () => guardApi(() async {
          final res = await _dio.get<Map<String, dynamic>>(
            '/study/history',
            queryParameters: {
              'days': days,
              // Gun siniri cihazin yerel saatine gore cizilsin (TR: 180)
              'tz_offset_minutes': DateTime.now().timeZoneOffset.inMinutes,
            },
          );
          return res.data!;
        }));
    return StudyHistory.fromJson(data);
  }
}
