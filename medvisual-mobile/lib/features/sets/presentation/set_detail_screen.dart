import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_client.dart';
import '../../../core/export_sheet.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../documents/data/documents_repository.dart';
import '../../documents/domain/document.dart';
import '../../sets/data/sets_repository.dart';
import '../../sets/data/terms_repository.dart';
import '../domain/card_set.dart';
import '../domain/flashcard.dart';
import 'candidate_sheet.dart';
import 'set_detail_bloc.dart';

/// Deste detayi: kartlar (dokununca cevrilir), duzenleme/silme/gorsel bulma.
class SetDetailScreen extends StatelessWidget {
  const SetDetailScreen({super.key, required this.setId});

  final String setId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          SetDetailBloc(context.read<SetsRepository>(), setId)
            ..add(const SetDetailStarted()),
      child: const _SetDetailBody(),
    );
  }
}

class _SetDetailBody extends StatelessWidget {
  const _SetDetailBody();

  Future<void> _addCard(BuildContext context) async {
    final bloc = context.read<SetDetailBloc>();
    final terms = context.read<TermsRepository>();
    // Terim onerilerini arka planda yukle (onbellege alinir).
    unawaited(terms.list().catchError((_) => <String>[]));
    final front = TextEditingController();
    final back = TextEditingController();
    final term = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kart ekle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: front,
              autofocus: true,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Ön yüz (soru)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: back,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Arka yüz (cevap)'),
            ),
            const SizedBox(height: 10),
            TermAutocompleteField(controller: term, options: terms.cached),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    final frontText = front.text.trim();
    final backText = back.text.trim();
    final termText = term.text.trim();
    front.dispose();
    back.dispose();
    term.dispose();
    // Web ile ayni kural: on VE arka yuz zorunlu (bos cevapli kart olmasin)
    if (ok == true && frontText.isNotEmpty && backText.isNotEmpty) {
      bloc.add(CardAddSubmitted(
        front: frontText,
        back: backText,
        term: termText.isEmpty ? null : termText,
      ));
    } else if (ok == true && context.mounted) {
      showSnack(context, 'Ön yüz ve arka yüz boş bırakılamaz.');
    }
  }

  Future<void> _export(BuildContext context, String setId) {
    final repo = context.read<SetsRepository>();
    return showExportSheet(
      context,
      formats: const ['json', 'csv', 'tsv', 'anki', 'txt', 'pdf', 'apkg'],
      download: (format) => repo.export(setId, format),
    );
  }

  /// Toplu otomatik gorsel: hazir bir dokuman sec (varsayilan destenin
  /// dokumani) ve onayla -> bloc auto-images olayini tetikler.
  Future<void> _autoImages(BuildContext context, CardSet set) async {
    final bloc = context.read<SetDetailBloc>();
    final docsRepo = context.read<DocumentsRepository>();

    List<Document> readyDocs = const [];
    try {
      final all = await docsRepo.list();
      readyDocs = all.where((d) => d.isReady).toList();
    } catch (_) {
      // Liste alinamasa da destenin kendi dokumaniyla devam edilebilir.
    }
    if (!context.mounted) return;

    String? documentId = set.documentId;
    // Destenin dokumani yoksa kullaniciya hazir dokuman sectir.
    if (documentId == null && readyDocs.isNotEmpty) {
      documentId = await showModalBottomSheet<String>(
        context: context,
        showDragHandle: true,
        builder: (sheetContext) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('Görsel kaynağı dokümanını seçin',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              for (final d in readyDocs)
                ListTile(
                  leading: const Icon(Icons.picture_as_pdf_outlined,
                      color: AppColors.indigo),
                  title: Text(d.filename,
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  onTap: () => Navigator.pop(sheetContext, d.id),
                ),
            ],
          ),
        ),
      );
      if (documentId == null || !context.mounted) return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Toplu görsel üretilsin mi?'),
        content: const Text(
            'Görseli olmayan tüm kartlar için DIP motorundan otomatik '
            'görsel aranacak. Bu işlem birkaç dakika sürebilir.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Başlat'),
          ),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(SetAutoImagesRequested(documentId: documentId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<SetDetailBloc, SetDetailState>(
      listenWhen: (p, c) => p.notice != c.notice,
      listener: (context, state) {
        if (state.notice != null) showSnack(context, state.notice!);
      },
      builder: (context, state) {
        final set = state.set;
        return Scaffold(
          appBar: AppBar(
            title: Text(set?.title ?? 'Deste',
                maxLines: 1, overflow: TextOverflow.ellipsis),
            actions: [
              if (set != null && set.isReady && set.cards.isNotEmpty)
                IconButton(
                  tooltip: 'Bu desteyle çalış',
                  icon: const Icon(Icons.school_outlined),
                  onPressed: () =>
                      context.push('/calis/oturum?setId=${set.id}'),
                ),
              if (set != null && set.isReady && set.cards.isNotEmpty)
                IconButton(
                  tooltip: 'Serbest çalış (zamanlama etkilenmez)',
                  icon: const Icon(Icons.casino_outlined),
                  onPressed: () => context
                      .push('/calis/oturum?setId=${set.id}&mode=cram'),
                ),
              if (set != null && set.isReady && set.cards.isNotEmpty)
                IconButton(
                  tooltip: 'Dışa Aktar',
                  icon: const Icon(Icons.ios_share),
                  onPressed: () => _export(context, set.id),
                ),
              if (set != null && set.isReady && set.cards.isNotEmpty)
                PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == 'auto-images') _autoImages(context, set);
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'auto-images',
                      child: ListTile(
                        leading: Icon(Icons.auto_awesome, color: AppColors.teal),
                        title: Text('Toplu görsel ekle'),
                        contentPadding: EdgeInsets.zero,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          floatingActionButton: set != null && !set.isGenerating
              ? FloatingActionButton(
                  tooltip: 'Kart ekle',
                  onPressed: () => _addCard(context),
                  child: const Icon(Icons.add),
                )
              : null,
          body: switch (state.status) {
            ViewStatus.initial ||
            ViewStatus.loading =>
              const Center(child: CircularProgressIndicator()),
            ViewStatus.failure => ErrorView(
                message: state.error ?? 'Deste yüklenemedi.',
                onRetry: () => context
                    .read<SetDetailBloc>()
                    .add(const SetDetailStarted()),
              ),
            ViewStatus.success => _SetContent(set: set!),
          },
        );
      },
    );
  }
}

class _SetContent extends StatelessWidget {
  const _SetContent({required this.set});

  final CardSet set;

  @override
  Widget build(BuildContext context) {
    if (set.isGenerating) {
      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Üretiliyor...',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.indigo)),
            SizedBox(height: 6),
            Text(
              'Kartlar hazırlanıyor; bu işlem sayfa sayısına göre\nbirkaç dakika sürebilir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
      );
    }
    if (set.status == 'failed') {
      return ErrorView(message: set.error ?? 'Üretim başarısız oldu.');
    }
    if (set.cards.isEmpty) {
      return const EmptyView(
        icon: Icons.crop_portrait,
        title: 'Bu destede kart yok',
        subtitle: 'Sağ alttaki + butonuyla elle kart ekleyebilirsiniz.',
      );
    }
    final description = set.description;
    final hasDescription = description != null && description.isNotEmpty;
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      // Ilk satir: deste aciklamasi (sayfa araligi + uretim yontemi rozeti —
      // web SetDetail paritesi, PRD'nin llm_enhanced gosterimi)
      itemCount: set.cards.length + (hasDescription ? 1 : 0),
      itemBuilder: (context, i) {
        if (hasDescription && i == 0) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
            child: Text(
              description,
              style: TextStyle(
                fontSize: 12,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }
        final cardIndex = hasDescription ? i - 1 : i;
        return _FlashcardTile(
          card: set.cards[cardIndex],
          index: cardIndex,
          documentId: set.documentId,
        );
      },
    );
  }
}

/// Tek kart: dokununca on/arka yuz cevrilir (yalnizca gorsel durum —
/// is mantigi BLoC'tadir). Uzun basinca duzenleme menusu acilir.
class _FlashcardTile extends StatefulWidget {
  const _FlashcardTile({
    required this.card,
    required this.index,
    this.documentId,
  });

  final Flashcard card;
  final int index;
  final String? documentId;

  @override
  State<_FlashcardTile> createState() => _FlashcardTileState();
}

class _FlashcardTileState extends State<_FlashcardTile> {
  bool _flipped = false;

  Future<void> _edit(BuildContext context) async {
    final bloc = context.read<SetDetailBloc>();
    final terms = context.read<TermsRepository>();
    unawaited(terms.list().catchError((_) => <String>[]));
    final front = TextEditingController(text: widget.card.front);
    final back = TextEditingController(text: widget.card.back);
    final term = TextEditingController(text: widget.card.term ?? '');
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kartı düzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: front,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Ön yüz'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: back,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Arka yüz'),
            ),
            const SizedBox(height: 10),
            // Terim duzenlenebilir (gorsel eslestirmenin anahtari, web paritesi)
            TermAutocompleteField(controller: term, options: terms.cached),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    final frontText = front.text.trim();
    final backText = back.text.trim();
    final termText = term.text.trim();
    front.dispose();
    back.dispose();
    term.dispose();
    if (ok == true && frontText.isNotEmpty && backText.isNotEmpty) {
      bloc.add(CardEditSubmitted(
        widget.card.id,
        front: frontText,
        back: backText,
        term: termText, // bos string = terimi temizle
      ));
    } else if (ok == true && context.mounted) {
      showSnack(context, 'Ön yüz ve arka yüz boş bırakılamaz.');
    }
  }

  Future<void> _findImage(BuildContext context) async {
    final bloc = context.read<SetDetailBloc>();
    final updated = await showCandidateSheet(
      context,
      card: widget.card,
      documentId: widget.documentId,
    );
    if (updated != null) bloc.add(CardReplaced(updated));
  }

  Future<void> _confirmRemoveImage(BuildContext context) async {
    final bloc = context.read<SetDetailBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Görsel kaldırılsın mı?'),
        content: const Text('Bu kartın görseli kaldırılacak.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kaldır'),
          ),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(CardImageRemoveRequested(widget.card.id));
    }
  }

  void _showMenu(BuildContext context) {
    final bloc = context.read<SetDetailBloc>();
    final hasImage = widget.card.imageUrl != null;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Düzenle'),
              onTap: () {
                Navigator.pop(sheetContext);
                _edit(context);
              },
            ),
            if (hasImage) ...[
              ListTile(
                leading:
                    const Icon(Icons.image_search, color: AppColors.teal),
                title: const Text('Görseli Değiştir'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _findImage(context);
                },
              ),
              ListTile(
                leading: const Icon(Icons.hide_image_outlined,
                    color: AppColors.warning),
                title: const Text('Görseli Kaldır'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _confirmRemoveImage(context);
                },
              ),
            ] else
              ListTile(
                leading:
                    const Icon(Icons.image_search, color: AppColors.teal),
                title: const Text('Görsel Bul'),
                onTap: () {
                  Navigator.pop(sheetContext);
                  _findImage(context);
                },
              ),
            ListTile(
              leading:
                  const Icon(Icons.delete_outline, color: AppColors.danger),
              title: const Text('Sil'),
              onTap: () {
                Navigator.pop(sheetContext);
                bloc.add(CardDeleteRequested(widget.card.id));
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => setState(() => _flipped = !_flipped),
        onLongPress: () => _showMenu(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (card.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    resolveImageUrl(card.imageUrl!),
                    width: 64,
                    height: 64,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => const SizedBox(
                      width: 64,
                      height: 64,
                      child: Icon(Icons.broken_image_outlined,
                          color: Colors.blueGrey),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: Column(
                    key: ValueKey(_flipped),
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              _flipped ? 'ARKA YÜZ' : 'ÖN YÜZ',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.1,
                                color: _flipped
                                    ? AppColors.teal
                                    : AppColors.indigo,
                              ),
                            ),
                          ),
                          if (card.page != null)
                            Text('s. ${card.page}',
                                style: const TextStyle(
                                    fontSize: 11, color: Colors.blueGrey)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(_flipped ? card.back : card.front),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
