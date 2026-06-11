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

final class _ReviewQueuedOffline extends StudyEvent {
  const _ReviewQueuedOffline();
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
    /// Cevrimdisi kuyruga alinan cevap sayisi (baglanti gelince gonderilir).
    @Default(0) int offlineQueued,
    @Default(0) int newCount,
    /// Serbest (cram) modu: notlar sunucuya yazilmaz, zamanlama etkilenmez.
    @Default(false) bool cram,
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
  StudyBloc(this._repo, {this.setId, this.cramMode = false})
      : super(const StudyState()) {
    on<StudySessionStarted>(_onStarted);
    on<StudyCardFlipped>(
        (e, emit) => emit(state.copyWith(flipped: !state.flipped)));
    on<StudyCardGraded>(_onGraded);
    on<_ReviewSyncFailed>((e, emit) =>
        emit(state.copyWith(syncFailures: state.syncFailures + 1)));
    on<_ReviewQueuedOffline>((e, emit) =>
        emit(state.copyWith(offlineQueued: state.offlineQueued + 1)));
  }

  final StudyRepository _repo;
  final String? setId;
  final bool cramMode;

  Future<void> _onStarted(
      StudySessionStarted event, Emitter<StudyState> emit) async {
    emit(StudyState(phase: StudyPhase.loading, cram: cramMode));
    // Onceki cevrimdisi oturumun bekleyen notlarini firsattan gondermeyi dene
    unawaited(_repo.syncOutbox().catchError((Object _) => 0));
    try {
      final due = await _repo.due(
        setId: setId,
        mode: cramMode ? 'cram' : 'due',
      );
      if (due.cards.isEmpty) {
        emit(StudyState(phase: StudyPhase.empty, cram: cramMode));
        return;
      }
      final cards = [...due.cards];
      if (cramMode) cards.shuffle(); // serbest modda karisik sirayla
      emit(StudyState(
        phase: StudyPhase.active,
        queue: cards,
        newCount: due.newCount,
        cram: cramMode,
      ));
    } on ApiException catch (e) {
      emit(StudyState(phase: StudyPhase.failure, error: e.message, cram: cramMode));
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
    final updatedCurrent = current.copyWith(review: optimistic);
    var queue = [
      for (final dc in state.queue)
        dc.card.id == current.card.id ? updatedCurrent : dc,
    ];
    // 'Tekrar' denen kart ayni oturumda kuyrugun sonuna geri gelir
    if (event.grade == Grade.again) {
      queue = [...queue, updatedCurrent];
    }
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

    // Serbest modda not sunucuya YAZILMAZ (zamanlama etkilenmez).
    if (state.cram) return;

    // Sunucu yazimi arka planda; baglanti yoksa repository outbox'a kuyruklar
    // (kayip yok), gercek sunucu hatasi ise sayilir ama oturumu kesmez.
    unawaited(() async {
      try {
        final result = await _repo.submitReview(current.card.id, event.grade);
        if (result == null && !isClosed) add(const _ReviewQueuedOffline());
      } catch (_) {
        if (!isClosed) add(const _ReviewSyncFailed());
      }
    }());
  }
}
