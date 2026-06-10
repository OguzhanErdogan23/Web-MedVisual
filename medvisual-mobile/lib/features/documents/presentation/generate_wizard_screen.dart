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
    if (v == null || v.trim().isEmpty) return 'Sayfa araligi girin (orn. 25-50)';
    final re = RegExp(r'^\d+\s*-\s*\d+$');
    if (!re.hasMatch(v.trim())) return 'Format: baslangic-bitis (orn. 25-50)';
    final parts = v.split('-').map((p) => int.parse(p.trim())).toList();
    if (parts[0] < 1 || parts[1] < parts[0]) return 'Gecersiz aralik';
    final pages = widget.document?.pageCount;
    if (pages != null && parts[1] > pages) {
      return 'Dokuman $pages sayfa; aralik asiyor';
    }
    return null;
  }

  void _submit(BuildContext context) {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    context.read<GenerateCubit>().submit(
          documentId: widget.documentId,
          range: _range.text.trim(),
          count: int.parse(_count.text.trim()),
          enhance: _enhance,
          title: _title.text.trim().isEmpty ? null : _title.text.trim(),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Icerik Uret')),
      body: BlocConsumer<GenerateCubit, GenerateState>(
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
                        label: Text('Bilgi Karti'),
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
                      labelText: 'Sayfa araligi',
                      hintText: 'orn. 25-50',
                      prefixIcon: Icon(Icons.menu_book_outlined),
                    ),
                    validator: _validateRange,
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _count,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: isCards ? 'En fazla kart sayisi' : 'Soru sayisi',
                      prefixIcon: const Icon(Icons.numbers),
                    ),
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      final maxN = isCards ? 120 : 40;
                      if (n == null || n < 1 || n > maxN) {
                        return '1-$maxN arasi bir sayi girin';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _title,
                    decoration: InputDecoration(
                      labelText:
                          isCards ? 'Deste basligi (istege bagli)' : 'Quiz basligi (istege bagli)',
                      prefixIcon: const Icon(Icons.title),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SwitchListTile(
                    value: _enhance,
                    onChanged: (v) => setState(() => _enhance = v),
                    title: const Text('Gemini ile zenginlestir'),
                    subtitle: const Text(
                        'Daha tutarli ve klinik odakli sorular icin onerilir.'),
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
                        ? 'Baslatiliyor...'
                        : (isCards ? 'Kart Uret' : 'Quiz Uret')),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Uretim arka planda calisir; detay ekraninda ilerlemeyi gorebilirsiniz.',
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
