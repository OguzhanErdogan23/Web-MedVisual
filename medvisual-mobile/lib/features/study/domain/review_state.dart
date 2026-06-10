import 'package:freezed_annotation/freezed_annotation.dart';

part 'review_state.freezed.dart';
part 'review_state.g.dart';

/// SM-2 tekrar durumu (immutable deger nesnesi — freezed).
///
/// Sunucudaki `card_reviews` satirinin istemci karsiligi. [applySm2] saf
/// fonksiyonu bu nesneyi degistirmez, her zaman YENI bir ornek dondurur.
@freezed
abstract class ReviewState with _$ReviewState {
  const factory ReviewState({
    @Default(2.5) double easeFactor,
    @Default(0.0) double intervalDays,
    @Default(0) int repetitions,
    DateTime? dueAt,
    int? lastGrade,
  }) = _ReviewState;

  factory ReviewState.fromJson(Map<String, dynamic> json) =>
      _$ReviewStateFromJson(json);
}
