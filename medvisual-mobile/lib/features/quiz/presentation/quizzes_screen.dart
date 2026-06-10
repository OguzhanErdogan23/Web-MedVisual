import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../domain/quiz.dart';
import 'quizzes_cubit.dart';

/// Quizler: uretilen quizlerin listesi.
class QuizzesScreen extends StatelessWidget {
  const QuizzesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Quizler')),
      body: BlocConsumer<QuizzesCubit, QuizzesState>(
        listenWhen: (p, c) => p.notice != c.notice,
        listener: (context, state) {
          if (state.notice != null) showSnack(context, state.notice!);
        },
        builder: (context, state) {
          if (state.status == ViewStatus.loading ||
              state.status == ViewStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ViewStatus.failure) {
            return ErrorView(
              message: state.error ?? 'Quizler yuklenemedi.',
              onRetry: () => context.read<QuizzesCubit>().load(),
            );
          }
          if (state.quizzes.isEmpty) {
            return const EmptyView(
              icon: Icons.quiz_outlined,
              title: 'Henuz quiz yok',
              subtitle:
                  'Panelden hazir bir dokuman secip quiz uretimini baslatin.',
            );
          }
          return RefreshIndicator(
            onRefresh: () => context.read<QuizzesCubit>().load(silent: true),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: state.quizzes.length,
              itemBuilder: (context, i) => _QuizTile(quiz: state.quizzes[i]),
            ),
          );
        },
      ),
    );
  }
}

class _QuizTile extends StatelessWidget {
  const _QuizTile({required this.quiz});

  final Quiz quiz;

  Future<void> _confirmDelete(BuildContext context) async {
    final cubit = context.read<QuizzesCubit>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quiz silinsin mi?'),
        content: Text('"${quiz.title}" silinecek.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    if (ok == true) cubit.delete(quiz.id);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFFFF3E0),
          child: Icon(Icons.quiz, color: AppColors.warning),
        ),
        title: Text(quiz.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            '${quiz.questionCount} soru',
            if (quiz.status == 'failed' && quiz.error != null) quiz.error!,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip(status: quiz.status),
            IconButton(
              tooltip: 'Sil',
              icon: const Icon(Icons.delete_outline),
              onPressed: () => _confirmDelete(context),
            ),
          ],
        ),
        onTap: () => context.push('/quizler/${quiz.id}'),
      ),
    );
  }
}
