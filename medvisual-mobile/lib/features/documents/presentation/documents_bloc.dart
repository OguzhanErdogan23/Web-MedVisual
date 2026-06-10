import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../core/api_client.dart';
import '../../../core/widgets.dart';
import '../../study/data/study_repository.dart';
import '../../study/domain/study_models.dart';
import '../data/documents_repository.dart';
import '../domain/document.dart';

part 'documents_bloc.freezed.dart';

// ---------------------------------------------------------------------------
// Olaylar
// ---------------------------------------------------------------------------
sealed class DocumentsEvent {
  const DocumentsEvent();
}

final class DocumentsStarted extends DocumentsEvent {
  const DocumentsStarted();
}

final class DocumentsRefreshed extends DocumentsEvent {
  const DocumentsRefreshed();
}

final class DocumentUploadRequested extends DocumentsEvent {
  const DocumentUploadRequested({
    required this.filename,
    this.path,
    this.bytes,
  });

  final String filename;
  final String? path;
  final List<int>? bytes;
}

final class BookLoadRequested extends DocumentsEvent {
  const BookLoadRequested(this.name);

  final String name;
}

final class DocumentDeleteRequested extends DocumentsEvent {
  const DocumentDeleteRequested(this.id);

  final String id;
}

final class _DocumentsPolled extends DocumentsEvent {
  const _DocumentsPolled();
}

// ---------------------------------------------------------------------------
// Durum (immutable — freezed)
// ---------------------------------------------------------------------------
@freezed
abstract class DocumentsState with _$DocumentsState {
  const factory DocumentsState({
    @Default(ViewStatus.initial) ViewStatus status,
    @Default(<Document>[]) List<Document> documents,
    StudyStats? stats,
    @Default(false) bool uploading,
    String? error,
    String? notice,
  }) = _DocumentsState;
}

// ---------------------------------------------------------------------------
// BLoC: dokuman listesi + istatistikler; isleyen dokuman varken 2.5 sn'de
// bir poll eder. Timer close()'da iptal edilir.
// ---------------------------------------------------------------------------
class DocumentsBloc extends Bloc<DocumentsEvent, DocumentsState> {
  DocumentsBloc(this._documents, this._study)
      : super(const DocumentsState()) {
    on<DocumentsStarted>(_onStarted);
    on<DocumentsRefreshed>((event, emit) => _load(emit, silent: false));
    on<_DocumentsPolled>((event, emit) => _load(emit, silent: true));
    on<DocumentUploadRequested>(_onUpload);
    on<BookLoadRequested>(_onLoadBook);
    on<DocumentDeleteRequested>(_onDelete);
  }

  final DocumentsRepository _documents;
  final StudyRepository _study;
  Timer? _pollTimer;

  static const _pollInterval = Duration(milliseconds: 2500);

  Future<void> _onStarted(
      DocumentsStarted event, Emitter<DocumentsState> emit) async {
    emit(state.copyWith(status: ViewStatus.loading, error: null));
    await _load(emit, silent: true);
  }

  Future<void> _load(Emitter<DocumentsState> emit,
      {required bool silent}) async {
    if (!silent) {
      emit(state.copyWith(status: ViewStatus.loading, error: null));
    }
    try {
      final results = await Future.wait([
        _documents.list(),
        _study.stats(),
      ]);
      final docs = results[0] as List<Document>;
      final stats = results[1] as StudyStats;
      emit(state.copyWith(
        status: ViewStatus.success,
        documents: docs,
        stats: stats,
        error: null,
      ));
      _syncPolling(docs);
    } on ApiException catch (e) {
      if (state.documents.isEmpty) {
        emit(state.copyWith(status: ViewStatus.failure, error: e.message));
      } else {
        _notify(emit, error: e.message);
      }
    }
  }

  Future<void> _onUpload(
      DocumentUploadRequested event, Emitter<DocumentsState> emit) async {
    emit(state.copyWith(uploading: true));
    try {
      await _documents.upload(
        filename: event.filename,
        filePath: event.path,
        bytes: event.bytes,
      );
      emit(state.copyWith(uploading: false));
      _notify(emit, notice: 'PDF yuklendi, isleniyor...');
      await _load(emit, silent: true);
    } on ApiException catch (e) {
      emit(state.copyWith(uploading: false));
      _notify(emit, error: e.message);
    }
  }

  Future<void> _onLoadBook(
      BookLoadRequested event, Emitter<DocumentsState> emit) async {
    try {
      await _documents.loadBook(event.name);
      _notify(emit, notice: 'Kitap kutuphaneden yukleniyor...');
      await _load(emit, silent: true);
    } on ApiException catch (e) {
      _notify(emit, error: e.message);
    }
  }

  Future<void> _onDelete(
      DocumentDeleteRequested event, Emitter<DocumentsState> emit) async {
    try {
      await _documents.delete(event.id);
      emit(state.copyWith(
        documents:
            state.documents.where((d) => d.id != event.id).toList(),
      ));
      _notify(emit, notice: 'Dokuman silindi.');
      await _load(emit, silent: true);
    } on ApiException catch (e) {
      _notify(emit, error: e.message);
    }
  }

  /// Tek seferlik mesaj: yayinla, ardindan temizle (listener null'i yoksayar).
  void _notify(Emitter<DocumentsState> emit, {String? notice, String? error}) {
    emit(state.copyWith(notice: notice, error: error));
    emit(state.copyWith(notice: null, error: null));
  }

  void _syncPolling(List<Document> docs) {
    final anyProcessing = docs.any((d) => d.isProcessing);
    if (anyProcessing && _pollTimer == null) {
      _pollTimer = Timer.periodic(_pollInterval, (_) {
        if (!isClosed) add(const _DocumentsPolled());
      });
    } else if (!anyProcessing) {
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
