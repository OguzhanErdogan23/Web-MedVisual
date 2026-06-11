import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import type { StudyHistoryResponse } from '../types'

const WEEKS = 18 // ~126 gün
const DAY_LABELS = ['Pzt', '', 'Çar', '', 'Cum', '', 'Paz']
const LEVEL_CLASSES = [
  'bg-slate-100 dark:bg-slate-700',
  'bg-emerald-200 dark:bg-emerald-900',
  'bg-emerald-300 dark:bg-emerald-700',
  'bg-emerald-500 dark:bg-emerald-500',
  'bg-emerald-700 dark:bg-emerald-300',
]

function intensity(total: number): number {
  if (total <= 0) return 0
  if (total < 5) return 1
  if (total < 10) return 2
  if (total < 20) return 3
  return 4
}

/** Yerel saat diliminde YYYY-MM-DD anahtarı. */
function dayKey(d: Date): string {
  const m = String(d.getMonth() + 1).padStart(2, '0')
  const day = String(d.getDate()).padStart(2, '0')
  return `${d.getFullYear()}-${m}-${day}`
}

/** Bugünden geriye kesintisiz çalışılan gün sayısı (bugün 0 ise dünden başlar). */
export function computeStreak(totals: Map<string, number>, today: Date): number {
  const d = new Date(today)
  if (!((totals.get(dayKey(d)) ?? 0) > 0)) d.setDate(d.getDate() - 1)
  let streak = 0
  while ((totals.get(dayKey(d)) ?? 0) > 0) {
    streak++
    d.setDate(d.getDate() - 1)
  }
  return streak
}

export default function StudyHeatmap() {
  // Gün sınırı kullanıcının yerel saatine göre çizilsin (TR akşam çalışmaları doğru güne)
  const tzOffset = -new Date().getTimezoneOffset()
  const historyQuery = useQuery({
    queryKey: ['study-history', 'heatmap'],
    queryFn: () =>
      api.get<StudyHistoryResponse>(
        `/study/history?days=${WEEKS * 7}&tz_offset_minutes=${tzOffset}`,
      ),
  })

  const data = historyQuery.data
  if (historyQuery.isError || !data) return null

  const totals = new Map(data.days.map((d) => [d.date, d.total]))
  const today = new Date()
  const streak = computeStreak(totals, today)

  // Izgara: sütun=hafta (eski→yeni), satır=Pzt..Paz; başlangıcı Pazartesi'ye hizala
  const start = new Date(today)
  start.setDate(start.getDate() - (WEEKS * 7 - 1))
  while (start.getDay() !== 1) start.setDate(start.getDate() - 1)

  const weeks: { key: string; total: number; future: boolean }[][] = []
  const cursor = new Date(start)
  while (cursor <= today) {
    const col: { key: string; total: number; future: boolean }[] = []
    for (let i = 0; i < 7; i++) {
      const key = dayKey(cursor)
      col.push({ key, total: totals.get(key) ?? 0, future: cursor > today })
      cursor.setDate(cursor.getDate() + 1)
    }
    weeks.push(col)
  }

  return (
    <section>
      <div className="mb-4 flex items-center justify-between">
        <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
          Çalışma Takvimi
        </h2>
        <span className="rounded-full bg-orange-50 px-3 py-1 text-sm font-semibold text-orange-600 dark:bg-orange-950/50 dark:text-orange-400">
          🔥 {streak} gün seri
        </span>
      </div>
      <div className="overflow-x-auto rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <div className="flex gap-1">
          <div className="mr-1 flex flex-col gap-1">
            {DAY_LABELS.map((label, i) => (
              <span key={i} className="flex h-3.5 items-center text-[9px] text-slate-400">
                {label}
              </span>
            ))}
          </div>
          {weeks.map((col, wi) => (
            <div key={wi} className="flex flex-col gap-1">
              {col.map((cell) =>
                cell.future ? (
                  <span key={cell.key} className="h-3.5 w-3.5" />
                ) : (
                  <span
                    key={cell.key}
                    title={`${new Date(cell.key).toLocaleDateString('tr-TR')}: ${cell.total} tekrar`}
                    className={`h-3.5 w-3.5 rounded-sm ${LEVEL_CLASSES[intensity(cell.total)]}`}
                  />
                ),
              )}
            </div>
          ))}
        </div>
        <div className="mt-3 flex items-center gap-1.5 text-[10px] text-slate-400">
          Az
          {LEVEL_CLASSES.map((c) => (
            <span key={c} className={`h-2.5 w-2.5 rounded-sm ${c}`} />
          ))}
          Çok
        </div>
      </div>
    </section>
  )
}
