import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../domain/card_set.dart';
import 'sets_bloc.dart';

/// Desteler: kullanicinin bilgi karti desteleri.
class SetsScreen extends StatelessWidget {
  const SetsScreen({super.key});

  /// Kart dosyasi sec -> istege bagli deste adi sor -> ice aktarimi baslat.
  Future<void> _importCards(BuildContext context) async {
    final bloc = context.read<SetsBloc>();
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'json', 'tsv', 'apkg', 'txt'],
      withData: false,
    );
    final file = result?.files.firstOrNull;
    final path = file?.path;
    if (file == null || path == null || !context.mounted) return;

    final controller = TextEditingController();
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Kart Dosyası İçe Aktar'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Deste adı',
            helperText: 'Boş bırakılırsa dosya adı kullanılır',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('İçe Aktar'),
          ),
        ],
      ),
    );
    if (title == null) return; // Vazgecildi.
    bloc.add(SetImportRequested(
      filePath: path,
      filename: file.name,
      setTitle: title.isEmpty ? null : title,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Desteler'),
        actions: [
          BlocBuilder<SetsBloc, SetsState>(
            buildWhen: (p, c) => p.importing != c.importing,
            builder: (context, state) => state.importing
                ? const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.upload_file_outlined),
                    tooltip: 'Kart Dosyası İçe Aktar',
                    onPressed: () => _importCards(context),
                  ),
          ),
        ],
      ),
      body: BlocConsumer<SetsBloc, SetsState>(
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
              message: state.error ?? 'Desteler yuklenemedi.',
              onRetry: () => context.read<SetsBloc>().add(const SetsStarted()),
            );
          }
          if (state.sets.isEmpty) {
            return const EmptyView(
              icon: Icons.style_outlined,
              title: 'Henuz deste yok',
              subtitle:
                  'Panelden hazir bir dokuman secip kart uretimini baslatin.',
            );
          }
          return RefreshIndicator(
            onRefresh: () async =>
                context.read<SetsBloc>().add(const SetsRefreshed()),
            child: ListView.builder(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.only(top: 8, bottom: 24),
              itemCount: state.sets.length,
              itemBuilder: (context, i) => _SetTile(set: state.sets[i]),
            ),
          );
        },
      ),
    );
  }
}

class _SetTile extends StatelessWidget {
  const _SetTile({required this.set});

  final CardSet set;

  Future<void> _rename(BuildContext context) async {
    final bloc = context.read<SetsBloc>();
    final controller = TextEditingController(text: set.title);
    final title = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Desteyi yeniden adlandir'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(labelText: 'Baslik'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Vazgec'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(dialogContext, controller.text.trim()),
            child: const Text('Kaydet'),
          ),
        ],
      ),
    );
    if (title != null && title.isNotEmpty) {
      bloc.add(SetRenameRequested(set.id, title));
    }
  }

  Future<void> _confirmDelete(BuildContext context) async {
    final bloc = context.read<SetsBloc>();
    final ok = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Deste silinsin mi?'),
        content: Text('"${set.title}" ve tum kartlari silinecek.'),
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
    if (ok == true) bloc.add(SetDeleteRequested(set.id));
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: const CircleAvatar(
          backgroundColor: Color(0xFFE0F2F1),
          child: Icon(Icons.style, color: AppColors.teal),
        ),
        title: Text(set.title, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          [
            '${set.cardCount} kart',
            if (set.description != null && set.description!.isNotEmpty)
              set.description!,
            if (set.status == 'failed' && set.error != null) set.error!,
          ].join(' • '),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            StatusChip(status: set.status),
            PopupMenuButton<String>(
              onSelected: (value) => switch (value) {
                'rename' => _rename(context),
                'delete' => _confirmDelete(context),
                _ => null,
              },
              itemBuilder: (context) => const [
                PopupMenuItem(
                  value: 'rename',
                  child: ListTile(
                    leading: Icon(Icons.edit_outlined),
                    title: Text('Yeniden adlandir'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
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
        onTap: () => context.push('/desteler/${set.id}'),
      ),
    );
  }
}
