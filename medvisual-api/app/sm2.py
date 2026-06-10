"""SM-2 araliklı tekrar algoritmasi — saf fonksiyon (otorite: API).

Flutter tarafinda ayni algoritma Dart saf fonksiyonu olarak da yazilir
(optimistic UI + Fonksiyonel Programlama dersi vitrini); deterministik
oldugu icin iki taraf birebir ayni sonucu uretir, yazma yalnizca buradan yapilir.

Grade olcegi (istemci butonlari): 0=again, 1=hard, 2=good, 3=easy
Klasik SM-2 kalite esleme: again->2 (basarisiz), hard->3, good->4, easy->5
"""
from dataclasses import dataclass
from datetime import datetime, timedelta

GRADE_TO_QUALITY = {0: 2, 1: 3, 2: 4, 3: 5}
AGAIN_RETRY_MINUTES = 10
MIN_EASE = 1.3


@dataclass(frozen=True)
class ReviewState:
    ease_factor: float = 2.5
    interval_days: float = 0.0
    repetitions: int = 0
    due_at: datetime = datetime.min


def apply_sm2(state: ReviewState, grade: int, now: datetime) -> ReviewState:
    """Yan etkisiz: yeni ReviewState dondurur, girdiyi degistirmez.

    - grade 0 (again): tekrar sayaci sifirlanir, kart 10 dk sonra yeniden gelir.
    - grade >= 1: klasik SM-2 araliklari (1 gun, 6 gun, sonra interval * EF).
    - EF guncellemesi her cevapta SM-2 formulu ile yapilir, taban 1.3.
    """
    if grade not in GRADE_TO_QUALITY:
        raise ValueError(f"grade 0-3 araliginda olmali, gelen: {grade}")
    q = GRADE_TO_QUALITY[grade]
    ef = state.ease_factor + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02))
    ef = max(MIN_EASE, ef)

    if grade == 0:
        return ReviewState(
            ease_factor=ef,
            interval_days=0.0,
            repetitions=0,
            due_at=now + timedelta(minutes=AGAIN_RETRY_MINUTES),
        )

    if state.repetitions == 0:
        interval = 1.0
    elif state.repetitions == 1:
        interval = 6.0
    else:
        interval = round(state.interval_days * ef, 2)
    # "hard" dogru sayilir ama araligi kisaltir (Anki benzeri davranis)
    if grade == 1:
        interval = max(1.0, round(interval * 0.6, 2))

    return ReviewState(
        ease_factor=ef,
        interval_days=interval,
        repetitions=state.repetitions + 1,
        due_at=now + timedelta(days=interval),
    )
