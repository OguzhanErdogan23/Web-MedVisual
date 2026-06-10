import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api_client.dart';
import '../data/documents_repository.dart';

part 'generate_cubit.freezed.dart';

enum GenerateKind { cards, quiz }

/// Uretim sihirbazi durumu (immutable — freezed).
@freezed
abstract class GenerateState with _$GenerateState {
  const factory GenerateState({
    @Default(GenerateKind.cards) GenerateKind kind,
    @Default(false) bool submitting,
    String? error,
    /// Uretim baslatildiginda olusan set/quiz id'si (yonlendirme icin).
    String? createdId,
    GenerateKind? createdKind,
  }) = _GenerateState;
}

/// Kart/quiz uretimini baslatir; olusan kaydin id'sini state'e yazar.
class GenerateCubit extends Cubit<GenerateState> {
  GenerateCubit(this._repo) : super(const GenerateState());

  final DocumentsRepository _repo;

  void setKind(GenerateKind kind) => emit(state.copyWith(kind: kind));

  Future<void> submit({
    required String documentId,
    required String range,
    required int count,
    required bool enhance,
    String? title,
  }) async {
    emit(state.copyWith(submitting: true, error: null));
    try {
      final row = state.kind == GenerateKind.cards
          ? await _repo.generateCards(
              documentId,
              range: range,
              maxCards: count,
              enhance: enhance,
              setTitle: title,
            )
          : await _repo.generateQuiz(
              documentId,
              range: range,
              nQuestions: count,
              enhance: enhance,
              title: title,
            );
      emit(state.copyWith(
        submitting: false,
        createdId: row['id'] as String?,
        createdKind: state.kind,
      ));
    } on ApiException catch (e) {
      emit(state.copyWith(submitting: false, error: e.message));
    }
  }
}
