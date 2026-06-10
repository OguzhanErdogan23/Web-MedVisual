import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api_client.dart';
import '../../../core/widgets.dart';
import '../data/sets_repository.dart';
import '../domain/card_set.dart';

part 'sets_bloc.freezed.dart';

sealed class SetsEvent {
  const SetsEvent();
}

final class SetsStarted extends SetsEvent {
  const SetsStarted();
}

final class SetsRefreshed extends SetsEvent {
  const SetsRefreshed();
}

final class SetDeleteRequested extends SetsEvent {
  const SetDeleteRequested(this.id);

  final String id;
}

final class SetRenameRequested extends SetsEvent {
  const SetRenameRequested(this.id, this.title);

  final String id;
  final String title;
}

@freezed
abstract class SetsState with _$SetsState {
  const factory SetsState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<CardSet>[]) List<CardSet> sets,
    String? error,
    String? notice,
  }) = _SetsState;
}

/// Deste listesi BLoC'u.
class SetsBloc extends Bloc<SetsEvent, SetsState> {
  SetsBloc(this._repo) : super(const SetsState()) {
    on<SetsStarted>((e, emit) => _load(emit));
    on<SetsRefreshed>((e, emit) => _load(emit, silent: true));
    on<SetDeleteRequested>(_onDelete);
    on<SetRenameRequested>(_onRename);
  }

  final SetsRepository _repo;

  Future<void> _load(Emitter<SetsState> emit, {bool silent = false}) async {
    if (!silent || state.sets.isEmpty) {
      emit(state.copyWith(status: ViewStatus.loading, error: null));
    }
    try {
      final sets = await _repo.list();
      emit(state.copyWith(
          status: ViewStatus.success, sets: sets, error: null));
    } on ApiException catch (e) {
      emit(state.copyWith(status: ViewStatus.failure, error: e.message));
    }
  }

  Future<void> _onDelete(
      SetDeleteRequested event, Emitter<SetsState> emit) async {
    try {
      await _repo.delete(event.id);
      emit(state.copyWith(
        sets: state.sets.where((s) => s.id != event.id).toList(),
        notice: 'Deste silindi.',
      ));
      emit(state.copyWith(notice: null));
    } on ApiException catch (e) {
      emit(state.copyWith(notice: e.message));
      emit(state.copyWith(notice: null));
    }
  }

  Future<void> _onRename(
      SetRenameRequested event, Emitter<SetsState> emit) async {
    try {
      final updated = await _repo.update(event.id, title: event.title);
      emit(state.copyWith(
        sets: [
          for (final s in state.sets)
            s.id == event.id ? s.copyWith(title: updated.title) : s,
        ],
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(notice: e.message));
      emit(state.copyWith(notice: null));
    }
  }
}
