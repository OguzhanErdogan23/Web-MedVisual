import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api_client.dart';
import '../data/study_repository.dart';
import '../domain/review_state.dart';
import '../domain/sm2.dart';
import '../domain/study_models.dart';

part 'study_bloc.freezed.dart';

// ---------------------------------------------------------------------------
// Olaylar
// ---------------------------------------------------------------------------
sealed class StudyEvent {
  const StudyEvent();
}

final class StudySessionStarted extends StudyEvent {
  const StudySessionStarted();
}

final class StudyCardFlipped extends StudyEvent {
  const StudyCardFlipped();
}

final class StudyCardGraded extends StudyEvent {
  const StudyCardGraded(this.grade);

  final Grade grade;
}

final class _ReviewSyncFailed extends StudyEvent {
  const _ReviewSyncFailed();
}

// ---------------------------------------------------------------------------
// Durum (immutable — freezed). Kuyruk degistirilmez; her cevapta YENI bir
// durum yayinlanir (declarative UI: ekran yalnizca bu durumun izdusumudur).
// ---------------------------------------------------------------------------
enum StudyPhase { loading, active, finished, empty, failure }

@freezed
abstract class StudyState with _$StudyState {
  const StudyState._();

  const factory StudyState({
    @Default(StudyPhase.loading) StudyPhase phase,
    @Default(<DueCard>[]) List<DueCard> queue,
    @Default(0) int index,
    @Default(false) bool flipped,
    /// Not -> cevap sayisi (oturum ozeti icin).
    @Default(<Grade, int>{}) Map<Grade, int> gradeCounts,
    /// Sunucuya yazilamayan cevap sayisi (bilgilendirme).
    @Default(0) int syncFailures,
    @Default(0) int newCount,
    String? error,
  }) = _StudyState;

  DueCard? get current =>
      (phase == StudyPhase.active && index < queue.length)
          ? queue[index]
          : null;

  int get answered => gradeCounts.values.fold(0, (a, b) => a + b);
}

// ---------------------------------------------------------------------------
// BLoC: kuyrugu yukler; her notta saf [applySm2] ile optimistic yeni durum
// hesaplar, sunucu yazimini arka planda yapar (otorite sunucudur).
// ---------------------------------------------------------------------------
class StudyBloc extends Bloc<StudyEvent, StudyState> {
  StudyBloc(this._repo, {this.setId}) : super(const StudyState()) {
    on<StudySessionStarted>(_onStarted);
    on<StudyCardFlipped>(
        (e, emit) => emit(state.copyWith(flipped: !state.flipped)));
    on<StudyCardGraded>(_onGraded);
    on<_ReviewSyncFailed>((e, emit) =>
        emit(state.copyWith(syncFailures: state.syncFailures + 1)));
  }

  final StudyRepository _repo;
  final String? setId;

  Future<void> _onStarted(
      StudySessionStarted event, Emitter<StudyState> emit) async {
    emit(const StudyState(phase: StudyPhase.loading));
    try {
      final due = await _repo.due(setId: setId);
      if (due.cards.isEmpty) {
        emit(const StudyState(phase: StudyPhase.empty));
        return;
      }
      emit(StudyState(
        phase: StudyPhase.active,
        queue: due.cards,
        newCount: due.newCount,
      ));
    } on ApiException catch (e) {
      emit(StudyState(phase: StudyPhase.failure, error: e.message));
    }
  }

  Future<void> _onGraded(
      StudyCardGraded event, Emitter<StudyState> emit) async {
    final current = state.current;
    if (current == null) return;

    // Saf fonksiyon: optimistic yeni tekrar durumu (girdi degismez).
    final optimistic = applySm2(
      current.review ?? const ReviewState(),
      event.grade,
      DateTime.now().toUtc(),
    );

    // Kuyruk dokunulmaz; guncellenmis kart yeni listede yer alir
    // (oturum ici gosterim — kalici yazim sunucudadir).
    final queue = [
      for (final dc in state.queue)
        dc.card.id == current.card.id ? dc.copyWith(review: optimistic) : dc,
    ];
    final counts = {
      ...state.gradeCounts,
      event.grade: (state.gradeCounts[event.grade] ?? 0) + 1,
    };
    final nextIndex = state.index + 1;

    emit(state.copyWith(
      queue: queue,
      gradeCounts: counts,
      index: nextIndex,
      flipped: false,
      phase:
          nextIndex >= queue.length ? StudyPhase.finished : StudyPhase.active,
    ));

    // Sunucu yazimi arka planda (fire-and-forget); hata sayilir ama oturumu
    // kesmez — SM-2 otoritesi sunucu oldugundan bir sonraki /study/due
    // cagrisi dogru durumu getirir.
    unawaited(
      _repo.submitReview(current.card.id, event.grade).catchError((Object _) {
        if (!isClosed) add(const _ReviewSyncFailed());
        return const ReviewState();
      }),
    );
  }
}
