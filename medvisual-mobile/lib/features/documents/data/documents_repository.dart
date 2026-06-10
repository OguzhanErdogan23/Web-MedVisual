import 'package:dio/dio.dart';

import '../../../core/api_client.dart';
import '../domain/document.dart';

/// Dokuman + kutuphane uclari. Tum metodlar freezed model dondurur,
/// hatalar [ApiException] olarak firlatilir.
class DocumentsRepository {
  DocumentsRepository(this._dio);

  final Dio _dio;

  Future<List<Document>> list() => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/documents');
        final items = (res.data?['documents'] as List? ?? const [])
            .cast<Map<String, dynamic>>();
        return items.map(Document.fromJson).toList(growable: false);
      });

  Future<Document> getById(String id) => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/documents/$id');
        return Document.fromJson(res.data!);
      });

  Future<Document> upload({
    required String filename,
    String? filePath,
    List<int>? bytes,
  }) =>
      guardApi(() async {
        final multipart = filePath != null
            ? await MultipartFile.fromFile(filePath, filename: filename)
            : MultipartFile.fromBytes(bytes ?? const [], filename: filename);
        final form = FormData.fromMap({'file': multipart});
        final res =
            await _dio.post<Map<String, dynamic>>('/documents', data: form);
        return Document.fromJson(res.data!);
      });

  Future<void> delete(String id) =>
      guardApi(() => _dio.delete<void>('/documents/$id'));

  Future<List<Book>> listBooks() => guardApi(() async {
        final res = await _dio.get<Map<String, dynamic>>('/books');
        final items = (res.data?['books'] as List? ?? const [])
            .cast<Map<String, dynamic>>();
        return items.map(Book.fromJson).toList(growable: false);
      });

  Future<Document> loadBook(String name) => guardApi(() async {
        final res = await _dio
            .post<Map<String, dynamic>>('/books/load', data: {'name': name});
        return Document.fromJson(res.data!);
      });

  /// Kart uretimini baslatir; `generating` durumunda set satiri doner.
  Future<Map<String, dynamic>> generateCards(
    String documentId, {
    required String range,
    required int maxCards,
    required bool enhance,
    String source = 'auto',
    String? setTitle,
  }) =>
      guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/documents/$documentId/generate/cards',
          data: {
            'range': range,
            'max_cards': maxCards,
            'enhance': enhance,
            'source': source,
            if (setTitle != null && setTitle.isNotEmpty) 'set_title': setTitle,
          },
        );
        return res.data!;
      });

  /// Quiz uretimini baslatir; `generating` durumunda quiz satiri doner.
  Future<Map<String, dynamic>> generateQuiz(
    String documentId, {
    required String range,
    required int nQuestions,
    required bool enhance,
    String source = 'auto',
    String? title,
  }) =>
      guardApi(() async {
        final res = await _dio.post<Map<String, dynamic>>(
          '/documents/$documentId/generate/quiz',
          data: {
            'range': range,
            'n_questions': nQuestions,
            'enhance': enhance,
            'source': source,
            if (title != null && title.isNotEmpty) 'title': title,
          },
        );
        return res.data!;
      });
}
