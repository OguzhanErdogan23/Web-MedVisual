"""SM-2 saf fonksiyon testleri — ayni tablolar Flutter tarafindaki Dart
implementasyonunun testlerinde de kullanilacak (iki taraf birebir ayni
sonucu uretmeli, otorite API'dir)."""
from datetime import datetime, timedelta, timezone

import pytest

from app.sm2 import MIN_EASE, ReviewState, apply_sm2

NOW = datetime(2026, 6, 10, 12, 0, 0, tzinfo=timezone.utc)


def test_first_good_review_schedules_one_day():
    s = apply_sm2(ReviewState(), grade=2, now=NOW)
    assert s.repetitions == 1
    assert s.interval_days == 1.0
    assert s.due_at == NOW + timedelta(days=1)


def test_second_good_review_schedules_six_days():
    s1 = apply_sm2(ReviewState(), grade=2, now=NOW)
    s2 = apply_sm2(s1, grade=2, now=NOW)
    assert s2.repetitions == 2
    assert s2.interval_days == 6.0


def test_third_review_multiplies_by_ease_factor():
    s = ReviewState()
    for _ in range(3):
        s = apply_sm2(s, grade=2, now=NOW)
    assert s.repetitions == 3
    assert s.interval_days == pytest.approx(6 * s.ease_factor, abs=0.05)


def test_again_resets_repetitions_and_schedules_ten_minutes():
    s1 = apply_sm2(ReviewState(), grade=2, now=NOW)
    s2 = apply_sm2(s1, grade=0, now=NOW)
    assert s2.repetitions == 0
    assert s2.interval_days == 0.0
    assert s2.due_at == NOW + timedelta(minutes=10)


def test_again_lowers_ease_factor():
    s = apply_sm2(ReviewState(), grade=0, now=NOW)
    assert s.ease_factor < 2.5


def test_easy_raises_ease_factor():
    s = apply_sm2(ReviewState(), grade=3, now=NOW)
    assert s.ease_factor > 2.5


def test_hard_shortens_interval_but_counts_as_success():
    good = apply_sm2(ReviewState(), grade=2, now=NOW)
    hard = apply_sm2(ReviewState(), grade=1, now=NOW)
    assert hard.repetitions == 1
    assert hard.interval_days <= good.interval_days


def test_ease_factor_never_below_minimum():
    s = ReviewState()
    for _ in range(20):
        s = apply_sm2(s, grade=0, now=NOW)
    assert s.ease_factor == pytest.approx(MIN_EASE)


def test_input_state_is_not_mutated():
    original = ReviewState()
    apply_sm2(original, grade=2, now=NOW)
    assert original.repetitions == 0
    assert original.interval_days == 0.0


def test_invalid_grade_raises():
    with pytest.raises(ValueError):
        apply_sm2(ReviewState(), grade=5, now=NOW)
