// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_history.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StudyDay _$StudyDayFromJson(Map<String, dynamic> json) => _StudyDay(
  date: json['date'] as String,
  total: (json['total'] as num?)?.toInt() ?? 0,
  correct: (json['correct'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$StudyDayToJson(_StudyDay instance) => <String, dynamic>{
  'date': instance.date,
  'total': instance.total,
  'correct': instance.correct,
};

_StudyHistory _$StudyHistoryFromJson(Map<String, dynamic> json) =>
    _StudyHistory(
      days:
          (json['days'] as List<dynamic>?)
              ?.map((e) => StudyDay.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <StudyDay>[],
      totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$StudyHistoryToJson(_StudyHistory instance) =>
    <String, dynamic>{
      'days': instance.days.map((e) => e.toJson()).toList(),
      'total_reviews': instance.totalReviews,
    };
