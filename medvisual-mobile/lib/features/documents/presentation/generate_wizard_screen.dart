import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme.dart';
import '../../../core/widgets.dart';
import '../data/documents_repository.dart';
import '../domain/document.dart';
import 'generate_cubit.dart';

/// Uretim sihirbazi: secili dokumandan kart destesi veya quiz uretir.
class GenerateWizardScreen extends StatelessWidget {
  const GenerateWizardScreen({
    super.key,
    required this.documentId,
    this.document,
  });

  final String documentId;
  final Document? document;

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => GenerateCubit(context.read<DocumentsRepository>()),
      child: _WizardBody(documentId: documentId, document: document),
    );
  }
}

class _WizardBody extends StatefulWidget {
  const _WizardBody({required this.documentId, this.document});

  final String documentId;
  final Document? document;

  @override
  State<_WizardBody> createState() => _WizardBodyState();
}

class _WizardBodyState extends State<_WizardBody> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _range;
  final _count = TextEditingController(text: '20');
  final _title = TextEditingController();
  bool _enhance = true;

  @override
  void initState() {
    super.initState();
    final pages = widget.document?.pageCount;
    _range = TextEditingController(
        text: pages != null ? '1-${pages.clamp(1, 25)}' : '1-25');
  }

  @override
  void dispose() {
    _range.dispose();
    _count.dispose();
    _title.dispose();
    super.dispose();
  }

  String? _validateRange(String? v) {
    if (v == null || v.trim().isEmpty) {
      return 'Sayfa aralığı girin (örn. 25-50 veya tek sayfa 25)';
    }
    // Tek sayfa da kabul edilir (web ile ayni kural)
    final m = RegExp(r'^(\d+)(?:\s*-\s*(\d+))?$').firstMatch(v.trim());
    if (m == null) return 'Format: 25-50 veya tek sayfa 25';
    final start = int.parse(m.group(1)!);
    final end = m.group(2) != null ? int.parse(m.group(2)!) : start;
    if (start < 1 || end < start) return 'Geçersiz aralık';
    final pages = widget.document?.pageCount;
    if (pages != null && end > pages) {
      return 'Doküman $pages sayfa; aralık aşıyor';
    }
    return null;
  }

  /// "n" girilirse backend icin "n-n" bicimine cevirir.
  String _normalizedRange() {
    final m =
        RegExp(r'^(\d+)(?:\s*-\s*(\d+))?$').firstMatch(_range.text.trim())!;
    final start = m.group(1)!;
    final end = m.group(2) ?? start;
    return '$start-$end';
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<GenerateCubit>().submit(
          documentId: widget.documentId,
          range: _normalizedRange(),
          count: int.parse(_count.text.trim()),
          enhance: _enhance,
          title: _title.text.trim().isEmpty ? null : _title.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('İçerik Üret')),
      body: BlocConsumer<GenerateCubit, GenerateState>(
        // Hata/yonlendirme yalnizca degistiginde islensin: sekme degisiminde
        // ayni hata snack'inin tekrar gosterilmesini onler
        listenWhen: (p, c) =>
            p.error != c.error || p.createdId != c.createdId,
        listener: (context, state) {
          if (state.error != null) {
            showSnack(context, state.error!, error: true);
          }
          if (state.createdId != null) {
            final path = state.createdKind == GenerateKind.cards
                ? '/desteler/${state.createdId}'
                : '/quizler/${state.createdId}';
            context.pushReplacement(path);
          }
        },
        builder: (context, state) {
          final isCards = state.kind == GenerateKind.cards;
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.document != null)
                    Card(
                      margin: const EdgeInsets.only(bottom: 16),
                      child: ListTile(
                        leading: const Icon(Icons.picture_as_pdf,
                            color: AppColors.indigo),
                        title: Text(widget.document!.filename,
                            maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: widget.document!.pageCount != null
                            ? Text('${widget.document!.pageCount} sayfa')
                            : null,
                      ),
                    ),
                  SegmentedButton<GenerateKind>(
                    segments: const [
                      ButtonSegment(
                        value: GenerateKind.cards,
                        label: Text('Bilgi Kartı'),
                        icon: Icon(Icons.style_outlined),
                      ),
                      ButtonSegment(
                        value: GenerateKind.quiz,
                        label: Text('Quiz'),
                        icon: Icon(Icons.quiz_outlined),
                      ),
                    ],
                    selected: {state.kind},
                    onSelectionChanged: (s) =>
                        context.read<GenerateCubit>().setKind(s.first),
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: _range,
                    decoration: const InputDecoration(
                      labelText: 'Sayfa aralığı',
                      hintText: 'örn. 25-50',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    validator: _validateRange,
                  ),
                  const SizedBox(height: 14),
                  // Kaynak secimi: metin katmani bozuk PDF'lerde OCR'a zorlama
                  // imkani (web paritesi)
                  DropdownButtonFormField<GenerateSource>(
                    value: state.source,
                    decoration: const InputDecoration(
                      labelText: 'Kaynak',
                      prefixIcon: Icon(Icons.input_outlined),
                    ),
                    items: const [
                      DropdownMenuItem(
                          value: GenerateSource.auto,
                          child: Text('Otomatik')),
                      DropdownMenuItem(
                          value: GenerateSource.text,
                          child: Text('Metin katmanı')),
                      DropdownMenuItem(
                          value: GenerateSource.ocr, child: Text('OCR')),
                    ],
                    onChanged: (v) {
                      if (v != null) {
                        context.read<GenerateCubit>().setSource(v);
                      }
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _count,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isCards ? 'En fazla kart sayısı' : 'Soru sayısı',
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      final maxN = isCards ? 120 : 40;
                      if (n == null || n < 1 || n > maxN) {
                        return '1-$maxN arası bir sayı girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _title,
                    decoration: InputDecoration(
                      labelText: isCards
                          ? 'Deste başlığı (isteğe bağlı)'
                          : 'Quiz başlığı (isteğe bağlı)',
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _enhance,
                    onChanged: (v) => setState(() => _enhance = v),
                    title: const Text('Gemini ile zenginleştir'),
                    subtitle: const Text(
                        'Daha tutarlı ve klinik odaklı içerik için önerilir.'),
                    secondary:
                        const Icon(Icons.auto_awesome, color: AppColors.teal),
                    contentPadding: EdgeInsets.zero,
                  ),
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed:
                        state.submitting ? null : () => _submit(context),
                    icon: state.submitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.play_arrow),
                    label: Text(state.submitting
                        ? 'Başlatılıyor...'
                        : (isCards ? 'Kart Üret' : 'Quiz Üret')),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Üretim arka planda çalışır; detay ekranında ilerlemeyi görebilirsiniz.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 12, color: Colors.blueGrey),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
