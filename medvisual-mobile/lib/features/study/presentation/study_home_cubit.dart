import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api_client.dart';
import '../../../core/safe_emit.dart';
import '../../../core/widgets.dart';
import '../../sets/data/sets_repository.dart';
import '../../sets/domain/card_set.dart';
import '../data/study_repository.dart';
import '../domain/study_history.dart';

part 'study_home_cubit.freezed.dart';

/// Calisma ana ekrani durumu: deste secici + vadesi gelen sayilari +
/// isi haritasi icin gecmis.
@freezed
abstract class StudyHomeState with _$StudyHomeState {
  const factory StudyHomeState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<CardSet>[]) List<CardSet> sets,
    @Default(0) int totalDue,
    @Default(0) int newCount,
    StudyHistory? history,
    String? error,
  }) = _StudyHomeState;
}

class StudyHomeCubit extends Cubit<StudyHomeState> with SafeEmit {
  StudyHomeCubit(this._sets, this._study) : super(const StudyHomeState());

  final SetsRepository _sets;
  final StudyRepository _study;

  Future<void> load() async {
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    try {
      final allSets = await _sets.list();
      final due = await _study.due();
      // 18 hafta ~ 126 gun: isi haritasi penceresi
      StudyHistory? history;
      try {
        history = await _study.history(days: 126);
      } on ApiException {
        history = null; // gecmis yuklenemezse harita gizlenir, ekran calisir
      }
      final sets = allSets
          .where((s) => s.isReady && s.cardCount > 0)
          .toList(growable: false);
      safeEmit(state.copyWith(
        status: ViewStatus.success,
        sets: sets,
        totalDue: due.totalDue,
        newCount: due.newCount,
        history: history,
      ));
    } on ApiException catch (e) {
      safeEmit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }
}
