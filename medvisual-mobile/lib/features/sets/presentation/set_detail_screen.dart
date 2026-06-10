import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../sets/data/sets_repository.dart';
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
              decoration: const InputDecoration(labelText: 'On yuz (soru)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: back,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Arka yuz (cevap)'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: term,
              decoration:
                  const InputDecoration(labelText: 'Terim (istege bagli)'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Ekle'),
          ),
        ],
      ),
    );
    if (ok == true && front.text.trim().isNotEmpty) {
      bloc.add(CardAddSubmitted(
        front: front.text.trim(),
        back: back.text.trim(),
        term: term.text.trim().isEmpty ? null : term.text.trim(),
      ));
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
                  tooltip: 'Bu desteyle calis',
                  icon: const Icon(Icons.school_outlined),
                  onPressed: () =>
                      context.push('/calis/oturum?setId=${set.id}'),
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
                message: state.error ?? 'Deste yuklenemedi.',
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
            Text('Uretiliyor...',
                style: TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.indigo)),
            SizedBox(height: 6),
            Text(
              'Kartlar hazirlaniyor; bu islem sayfa sayisina gore\nbirkac dakika surebilir.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.blueGrey),
            ),
          ],
        ),
      );
    }
    if (set.status == 'failed') {
      return ErrorView(message: set.error ?? 'Uretim basarisiz oldu.');
    }
    if (set.cards.isEmpty) {
      return const EmptyView(
        icon: Icons.crop_portrait,
        title: 'Bu destede kart yok',
        subtitle: 'Sag alttaki + butonuyla elle kart ekleyebilirsiniz.',
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 88),
      itemCount: set.cards.length,
      itemBuilder: (context, i) => _FlashcardTile(
        card: set.cards[i],
        index: i,
        documentId: set.documentId,
      ),
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
    final front = TextEditingController(text: widget.card.front);
    final back = TextEditingController(text: widget.card.back);
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Karti duzenle'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: front,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'On yuz'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: back,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Arka yuz'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (ok == true) {
      bloc.add(CardEditSubmitted(
        widget.card.id,
        front: front.text.trim(),
        back: back.text.trim(),
      ));
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

  void _showMenu(BuildContext context) {
    final bloc = context.read<SetDetailBloc>();
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Duzenle'),
              onTap: () {
                Navigator.pop(sheetContext);
                _edit(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.image_search, color: AppColors.teal),
              title: const Text('Gorsel Bul'),
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
                              _flipped ? 'ARKA YUZ' : 'ON YUZ',
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
