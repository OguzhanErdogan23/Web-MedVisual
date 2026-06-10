import { useCallback, useEffect, useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, API_URL, getAccessToken } from '../lib/api'
import { useToast } from '../hooks/useToast'
import Spinner from '../components/Spinner'
import EmptyState from '../components/EmptyState'
import type { DueResponse, ReviewRow, StudyCard } from '../types'

const GRADES = [
  { grade: 0, label: 'Tekrar', key: '1', classes: 'bg-red-600 hover:bg-red-700' },
  { grade: 1, label: 'Zor', key: '2', classes: 'bg-orange-500 hover:bg-orange-600' },
  { grade: 2, label: 'İyi', key: '3', classes: 'bg-green-600 hover:bg-green-700' },
  { grade: 3, label: 'Kolay', key: '4', classes: 'bg-blue-600 hover:bg-blue-700' },
] as const

function resolveImageUrl(url: string, token: string | null): string {
  if (url.startsWith('http://') || url.startsWith('https://')) return url
  return `${API_URL}${url}?token=${token ?? ''}`
}

export default function Study() {
  const { setId } = useParams<{ setId: string }>()
  const queryClient = useQueryClient()
  const { toast } = useToast()
  const [token, setToken] = useState<string | null>(null)
  const [queue, setQueue] = useState<StudyCard[] | null>(null)
  const [index, setIndex] = useState(0)
  const [flipped, setFlipped] = useState(false)
  const [gradeCounts, setGradeCounts] = useState<Record<number, number>>({})

  useEffect(() => {
    getAccessToken().then(setToken)
  }, [])

  const dueQuery = useQuery({
    queryKey: ['study-due', setId ?? 'all'],
    queryFn: () =>
      api.get<DueResponse>(
        `/study/due?${setId ? `set_id=${setId}&` : ''}limit=50`,
      ),
    refetchOnWindowFocus: false,
  })

  // İlk yüklemede kuyruğu doldur
  useEffect(() => {
    if (dueQuery.data && queue === null) {
      setQueue(dueQuery.data.cards)
      setIndex(0)
      setFlipped(false)
      setGradeCounts({})
    }
  }, [dueQuery.data, queue])

  const review = useMutation({
    mutationFn: ({ cardId, grade }: { cardId: string; grade: number }) =>
      api.post<ReviewRow>('/study/reviews', { card_id: cardId, grade }),
    onError: (err: Error) => toast(err.message),
  })

  const current = queue && index < queue.length ? queue[index] : null
  const done = queue !== null && index >= queue.length
  const totalGraded = Object.values(gradeCounts).reduce((a, b) => a + b, 0)

  const handleGrade = useCallback(
    (grade: number) => {
      if (!current || !flipped) return
      review.mutate({ cardId: current.id, grade })
      setGradeCounts((prev) => ({ ...prev, [grade]: (prev[grade] ?? 0) + 1 }))
      setIndex((i) => i + 1)
      setFlipped(false)
    },
    [current, flipped, review],
  )

  // Klavye kısayolları
  useEffect(() => {
    const handler = (e: KeyboardEvent) => {
      if (e.target instanceof HTMLInputElement || e.target instanceof HTMLTextAreaElement) return
      if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault()
        if (!flipped && current) setFlipped(true)
        return
      }
      const idx = ['1', '2', '3', '4'].indexOf(e.key)
      if (idx >= 0) handleGrade(idx)
    }
    window.addEventListener('keydown', handler)
    return () => window.removeEventListener('keydown', handler)
  }, [flipped, current, handleGrade])

  // Oturum bitince istatistikleri tazele
  useEffect(() => {
    if (done && totalGraded > 0) {
      queryClient.invalidateQueries({ queryKey: ['study-stats'] })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [done])

  if (dueQuery.isLoading || queue === null) {
    return (
      <div className="flex justify-center py-20">
        <Spinner size={9} />
      </div>
    )
  }

  if (dueQuery.isError) {
    return (
      <div className="mx-auto max-w-2xl rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700">
        Kartlar yüklenemedi: {(dueQuery.error as Error).message}
      </div>
    )
  }

  if (queue.length === 0) {
    return (
      <div className="mx-auto max-w-2xl">
        <EmptyState
          icon="🎉"
          title="Şu an çalışılacak kart yok"
          description="Tüm kartlarınız güncel! Yeni kartlar üretebilir veya daha sonra tekrar gelebilirsiniz."
          action={
            <Link
              to="/"
              className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              Panele dön
            </Link>
          }
        />
      </div>
    )
  }

  if (done) {
    return (
      <div className="mx-auto max-w-md">
        <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm">
          <div className="mb-3 text-4xl">🎉</div>
          <h1 className="text-xl font-semibold text-slate-900">Oturum tamamlandı!</h1>
          <p className="mt-1 text-sm text-slate-500">{totalGraded} kart çalıştınız.</p>
          <div className="mt-6 grid grid-cols-4 gap-2">
            {GRADES.map((g) => (
              <div key={g.grade} className="rounded-xl bg-slate-50 p-3">
                <p className="text-lg font-semibold text-slate-900">
                  {gradeCounts[g.grade] ?? 0}
                </p>
                <p className="text-xs text-slate-500">{g.label}</p>
              </div>
            ))}
          </div>
          <Link
            to="/"
            className="mt-8 inline-block rounded-lg bg-indigo-600 px-5 py-2.5 text-sm font-medium text-white hover:bg-indigo-700"
          >
            Panele dön
          </Link>
        </div>
      </div>
    )
  }

  const remaining = queue.length - index
  const progress = (index / queue.length) * 100

  return (
    <div className="mx-auto flex max-w-2xl flex-col items-center gap-6">
      {/* İlerleme */}
      <div className="w-full">
        <div className="mb-1.5 flex justify-between text-xs font-medium text-slate-500">
          <span>
            Kart {index + 1} / {queue.length}
          </span>
          <span>Kalan {remaining}</span>
        </div>
        <div className="h-2 w-full overflow-hidden rounded-full bg-slate-200">
          <div
            className="h-full rounded-full bg-indigo-600 transition-all"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      {/* Kart */}
      <button
        onClick={() => !flipped && setFlipped(true)}
        className={`flex min-h-[320px] w-full flex-col items-center justify-center gap-4 rounded-3xl border bg-white p-8 text-center shadow-sm transition-shadow ${
          flipped ? 'border-teal-200' : 'cursor-pointer border-slate-200 hover:shadow-md'
        }`}
      >
        <span className="text-[10px] font-semibold uppercase tracking-widest text-slate-400">
          {flipped ? 'Cevap' : 'Soru'}
        </span>
        {current!.image_url && (
          <img
            src={resolveImageUrl(current!.image_url, token)}
            alt="Kart görseli"
            className="max-h-44 rounded-xl border border-slate-100 bg-slate-50 object-contain"
          />
        )}
        <p className="whitespace-pre-wrap text-lg font-medium text-slate-900">
          {flipped ? current!.back : current!.front}
        </p>
        {!flipped && (
          <span className="mt-2 text-xs text-slate-400">
            Çevirmek için tıklayın veya Boşluk tuşuna basın
          </span>
        )}
        {current!.term && flipped && (
          <span className="rounded-full bg-indigo-50 px-3 py-1 text-xs font-medium text-indigo-700">
            {current!.term}
          </span>
        )}
      </button>

      {/* Not tuşları */}
      {flipped ? (
        <div className="grid w-full grid-cols-4 gap-3">
          {GRADES.map((g) => (
            <button
              key={g.grade}
              onClick={() => handleGrade(g.grade)}
              className={`rounded-xl px-4 py-3 text-sm font-semibold text-white transition-colors ${g.classes}`}
            >
              {g.label}
              <span className="mt-0.5 block text-[10px] font-normal opacity-75">
                tuş {g.key}
              </span>
            </button>
          ))}
        </div>
      ) : (
        <p className="text-xs text-slate-400">
          Cevabı gördükten sonra 1-4 tuşlarıyla değerlendirme yapabilirsiniz.
        </p>
      )}
    </div>
  )
}
