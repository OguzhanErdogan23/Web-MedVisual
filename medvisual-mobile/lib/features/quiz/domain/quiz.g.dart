// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'quiz.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Quiz _$QuizFromJson(Map<String, dynamic> json) => _Quiz(
  id: json['id'] as String,
  title: json['title'] as String,
  status: json['status'] as String,
  error: json['error'] as String?,
  documentId: json['document_id'] as String?,
  questionCount: (json['question_count'] as num?)?.toInt() ?? 0,
  questions:
      (json['questions'] as List<dynamic>?)
          ?.map((e) => QuizQuestion.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const <QuizQuestion>[],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$QuizToJson(_Quiz instance) => <String, dynamic>{
  'id': instance.id,
  'title': instance.title,
  'status': instance.status,
  'error': instance.error,
  'document_id': instance.documentId,
  'question_count': instance.questionCount,
  'questions': instance.questions.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt?.toIso8601String(),
};

_QuizQuestion _$QuizQuestionFromJson(Map<String, dynamic> json) =>
    _QuizQuestion(
      id: json['id'] as String?,
      question: json['question'] as String,
      options:
          (json['options'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const <String>[],
      answerIndex: (json['answer_index'] as num?)?.toInt() ?? 0,
    );

Map<String, dynamic> _$QuizQuestionToJson(_QuizQuestion instance) =>
    <String, dynamic>{
      'id': instance.id,
      'question': instance.question,
      'options': instance.options,
      'answer_index': instance.answerIndex,
    };
