import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../domain/study_history.dart';

/// 14 gunluk tekrar grafigi: her gun icin bir cubuk; dogru cevaplar yesil,
/// kalan (yanlis) kismi gri. Harici grafik paketi kullanmaz.
class ProgressChart extends StatelessWidget {
  const ProgressChart({super.key, required this.history});

  final StudyHistory history;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final days = history.days;
    final maxTotal =
        days.fold<int>(0, (m, d) => d.total > m ? d.total : m);

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardTheme.color,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: theme.brightness == Brightness.dark
              ? const Color(0xFF2C313B)
              : const Color(0xFFE3E6F0),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insights_outlined,
                  size: 18, color: AppColors.indigo),
              const SizedBox(width: 6),
              Text(
                'Son 14 gun',
                style: theme.textTheme.titleSmall
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const Spacer(),
              Text(
                '${history.totalReviews} tekrar',
                style: const TextStyle(
                    color: Colors.blueGrey,
                    fontSize: 12,
                    fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (history.totalReviews == 0)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(
                child: Text(
                  'Henüz tekrar yok. Çalışmaya başladığınızda\n'
                  'ilerlemeniz burada gorunecek.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.blueGrey, fontSize: 13),
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  for (final day in days)
                    Expanded(
                      child: _Bar(
                        day: day,
                        maxTotal: maxTotal == 0 ? 1 : maxTotal,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({required this.day, required this.maxTotal});

  final StudyDay day;
  final int maxTotal;

  @override
  Widget build(BuildContext context) {
    const maxHeight = 96.0;
    final totalH = day.total == 0 ? 2.0 : (day.total / maxTotal) * maxHeight;
    final correctH =
        day.total == 0 ? 0.0 : (day.correct / maxTotal) * maxHeight;
    final label = day.date.length >= 5 ? day.date.substring(5) : day.date;
    return Tooltip(
      message: '$label\n${day.correct}/${day.total} dogru',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                Container(
                  height: totalH,
                  decoration: BoxDecoration(
                    color: Colors.blueGrey.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                Container(
                  height: correctH,
                  decoration: BoxDecoration(
                    color: AppColors.success,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(fontSize: 8, color: Colors.blueGrey),
              maxLines: 1,
              overflow: TextOverflow.clip,
            ),
          ],
        ),
      ),
    );
  }
}
