import 'package:flutter_test/flutter_test.dart';
import 'package:medvisual_mobile/features/study/domain/review_state.dart';
import 'package:medvisual_mobile/features/study/domain/sm2.dart';

void main() {
  final now = DateTime.utc(2026, 6, 10, 12, 0, 0);

  group('applySm2 — saf SM-2 fonksiyonu (sunucuyla birebir)', () {
    test('ilk "iyi" cevap: 1 gun, repetitions 1, EF sabit (2.5)', () {
      const initial = ReviewState();
      final next = applySm2(initial, Grade.good, now);

      expect(next.intervalDays, 1.0);
      expect(next.repetitions, 1);
      // q=4: EF + (0.1 - 1*(0.08 + 0.02)) = EF + 0 → degismez.
      expect(next.easeFactor, closeTo(2.5, 1e-9));
      expect(next.dueAt, now.add(const Duration(days: 1)));
    });

    test('ikinci "iyi" cevap: 6 gun', () {
      const initial = ReviewState();
      final first = applySm2(initial, Grade.good, now);
      final second = applySm2(first, Grade.good, now);

      expect(second.intervalDays, 6.0);
      expect(second.repetitions, 2);
      expect(second.dueAt, now.add(const Duration(days: 6)));
    });

    test('ucuncu "iyi" cevap: interval = round(6 * EF, 2)', () {
      const initial = ReviewState();
      final s1 = applySm2(initial, Grade.good, now);
      final s2 = applySm2(s1, Grade.good, now);
      final s3 = applySm2(s2, Grade.good, now);

      // EF iki "iyi"den sonra hala 2.5 → 6 * 2.5 = 15.0
      expect(s3.intervalDays, closeTo(6 * s2.easeFactor, 1e-9));
      expect(s3.intervalDays, 15.0);
      expect(s3.repetitions, 3);
    });

    test('"tekrar": sayac sifirlanir, 10 dk sonra gelir, EF duser', () {
      final mature = applySm2(
          applySm2(const ReviewState(), Grade.good, now), Grade.good, now);
      final next = applySm2(mature, Grade.again, now);

      expect(next.repetitions, 0);
      expect(next.intervalDays, 0.0);
      expect(next.dueAt, now.add(const Duration(minutes: 10)));
      // q=2: EF + (0.1 - 3*(0.08 + 3*0.02)) = EF - 0.32
      expect(next.easeFactor, closeTo(mature.easeFactor - 0.32, 1e-9));
      expect(next.easeFactor, lessThan(mature.easeFactor));
    });

    test('"kolay": EF yukselir (+0.1)', () {
      const initial = ReviewState();
      final next = applySm2(initial, Grade.easy, now);

      expect(next.easeFactor, closeTo(2.6, 1e-9));
      expect(next.repetitions, 1);
      expect(next.intervalDays, 1.0);
    });

    test('"zor": basarili sayilir ama "iyi"den kisa aralik verir', () {
      final afterOne = applySm2(const ReviewState(), Grade.good, now);

      final good = applySm2(afterOne, Grade.good, now);
      final hard = applySm2(afterOne, Grade.hard, now);

      // Ikisi de basari: repetitions artar.
      expect(good.repetitions, 2);
      expect(hard.repetitions, 2);
      // good: 6 gun; hard: max(1.0, round(6*0.6, 2)) = 3.6 gun.
      expect(good.intervalDays, 6.0);
      expect(hard.intervalDays, 3.6);
      expect(hard.intervalDays, lessThan(good.intervalDays));
      // hard EF dusurur: q=3 → EF - 0.14
      expect(hard.easeFactor, closeTo(afterOne.easeFactor - 0.14, 1e-9));
    });

    test('"zor" araligi 1 gunun altina inmez', () {
      const initial = ReviewState();
      final next = applySm2(initial, Grade.hard, now);

      // reps=0 → 1 gun; round(1*0.6, 2)=0.6 → taban 1.0.
      expect(next.intervalDays, 1.0);
    });

    test('EF tabani: cok sayida "tekrar" sonrasi 1.3 altina inmez', () {
      var state = const ReviewState();
      for (var i = 0; i < 20; i++) {
        state = applySm2(state, Grade.again, now);
        expect(state.easeFactor, greaterThanOrEqualTo(minEase));
      }
      expect(state.easeFactor, minEase);
    });

    test('girdi degistirilmez (yan etkisizlik / immutability)', () {
      const original = ReviewState(
        easeFactor: 2.5,
        intervalDays: 6.0,
        repetitions: 2,
      );
      // Ayni degerlerle bagimsiz bir kopya (esitlik referans degil deger bazli).
      const snapshot = ReviewState(
        easeFactor: 2.5,
        intervalDays: 6.0,
        repetitions: 2,
      );

      final next = applySm2(original, Grade.easy, now);

      expect(next, isNot(same(original)));
      expect(original, snapshot); // freezed deger esitligi: alanlar degismedi
      expect(original.easeFactor, 2.5);
      expect(original.intervalDays, 6.0);
      expect(original.repetitions, 2);
      expect(original.dueAt, isNull);
    });

    test('referans seffafligi: ayni girdi her zaman ayni sonucu verir', () {
      const state = ReviewState(easeFactor: 2.2, intervalDays: 9, repetitions: 4);
      final a = applySm2(state, Grade.good, now);
      final b = applySm2(state, Grade.good, now);
      expect(a, b);
    });
  });

  group('projectedIntervalLabel', () {
    test('tekrar -> 10 dk, ilk iyi -> 1 gun', () {
      const s = ReviewState();
      expect(projectedIntervalLabel(s, Grade.again), '10 dk');
      expect(projectedIntervalLabel(s, Grade.good), '1 gun');
    });
  });

  // -------------------------------------------------------------------------
  // Golden parite vektorleri: ayni girdiler backend tests/test_sm2.py'de de
  // test edilir. Tablo degisirse IKI testi birden guncelleyin (bulgu C26).
  // -------------------------------------------------------------------------
  group('golden parite (backend ile birebir)', () {
    final now = DateTime.utc(2026, 6, 11);

    test('hard half-up: ef=1.3, interval=1.75 -> 1.37 gun', () {
      const s = ReviewState(easeFactor: 1.3, intervalDays: 1.75, repetitions: 6);
      final r = applySm2(s, Grade.hard, now);
      expect(r.easeFactor, closeTo(1.3, 1e-9));
      expect(r.intervalDays, closeTo(1.37, 1e-9));
    });

    test('good: ef=2.5, interval=6 -> 15 gun', () {
      const s = ReviewState(easeFactor: 2.5, intervalDays: 6, repetitions: 2);
      final r = applySm2(s, Grade.good, now);
      expect(r.easeFactor, closeTo(2.5, 1e-9));
      expect(r.intervalDays, closeTo(15.0, 1e-9));
    });

    test('easy: ef=2.21, interval=14.5 -> 33.49 gun', () {
      const s = ReviewState(easeFactor: 2.21, intervalDays: 14.5, repetitions: 4);
      final r = applySm2(s, Grade.easy, now);
      expect(r.easeFactor, closeTo(2.31, 1e-9));
      expect(r.intervalDays, closeTo(33.49, 1e-9));
    });
  });
}