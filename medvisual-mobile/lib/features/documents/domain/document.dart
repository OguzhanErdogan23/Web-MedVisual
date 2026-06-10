import 'package:freezed_annotation/freezed_annotation.dart';

part 'document.freezed.dart';
part 'document.g.dart';

/// Yuklenen PDF dokumani (immutable — freezed).
@freezed
abstract class Document with _$Document {
  const Document._();

  const factory Document({
    required String id,
    String? dipDocId,
    required String filename,
    int? pageCount,
    bool? hasText,
    required String status,
    String? error,
    DateTime? createdAt,
  }) = _Document;

  factory Document.fromJson(Map<String, dynamic> json) =>
      _$DocumentFromJson(json);

  bool get isProcessing => status == 'processing';
  bool get isReady => status == 'ready';
}

/// DIP kutuphanesindeki hazir kitap.
@freezed
abstract class Book with _$Book {
  const factory Book({
    required String name,
    required String display,
    double? sizeMb,
    int? pages,
  }) = _Book;

  factory Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);
}
