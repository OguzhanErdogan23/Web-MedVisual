// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'review_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReviewState _$ReviewStateFromJson(Map<String, dynamic> json) => _ReviewState(
  easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
  intervalDays: (json['interval_days'] as num?)?.toDouble() ?? 0.0,
  repetitions: (json['repetitions'] as num?)?.toInt() ?? 0,
  dueAt: json['due_at'] == null
      ? null
      : DateTime.parse(json['due_at'] as String),
  lastGrade: (json['last_grade'] as num?)?.toInt(),
);

Map<String, dynamic> _$ReviewStateToJson(_ReviewState instance) =>
    <String, dynamic>{
      'ease_factor': instance.easeFactor,
      'interval_days': instance.intervalDays,
      'repetitions': instance.repetitions,
      'due_at': instance.dueAt?.toIso8601String(),
      'last_grade': instance.lastGrade,
    };
