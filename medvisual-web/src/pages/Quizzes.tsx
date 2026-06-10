import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import { useToast } from '../hooks/useToast'
import StatusBadge from '../components/StatusBadge'
import EmptyState from '../components/EmptyState'
import ConfirmDialog from '../components/ConfirmDialog'
import type { QuizRow, QuizzesResponse } from '../types'

export default function Quizzes() {
  const queryClient = useQueryClient()
  const { toast } = useToast()
  const [deleteTarget, setDeleteTarget] = useState<QuizRow | null>(null)

  const quizzesQuery = useQuery({
    queryKey: ['quizzes'],
    queryFn: () => api.get<QuizzesResponse>('/quizzes'),
    refetchInterval: (q) =>
      q.state.data?.quizzes.some((quiz) => quiz.status === 'generating') ? 2500 : false,
  })

  const deleteQuiz = useMutation({
    mutationFn: (id: string) => api.delete(`/quizzes/${id}`),
    onSuccess: () => {
      toast('Quiz silindi.', 'success')
      setDeleteTarget(null)
      queryClient.invalidateQueries({ queryKey: ['quizzes'] })
    },
    onError: (err: Error) => toast(err.message),
  })

  const quizzes = quizzesQuery.data?.quizzes ?? []

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-slate-900">Quizler</h1>
        <p className="mt-1 text-sm text-slate-500">
          Dokümanlarınızdan üretilen çoktan seçmeli quizler.
        </p>
      </div>

      {quizzesQuery.isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-32 animate-pulse rounded-2xl bg-slate-200/60" />
          ))}
        </div>
      ) : quizzes.length === 0 ? (
        <EmptyState
          icon="❓"
          title="Henüz quiz yok"
          description="Panelden bir dokümanın yanındaki 'Quiz Üret' butonuyla ilk quizinizi oluşturun."
          action={
            <Link
              to="/"
              className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              Panele git
            </Link>
          }
        />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {quizzes.map((quiz) => (
            <div
              key={quiz.id}
              className="flex flex-col rounded-2xl border border-slate-200 bg-white p-5 shadow-sm"
            >
              <div className="flex items-start justify-between gap-3">
                <h3 className="font-semibold text-slate-900">{quiz.title}</h3>
                <StatusBadge status={quiz.status} />
              </div>
              {quiz.status === 'failed' && quiz.error && (
                <p className="mt-2 line-clamp-2 text-xs text-red-600">{quiz.error}</p>
              )}
              <p className="mt-2 text-xs font-medium text-slate-400">
                {quiz.question_count} soru ·{' '}
                {new Date(quiz.created_at).toLocaleDateString('tr-TR')}
              </p>
              <div className="mt-auto flex gap-2 pt-4">
                <Link
                  to={`/quizzes/${quiz.id}`}
                  className="flex-1 rounded-lg bg-indigo-600 px-3 py-2 text-center text-sm font-medium text-white hover:bg-indigo-700"
                >
                  {quiz.status === 'generating' ? 'İlerlemeyi gör' : 'Başla'}
                </Link>
                <button
                  onClick={() => setDeleteTarget(quiz)}
                  className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-slate-600 hover:border-red-200 hover:bg-red-50 hover:text-red-700"
                >
                  Sil
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      <ConfirmDialog
        open={deleteTarget !== null}
        title="Quizi sil"
        message={`"${deleteTarget?.title}" silinecek. Devam edilsin mi?`}
        loading={deleteQuiz.isPending}
        onConfirm={() => deleteTarget && deleteQuiz.mutate(deleteTarget.id)}
        onCancel={() => setDeleteTarget(null)}
      />
    </div>
  )
}
