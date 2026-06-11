import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api_client.dart';
import '../../../core/safe_emit.dart';
import '../../../core/widgets.dart';
import '../data/quizzes_repository.dart';
import '../domain/quiz.dart';

part 'quizzes_cubit.freezed.dart';

@freezed
abstract class QuizzesState with _$QuizzesState {
  const factory QuizzesState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<Quiz>[]) List<Quiz> quizzes,
    String? error,
    String? notice,
  }) = _QuizzesState;
}

/// Quiz listesi.
class QuizzesCubit extends Cubit<QuizzesState> with SafeEmit {
  QuizzesCubit(this._repo) : super(const QuizzesState());

  final QuizzesRepository _repo;

  Future<void> load({bool silent = false}) async {
    if (!silent || state.quizzes.isEmpty) {
      emit(state.copyWith(status: ViewStatus.loading, error: null));
    }
    try {
      final quizzes = await _repo.list();
      safeEmit(state.copyWith(
          status: ViewStatus.success, quizzes: quizzes, error: null));
    } on ApiException catch (e) {
      safeEmit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repo.delete(id);
      safeEmit(state.copyWith(
        quizzes: state.quizzes.where((q) => q.id != id).toList(),
        notice: 'Quiz silindi.',
      ));
      safeEmit(state.copyWith(notice: null));
    } on ApiException catch (e) {
      safeEmit(state.copyWith(notice: e.message));
      safeEmit(state.copyWith(notice: null));
    }
  }

  Future<void> rename(String id, String title) async {
    try {
      final updated = await _repo.rename(id, title);
      safeEmit(state.copyWith(
        quizzes: [
          // PATCH yaniti question_count icermez; mevcut nesneyi koruyup
          // yalnizca basligi guncelle (aksi halde listede soru sayisi 0 olur)
          for (final q in state.quizzes)
            q.id == id ? q.copyWith(title: updated.title) : q,
        ],
        notice: 'Quiz yeniden adlandırıldı.',
      ));
      safeEmit(state.copyWith(notice: null));
    } on ApiException catch (e) {
      safeEmit(state.copyWith(notice: e.message));
      safeEmit(state.copyWith(notice: null));
    }
  }
}
