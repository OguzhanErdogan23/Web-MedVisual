import 'package:flutter/material.dart';
import 'package:share_plus/share_plus.dart';

import 'export_file.dart';
import 'widgets.dart';

/// Disa aktarma alt sayfasi: format sec, bayt indir, gecici dosya yaz, paylas.
/// [download] secilen formati indirip [ExportFile] dondurmelidir.
Future<void> showExportSheet(
  BuildContext context, {
  required List<String> formats,
  required Future<ExportFile> Function(String format) download,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) =>
        _ExportSheetBody(formats: formats, download: download),
  );
}

const _formatLabels = <String, String>{
  'json': 'JSON',
  'csv': 'CSV',
  'tsv': 'TSV',
  'anki': 'Anki (metin)',
  'txt': 'Düz metin',
  'pdf': 'PDF',
  'apkg': 'Anki paketi (.apkg)',
};

const _formatIcons = <String, IconData>{
  'json': Icons.data_object,
  'csv': Icons.grid_on,
  'tsv': Icons.grid_on,
  'anki': Icons.school_outlined,
  'txt': Icons.text_snippet_outlined,
  'pdf': Icons.picture_as_pdf_outlined,
  'apkg': Icons.inventory_2_outlined,
};

class _ExportSheetBody extends StatefulWidget {
  const _ExportSheetBody({required this.formats, required this.download});

  final List<String> formats;
  final Future<ExportFile> Function(String format) download;

  @override
  State<_ExportSheetBody> createState() => _ExportSheetBodyState();
}

class _ExportSheetBodyState extends State<_ExportSheetBody> {
  String? _busyFormat;

  Future<void> _export(String format) async {
    setState(() => _busyFormat = format);
    try {
      final file = await widget.download(format);
      final path = await file.writeToTemp();
      await Share.shareXFiles([XFile(path)], text: file.filename);
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        setState(() => _busyFormat = null);
        showSnack(context, 'Disa aktarilamadi. Lutfen tekrar deneyin.',
            error: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _busyFormat != null;
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Text(
                'Dışa Aktar',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ),
            for (final format in widget.formats)
              ListTile(
                enabled: !busy,
                leading: Icon(_formatIcons[format] ?? Icons.download_outlined),
                title: Text(_formatLabels[format] ?? format.toUpperCase()),
                trailing: _busyFormat == format
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
                onTap: busy ? null : () => _export(format),
              ),
          ],
        ),
      ),
    );
  }
}
