// SM-2 öngörülen aralık etiketleri — sunucudaki app/sm2.py ile aynı formüller.
// Yalnızca not butonlarının alt yazısı için kullanılır; otorite sunucudur.
import type { ReviewRow } from '../types'

const GRADE_TO_QUALITY = [2, 3, 4, 5] // 0=tekrar 1=zor 2=iyi 3=kolay
const MIN_EASE = 1.3
const AGAIN_RETRY_MINUTES = 10

function round2(v: number): number {
  // Sunucuyla hizalı half-up yuvarlama (bkz. denetim bulgusu C26)
  return Math.round(v * 100) / 100
}

/** Bir notun üreteceği yeni aralığı (gün) hesaplar. */
export function projectedIntervalDays(
  review: ReviewRow | null | undefined,
  grade: number,
): number {
  const ease = review?.ease_factor ?? 2.5
  const intervalDays = review?.interval_days ?? 0
  const repetitions = review?.repetitions ?? 0

  const q = GRADE_TO_QUALITY[grade] ?? 4
  const ef = Math.max(MIN_EASE, ease + (0.1 - (5 - q) * (0.08 + (5 - q) * 0.02)))

  if (grade === 0) return 0
  let interval: number
  if (repetitions === 0) interval = 1
  else if (repetitions === 1) interval = 6
  else interval = round2(intervalDays * ef)
  if (grade === 1) interval = Math.max(1, round2(interval * 0.6))
  return interval
}

/** İnsan-okur Türkçe etiket: "10 dk", "1 gün", "6 gün", "1.2 ay". */
export function projectedIntervalLabel(
  review: ReviewRow | null | undefined,
  grade: number,
): string {
  if (grade === 0) return `${AGAIN_RETRY_MINUTES} dk`
  const days = projectedIntervalDays(review, grade)
  if (days < 30) {
    const text = Number.isInteger(days) ? String(days) : days.toFixed(1)
    return `${text} gün`
  }
  return `${(days / 30).toFixed(1)} ay`
}
