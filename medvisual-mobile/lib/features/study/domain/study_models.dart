import 'package:freezed_annotation/freezed_annotation.dart';

import '../../sets/domain/flashcard.dart';
import 'review_state.dart';

part 'study_models.freezed.dart';
part 'study_models.g.dart';

/// Vadesi gelmis kart: kart + (varsa) tekrar durumu.
@freezed
abstract class DueCard with _$DueCard {
  const factory DueCard({
    required Flashcard card,
    ReviewState? review,
  }) = _DueCard;

  /// /study/due ogeleri kart alanlarini ust duzeyde, tekrar durumunu
  /// `review` anahtarinda tasir.
  factory DueCard.fromApi(Map<String, dynamic> json) => DueCard(
        card: Flashcard.fromJson(json),
        review: json['review'] == null
            ? null
            : ReviewState.fromJson(json['review'] as Map<String, dynamic>),
      );
}

/// /study/due yaniti.
@freezed
abstract class DueResult with _$DueResult {
  const factory DueResult({
    @Default(<DueCard>[]) List<DueCard> cards,
    @Default(0) int totalDue,
    @Default(0) int newCount,
  }) = _DueResult;
}

/// /study/stats yaniti (panel sayaclari).
@freezed
abstract class StudyStats with _$StudyStats {
  const factory StudyStats({
    @Default(0) int documents,
    @Default(0) int sets,
    @Default(0) int cards,
    @Default(0) int quizzes,
    @Default(0) int dueNow,
    @Default(0) int studiedCards,
  }) = _StudyStats;

  factory StudyStats.fromJson(Map<String, dynamic> json) =>
      _$StudyStatsFromJson(json);
}
