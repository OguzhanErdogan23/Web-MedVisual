import 'package:freezed_annotation/freezed_annotation.dart';

part 'flashcard.freezed.dart';
part 'flashcard.g.dart';

/// Tek bilgi karti (immutable — freezed).
@freezed
abstract class Flashcard with _$Flashcard {
  const factory Flashcard({
    required String id,
    String? setId,
    required String front,
    required String back,
    String? term,
    String? kind,
    int? page,
    String? imageUrl,
    int? position,
  }) = _Flashcard;

  factory Flashcard.fromJson(Map<String, dynamic> json) =>
      _$FlashcardFromJson(json);
}
