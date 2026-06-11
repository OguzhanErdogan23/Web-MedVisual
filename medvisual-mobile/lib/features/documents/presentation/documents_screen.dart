import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../../study/domain/study_models.dart';
import '../../study/presentation/progress_chart.dart';
import '../domain/document.dart';
import 'books_sheet.dart';
import 'documents_bloc.dart';

/// Panel: istatistik cipleri + dokuman listesi + PDF yukleme + kutuphane.
class DocumentsScreen extends StatelessWidget {
  const DocumentsScreen({super.key});

  Future<void> _pickPdf(BuildContext context) async {
    final bloc = context.read<DocumentsBloc>();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: false,
    );
    final file = result?.files.firstOrNull;
    if (file == null) return;
    bloc.add(DocumentUploadRequested(
      filename: file.name,
      path: file.path,
      bytes: file.bytes,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MedVisual'),
        actions: [
          IconButton(
            tooltip: 'Kütüphane',
            icon: const Icon(Icons.local_library_outlined),
            onPressed: () => showBooksSheet(context),
          ),
          IconButton(
            tooltip: 'Ayarlar',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () => context.push('/ayarlar'),
          ),
        ],
      ),
      floatingActionButton: BlocBuilder<DocumentsBloc, DocumentsState>(
        buildWhen: (p, c) => p.uploading != c.uploading,
        builder: (context, state) => FloatingActionButton.extended(
          onPressed: state.uploading ? null : () => _pickPdf(context),
          icon: state.uploading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.upload_file),
          label: Text(state.uploading ? 'Yükleniyor...' : 'PDF Yükle'),
        ),
      ),
      body: BlocConsumer<DocumentsBloc, DocumentsState>(
        listenWhen: (p, c) => p.notice != c.notice || p.error != c.error,
        listener: (context, state) {
          if (state.notice != null) showSnack(context, state.notice!);
          if (state.error != null && state.status != ViewStatus.failure) {
            showSnack(context, state.error!, error: true);
          }
        },
        builder: (context, state) {
          if (state.status == ViewStatus.loading ||
              state.status == ViewStatus.initial) {
            return const Center(child: CircularProgressIndicator());
          }
          if (state.status == ViewStatus.failure) {
            return ErrorView(
              message: state.error ?? 'Dokümanlar yüklenemedi.',
              onRetry: () =>
                  context.read<DocumentsBloc>().add(const DocumentsRefreshed()),
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<DocumentsBloc>().add(const DocumentsRefreshed()),
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(bottom: 96),
              children: [
                if (state.stats != null) _StatsRow(stats: state.stats!),
                if (state.history != null)
                  ProgressChart(history: state.history!),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 4),
                  child: Text(
                    'Dokümanlar',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                ),
                if (state.documents.isEmpty)
                  const Padding(
                    padding: EdgeInsets.only(top: 48),
                    child: EmptyView(
                      icon: Icons.picture_as_pdf_outlined,
                      title: 'Henüz doküman yok',
                      subtitle:
                          'Bir PDF yükleyin veya kütüphaneden hazır kitap seçin.',
                    ),
                  )
                else
                  ...state.documents.map((d) => _DocumentTile(document: d)),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow({required this.stats});

  final StudyStats stats;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final items = [
      (Icons.picture_as_pdf_outlined, 'Doküman', stats.documents),
      (Icons.style_outlined, 'Deste', stats.sets),
      (Icons.crop_portrait, 'Kart', stats.cards),
      (Icons.quiz_outlined, 'Quiz', stats.quizzes),
      (Icons.alarm, 'Vadesi gelen', stats.dueNow),
      (Icons.school_outlined, 'Çalışılan', stats.studiedCards),
    ];
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final (icon, label, value) in items)
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                // Koyu temada sabit beyaz yerine tema yuzeyi
                color: scheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                    color: isDark
                        ? scheme.outlineVariant
                        : const Color(0xFFE3E6F0)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(icon, size: 18, color: AppColors.teal),
                  const SizedBox(width: 6),
                  Text(
                    '$value',
                    style: const TextStyle(
                        fontWeight: FontWeight.w800, color: AppColors.indigo),
                  ),
                  const SizedBox(width: 4),
                  Text(label,
                      style: TextStyle(
                          fontSize: 12, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _DocumentTile extends StatelessWidget {
  const _DocumentTile({required this.document});

  final Document document;

  @override
  Widget build(BuildContext context) {
    final d = document;
    final subtitleParts = [
      if (d.pageCount != null) '${d.pageCount} sayfa',
      if (d.status == 'failed' && d.error != null) d.error!,
      if (d.status == 'expired')
        'DIP motorunda süresi doldu; yeniden yükleyin.',
    ];
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE8EAF6),
          child: Icon(Icons.picture_as_pdf, color: AppColors.indigo),
        ),
        title: Text(d.filename, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: subtitleParts.isEmpty
            ? null
            : Text(subtitleParts.join(' • '),
                maxLines: 2, overflow: TextOverflow.ellipsis),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip(status: d.status),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'delete') {
                  context
                      .read<DocumentsBloc>()
                      .add(DocumentDeleteRequested(d.id));
                }
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline, color: AppColors.danger),
                    title: Text('Sil'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ),
        onTap: d.isReady
            ? () => context.push('/panel/uret/${d.id}', extra: d)
            : null,
      ),
    );
  }
}
