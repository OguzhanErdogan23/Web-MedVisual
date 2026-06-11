import 'package:flutter_test/flutter_test.dart';
import 'package:medvisual_mobile/features/study/presentation/study_heatmap.dart';

void main() {
  group('computeStreak — saf fonksiyon', () {
    final today = DateTime(2026, 6, 11);

    test('hic calisma yoksa 0', () {
      expect(computeStreak({}, today), 0);
    });

    test('bugun dahil ardisik gunler sayilir', () {
      final totals = {
        '2026-06-11': 5,
        '2026-06-10': 3,
        '2026-06-09': 1,
        '2026-06-07': 9, // aradaki 08 bos: seri burada kirilir
      };
      expect(computeStreak(totals, today), 3);
    });

    test('bugun 0 ise seri bozulmaz, dunden sayilir', () {
      final totals = {'2026-06-10': 2, '2026-06-09': 4};
      expect(computeStreak(totals, today), 2);
    });

    test('yalnizca eski gunler: seri 0', () {
      final totals = {'2026-06-01': 7};
      expect(computeStreak(totals, today), 0);
    });
  });

  group('intensityLevel', () {
    test('kademeler', () {
      expect(intensityLevel(0), 0);
      expect(intensityLevel(1), 1);
      expect(intensityLevel(4), 1);
      expect(intensityLevel(5), 2);
      expect(intensityLevel(9), 2);
      expect(intensityLevel(10), 3);
      expect(intensityLevel(19), 3);
      expect(intensityLevel(20), 4);
      expect(intensityLevel(999), 4);
    });
  });

  group('dayKey', () {
    test('yerel YYYY-MM-DD bicimi', () {
      expect(dayKey(DateTime(2026, 6, 1)), '2026-06-01');
      expect(dayKey(DateTime(2026, 12, 31)), '2026-12-31');
    });
  });
}
