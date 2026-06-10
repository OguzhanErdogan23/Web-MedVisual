import 'package:flutter/material.dart';

import 'theme.dart';

/// Liste/detay ekranlarinin ortak goruntuleme durumu.
enum ViewStatus { initial, loading, success, failure }

/// Belge/set/quiz `status` alanini Turkce etikete cevirir.
String statusLabelTr(String status) => switch (status) {
      'processing' => 'Isleniyor',
      'generating' => 'Uretiliyor',
      'ready' => 'Hazir',
      'failed' => 'Hata',
      'expired' => 'Suresi doldu',
      _ => status,
    };

Color statusColor(String status) => switch (status) {
      'processing' || 'generating' => AppColors.indigo,
      'ready' => AppColors.success,
      'failed' => AppColors.danger,
      'expired' => AppColors.warning,
      _ => Colors.blueGrey,
    };

/// Durum cipi; isleniyor/uretiliyor durumlarinda yumusakca yanip soner.
class StatusChip extends StatelessWidget {
  const StatusChip({super.key, required this.status});

  final String status;

  bool get _busy => status == 'processing' || status == 'generating';

  @override
  Widget build(BuildContext context) {
    final color = statusColor(status);
    final chip = Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_busy)
            Padding(
              padding: const EdgeInsets.only(right: 6),
              child: SizedBox(
                width: 10,
                height: 10,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              ),
            ),
          Text(
            statusLabelTr(status),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
    return _busy ? _Pulse(child: chip) : chip;
  }
}

class _Pulse extends StatefulWidget {
  const _Pulse({required this.child});

  final Widget child;

  @override
  State<_Pulse> createState() => _PulseState();
}

class _PulseState extends State<_Pulse> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
    lowerBound: 0.45,
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) =>
      FadeTransition(opacity: _controller, child: widget.child);
}

/// Hata gorunumu + "Tekrar dene" butonu.
class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline,
                size: 44, color: AppColors.danger),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar dene'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Bos liste gorunumu.
class EmptyView extends StatelessWidget {
  const EmptyView({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52, color: Colors.blueGrey.shade200),
            const SizedBox(height: 12),
            Text(title, style: theme.textTheme.titleMedium),
            if (subtitle != null) ...[
              const SizedBox(height: 6),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: Colors.blueGrey),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Terim girisi icin otomatik tamamlamali alan. [options] bellekte tutulan
/// terim listesidir; bos olabilir (o zaman duz metin alani gibi davranir).
class TermAutocompleteField extends StatelessWidget {
  const TermAutocompleteField({
    super.key,
    required this.controller,
    required this.options,
    this.labelText = 'Terim (istege bagli)',
  });

  final TextEditingController controller;
  final List<String> options;
  final String labelText;

  @override
  Widget build(BuildContext context) {
    return Autocomplete<String>(
      initialValue: controller.value,
      optionsBuilder: (value) {
        final query = value.text.trim().toLowerCase();
        if (query.isEmpty) return const Iterable<String>.empty();
        return options
            .where((o) => o.toLowerCase().contains(query))
            .take(20);
      },
      onSelected: (selection) => controller.text = selection,
      fieldViewBuilder:
          (context, textController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: textController,
          focusNode: focusNode,
          decoration: InputDecoration(labelText: labelText),
          // Dis controller'i her degisiklikte senkronla (manuel giris dahil).
          onChanged: (value) => controller.text = value,
        );
      },
      optionsViewBuilder: (context, onSelected, opts) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4,
            borderRadius: BorderRadius.circular(8),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 240, maxWidth: 360),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: opts.length,
                itemBuilder: (context, i) {
                  final option = opts.elementAt(i);
                  return ListTile(
                    dense: true,
                    title: Text(option),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

void showSnack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppColors.danger : null,
      ),
    );
}
