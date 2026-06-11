import { useCallback, useEffect, useState } from 'react'
import { Link, useParams, useSearchParams } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import { projectedIntervalLabel } from '../lib/sm2'
import { useToast } from '../hooks/useToast'
import Spinner from '../components/Spinner'
import EmptyState from '../components/EmptyState'
import AuthImage from '../components/AuthImage'
import type { DueResponse, ReviewRow, StudyCard } from '../types'

const GRADES = [
  { grade: 0, label: 'Tekrar', key: '1', classes: 'bg-red-600 hover:bg-red-700' },
  { grade: 1, label: 'Zor', key: '2', classes: 'bg-orange-500 hover:bg-orange-600' },
  { grade: 2, label: 'İyi', key: '3', classes: 'bg-green-600 hover:bg-green-700' },
  { grade: 3, label: 'Kolay', key: '4', classes: 'bg-blue-600 hover:bg-blue-700' },
] as const

function shuffle<T>(items: T[]): T[] {
  const out = [...items]
  for (let i = out.length - 1; i > 0; i--) {
    const j = Math.floor(Math.random() * (i + 1))
    ;[out[i], out[j]] = [out[j], out[i]]
  }
  return out
}

export default function Study() {
  const { setId } = useParams<{ setId: string }>()
  const [searchParams] = useSearchParams()
  // Serbest (cram) mod: tüm kartlar gelir, notlar sunucuya YAZILMAZ
  const cram = searchParams.get('mode') === 'cram'
  const queryClient = useQueryClient()
  const { toast } = useToast()
  const [queue, setQueue] = useState<StudyCard[] | null>(null)
  const [index, setIndex] = useState(0)
  const [flipped, setFlipped] = useState(false)
  const [gradeCounts, setGradeCounts] = useState<Record<number, number>>({})
  const [failedReviews, setFailedReviews] = useState<{ cardId: string; grade: number }[]>([])

  // Route parametresi veya mod değişince oturumu sıfırla (remount olmaz)
  useEffect(() => {
    setQueue(null)
    setIndex(0)
    setFlipped(false)
    setGradeCounts({})
    setFailedReviews([])
  }, [setId, cram])

  const dueQuery = useQuery({
    queryKey: ['study-due', setId ?? 'all', cram ? 'cram' : 'due'],
    queryFn: () =>
      api.get<DueResponse>(
        `/study/due?${setId ? `set_id=${setId}&` : ''}limit=50${cram ? '&mode=cram' : ''}`,
      ),
    refetchOnWindowFocus: false,
  })

  // İlk yüklemede kuyruğu doldur (serbest modda karıştır)
  useEffect(() => {
    if (dueQuery.data && queue === null) {
      setQueue(cram ? shuffle(dueQuery.data.cards) : dueQuery.data.cards)
      setIndex(0)
      setFlipped(false)
      setGradeCounts({})
      setFailedReviews([])
    }
  }, [dueQuery.data, queue, cram])

  const review = useMutation({
    mutationFn: ({ cardId, grade }: { cardId: string; grade: number }) =>
      api.post<ReviewRow>('/study/reviews', { card_id: cardId, grade }),
    retry: 2,
    onError: (err: Error, vars) => {
      // Kaybolmasın: oturum sonunda yeniden gönderilebilsin
      setFailedReviews((prev) => [...prev, { cardId: vars.cardId, grade: vars.grade }])
      toast(err.message)
    },
  })

  const current = queue && index < queue.length ? queue[index] : null
  const done = queue !== null && queue.length > 0 && index >= queue.length
  const totalGraded = Object.values(gradeCounts).reduce((a, b) => a + b, 0)

  const handleGrade = useCallback(
    (grade: number) => {
      if (!current || !flipped) return
      if (!cram) review.mutate({ cardId: current.id, grade })
      setGradeCounts((prev) => ({ ...prev, [grade]: (prev[grade] ?? 0) + 1 }))
      // 'Tekrar': kart oturum kuyruğunun sonuna geri eklenir (Anki davranışı)
      if (grade === 0) setQueue((q) => (q ? [...q, current] : q))
      setIndex((i) => i + 1)
      setFlipped(false)
    },
    [current, flipped, review, cram],
  )

  const retryFailed = useCallback(() => {
    const pending = failedReviews
    setFailedReviews([])
    pending.forEach((f) => review.mutate({ cardId: f.cardId, grade: f.grade }))
  }, [failedReviews, review])

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

  // Oturum bitince istatistikleri tazele — uçuştaki review istekleri bittikten sonra
  useEffect(() => {
    if (done && totalGraded > 0 && !cram && !review.isPending) {
      queryClient.invalidateQueries({ queryKey: ['study-stats'] })
      queryClient.invalidateQueries({ queryKey: ['study-history'] })
      queryClient.invalidateQueries({ queryKey: ['study-due'] })
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [done, review.isPending])

  // Hata durumu spinner'dan ÖNCE: aksi halde queue hiç dolmaz ve sonsuz spinner olur
  if (dueQuery.isError) {
    return (
      <div className="mx-auto max-w-2xl space-y-4">
        <div className="rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/40 dark:text-red-300">
          Kartlar yüklenemedi: {(dueQuery.error as Error).message}
        </div>
        <button
          onClick={() => dueQuery.refetch()}
          className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
        >
          Tekrar dene
        </button>
      </div>
    )
  }

  if (dueQuery.isLoading || queue === null) {
    return (
      <div className="flex justify-center py-20">
        <Spinner size={9} />
      </div>
    )
  }

  if (queue.length === 0) {
    return (
      <div className="mx-auto max-w-2xl">
        {cram ? (
          <EmptyState
            icon="🃏"
            title="Çalışılacak kart bulunamadı"
            description="Bu kapsamda hiç kart yok. Önce bir desteye kart ekleyin veya üretin."
            action={
              <Link
                to="/sets"
                className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
              >
                Destelere git
              </Link>
            }
          />
        ) : (
          <EmptyState
            icon="🎉"
            title="Şu an çalışılacak kart yok"
            description="Tüm kartlarınız güncel! Serbest modda yine de pratik yapabilirsiniz — notlar zamanlamayı etkilemez."
            action={
              <div className="flex justify-center gap-3">
                <Link
                  to={`${setId ? `/study/${setId}` : '/study'}?mode=cram`}
                  className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700"
                >
                  🎯 Serbest çalış
                </Link>
                <Link
                  to="/"
                  className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700"
                >
                  Panele dön
                </Link>
              </div>
            }
          />
        )}
      </div>
    )
  }

  if (done) {
    return (
      <div className="mx-auto max-w-md">
        <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm dark:border-slate-700 dark:bg-slate-800">
          <div className="mb-3 text-4xl">🎉</div>
          <h1 className="text-xl font-semibold text-slate-900 dark:text-slate-100">Oturum tamamlandı!</h1>
          <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
            {totalGraded} kart çalıştınız.
            {cram && ' (Serbest mod — zamanlama etkilenmedi.)'}
          </p>
          <div className="mt-6 grid grid-cols-4 gap-2">
            {GRADES.map((g) => (
              <div key={g.grade} className="rounded-xl bg-slate-50 p-3 dark:bg-slate-900">
                <p className="text-lg font-semibold text-slate-900 dark:text-slate-100">
                  {gradeCounts[g.grade] ?? 0}
                </p>
                <p className="text-xs text-slate-500 dark:text-slate-400">{g.label}</p>
              </div>
            ))}
          </div>
          {failedReviews.length > 0 && (
            <div className="mt-5 rounded-xl border border-amber-200 bg-amber-50 px-4 py-3 text-sm text-amber-800 dark:border-amber-800 dark:bg-amber-950/40 dark:text-amber-300">
              <p>{failedReviews.length} değerlendirme sunucuya kaydedilemedi.</p>
              <button
                onClick={retryFailed}
                disabled={review.isPending}
                className="mt-2 rounded-lg bg-amber-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-amber-700 disabled:opacity-50"
              >
                Yeniden gönder
              </button>
            </div>
          )}
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
      {cram && (
        <div className="w-full rounded-xl border border-teal-200 bg-teal-50 px-4 py-2 text-center text-xs font-medium text-teal-700 dark:border-teal-800 dark:bg-teal-950/40 dark:text-teal-300">
          🎯 Serbest mod — notlar tekrar zamanlamasını etkilemez
        </div>
      )}
      {/* İlerleme */}
      <div className="w-full">
        <div className="mb-1.5 flex justify-between text-xs font-medium text-slate-500 dark:text-slate-400">
          <span>
            Kart {index + 1} / {queue.length}
          </span>
          <span>Kalan {remaining}</span>
        </div>
        <div className="h-2 w-full overflow-hidden rounded-full bg-slate-200 dark:bg-slate-700">
          <div
            className="h-full rounded-full bg-indigo-600 transition-all"
            style={{ width: `${progress}%` }}
          />
        </div>
      </div>

      {/* Kart */}
      <button
        onClick={() => !flipped && setFlipped(true)}
        className={`flex min-h-[320px] w-full flex-col items-center justify-center gap-4 rounded-3xl border bg-white p-8 text-center shadow-sm transition-shadow dark:bg-slate-800 ${
          flipped ? 'border-teal-200 dark:border-teal-800' : 'cursor-pointer border-slate-200 hover:shadow-md dark:border-slate-700'
        }`}
      >
        <span className="text-[10px] font-semibold uppercase tracking-widest text-slate-400 dark:text-slate-500">
          {flipped ? 'Cevap' : 'Soru'}
        </span>
        {current!.image_url && (
          <AuthImage
            src={current!.image_url}
            alt="Kart görseli"
            className="max-h-44 rounded-xl border border-slate-100 bg-slate-50 object-contain"
          />
        )}
        <p className="whitespace-pre-wrap text-lg font-medium text-slate-900 dark:text-slate-100">
          {flipped ? current!.back : current!.front}
        </p>
        {!flipped && (
          <span className="mt-2 text-xs text-slate-400 dark:text-slate-500">
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
                {cram ? `tuş ${g.key}` : projectedIntervalLabel(current!.review, g.grade)}
              </span>
            </button>
          ))}
        </div>
      ) : (
        <p className="text-xs text-slate-400 dark:text-slate-500">
          Cevabı gördükten sonra 1-4 tuşlarıyla değerlendirme yapabilirsiniz.
        </p>
      )}
    </div>
  )
}
