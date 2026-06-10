import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api_client.dart';
import '../data/quizzes_repository.dart';
import '../domain/quiz.dart';

part 'quiz_player_bloc.freezed.dart';

sealed class QuizPlayerEvent {
  const QuizPlayerEvent();
}

final class QuizPlayerStarted extends QuizPlayerEvent {
  const QuizPlayerStarted();
}

final class _QuizPolled extends QuizPlayerEvent {
  const _QuizPolled();
}

final class OptionSelected extends QuizPlayerEvent {
  const OptionSelected(this.optionIndex);

  final int optionIndex;
}

final class NextQuestionRequested extends QuizPlayerEvent {
  const NextQuestionRequested();
}

final class QuizRestartRequested extends QuizPlayerEvent {
  const QuizRestartRequested();
}

enum QuizPhase { loading, generating, playing, finished, failure }

/// Quiz oynatici durumu (immutable — freezed). Her secim/ilerleme yeni
/// bir durum nesnesi uretir; UI bu durumun saf izdusumudur.
@freezed
abstract class QuizPlayerState with _$QuizPlayerState {
  const QuizPlayerState._();

  const factory QuizPlayerState({
    @Default(QuizPhase.loading) QuizPhase phase,
    Quiz? quiz,
    @Default(0) int index,
    /// Gecerli soruda secilen sik (null: henuz secilmedi).
    int? selected,
    @Default(0) int score,
    String? error,
  }) = _QuizPlayerState;

  QuizQuestion? get currentQuestion =>
      (quiz != null && index < quiz!.questions.length)
          ? quiz!.questions[index]
          : null;

  bool get answered => selected != null;
}

/// Quiz yukler (`generating` ise poll eder) ve oynatir.
class QuizPlayerBloc extends Bloc<QuizPlayerEvent, QuizPlayerState> {
  QuizPlayerBloc(this._repo, this.quizId) : super(const QuizPlayerState()) {
    on<QuizPlayerStarted>(_onStarted);
    on<_QuizPolled>((e, emit) => _load(emit));
    on<OptionSelected>(_onOptionSelected);
    on<NextQuestionRequested>(_onNext);
    on<QuizRestartRequested>((e, emit) => emit(state.copyWith(
        phase: QuizPhase.playing, index: 0, selected: null, score: 0)));
  }

  final QuizzesRepository _repo;
  final String quizId;
  Timer? _pollTimer;

  Future<void> _onStarted(
      QuizPlayerStarted event, Emitter<QuizPlayerState> emit) async {
    emit(const QuizPlayerState(phase: QuizPhase.loading));
    await _load(emit);
  }

  Future<void> _load(Emitter<QuizPlayerState> emit) async {
    try {
      final quiz = await _repo.getById(quizId);
      if (quiz.isGenerating) {
        emit(state.copyWith(phase: QuizPhase.generating, quiz: quiz));
        _startPolling();
        return;
      }
      _stopPolling();
      if (quiz.status == 'failed') {
        emit(state.copyWith(
          phase: QuizPhase.failure,
          quiz: quiz,
          error: quiz.error ?? 'Quiz uretimi basarisiz oldu.',
        ));
        return;
      }
      if (quiz.questions.isEmpty) {
        emit(state.copyWith(
          phase: QuizPhase.failure,
          quiz: quiz,
          error: 'Bu quizde soru bulunamadi.',
        ));
        return;
      }
      // Yalnizca ilk gecis: oynatma durumunu sifirla.
      if (state.phase != QuizPhase.playing) {
        emit(QuizPlayerState(phase: QuizPhase.playing, quiz: quiz));
      }
    } on ApiException catch (e) {
      _stopPolling();
      emit(state.copyWith(phase: QuizPhase.failure, error: e.message));
    }
  }

  void _onOptionSelected(
      OptionSelected event, Emitter<QuizPlayerState> emit) {
    final question = state.currentQuestion;
    if (question == null || state.answered) return;
    final correct = event.optionIndex == question.answerIndex;
    emit(state.copyWith(
      selected: event.optionIndex,
      score: correct ? state.score + 1 : state.score,
    ));
  }

  void _onNext(NextQuestionRequested event, Emitter<QuizPlayerState> emit) {
    final quiz = state.quiz;
    if (quiz == null || !state.answered) return;
    final next = state.index + 1;
    if (next >= quiz.questions.length) {
      emit(state.copyWith(phase: QuizPhase.finished, selected: null));
    } else {
      emit(state.copyWith(index: next, selected: null));
    }
  }

  void _startPolling() {
    _pollTimer ??= Timer.periodic(const Duration(milliseconds: 2500), (_) {
      if (!isClosed) add(const _QuizPolled());
    });
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  Future<void> close() {
    _stopPolling();
    return super.close();
  }
}
