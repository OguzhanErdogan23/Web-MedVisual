import 'package:freezed_annotation/freezed_annotation.dart';

part 'study_history.freezed.dart';
part 'study_history.g.dart';

/// Tek gunluk tekrar ozeti.
@freezed
abstract class StudyDay with _$StudyDay {
  const factory StudyDay({
    required String date,
    @Default(0) int total,
    @Default(0) int correct,
  }) = _StudyDay;

  factory StudyDay.fromJson(Map<String, dynamic> json) =>
      _$StudyDayFromJson(json);
}

/// /study/history yaniti: gunluk tekrarlar + toplam.
@freezed
abstract class StudyHistory with _$StudyHistory {
  const factory StudyHistory({
    @Default(<StudyDay>[]) List<StudyDay> days,
    @Default(0) int totalReviews,
  }) = _StudyHistory;

  factory StudyHistory.fromJson(Map<String, dynamic> json) =>
      _$StudyHistoryFromJson(json);
}
