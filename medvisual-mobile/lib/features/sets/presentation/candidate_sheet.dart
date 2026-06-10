import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api_client.dart';
import '../../../core/config.dart';
import '../../../core/theme.dart';
import '../data/sets_repository.dart';
import '../domain/candidate.dart';
import '../domain/flashcard.dart';
import 'match_cubit.dart';

/// "Gorsel Bul" alt sayfasi: sayfa araligi al, DIP'te tara, adaylari goster,
/// secileni kalici gorsel yap. Secim basariliysa guncel [Flashcard] doner.
Future<Flashcard?> showCandidateSheet(
  BuildContext context, {
  required Flashcard card,
  String? documentId,
}) {
  final repo = context.read<SetsRepository>();
  return showModalBottomSheet<Flashcard>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => BlocProvider(
      create: (_) => MatchCubit(repo, card.id),
      child: Padding(
        padding:
            EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
        child: _CandidateSheetBody(card: card, documentId: documentId),
      ),
    ),
  );
}

class _CandidateSheetBody extends StatefulWidget {
  const _CandidateSheetBody({required this.card, this.documentId});

  final Flashcard card;
  final String? documentId;

  @override
  State<_CandidateSheetBody> createState() => _CandidateSheetBodyState();
}

class _CandidateSheetBodyState extends State<_CandidateSheetBody> {
  late final TextEditingController _range;

  @override
  void initState() {
    super.initState();
    final page = widget.card.page;
    _range = TextEditingController(
      text: page != null ? '${math.max(1, page - 2)}-${page + 2}' : '',
    );
  }

  @override
  void dispose() {
    _range.dispose();
    super.dispose();
  }

  void _search(BuildContext context) {
    final range = _range.text.trim();
    if (!RegExp(r'^\d+\s*-\s*\d+$').hasMatch(range)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Sayfa araligi girin (orn. 25-50).')));
      return;
    }
    context
        .read<MatchCubit>()
        .search(range: range, documentId: widget.documentId);
  }

  @override
  Widget build(BuildContext context) {
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
                Text('Gorsel Bul',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge
                        ?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(
                  widget.card.term ?? widget.card.front,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.blueGrey),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _range,
                        enabled: !state.searching,
                        decoration: const InputDecoration(
                          labelText: 'Sayfa araligi',
                          hintText: 'orn. 25-50',
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
                  const Text(
                    'Sayfalar taraniyor, gorsel adaylari cikariliyor...\n'
                    'Bu islem 30-120 saniye surebilir.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 24),
                ] else if (state.error != null) ...[
                  Text(state.error!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.danger)),
                  const SizedBox(height: 16),
                ] else if (state.searched && state.candidates.isEmpty) ...[
                  const Text(
                    'Bu aralikta uygun gorsel adayi bulunamadi. '
                    'Farkli bir aralik deneyin.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 16),
                ] else if (state.candidates.isNotEmpty) ...[
                  Text('Adaylar (${state.candidates.length}) — secmek icin dokunun',
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
    final token = currentAccessToken();
    final imageUrl = '$apiBaseUrl${candidate.url}?token=$token';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: enabled
          ? () => context.read<MatchCubit>().select(candidate)
          : null,
      child: Container(
        width: 180,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFD5DAE8)),
          borderRadius: BorderRadius.circular(12),
          color: Colors.white,
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
                      errorBuilder: (context, error, stack) => const Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: Colors.blueGrey),
                      ),
                    ),
                    if (selecting)
                      Container(
                        color: Colors.white70,
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
                    style:
                        const TextStyle(fontSize: 11, color: Colors.blueGrey),
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
