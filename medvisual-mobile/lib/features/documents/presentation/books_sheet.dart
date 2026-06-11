import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../core/api_client.dart';
import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../data/documents_repository.dart';
import '../domain/document.dart';
import 'documents_bloc.dart';

/// Kutuphane alt sayfasi: DIP motorundaki hazir kitaplari listeler.
Future<void> showBooksSheet(BuildContext context) {
  final bloc = context.read<DocumentsBloc>();
  final repo = context.read<DocumentsRepository>();
  return showModalBottomSheet(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) => SizedBox(
      height: MediaQuery.of(sheetContext).size.height * 0.7,
      child: _BooksSheetBody(repo: repo, bloc: bloc),
    ),
  );
}

class _BooksSheetBody extends StatelessWidget {
  const _BooksSheetBody({required this.repo, required this.bloc});

  final DocumentsRepository repo;
  final DocumentsBloc bloc;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: Text('Kütüphane',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700)),
        ),
        Expanded(
          child: FutureBuilder<List<Book>>(
            future: repo.listBooks(),
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              if (snapshot.hasError) {
                return ErrorView(message: readableApiError(snapshot.error!));
              }
              final books = snapshot.data ?? const <Book>[];
              if (books.isEmpty) {
                return const EmptyView(
                  icon: Icons.local_library_outlined,
                  title: 'Kütüphane boş',
                  subtitle: 'DIP motorunun books/ klasorune PDF ekleyin.',
                );
              }
              return ListView.builder(
                itemCount: books.length,
                itemBuilder: (context, i) {
                  final b = books[i];
                  final meta = [
                    if (b.pages != null) '${b.pages} sayfa',
                    if (b.sizeMb != null)
                      '${b.sizeMb!.toStringAsFixed(1)} MB',
                  ].join(' • ');
                  return ListTile(
                    leading: const Icon(Icons.menu_book_outlined,
                        color: AppColors.teal),
                    title: Text(b.display,
                        maxLines: 2, overflow: TextOverflow.ellipsis),
                    subtitle: meta.isEmpty ? null : Text(meta),
                    trailing: FilledButton.tonal(
                      onPressed: () {
                        bloc.add(BookLoadRequested(b.name));
                        Navigator.of(context).pop();
                      },
                      child: const Text('Yükle'),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
