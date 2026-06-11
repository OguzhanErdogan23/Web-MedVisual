import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:go_router/go_router.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../data/study_repository.dart';
import '../domain/review_state.dart';
import '../domain/sm2.dart';
import '../domain/study_models.dart';
import 'study_bloc.dart';

/// Calisma oturumu: buyuk kart (dokununca cevrilir), 4 not butonu,
/// SM-2 saf fonksiyonuyla optimistic ilerleme.
/// [cram] true ise serbest mod: tum kartlar gelir, notlar sunucuya yazilmaz.
class StudyScreen extends StatelessWidget {
  const StudyScreen({super.key, this.setId, this.cram = false});

  final String? setId;
  final bool cram;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => StudyBloc(
        context.read<StudyRepository>(),
        setId: setId,
        cramMode: cram,
      )..add(const StudySessionStarted()),
      child: const _StudyBody(),
    );
  }
}

class _StudyBody extends StatefulWidget {
  const _StudyBody();

  @override
  State<_StudyBody> createState() => _StudyBodyState();
}

class _StudyBodyState extends State<_StudyBody> {
  final CardSwiperController _controller = CardSwiperController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  static const _gradeDirections = {
    Grade.again: CardSwiperDirection.left,
    Grade.hard: CardSwiperDirection.bottom,
    Grade.good: CardSwiperDirection.right,
    Grade.easy: CardSwiperDirection.top,
  };

  Grade _gradeForDirection(CardSwiperDirection direction) =>
      _gradeDirections.entries
          .firstWhere(
            (e) => e.value == direction,
            orElse: () => const MapEntry(Grade.good, CardSwiperDirection.right),
          )
          .key;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<StudyBloc, StudyState>(
          builder: (context, state) =>
              Text(state.cram ? 'Serbest Çalışma' : 'Çalışma Oturumu'),
        ),
      ),
      body: BlocBuilder<StudyBloc, StudyState>(
        builder: (context, state) {
          return switch (state.phase) {
            StudyPhase.loading =>
              const Center(child: CircularProgressIndicator()),
            StudyPhase.failure => ErrorView(
                message: state.error ?? 'Kartlar yüklenemedi.',
                onRetry: () => context
                    .read<StudyBloc>()
                    .add(const StudySessionStarted()),
              ),
            StudyPhase.empty => _EmptyState(
                cram: state.cram, onClose: () => context.pop()),
            StudyPhase.finished => _Summary(state: state),
            StudyPhase.active => _ActiveSession(
                state: state,
                controller: _controller,
                onSwipe: (direction) => context
                    .read<StudyBloc>()
                    .add(StudyCardGraded(_gradeForDirection(direction))),
                onGradePressed: (grade) =>
                    _controller.swipe(_gradeDirections[grade]!),
              ),
          };
        },
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.cram, required this.onClose});

  final bool cram;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.celebration_outlined,
              size: 56, color: AppColors.teal),
          const SizedBox(height: 12),
          Text(
            cram
                ? 'Bu kapsamda çalışılacak kart bulunamadı.'
                : 'Harika! Şu an vadesi gelen kart yok.',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          FilledButton(onPressed: onClose, child: const Text('Geri dön')),
        ],
      ),
    );
  }
}

class _ActiveSession extends StatelessWidget {
  const _ActiveSession({
    required this.state,
    required this.controller,
    required this.onSwipe,
    required this.onGradePressed,
  });

  final StudyState state;
  final CardSwiperController controller;
  final void Function(CardSwiperDirection direction) onSwipe;
  final void Function(Grade grade) onGradePressed;

  @override
  Widget build(BuildContext context) {
    final total = state.queue.length;
    final current = state.current;
    final review = current?.review ?? const ReviewState();
    final scheme = Theme.of(context).colorScheme;
    return SafeArea(
      child: Column(
        children: [
          if (state.cram)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.fromLTRB(20, 8, 20, 0),
              padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
              decoration: BoxDecoration(
                color: AppColors.teal.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                '🎯 Serbest mod — notlar tekrar zamanlamasını etkilemez',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.teal),
              ),
            ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Kart ${state.index + 1} / $total',
                        style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo)),
                    Text(
                      state.cram ? 'karışık sıra' : '${state.newCount} yeni',
                      style: TextStyle(color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: total == 0 ? 0 : state.index / total,
                    minHeight: 6,
                    backgroundColor: scheme.surfaceContainerHighest,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: CardSwiper(
                controller: controller,
                cardsCount: total,
                numberOfCardsDisplayed: math.min(2, total),
                isLoop: false,
                // Kart cevrilmeden el ile kaydirma kapali; not butonlari
                // (controller) her zaman calisir. Cevrildikten sonra
                // kaydirma yonu de not verir: sol=Tekrar, asagi=Zor,
                // sag=Iyi, yukari=Kolay.
                isDisabled: !state.flipped,
                duration: const Duration(milliseconds: 250),
                onSwipe: (previousIndex, currentIndex, direction) {
                  onSwipe(direction);
                  return true;
                },
                cardBuilder: (context, index, hOffset, vOffset) {
                  final dueCard = state.queue[index];
                  final isTop = index == state.index;
                  return _StudyCard(
                    dueCard: dueCard,
                    flipped: isTop && state.flipped,
                    onTap: isTop
                        ? () => context
                            .read<StudyBloc>()
                            .add(const StudyCardFlipped())
                        : null,
                  );
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: state.flipped
                ? Row(
                    children: [
                      _GradeButton(
                        label: 'Tekrar',
                        sublabel: state.cram
                            ? 'serbest'
                            : projectedIntervalLabel(review, Grade.again),
                        color: AppColors.danger,
                        onPressed: () => onGradePressed(Grade.again),
                      ),
                      _GradeButton(
                        label: 'Zor',
                        sublabel: state.cram
                            ? 'serbest'
                            : projectedIntervalLabel(review, Grade.hard),
                        color: AppColors.warning,
                        onPressed: () => onGradePressed(Grade.hard),
                      ),
                      _GradeButton(
                        label: 'İyi',
                        sublabel: state.cram
                            ? 'serbest'
                            : projectedIntervalLabel(review, Grade.good),
                        color: AppColors.teal,
                        onPressed: () => onGradePressed(Grade.good),
                      ),
                      _GradeButton(
                        label: 'Kolay',
                        sublabel: state.cram
                            ? 'serbest'
                            : projectedIntervalLabel(review, Grade.easy),
                        color: AppColors.indigo,
                        onPressed: () => onGradePressed(Grade.easy),
                      ),
                    ],
                  )
                : SizedBox(
                    height: 64,
                    child: Center(
                      child: Text(
                        'Cevabı görmek için karta dokunun',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _StudyCard extends StatelessWidget {
  const _StudyCard({
    required this.dueCard,
    required this.flipped,
    this.onTap,
  });

  final DueCard dueCard;
  final bool flipped;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final card = dueCard.card;
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          // Koyu temada sabit beyaz yerine tema yuzeyi (metin okunur kalir)
          color: scheme.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: flipped
                ? AppColors.teal
                : (isDark ? scheme.outlineVariant : const Color(0xFFD5DAE8)),
            width: flipped ? 1.6 : 1,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x14000000),
              blurRadius: 16,
              offset: Offset(0, 6),
            ),
          ],
        ),
        padding: const EdgeInsets.all(20),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 200),
          child: Column(
            key: ValueKey(flipped),
            children: [
              Text(
                flipped ? 'ARKA YÜZ' : 'ÖN YÜZ',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: flipped ? AppColors.teal : AppColors.indigo,
                ),
              ),
              const SizedBox(height: 12),
              if (card.imageUrl != null) ...[
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      resolveImageUrl(card.imageUrl!),
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stack) => Center(
                        child: Icon(Icons.broken_image_outlined,
                            color: scheme.onSurfaceVariant),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],
              Expanded(
                flex: 2,
                child: Center(
                  child: SingleChildScrollView(
                    child: Text(
                      flipped ? card.back : card.front,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                ),
              ),
              if (card.page != null)
                Text('Sayfa ${card.page}',
                    style: TextStyle(
                        fontSize: 11, color: scheme.onSurfaceVariant)),
            ],
          ),
        ),
      ),
    );
  }
}

class _GradeButton extends StatelessWidget {
  const _GradeButton({
    required this.label,
    required this.sublabel,
    required this.color,
    required this.onPressed,
  });

  final String label;
  final String sublabel;
  final Color color;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: color,
            padding: const EdgeInsets.symmetric(vertical: 10),
          ),
          onPressed: onPressed,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(label,
                  style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(sublabel,
                  style: const TextStyle(
                      fontSize: 11, color: Colors.white70)),
            ],
          ),
        ),
      ),
    );
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.state});

  final StudyState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final rows = [
      ('Tekrar', Grade.again, AppColors.danger),
      ('Zor', Grade.hard, AppColors.warning),
      ('İyi', Grade.good, AppColors.teal),
      ('Kolay', Grade.easy, AppColors.indigo),
    ];
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(Icons.emoji_events_outlined,
                  size: 56, color: AppColors.teal),
              const SizedBox(height: 10),
              Text(
                'Oturum tamamlandı!',
                textAlign: TextAlign.center,
                style: Theme.of(context)
                    .textTheme
                    .headlineSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 4),
              Text(
                state.cram
                    ? '${state.answered} kart çalışıldı (serbest mod — kayıt edilmedi)'
                    : '${state.answered} kart çalışıldı',
                textAlign: TextAlign.center,
                style: TextStyle(color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              for (final (label, grade, color) in rows)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 10),
                      Expanded(child: Text(label)),
                      Text('${state.gradeCounts[grade] ?? 0}',
                          style:
                              const TextStyle(fontWeight: FontWeight.w800)),
                    ],
                  ),
                ),
              if (state.offlineQueued > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${state.offlineQueued} cevap çevrimdışı kaydedildi; '
                  'bağlantı gelince otomatik gönderilecek.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 12, color: AppColors.teal),
                ),
              ],
              if (state.syncFailures > 0) ...[
                const SizedBox(height: 12),
                Text(
                  '${state.syncFailures} cevap sunucuya yazılamadı.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.warning),
                ),
              ],
              const SizedBox(height: 24),
              FilledButton(
                onPressed: () => context.pop(),
                child: const Text('Bitir'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
