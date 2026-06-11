import { useState } from 'react'
import { Link } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import { useToast } from '../hooks/useToast'
import StatusBadge from '../components/StatusBadge'
import EmptyState from '../components/EmptyState'
import ConfirmDialog from '../components/ConfirmDialog'
import ExportMenu from '../components/ExportMenu'
import Modal from '../components/Modal'
import Spinner from '../components/Spinner'
import type { QuizRow, QuizzesResponse } from '../types'

const QUIZ_EXPORT_FORMATS = [
  { value: 'json', label: 'JSON', ext: 'json' },
  { value: 'csv', label: 'CSV', ext: 'csv' },
  { value: 'txt', label: 'TXT', ext: 'txt' },
  { value: 'pdf', label: 'PDF', ext: 'pdf' },
]

export default function Quizzes() {
  const queryClient = useQueryClient()
  const { toast } = useToast()
  const [deleteTarget, setDeleteTarget] = useState<QuizRow | null>(null)
  const [renameTarget, setRenameTarget] = useState<QuizRow | null>(null)
  const [renameDraft, setRenameDraft] = useState('')

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

  const renameQuiz = useMutation({
    mutationFn: ({ id, title }: { id: string; title: string }) =>
      api.patch<QuizRow>(`/quizzes/${id}`, { title }),
    onSuccess: () => {
      toast('Quiz yeniden adlandırıldı.', 'success')
      setRenameTarget(null)
      queryClient.invalidateQueries({ queryKey: ['quizzes'] })
    },
    onError: (err: Error) => toast(err.message),
  })

  const openRename = (quiz: QuizRow) => {
    setRenameDraft(quiz.title)
    setRenameTarget(quiz)
  }

  const quizzes = quizzesQuery.data?.quizzes ?? []

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-slate-900 dark:text-slate-100">Quizler</h1>
        <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
          Dokümanlarınızdan üretilen çoktan seçmeli quizler.
        </p>
      </div>

      {quizzesQuery.isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3].map((i) => (
            <div key={i} className="h-32 animate-pulse rounded-2xl bg-slate-200/60" />
          ))}
        </div>
      ) : quizzesQuery.isError ? (
        <div className="rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/40 dark:text-red-300">
          Quizler yüklenemedi: {(quizzesQuery.error as Error).message}
          <button
            onClick={() => quizzesQuery.refetch()}
            className="ml-3 rounded-lg bg-red-600 px-3 py-1 text-xs font-medium text-white hover:bg-red-700"
          >
            Tekrar dene
          </button>
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
              className="flex flex-col rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800"
            >
              <div className="flex items-start justify-between gap-3">
                <h3 className="font-semibold text-slate-900 dark:text-slate-100">{quiz.title}</h3>
                <StatusBadge status={quiz.status} />
              </div>
              {quiz.status === 'failed' && quiz.error && (
                <p className="mt-2 line-clamp-2 text-xs text-red-600 dark:text-red-400">{quiz.error}</p>
              )}
              <p className="mt-2 text-xs font-medium text-slate-400 dark:text-slate-500">
                {quiz.question_count} soru ·{' '}
                {new Date(quiz.created_at).toLocaleDateString('tr-TR')}
              </p>
              <div className="mt-auto flex flex-wrap gap-2 pt-4">
                <Link
                  to={`/quizzes/${quiz.id}`}
                  className="flex-1 rounded-lg bg-indigo-600 px-3 py-2 text-center text-sm font-medium text-white hover:bg-indigo-700"
                >
                  {quiz.status === 'generating' ? 'İlerlemeyi gör' : 'Başla'}
                </Link>
                {quiz.status === 'ready' && (
                  <ExportMenu
                    basePath={`/quizzes/${quiz.id}/export`}
                    fallbackBaseName={quiz.title}
                    formats={QUIZ_EXPORT_FORMATS}
                  />
                )}
                <button
                  onClick={() => openRename(quiz)}
                  title="Yeniden adlandır"
                  aria-label="Yeniden adlandır"
                  className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
                >
                  ✏️
                </button>
                <button
                  onClick={() => setDeleteTarget(quiz)}
                  className="rounded-lg border border-slate-200 px-3 py-2 text-sm font-medium text-slate-600 hover:border-red-200 hover:bg-red-50 hover:text-red-700 dark:border-slate-600 dark:text-slate-300 dark:hover:border-red-900 dark:hover:bg-red-950/40 dark:hover:text-red-400"
                >
                  Sil
                </button>
              </div>
            </div>
          ))}
        </div>
      )}

      <Modal
        open={renameTarget !== null}
        onClose={() => setRenameTarget(null)}
        title="Quizi yeniden adlandır"
        widthClass="max-w-md"
      >
        <form
          onSubmit={(e) => {
            e.preventDefault()
            if (renameTarget && renameDraft.trim()) {
              renameQuiz.mutate({ id: renameTarget.id, title: renameDraft.trim() })
            }
          }}
          className="space-y-4"
        >
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
              Quiz adı
            </label>
            <input
              type="text"
              autoFocus
              value={renameDraft}
              onChange={(e) => setRenameDraft(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
            />
          </div>
          <div className="flex justify-end gap-3">
            <button
              type="button"
              onClick={() => setRenameTarget(null)}
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700"
            >
              Vazgeç
            </button>
            <button
              type="submit"
              disabled={renameQuiz.isPending || !renameDraft.trim()}
              className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
            >
              {renameQuiz.isPending && (
                <Spinner size={4} className="border-indigo-300 border-t-white" />
              )}
              Kaydet
            </button>
          </div>
        </form>
      </Modal>

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
