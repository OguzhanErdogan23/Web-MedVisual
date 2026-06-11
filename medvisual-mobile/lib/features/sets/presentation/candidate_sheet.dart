import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../documents/data/documents_repository.dart';
import '../../documents/domain/document.dart';
import '../data/sets_repository.dart';
import '../domain/candidate.dart';
import '../domain/flashcard.dart';
import 'match_cubit.dart';

/// "Gorsel Bul" alt sayfasi: sayfa araligi al, DIP'te tara, adaylari goster,
/// secileni kalici gorsel yap. Secim basariliysa guncel [Flashcard] doner.
/// Deste bir dokumana bagli degilse ([documentId] null) kullaniciya hazir
/// dokumanlardan secim yaptirilir (web ile parite).
Future<Flashcard?> showCandidateSheet(
  BuildContext context, {
  required Flashcard card,
  String? documentId,
}) {
  final repo = context.read<SetsRepository>();
  final docsRepo = context.read<DocumentsRepository>();
  return showModalBottomSheet<Flashcard>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => MatchCubit(repo, card.id),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: _CandidateSheetBody(
          card: card,
          documentId: documentId,
          docsRepo: docsRepo,
        ),
      ),
    ),
  );
}

class _CandidateSheetBody extends StatefulWidget {
  const _CandidateSheetBody({
    required this.card,
    required this.docsRepo,
    this.documentId,
  });

  final Flashcard card;
  final String? documentId;
  final DocumentsRepository docsRepo;

  @override
  State<_CandidateSheetBody> createState() => _CandidateSheetBodyState();
}

class _CandidateSheetBodyState extends State<_CandidateSheetBody> {
  late final TextEditingController _range;
  List<Document>? _readyDocs; // documentId null ise yuklenir
  String? _selectedDocId;
  bool _docsLoading = false;
  String? _docsError;

  @override
  void initState() {
    super.initState();
    final page = widget.card.page;
    _range = TextEditingController(
      text: page != null ? '${math.max(1, page - 5)}-${page + 5}' : '',
    );
    if (widget.documentId == null) _loadDocs();
  }

  Future<void> _loadDocs() async {
    setState(() {
      _docsLoading = true;
      _docsError = null;
    });
    try {
      final docs = await widget.docsRepo.list();
      if (!mounted) return;
      setState(() {
        _readyDocs =
            docs.where((d) => d.isReady).toList(growable: false);
        _docsLoading = false;
      });
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() {
        _docsError = e.message;
        _docsLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _range.dispose();
    super.dispose();
  }

  void _search(BuildContext context) {
    var range = _range.text.trim();
    // Tek sayfa da kabul edilir: "25" -> "25-25" (web ile ayni kural)
    final match = RegExp(r'^(\d+)(?:\s*-\s*(\d+))?$').firstMatch(range);
    if (match == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sayfa aralığı girin (örn. 25-50 veya tek sayfa 25).')));
      return;
    }
    final start = int.parse(match.group(1)!);
    final end = match.group(2) != null ? int.parse(match.group(2)!) : start;
    if (start < 1 || end < start) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Aralık geçersiz: başlangıç bitişten büyük olamaz.')));
      return;
    }
    range = '$start-$end';
    final docId = widget.documentId ?? _selectedDocId;
    if (docId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Önce aranacak dokümanı seçin.')));
      return;
    }
    context.read<MatchCubit>().search(range: range, documentId: docId);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return BlocConsumer<MatchCubit, MatchState>(
      listener: (context, state) {
        if (state.selectedCard != null) {
          Navigator.of(context).pop(state.selectedCard);
        }
      },
      builder: (context, state) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Görsel Bul',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  widget.card.term ?? widget.card.front,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: scheme.onSurfaceVariant),
                ),
                const SizedBox(height: 14),
                // Deste dokumana bagli degilse kaynak dokuman secimi
                if (widget.documentId == null) ...[
                  if (_docsLoading)
                    const LinearProgressIndicator()
                  else if (_docsError != null)
                    Text(_docsError!,
                        style: const TextStyle(color: AppColors.danger))
                  else if ((_readyDocs ?? const []).isEmpty)
                    Text(
                      'Hazır durumda doküman yok. Önce panelden bir PDF yükleyin.',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    )
                  else
                    DropdownButtonFormField<String>(
                      value: _selectedDocId,
                      decoration:
                          const InputDecoration(labelText: 'Doküman seç'),
                      items: [
                        for (final d in _readyDocs!)
                          DropdownMenuItem(
                            value: d.id,
                            child: Text(
                              '${d.filename} (${d.pageCount ?? '?'} sayfa)',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: state.searching
                          ? null
                          : (v) => setState(() => _selectedDocId = v),
                    ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _range,
                        enabled: !state.searching,
                        decoration: const InputDecoration(
                          labelText: 'Sayfa aralığı',
                          hintText: 'örn. 25-50',
                        ),
                        onSubmitted: (_) => _search(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    FilledButton.icon(
                      onPressed:
                          state.searching ? null : () => _search(context),
                      icon: const Icon(Icons.image_search),
                      label: const Text('Ara'),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (state.searching) ...[
                  const LinearProgressIndicator(),
                  const SizedBox(height: 12),
                  Text(
                    'Sayfalar taranıyor, görsel adayları çıkarılıyor...\n'
                    'Bu işlem 30-120 saniye sürebilir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 24),
                ] else if (state.error != null) ...[
                  Text(state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 16),
                ] else if (state.searched && state.candidates.isEmpty) ...[
                  Text(
                    'Bu aralıkta uygun görsel adayı bulunamadı. '
                    'Farklı bir aralık deneyin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: scheme.onSurfaceVariant),
                  ),
                  const SizedBox(height: 16),
                ] else if (state.candidates.isNotEmpty) ...[
                  Text(
                      'Adaylar (${state.candidates.length}) — seçmek için dokunun',
                      style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 230,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: state.candidates.length,
                      separatorBuilder: (_, _) => const SizedBox(width: 10),
                      itemBuilder: (context, i) => _CandidateCard(
                        candidate: state.candidates[i],
                        selecting:
                            state.selectingPath == state.candidates[i].path,
                        enabled: state.selectingPath == null,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({
    required this.candidate,
    required this.selecting,
    required this.enabled,
  });

  final Candidate candidate;
  final bool selecting;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // resolveImageUrl: token null ise '?token=null' gondermez (guvenli kurulum)
    final imageUrl = resolveImageUrl(candidate.url);
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled
          ? () => context.read<MatchCubit>().select(candidate)
          : null,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          border: Border.all(
              color:
                  isDark ? scheme.outlineVariant : const Color(0xFFD5DAE8)),
          borderRadius: BorderRadius.circular(12),
          color: scheme.surface,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(11)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.network(
                      imageUrl,
                      fit: BoxFit.contain,
                      loadingBuilder: (context, child, progress) =>
                          progress == null
                              ? child
                              : const Center(
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2)),
                      errorBuilder: (context, error, stack) => Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: scheme.onSurfaceVariant),
                      ),
                    ),
                    if (selecting)
                      Container(
                        color: scheme.surface.withValues(alpha: 0.7),
                        child: const Center(
                            child: CircularProgressIndicator(strokeWidth: 2)),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    candidate.label ?? 'Aday',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, fontSize: 12),
                  ),
                  Text(
                    'Sayfa ${candidate.page ?? '-'}',
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
