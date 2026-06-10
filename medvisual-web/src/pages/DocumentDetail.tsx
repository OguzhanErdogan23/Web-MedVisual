import { useState } from 'react'
import type { FormEvent } from 'react'
import { useNavigate, useParams, useSearchParams } from 'react-router-dom'
import { useMutation, useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import { useToast } from '../hooks/useToast'
import StatusBadge from '../components/StatusBadge'
import Spinner from '../components/Spinner'
import type { DocumentRow, QuizRow, SetRow } from '../types'

const RANGE_RE = /^\d+(-\d+)?$/

type Tab = 'cards' | 'quiz'

export default function DocumentDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const { toast } = useToast()
  const [searchParams, setSearchParams] = useSearchParams()
  const tab: Tab = searchParams.get('tab') === 'quiz' ? 'quiz' : 'cards'

  const [range, setRange] = useState('')
  const [maxCards, setMaxCards] = useState(40)
  const [nQuestions, setNQuestions] = useState(10)
  const [source, setSource] = useState<'auto' | 'text' | 'ocr'>('auto')
  const [enhance, setEnhance] = useState(true)
  const [title, setTitle] = useState('')

  const docQuery = useQuery({
    queryKey: ['document', id],
    queryFn: () => api.get<DocumentRow>(`/documents/${id}`),
    enabled: !!id,
    refetchInterval: (q) => (q.state.data?.status === 'processing' ? 2500 : false),
  })

  const generateCards = useMutation({
    mutationFn: () =>
      api.post<SetRow>(`/documents/${id}/generate/cards`, {
        range,
        max_cards: maxCards,
        enhance,
        source,
        ...(title.trim() ? { set_title: title.trim() } : {}),
      }),
    onSuccess: (set) => {
      toast('Kart üretimi başladı.', 'success')
      navigate(`/sets/${set.id}`)
    },
    onError: (err: Error) => toast(err.message),
  })

  const generateQuiz = useMutation({
    mutationFn: () =>
      api.post<QuizRow>(`/documents/${id}/generate/quiz`, {
        range,
        n_questions: nQuestions,
        enhance,
        source,
        ...(title.trim() ? { title: title.trim() } : {}),
      }),
    onSuccess: (quiz) => {
      toast('Quiz üretimi başladı.', 'success')
      navigate(`/quizzes/${quiz.id}`)
    },
    onError: (err: Error) => toast(err.message),
  })

  const doc = docQuery.data
  const rangeValid = RANGE_RE.test(range.trim())
  const pending = generateCards.isPending || generateQuiz.isPending

  const handleSubmit = (e: FormEvent) => {
    e.preventDefault()
    if (!rangeValid) {
      toast('Geçerli bir sayfa aralığı girin, örn. "25-50" veya tek sayfa "25".')
      return
    }
    if (tab === 'cards') generateCards.mutate()
    else generateQuiz.mutate()
  }

  if (docQuery.isLoading) {
    return (
      <div className="flex justify-center py-20">
        <Spinner size={9} />
      </div>
    )
  }

  if (docQuery.isError || !doc) {
    return (
      <div className="mx-auto max-w-2xl rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/40 dark:text-red-300">
        Doküman yüklenemedi: {(docQuery.error as Error)?.message ?? 'bilinmeyen hata'}
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      {/* Doküman başlığı */}
      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <div className="flex items-start justify-between gap-4">
          <div>
            <h1 className="text-xl font-semibold tracking-tight text-slate-900 dark:text-slate-100">
              {doc.filename}
            </h1>
            <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
              {doc.page_count ?? '?'} sayfa ·{' '}
              {doc.has_text ? 'Metin katmanı var' : 'Metin katmanı yok (OCR gerekebilir)'}
            </p>
          </div>
          <StatusBadge status={doc.status} />
        </div>
        {doc.status === 'expired' && (
          <p className="mt-3 rounded-lg bg-amber-50 px-4 py-3 text-sm text-amber-800">
            Doküman motoru yeniden başlatılmış, lütfen PDF'i yeniden yükleyin.
          </p>
        )}
        {doc.status === 'failed' && doc.error && (
          <p className="mt-3 rounded-lg bg-red-50 px-4 py-3 text-sm text-red-700">{doc.error}</p>
        )}
      </div>

      {/* Sekmeler */}
      <div className="rounded-2xl border border-slate-200 bg-white shadow-sm dark:border-slate-700 dark:bg-slate-800">
        <div className="flex border-b border-slate-100 dark:border-slate-700">
          {(
            [
              { key: 'cards', label: '🃏 Bilgi Kartı' },
              { key: 'quiz', label: '❓ Quiz' },
            ] as { key: Tab; label: string }[]
          ).map((t) => (
            <button
              key={t.key}
              onClick={() => setSearchParams({ tab: t.key })}
              className={`flex-1 px-4 py-3 text-sm font-medium transition-colors ${
                tab === t.key
                  ? 'border-b-2 border-indigo-600 text-indigo-700 dark:text-indigo-400'
                  : 'text-slate-500 hover:text-slate-800 dark:text-slate-400 dark:hover:text-slate-200'
              }`}
            >
              {t.label}
            </button>
          ))}
        </div>

        <form onSubmit={handleSubmit} className="space-y-5 p-6">
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
              Sayfa aralığı
            </label>
            <input
              type="text"
              value={range}
              onChange={(e) => setRange(e.target.value)}
              placeholder={`örn. 25-50 (1-${doc.page_count ?? '?'} arası)`}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-100 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
            />
            {range.length > 0 && !rangeValid && (
              <p className="mt-1 text-xs text-red-600">
                "25-50" biçiminde bir aralık veya tek sayfa numarası girin.
              </p>
            )}
          </div>

          <div className="grid grid-cols-2 gap-4">
            {tab === 'cards' ? (
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                  Maksimum kart sayısı
                </label>
                <input
                  type="number"
                  min={1}
                  max={200}
                  value={maxCards}
                  onChange={(e) => setMaxCards(Number(e.target.value))}
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
                />
              </div>
            ) : (
              <div>
                <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                  Soru sayısı
                </label>
                <input
                  type="number"
                  min={1}
                  max={50}
                  value={nQuestions}
                  onChange={(e) => setNQuestions(Number(e.target.value))}
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
                />
              </div>
            )}
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">Kaynak</label>
              <select
                value={source}
                onChange={(e) => setSource(e.target.value as 'auto' | 'text' | 'ocr')}
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
              >
                <option value="auto">Otomatik</option>
                <option value="text">Metin katmanı</option>
                <option value="ocr">OCR</option>
              </select>
            </div>
          </div>

          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
              {tab === 'cards' ? 'Deste başlığı (isteğe bağlı)' : 'Quiz başlığı (isteğe bağlı)'}
            </label>
            <input
              type="text"
              value={title}
              onChange={(e) => setTitle(e.target.value)}
              placeholder={tab === 'cards' ? 'örn. Kardiyoloji — Aritmiler' : 'örn. Aritmi Quizi'}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
            />
          </div>

          <label className="flex cursor-pointer items-start gap-3 rounded-xl border border-slate-200 bg-slate-50/60 p-4 dark:border-slate-700 dark:bg-slate-900/40">
            <input
              type="checkbox"
              checked={enhance}
              onChange={(e) => setEnhance(e.target.checked)}
              className="mt-0.5 h-4 w-4 accent-indigo-600"
            />
            <span>
              <span className="block text-sm font-medium text-slate-800 dark:text-slate-200">
                Gemini ile zenginleştir
              </span>
              <span className="block text-xs text-slate-500 dark:text-slate-400">
                Daha kaliteli, klinik odaklı {tab === 'cards' ? 'kartlar' : 'sorular'} üretir;
                üretim biraz daha uzun sürebilir.
              </span>
              <span className="mt-0.5 block text-xs font-medium text-indigo-600 dark:text-indigo-400">
                Daha tutarlı ve klinik odaklı sorular için önerilir.
              </span>
            </span>
          </label>

          <button
            type="submit"
            disabled={pending || doc.status !== 'ready'}
            className="flex w-full items-center justify-center gap-2 rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
          >
            {pending && <Spinner size={4} className="border-indigo-300 border-t-white" />}
            {tab === 'cards' ? 'Kartları Üret' : 'Quiz Üret'}
          </button>
          {doc.status !== 'ready' && (
            <p className="text-center text-xs text-slate-500">
              Üretim için dokümanın "Hazır" durumda olması gerekir.
            </p>
          )}
        </form>
      </div>
    </div>
  )
}
