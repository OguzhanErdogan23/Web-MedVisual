import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../../../core/export_file.dart';
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

  /// Kart dosyasini (CSV/JSON/TSV/APKG/TXT) ice aktarir; olusan deste doner.
  Future<CardSet> importCards({
    required String filePath,
    required String filename,
    String? setTitle,
  }) =>
      guardApi(() async {
        final form = FormData.fromMap({
          'file': await MultipartFile.fromFile(filePath, filename: filename),
          if (setTitle != null && setTitle.isNotEmpty) 'set_title': setTitle,
        });
        final res =
            await _dio.post<Map<String, dynamic>>('/cards/import', data: form);
        return CardSet.fromJson(res.data!);
      });

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

  /// Desteyi secilen formatta disa aktarir; ham bayt + dosya adini doner.
  Future<ExportFile> export(String id, String format) => guardApi(() async {
        final res = await _dio.get<List<int>>(
          '/sets/$id/export',
          queryParameters: {'format': format},
          options: Options(responseType: ResponseType.bytes),
        );
        return ExportFile(
          bytes: res.data ?? const [],
          filename: filenameFromResponse(res, fallback: 'deste.$format'),
        );
      });

  /// Toplu otomatik gorsel uretimini baslatir (202; sonra set poll'lanir).
  Future<void> autoImages(String id, {String? range, String? documentId}) =>
      guardApi(() async {
        await _dio.post<Map<String, dynamic>>('/sets/$id/auto-images', data: {
          if (range != null && range.isNotEmpty) 'range': range,
          if (documentId != null) 'document_id': documentId,
        });
      });

  /// Karttan gorseli kaldirir; guncellenmis kart doner (image_url null).
  Future<Flashcard> removeImage(String cardId) => guardApi(() async {
        final res =
            await _dio.delete<Map<String, dynamic>>('/cards/$cardId/image');
        return Flashcard.fromJson(res.data!);
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
