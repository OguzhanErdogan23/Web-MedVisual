import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api_client.dart';
import '../../../core/safe_emit.dart';
import '../data/sets_repository.dart';
import '../domain/candidate.dart';
import '../domain/flashcard.dart';

part 'match_cubit.freezed.dart';

/// Gorsel aday arama/secme durumu (immutable — freezed).
@freezed
abstract class MatchState with _$MatchState {
  const factory MatchState({
    /// DIP taramasi calisiyor (30-120 sn surebilir).
    @Default(false) bool searching,
    @Default(false) bool searched,
    @Default(<Candidate>[]) List<Candidate> candidates,
    /// Secim istegi gonderilen adayin path'i.
    String? selectingPath,
    /// Kalici gorsel atanan guncel kart (basari sinyali).
    Flashcard? selectedCard,
    String? error,
  }) = _MatchState;
}

/// Kart icin gorsel adaylarini arar ve secileni kalici yapar.
class MatchCubit extends Cubit<MatchState> with SafeEmit {
  MatchCubit(this._repo, this.cardId) : super(const MatchState());

  final SetsRepository _repo;
  final String cardId;

  Future<void> search({required String range, String? documentId}) async {
    emit(state.copyWith(
      searching: true,
      searched: false,
      error: null,
      candidates: const [],
    ));
    try {
      final result =
          await _repo.matchCard(cardId, range: range, documentId: documentId);
      // Sheet kapatildiysa cubit kapanmistir; emit StateError firlatmasin
      safeEmit(state.copyWith(
        searching: false,
        searched: true,
        candidates: result.candidates,
      ));
    } on ApiException catch (e) {
      safeEmit(state.copyWith(searching: false, error: e.message));
    }
  }

  Future<void> select(Candidate candidate) async {
    emit(state.copyWith(selectingPath: candidate.path, error: null));
    try {
      final card = await _repo.selectImage(
        cardId,
        dipDocId: candidate.dipDocId,
        path: candidate.path,
      );
      safeEmit(state.copyWith(selectingPath: null, selectedCard: card));
    } on ApiException catch (e) {
      safeEmit(state.copyWith(selectingPath: null, error: e.message));
    }
  }
}
