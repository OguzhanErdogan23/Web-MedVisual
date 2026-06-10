import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../domain/candidate.dart';
import '../domain/card_set.dart';
import '../domain/flashcard.dart';

/// Deste + kart uclari.
class SetsRepository {
  SetsRepository(this._dio);

  final Dio _dio;

  Future<List<CardSet>> list() => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/sets');
        final items =
            (res.data?['sets'] as List? ?? const []).cast<Map<String, dynamic>>();
        return items.map(CardSet.fromJson).toList(growable: false);
      });

  /// Set + kartlari (istemci `generating` durumunu burada poll'lar).
  Future<CardSet> getById(String id) => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/sets/$id');
        return CardSet.fromJson(res.data!);
      });

  Future<CardSet> update(String id, {String? title, String? description}) =>
      guardApi(() async {
        final res = await _dio.patch<Map<String, dynamic>>('/sets/$id', data: {
          if (title != null) 'title': title,
          if (description != null) 'description': description,
        });
        return CardSet.fromJson(res.data!);
      });

  Future<void> delete(String id) =>
      guardApi(() => _dio.delete<void>('/sets/$id'));

  Future<Flashcard> addCard(
    String setId, {
    required String front,
    required String back,
    String? term,
  }) =>
      guardApi(() async {
        final res =
            await _dio.post<Map<String, dynamic>>('/sets/$setId/cards', data: {
          'front': front,
          'back': back,
          if (term != null && term.isNotEmpty) 'term': term,
        });
        return Flashcard.fromJson(res.data!);
      });

  Future<Flashcard> updateCard(String cardId, {String? front, String? back}) =>
      guardApi(() async {
        final res =
            await _dio.patch<Map<String, dynamic>>('/cards/$cardId', data: {
          if (front != null) 'front': front,
          if (back != null) 'back': back,
        });
        return Flashcard.fromJson(res.data!);
      });

  Future<void> deleteCard(String cardId) =>
      guardApi(() => _dio.delete<void>('/cards/$cardId'));

  /// Sayfa araligini DIP motorunda tarayip gorsel adaylari dondurur.
  /// YAVAS cagri (30-120 sn): cagiran taraf yukleme arayuzu gostermeli.
  Future<MatchResult> matchCard(
    String cardId, {
    required String range,
    String? documentId,
    String? term,
  }) =>
      guardApi(() async {
        final res = await _dio
            .post<Map<String, dynamic>>('/cards/$cardId/match', data: {
          'range': range,
          if (documentId != null) 'document_id': documentId,
          if (term != null && term.isNotEmpty) 'term': term,
        });
        return MatchResult.fromJson(res.data!);
      });

  /// Secilen adayi kalici gorsel yapar; guncellenmis kart doner.
  Future<Flashcard> selectImage(
    String cardId, {
    required String dipDocId,
    required String path,
  }) =>
      guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/cards/$cardId/select-image',
          data: {'dip_doc_id': dipDocId, 'path': path},
        );
        return Flashcard.fromJson(res.data!);
      });
}
