import { useState } from 'react'
import { Link, useParams } from 'react-router-dom'
import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import Spinner from '../components/Spinner'
import type { QuizDetail } from '../types'

export default function QuizPlayer() {
  const { id } = useParams<{ id: string }>()
  const [index, setIndex] = useState(0)
  const [answers, setAnswers] = useState<number[]>([])
  const [selected, setSelected] = useState<number | null>(null)

  const quizQuery = useQuery({
    queryKey: ['quiz', id],
    queryFn: () => api.get<QuizDetail>(`/quizzes/${id}`),
    enabled: !!id,
    refetchInterval: (q) => (q.state.data?.status === 'generating' ? 2500 : false),
  })

  const quiz = quizQuery.data

  if (quizQuery.isLoading) {
    return (
      <div className="flex justify-center py-20">
        <Spinner size={9} />
      </div>
    )
  }

  if (quizQuery.isError || !quiz) {
    return (
      <div className="mx-auto max-w-2xl rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700">
        Quiz yüklenemedi: {(quizQuery.error as Error)?.message ?? 'bilinmeyen hata'}
      </div>
    )
  }

  if (quiz.status === 'generating') {
    return (
      <div className="mx-auto max-w-2xl space-y-4">
        <div className="flex items-center justify-center gap-3 rounded-2xl border border-indigo-100 bg-indigo-50/60 py-6">
          <Spinner size={6} />
          <p className="text-sm font-medium text-indigo-700">
            Sorular üretiliyor... Bu sayfa otomatik güncellenecek.
          </p>
        </div>
        {[1, 2, 3].map((i) => (
          <div key={i} className="h-32 animate-pulse rounded-2xl bg-slate-200/60" />
        ))}
      </div>
    )
  }

  if (quiz.status === 'failed') {
    return (
      <div className="mx-auto max-w-2xl rounded-2xl border border-red-200 bg-red-50 px-5 py-6 text-sm text-red-700">
        <p className="font-semibold">Quiz üretimi başarısız oldu</p>
        <p className="mt-1">{quiz.error ?? 'Bilinmeyen bir hata oluştu.'}</p>
      </div>
    )
  }

  const questions = [...quiz.questions].sort((a, b) => a.position - b.position)

  if (questions.length === 0) {
    return (
      <div className="mx-auto max-w-2xl rounded-2xl border border-slate-200 bg-white px-5 py-10 text-center text-sm text-slate-500">
        Bu quizde soru bulunmuyor.
      </div>
    )
  }

  const finished = index >= questions.length

  // Sonuç ekranı
  if (finished) {
    const correct = answers.filter((a, i) => a === questions[i].answer_index).length
    const pct = Math.round((correct / questions.length) * 100)
    return (
      <div className="mx-auto max-w-2xl space-y-6">
        <div className="rounded-2xl border border-slate-200 bg-white p-8 text-center shadow-sm">
          <div className="mb-2 text-4xl">{pct >= 70 ? '🏆' : pct >= 50 ? '👍' : '📚'}</div>
          <h1 className="text-xl font-semibold text-slate-900">{quiz.title} — Sonuç</h1>
          <p className="mt-3 text-4xl font-bold text-indigo-600">%{pct}</p>
          <p className="mt-1 text-sm text-slate-500">
            {questions.length} sorudan {correct} doğru
          </p>
          <div className="mt-6 flex justify-center gap-3">
            <button
              onClick={() => {
                setIndex(0)
                setAnswers([])
                setSelected(null)
              }}
              className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              Tekrar dene
            </button>
            <Link
              to="/quizzes"
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
            >
              Quizlere dön
            </Link>
          </div>
        </div>

        {/* Soru bazlı inceleme */}
        <div className="space-y-3">
          <h2 className="text-base font-semibold text-slate-900">Soru incelemesi</h2>
          {questions.map((q, i) => {
            const userAnswer = answers[i]
            const isCorrect = userAnswer === q.answer_index
            return (
              <div
                key={i}
                className={`rounded-2xl border bg-white p-5 shadow-sm ${
                  isCorrect ? 'border-green-200' : 'border-red-200'
                }`}
              >
                <p className="text-sm font-medium text-slate-800">
                  {i + 1}. {q.question}
                </p>
                <div className="mt-3 space-y-1.5 text-sm">
                  {q.options.map((opt, oi) => (
                    <div
                      key={oi}
                      className={`rounded-lg px-3 py-1.5 ${
                        oi === q.answer_index
                          ? 'bg-green-50 font-medium text-green-800'
                          : oi === userAnswer
                            ? 'bg-red-50 text-red-700 line-through'
                            : 'text-slate-500'
                      }`}
                    >
                      {String.fromCharCode(65 + oi)}) {opt}
                      {oi === q.answer_index && ' ✓'}
                    </div>
                  ))}
                </div>
              </div>
            )
          })}
        </div>
      </div>
    )
  }

  const q = questions[index]
  const answered = selected !== null

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <div className="mb-1.5 flex justify-between text-xs font-medium text-slate-500">
          <span>{quiz.title}</span>
          <span>
            Soru {index + 1} / {questions.length}
          </span>
        </div>
        <div className="h-2 w-full overflow-hidden rounded-full bg-slate-200">
          <div
            className="h-full rounded-full bg-indigo-600 transition-all"
            style={{ width: `${(index / questions.length) * 100}%` }}
          />
        </div>
      </div>

      <div className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm">
        <p className="text-base font-medium text-slate-900">{q.question}</p>
        <div className="mt-5 space-y-2.5">
          {q.options.map((opt, oi) => {
            let classes =
              'border-slate-200 bg-white hover:border-indigo-300 hover:bg-indigo-50/40'
            if (answered) {
              if (oi === q.answer_index) {
                classes = 'border-green-400 bg-green-50 text-green-900'
              } else if (oi === selected) {
                classes = 'border-red-400 bg-red-50 text-red-900'
              } else {
                classes = 'border-slate-200 bg-white opacity-60'
              }
            }
            return (
              <button
                key={oi}
                disabled={answered}
                onClick={() => setSelected(oi)}
                className={`flex w-full items-center gap-3 rounded-xl border px-4 py-3 text-left text-sm transition-colors ${classes}`}
              >
                <span className="flex h-7 w-7 shrink-0 items-center justify-center rounded-full bg-slate-100 text-xs font-semibold text-slate-600">
                  {String.fromCharCode(65 + oi)}
                </span>
                {opt}
                {answered && oi === q.answer_index && <span className="ml-auto">✓</span>}
                {answered && oi === selected && oi !== q.answer_index && (
                  <span className="ml-auto">✕</span>
                )}
              </button>
            )
          })}
        </div>

        {answered && (
          <div className="mt-5 flex items-center justify-between">
            <p
              className={`text-sm font-medium ${
                selected === q.answer_index ? 'text-green-700' : 'text-red-700'
              }`}
            >
              {selected === q.answer_index ? 'Doğru! 🎉' : 'Yanlış — doğru cevap işaretlendi.'}
            </p>
            <button
              onClick={() => {
                setAnswers((prev) => [...prev, selected!])
                setSelected(null)
                setIndex((i) => i + 1)
              }}
              className="rounded-lg bg-indigo-600 px-5 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              {index + 1 === questions.length ? 'Sonucu gör' : 'Sonraki'}
            </button>
          </div>
        )}
      </div>
    </div>
  )
}
