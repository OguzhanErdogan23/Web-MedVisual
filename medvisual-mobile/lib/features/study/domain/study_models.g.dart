// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'study_models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_StudyStats _$StudyStatsFromJson(Map<String, dynamic> json) => _StudyStats(
  documents: (json['documents'] as num?)?.toInt() ?? 0,
  sets: (json['sets'] as num?)?.toInt() ?? 0,
  cards: (json['cards'] as num?)?.toInt() ?? 0,
  quizzes: (json['quizzes'] as num?)?.toInt() ?? 0,
  dueNow: (json['due_now'] as num?)?.toInt() ?? 0,
  studiedCards: (json['studied_cards'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$StudyStatsToJson(_StudyStats instance) =>
    <String, dynamic>{
      'documents': instance.documents,
      'sets': instance.sets,
      'cards': instance.cards,
      'quizzes': instance.quizzes,
      'due_now': instance.dueNow,
      'studied_cards': instance.studiedCards,
    };
