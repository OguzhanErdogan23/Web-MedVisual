import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api_client.dart';
import '../../../core/safe_emit.dart';
import '../data/documents_repository.dart';

part 'generate_cubit.freezed.dart';

enum GenerateKind { cards, quiz }

/// Uretim kaynagi: otomatik / metin katmani / OCR (web ile parite).
enum GenerateSource { auto, text, ocr }

/// Uretim sihirbazi durumu (immutable — freezed).
@freezed
abstract class GenerateState with _$GenerateState {
  const factory GenerateState({
    @Default(GenerateKind.cards) GenerateKind kind,
    @Default(GenerateSource.auto) GenerateSource source,
    @Default(false) bool submitting,
    String? error,
    /// Uretim baslatildiginda olusan set/quiz id'si (yonlendirme icin).
    String? createdId,
    GenerateKind? createdKind,
  }) = _GenerateState;
}

/// Kart/quiz uretimini baslatir; olusan kaydin id'sini state'e yazar.
class GenerateCubit extends Cubit<GenerateState> with SafeEmit {
  GenerateCubit(this._repo) : super(const GenerateState());

  final DocumentsRepository _repo;

  // error: null — eski hata snack'inin sekme degisiminde tekrar gosterilmesini onler
  void setKind(GenerateKind kind) =>
      emit(state.copyWith(kind: kind, error: null));

  void setSource(GenerateSource source) =>
      emit(state.copyWith(source: source, error: null));

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
              source: state.source.name,
              setTitle: title,
            )
          : await _repo.generateQuiz(
              documentId,
              range: range,
              nQuestions: count,
              enhance: enhance,
              source: state.source.name,
              title: title,
            );
      safeEmit(state.copyWith(
        submitting: false,
        createdId: row['id'] as String?,
        createdKind: state.kind,
      ));
    } on ApiException catch (e) {
      safeEmit(state.copyWith(submitting: false, error: e.message));
    }
  }
}
