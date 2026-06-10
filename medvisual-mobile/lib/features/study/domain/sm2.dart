/// SM-2 aralikli tekrar algoritmasi — SAF FONKSIYON (dersin vitrini).
///
/// Sunucudaki `app/sm2.py` ile birebir aynidir; otorite sunucudur, bu
/// kopya optimistic UI ve Fonksiyonel Programlama dersi gosterimi icindir.
/// Deterministik oldugu icin iki taraf ayni girdiyle ayni sonucu uretir.
///
/// Fonksiyonel ozellikler:
///  * Yan etkisiz: girdi [ReviewState] asla degistirilmez (freezed garantisi),
///    her cagri yeni bir deger nesnesi dondurur.
///  * Referans seffafligi: sonuc yalnizca (state, grade, now) girdilerine
///    baglidir; `DateTime.now()` gibi gizli girdiler parametreye cikarilmistir.
library;

import 'dart:math' as math;

import 'review_state.dart';

/// Istemci butonlari: 0=again, 1=hard, 2=good, 3=easy.
enum Grade { again, hard, good, easy }

/// Klasik SM-2 kalite eslemesi: again->2 (basarisiz), hard->3, good->4, easy->5.
const gradeToQuality = {
  Grade.again: 2,
  Grade.hard: 3,
  Grade.good: 4,
  Grade.easy: 5,
};

const againRetryMinutes = 10;
const minEase = 1.3;

double _round2(double v) => (v * 100).roundToDouble() / 100;

/// Yeni tekrar durumunu hesaplar; girdiyi DEGISTIRMEZ.
///
/// - [Grade.again]: tekrar sayaci sifirlanir, kart 10 dk sonra yeniden gelir.
/// - Basari (hard/good/easy): klasik SM-2 araliklari
///   (1 gun, 6 gun, sonra `round(interval * EF, 2)`).
/// - [Grade.hard] dogru sayilir ama araligi kisaltir
///   (`max(1.0, round(interval * 0.6, 2))` — Anki benzeri davranis).
/// - EF her cevapta `EF' = EF + (0.1 - (5-q)*(0.08+(5-q)*0.02))` ile
///   guncellenir; taban [minEase] (1.3).
ReviewState applySm2(ReviewState state, Grade grade, DateTime now) {
  final q = gradeToQuality[grade]!;
  final ef = math.max(
    minEase,
    state.easeFactor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)),
  );

  if (grade == Grade.again) {
    return ReviewState(
      easeFactor: ef,
      intervalDays: 0.0,
      repetitions: 0,
      dueAt: now.add(const Duration(minutes: againRetryMinutes)),
      lastGrade: grade.index,
    );
  }

  double interval;
  if (state.repetitions == 0) {
    interval = 1.0;
  } else if (state.repetitions == 1) {
    interval = 6.0;
  } else {
    interval = _round2(state.intervalDays * ef);
  }
  if (grade == Grade.hard) {
    interval = math.max(1.0, _round2(interval * 0.6));
  }

  return ReviewState(
    easeFactor: ef,
    intervalDays: interval,
    repetitions: state.repetitions + 1,
    dueAt: now.add(
      Duration(microseconds: (interval * Duration.microsecondsPerDay).round()),
    ),
    lastGrade: grade.index,
  );
}

/// Bir notun uretecegi araligi insan-okur Turkce metne cevirir
/// (calisma ekranindaki not butonlarinin alt yazisi). Saf fonksiyon.
String projectedIntervalLabel(ReviewState state, Grade grade) {
  if (grade == Grade.again) return '$againRetryMinutes dk';
  final next = applySm2(state, grade, DateTime.utc(2000));
  final days = next.intervalDays;
  if (days < 30) {
    final text = days == days.roundToDouble()
        ? days.round().toString()
        : days.toStringAsFixed(1);
    return '$text gun';
  }
  return '${(days / 30).toStringAsFixed(1)} ay';
}
