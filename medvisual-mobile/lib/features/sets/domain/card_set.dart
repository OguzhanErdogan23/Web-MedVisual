import 'package:freezed_annotation/freezed_annotation.dart';

import 'flashcard.dart';

part 'card_set.freezed.dart';
part 'card_set.g.dart';

/// Bilgi karti destesi (immutable — freezed).
@freezed
abstract class CardSet with _$CardSet {
  const CardSet._();

  const factory CardSet({
    required String id,
    required String title,
    String? description,
    required String status,
    String? error,
    String? documentId,
    @Default(0) int cardCount,
    @Default(<Flashcard>[]) List<Flashcard> cards,
    DateTime? createdAt,
  }) = _CardSet;

  factory CardSet.fromJson(Map<String, dynamic> json) =>
      _$CardSetFromJson(json);

  bool get isGenerating => status == 'generating';
  bool get isReady => status == 'ready';
}
