import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api_client.dart';
import '../../../core/widgets.dart';
import '../data/sets_repository.dart';
import '../domain/card_set.dart';
import '../domain/flashcard.dart';

part 'set_detail_bloc.freezed.dart';

sealed class SetDetailEvent {
  const SetDetailEvent();
}

final class SetDetailStarted extends SetDetailEvent {
  const SetDetailStarted();
}

final class _SetDetailPolled extends SetDetailEvent {
  const _SetDetailPolled();
}

final class CardEditSubmitted extends SetDetailEvent {
  const CardEditSubmitted(this.cardId, {required this.front, required this.back});

  final String cardId;
  final String front;
  final String back;
}

final class CardDeleteRequested extends SetDetailEvent {
  const CardDeleteRequested(this.cardId);

  final String cardId;
}

final class CardAddSubmitted extends SetDetailEvent {
  const CardAddSubmitted({required this.front, required this.back, this.term});

  final String front;
  final String back;
  final String? term;
}

/// Aday secimi sonrasi sunucudan donen guncel kart (kalici image_url ile).
final class CardReplaced extends SetDetailEvent {
  const CardReplaced(this.card);

  final Flashcard card;
}

/// Karttan gorseli kaldir (DELETE /cards/{id}/image).
final class CardImageRemoveRequested extends SetDetailEvent {
  const CardImageRemoveRequested(this.cardId);

  final String cardId;
}

/// Toplu otomatik gorsel uretimini baslat (POST /sets/{id}/auto-images).
final class SetAutoImagesRequested extends SetDetailEvent {
  const SetAutoImagesRequested({this.range, this.documentId});

  final String? range;
  final String? documentId;
}

@freezed
abstract class SetDetailState with _$SetDetailState {
  const factory SetDetailState({
    @Default(ViewStatus.initial) ViewStatus status,
    CardSet? set,
    String? error,
    String? notice,
  }) = _SetDetailState;
}

/// Deste detayi: kartlar + `generating` durumunda 2.5 sn'de bir poll.
class SetDetailBloc extends Bloc<SetDetailEvent, SetDetailState> {
  SetDetailBloc(this._repo, this.setId) : super(const SetDetailState()) {
    on<SetDetailStarted>(_onStarted);
    on<_SetDetailPolled>((e, emit) => _load(emit, silent: true));
    on<CardEditSubmitted>(_onCardEdit);
    on<CardDeleteRequested>(_onCardDelete);
    on<CardAddSubmitted>(_onCardAdd);
    on<CardReplaced>(_onCardReplaced);
    on<CardImageRemoveRequested>(_onCardImageRemove);
    on<SetAutoImagesRequested>(_onAutoImages);
  }

  final SetsRepository _repo;
  final String setId;
  Timer? _pollTimer;

  Future<void> _onStarted(
      SetDetailStarted event, Emitter<SetDetailState> emit) async {
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    await _load(emit, silent: true);
  }

  Future<void> _load(Emitter<SetDetailState> emit,
      {required bool silent}) async {
    try {
      final set = await _repo.getById(setId);
      emit(state.copyWith(
          status: ViewStatus.success, set: set, error: null));
      _syncPolling(set);
    } on ApiException catch (e) {
      if (state.set == null) {
        emit(state.copyWith(status: ViewStatus.failure, error: e.message));
      } else {
        _notify(emit, e.message);
      }
    }
  }

  Future<void> _onCardEdit(
      CardEditSubmitted event, Emitter<SetDetailState> emit) async {
    try {
      final updated = await _repo.updateCard(event.cardId,
          front: event.front, back: event.back);
      _replaceCard(emit, updated);
      _notify(emit, 'Kart guncellendi.');
    } on ApiException catch (e) {
      _notify(emit, e.message);
    }
  }

  Future<void> _onCardDelete(
      CardDeleteRequested event, Emitter<SetDetailState> emit) async {
    final set = state.set;
    if (set == null) return;
    try {
      await _repo.deleteCard(event.cardId);
      emit(state.copyWith(
        set: set.copyWith(
          cards: set.cards.where((c) => c.id != event.cardId).toList(),
        ),
      ));
      _notify(emit, 'Kart silindi.');
    } on ApiException catch (e) {
      _notify(emit, e.message);
    }
  }

  Future<void> _onCardAdd(
      CardAddSubmitted event, Emitter<SetDetailState> emit) async {
    final set = state.set;
    if (set == null) return;
    try {
      final card = await _repo.addCard(setId,
          front: event.front, back: event.back, term: event.term);
      emit(state.copyWith(set: set.copyWith(cards: [...set.cards, card])));
      _notify(emit, 'Kart eklendi.');
    } on ApiException catch (e) {
      _notify(emit, e.message);
    }
  }

  void _onCardReplaced(CardReplaced event, Emitter<SetDetailState> emit) {
    _replaceCard(emit, event.card);
    _notify(emit, 'Gorsel karta eklendi.');
  }

  Future<void> _onCardImageRemove(
      CardImageRemoveRequested event, Emitter<SetDetailState> emit) async {
    try {
      final updated = await _repo.removeImage(event.cardId);
      _replaceCard(emit, updated);
      _notify(emit, 'Gorsel kaldirildi.');
    } on ApiException catch (e) {
      _notify(emit, e.message);
    }
  }

  Future<void> _onAutoImages(
      SetAutoImagesRequested event, Emitter<SetDetailState> emit) async {
    try {
      await _repo.autoImages(setId,
          range: event.range, documentId: event.documentId);
      _notify(emit, 'Toplu gorsel uretimi baslatildi.');
      // Sunucu durumu `generating`e cekilir; poll ile ilerleme izlenir.
      await _load(emit, silent: true);
    } on ApiException catch (e) {
      _notify(emit, e.message);
    }
  }

  void _replaceCard(Emitter<SetDetailState> emit, Flashcard card) {
    final set = state.set;
    if (set == null) return;
    emit(state.copyWith(
      set: set.copyWith(
        cards: [for (final c in set.cards) c.id == card.id ? card : c],
      ),
    ));
  }

  void _notify(Emitter<SetDetailState> emit, String message) {
    emit(state.copyWith(notice: message));
    emit(state.copyWith(notice: null));
  }

  void _syncPolling(CardSet set) {
    if (set.isGenerating && _pollTimer == null) {
      _pollTimer = Timer.periodic(const Duration(milliseconds: 2500), (_) {
        if (!isClosed) add(const _SetDetailPolled());
      });
    } else if (!set.isGenerating) {
      _pollTimer?.cancel();
      _pollTimer = null;
    }
  }

  @override
  Future<void> close() {
    _pollTimer?.cancel();
    return super.close();
  }
}
