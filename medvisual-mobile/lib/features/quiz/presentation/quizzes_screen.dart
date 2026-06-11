import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/export_sheet.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../data/quizzes_repository.dart';
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
              message: state.error ?? 'Quizler yüklenemedi.',
              onRetry: () => context.read<QuizzesCubit>().load(),
            );
          }
          if (state.quizzes.isEmpty) {
            return const EmptyView(
              icon: Icons.quiz_outlined,
              title: 'Henüz quiz yok',
              subtitle:
                  'Panelden hazır bir doküman seçip quiz üretimini başlatın.',
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
            child: const Text('Vazgeç'),
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

  Future<void> _rename(BuildContext context) async {
    final cubit = context.read<QuizzesCubit>();
    final controller = TextEditingController(text: quiz.title);
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Quizi yeniden adlandır'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Başlık'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (title != null && title.isNotEmpty && title != quiz.title) {
      cubit.rename(quiz.id, title);
    }
  }

  Future<void> _export(BuildContext context) {
    final repo = context.read<QuizzesRepository>();
    return showExportSheet(
      context,
      formats: const ['json', 'csv', 'txt', 'pdf'],
      download: (format) => repo.export(quiz.id, format),
    );
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
            PopupMenuButton<String>(
              onSelected: (value) => switch (value) {
                'rename' => _rename(context),
                'export' => _export(context),
                'delete' => _confirmDelete(context),
                _ => null,
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Yeniden adlandır'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                if (quiz.isReady)
                  const PopupMenuItem(
                    value: 'export',
                    child: ListTile(
                      leading: Icon(Icons.ios_share),
                      title: Text('Dışa Aktar'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading:
                        Icon(Icons.delete_outline, color: AppColors.danger),
                    title: Text('Sil'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: () => context.push('/quizler/${quiz.id}'),
        onLongPress: () => _rename(context),
      ),
    );
  }
}
