import 'package:freezed_annotation/freezed_annotation.dart';

part 'quiz.freezed.dart';
part 'quiz.g.dart';

/// Quiz (immutable — freezed).
@freezed
abstract class Quiz with _$Quiz {
  const Quiz._();

  const factory Quiz({
    required String id,
    required String title,
    required String status,
    String? error,
    String? documentId,
    @Default(0) int questionCount,
    @Default(<QuizQuestion>[]) List<QuizQuestion> questions,
    DateTime? createdAt,
  }) = _Quiz;

  factory Quiz.fromJson(Map<String, dynamic> json) => _$QuizFromJson(json);

  bool get isGenerating => status == 'generating';
  bool get isReady => status == 'ready';
}

/// Coktan secmeli quiz sorusu (4 secenek).
@freezed
abstract class QuizQuestion with _$QuizQuestion {
  const factory QuizQuestion({
    String? id,
    required String question,
    @Default(<String>[]) List<String> options,
    @Default(0) int answerIndex,
  }) = _QuizQuestion;

  factory QuizQuestion.fromJson(Map<String, dynamic> json) =>
      _$QuizQuestionFromJson(json);
}
