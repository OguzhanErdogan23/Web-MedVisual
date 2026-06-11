import 'package:flutter/material.dart';

import '../../../core/theme.dart';
import '../domain/study_history.dart';

/// Yerel saatte YYYY-MM-DD anahtari (saf fonksiyon).
String dayKey(DateTime d) {
  final m = d.month.toString().padLeft(2, '0');
  final day = d.day.toString().padLeft(2, '0');
  return '${d.year}-$m-$day';
}

/// Bugunden geriye kesintisiz calisilan gun sayisi (saf fonksiyon).
/// Bugun 0 ise dunden saymaya baslar (bugun seriyi bozmaz, eklemez).
int computeStreak(Map<String, int> totals, DateTime today) {
  var d = DateTime(today.year, today.month, today.day);
  if ((totals[dayKey(d)] ?? 0) <= 0) d = d.subtract(const Duration(days: 1));
  var streak = 0;
  while ((totals[dayKey(d)] ?? 0) > 0) {
    streak++;
    d = d.subtract(const Duration(days: 1));
  }
  return streak;
}

/// 0..4 yogunluk kademesi (saf fonksiyon).
int intensityLevel(int total) {
  if (total <= 0) return 0;
  if (total < 5) return 1;
  if (total < 10) return 2;
  if (total < 20) return 3;
  return 4;
}

/// GitHub tarzi calisma isi haritasi + gun serisi cipi.
/// Sutun = hafta (eski -> yeni), satir = Pzt..Paz.
class StudyHeatmap extends StatelessWidget {
  const StudyHeatmap({super.key, required this.history, this.weeks = 18});

  final StudyHistory history;
  final int weeks;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final totals = {for (final d in history.days) d.date: d.total};
    final today = DateTime.now();
    final streak = computeStreak(totals, today);

    // Baslangici pazartesiye hizala
    var start = DateTime(today.year, today.month, today.day)
        .subtract(Duration(days: weeks * 7 - 1));
    while (start.weekday != DateTime.monday) {
      start = start.subtract(const Duration(days: 1));
    }

    final levelColors = [
      scheme.surfaceContainerHighest,
      AppColors.teal.withValues(alpha: 0.25),
      AppColors.teal.withValues(alpha: 0.45),
      AppColors.teal.withValues(alpha: 0.7),
      AppColors.teal,
    ];

    final columns = <Widget>[];
    var cursor = start;
    final endOfToday = DateTime(today.year, today.month, today.day);
    while (!cursor.isAfter(endOfToday)) {
      final cells = <Widget>[];
      for (var i = 0; i < 7; i++) {
        if (cursor.isAfter(endOfToday)) {
          cells.add(const SizedBox(width: 12, height: 12));
        } else {
          final total = totals[dayKey(cursor)] ?? 0;
          cells.add(
            Tooltip(
              message:
                  '${cursor.day}.${cursor.month}.${cursor.year}: $total tekrar',
              child: Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: levelColors[intensityLevel(total)],
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          );
        }
        if (i < 6) cells.add(const SizedBox(height: 3));
        cursor = cursor.add(const Duration(days: 1));
      }
      columns.add(Column(mainAxisSize: MainAxisSize.min, children: cells));
      columns.add(const SizedBox(width: 3));
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Çalışma Takvimi',
                    style: Theme.of(context)
                        .textTheme
                        .titleMedium
                        ?.copyWith(fontWeight: FontWeight.w700)),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '🔥 $streak gün seri',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.warning),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              reverse: true, // en yeni hafta gorunur baslasin
              child: Row(mainAxisSize: MainAxisSize.min, children: columns),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Text('Az',
                    style: TextStyle(
                        fontSize: 10, color: scheme.onSurfaceVariant)),
                const SizedBox(width: 4),
                for (final c in levelColors) ...[
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: c,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  const SizedBox(width: 3),
                ],
                const SizedBox(width: 1),
                Text('Çok',
                    style: TextStyle(
                        fontSize: 10, color: scheme.onSurfaceVariant)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
