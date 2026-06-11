import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../data/quizzes_repository.dart';
import '../domain/quiz.dart';
import 'quiz_player_bloc.dart';

/// Quiz oynatici: soru, 4 sik, aninda dogru/yanlis boyama, skor ekrani.
class QuizPlayerScreen extends StatelessWidget {
  const QuizPlayerScreen({super.key, required this.quizId});

  final String quizId;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) =>
          QuizPlayerBloc(context.read<QuizzesRepository>(), quizId)
            ..add(const QuizPlayerStarted()),
      child: const _PlayerBody(),
    );
  }
}

class _PlayerBody extends StatelessWidget {
  const _PlayerBody();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: BlocBuilder<QuizPlayerBloc, QuizPlayerState>(
          builder: (context, state) => Text(
            state.quiz?.title ?? 'Quiz',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
      body: BlocBuilder<QuizPlayerBloc, QuizPlayerState>(
        builder: (context, state) {
          return switch (state.phase) {
            QuizPhase.loading =>
              const Center(child: CircularProgressIndicator()),
            QuizPhase.generating => const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Üretiliyor...',
                        style: TextStyle(
                            fontWeight: FontWeight.w700,
                            color: AppColors.indigo)),
                    SizedBox(height: 6),
                    Text(
                      'Sorular hazırlanıyor; bu işlem birkaç dakika sürebilir.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            QuizPhase.failure => ErrorView(
                message: state.error ?? 'Quiz yüklenemedi.',
                onRetry: () => context
                    .read<QuizPlayerBloc>()
                    .add(const QuizPlayerStarted()),
              ),
            QuizPhase.finished => _ScoreView(state: state),
            QuizPhase.playing => _QuestionView(state: state),
          };
        },
      ),
    );
  }
}

class _QuestionView extends StatelessWidget {
  const _QuestionView({required this.state});

  final QuizPlayerState state;

  Color? _optionColor(int i) {
    final q = state.currentQuestion!;
    if (!state.answered) return null;
    if (i == q.answerIndex) return AppColors.success;
    if (i == state.selected) return AppColors.danger;
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final quiz = state.quiz!;
    final q = state.currentQuestion!;
    final total = quiz.questions.length;
    final isLast = state.index == total - 1;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Soru ${state.index + 1} / $total',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.indigo)),
                Text('Skor: ${state.score}',
                    style: const TextStyle(
                        fontWeight: FontWeight.w700, color: AppColors.teal)),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (state.index + (state.answered ? 1 : 0)) / total,
                minHeight: 6,
                backgroundColor: scheme.surfaceContainerHighest,
              ),
            ),
            const SizedBox(height: 20),
            Card(
              margin: EdgeInsets.zero,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Text(
                  q.question,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.separated(
                itemCount: q.options.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final color = _optionColor(i);
                  return OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 14),
                      // Koyu temada sabit beyaz yerine tema yuzeyi
                      backgroundColor:
                          color?.withValues(alpha: 0.1) ?? scheme.surface,
                      side: BorderSide(
                        color: color ??
                            (isDark
                                ? scheme.outlineVariant
                                : const Color(0xFFD5DAE8)),
                        width: color != null ? 1.8 : 1,
                      ),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: state.answered
                        ? null
                        : () => context
                            .read<QuizPlayerBloc>()
                            .add(OptionSelected(i)),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 13,
                          backgroundColor:
                              color ?? const Color(0xFFE8EAF6),
                          child: Text(
                            String.fromCharCode(65 + i),
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: color != null
                                  ? Colors.white
                                  : AppColors.indigo,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            q.options[i],
                            style: TextStyle(
                              color: scheme.onSurface,
                              fontWeight: color != null
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                            ),
                          ),
                        ),
                        if (state.answered && i == q.answerIndex)
                          const Icon(Icons.check_circle,
                              color: AppColors.success),
                        if (state.answered &&
                            i == state.selected &&
                            i != q.answerIndex)
                          const Icon(Icons.cancel, color: AppColors.danger),
                      ],
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: state.answered
                  ? () => context
                      .read<QuizPlayerBloc>()
                      .add(const NextQuestionRequested())
                  : null,
              icon: Icon(isLast ? Icons.flag : Icons.arrow_forward),
              label: Text(isLast ? 'Bitir' : 'Sonraki'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScoreView extends StatelessWidget {
  const _ScoreView({required this.state});

  final QuizPlayerState state;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final questions = state.quiz?.questions ?? const [];
    final total = questions.length;
    final pct = total == 0 ? 0 : (state.score * 100 / total).round();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Icon(
          pct >= 70 ? Icons.emoji_events : Icons.sentiment_satisfied_alt,
          size: 64,
          color: pct >= 70 ? AppColors.teal : AppColors.warning,
        ),
        const SizedBox(height: 12),
        Text('Quiz tamamlandı!',
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .headlineSmall
                ?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 8),
        Text(
          '$total sorudan ${state.score} doğru (%$pct)',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 16, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            OutlinedButton.icon(
              onPressed: () => context
                  .read<QuizPlayerBloc>()
                  .add(const QuizRestartRequested()),
              icon: const Icon(Icons.replay),
              label: const Text('Tekrar çöz'),
            ),
            const SizedBox(width: 12),
            FilledButton(
              onPressed: () => context.pop(),
              child: const Text('Kapat'),
            ),
          ],
        ),
        // Soru bazlı inceleme (web paritesi): doğru cevap + kullanıcının yanlışı
        if (state.answers.length == total && total > 0) ...[
          const SizedBox(height: 24),
          Text('Soru incelemesi',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          for (var i = 0; i < total; i++)
            _ReviewCard(
              index: i,
              question: questions[i],
              userAnswer: state.answers[i],
            ),
        ],
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.index,
    required this.question,
    required this.userAnswer,
  });

  final int index;
  final QuizQuestion question;
  final int userAnswer;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final correct = userAnswer == question.answerIndex;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: correct
              ? AppColors.success.withValues(alpha: 0.4)
              : AppColors.danger.withValues(alpha: 0.4),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${index + 1}. ${question.question}',
                style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            for (var oi = 0; oi < question.options.length; oi++)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('${String.fromCharCode(65 + oi)}) ',
                        style: TextStyle(
                            fontSize: 13, color: scheme.onSurfaceVariant)),
                    Expanded(
                      child: Text(
                        question.options[oi],
                        style: TextStyle(
                          fontSize: 13,
                          color: oi == question.answerIndex
                              ? AppColors.success
                              : (oi == userAnswer
                                  ? AppColors.danger
                                  : scheme.onSurfaceVariant),
                          fontWeight: oi == question.answerIndex
                              ? FontWeight.w700
                              : FontWeight.w400,
                          decoration: (oi == userAnswer && !correct)
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                    ),
                    if (oi == question.answerIndex)
                      const Icon(Icons.check, size: 16,
                          color: AppColors.success),
                    if (oi == userAnswer && !correct)
                      const Icon(Icons.close, size: 16,
                          color: AppColors.danger),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
