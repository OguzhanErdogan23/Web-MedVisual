import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api_client.dart';
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
class QuizzesCubit extends Cubit<QuizzesState> {
  QuizzesCubit(this._repo) : super(const QuizzesState());

  final QuizzesRepository _repo;

  Future<void> load({bool silent = false}) async {
    if (!silent || state.quizzes.isEmpty) {
      emit(state.copyWith(status: ViewStatus.loading, error: null));
    }
    try {
      final quizzes = await _repo.list();
      emit(state.copyWith(
          status: ViewStatus.success, quizzes: quizzes, error: null));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }

  Future<void> delete(String id) async {
    try {
      await _repo.delete(id);
      emit(state.copyWith(
        quizzes: state.quizzes.where((q) => q.id != id).toList(),
        notice: 'Quiz silindi.',
      ));
      emit(state.copyWith(notice: null));
    } on ApiException catch (e) {
      emit(state.copyWith(notice: e.message));
      emit(state.copyWith(notice: null));
    }
  }
}
