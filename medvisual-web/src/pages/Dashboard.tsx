import { useState } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import { useToast } from '../hooks/useToast'
import UploadDropzone from '../components/UploadDropzone'
import StatusBadge from '../components/StatusBadge'
import Modal from '../components/Modal'
import Spinner from '../components/Spinner'
import EmptyState from '../components/EmptyState'
import ConfirmDialog from '../components/ConfirmDialog'
import type {
  BooksResponse,
  DocumentRow,
  DocumentsResponse,
  StudyStats,
} from '../types'

const EXPIRED_HINT =
  'Doküman motoru yeniden başlatılmış, lütfen PDF\'i yeniden yükleyin'

function StatCard({ label, value, icon }: { label: string; value: number | string; icon: string }) {
  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex items-center gap-3">
        <span className="flex h-10 w-10 items-center justify-center rounded-xl bg-indigo-50 text-lg">
          {icon}
        </span>
        <div>
          <p className="text-2xl font-semibold text-slate-900">{value}</p>
          <p className="text-xs font-medium text-slate-500">{label}</p>
        </div>
      </div>
    </div>
  )
}

export default function Dashboard() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { toast } = useToast()
  const [libraryOpen, setLibraryOpen] = useState(false)
  const [deleteTarget, setDeleteTarget] = useState<DocumentRow | null>(null)

  const statsQuery = useQuery({
    queryKey: ['study-stats'],
    queryFn: () => api.get<StudyStats>('/study/stats'),
  })

  const docsQuery = useQuery({
    queryKey: ['documents'],
    queryFn: () => api.get<DocumentsResponse>('/documents'),
    refetchInterval: (q) =>
      q.state.data?.documents.some((d) => d.status === 'processing') ? 2500 : false,
  })

  const booksQuery = useQuery({
    queryKey: ['books'],
    queryFn: () => api.get<BooksResponse>('/books'),
    enabled: libraryOpen,
  })

  const loadBook = useMutation({
    mutationFn: (name: string) =>
      api.post<DocumentRow>('/books/load', { name }, { timeoutMs: 120_000 }),
    onSuccess: (doc) => {
      toast(`"${doc.filename}" kütüphaneden yükleniyor...`, 'success')
      setLibraryOpen(false)
      queryClient.invalidateQueries({ queryKey: ['documents'] })
    },
    onError: (err: Error) => toast(err.message),
  })

  const deleteDoc = useMutation({
    mutationFn: (id: string) => api.delete(`/documents/${id}`),
    onSuccess: () => {
      toast('Doküman silindi.', 'success')
      setDeleteTarget(null)
      queryClient.invalidateQueries({ queryKey: ['documents'] })
      queryClient.invalidateQueries({ queryKey: ['study-stats'] })
    },
    onError: (err: Error) => toast(err.message),
  })

  const stats = statsQuery.data
  const documents = docsQuery.data?.documents ?? []

  return (
    <div className="mx-auto max-w-6xl space-y-8">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-slate-900">Panel</h1>
        <p className="mt-1 text-sm text-slate-500">
          Hoş geldiniz! PDF yükleyin, kart ve quiz üretin, çalışmaya başlayın.
        </p>
      </div>

      {/* İstatistikler */}
      <div className="grid grid-cols-2 gap-4 lg:grid-cols-4">
        <StatCard label="Doküman" value={stats?.documents ?? '—'} icon="📄" />
        <StatCard label="Deste" value={stats?.sets ?? '—'} icon="🗂️" />
        <StatCard label="Kart" value={stats?.cards ?? '—'} icon="🃏" />
        <StatCard label="Bugün çalışılacak" value={stats?.due_now ?? '—'} icon="⏰" />
      </div>

      {/* Yükleme */}
      <UploadDropzone />

      {/* Doküman listesi */}
      <section>
        <div className="mb-4 flex items-center justify-between">
          <h2 className="text-lg font-semibold text-slate-900">Dokümanlar</h2>
          <button
            onClick={() => setLibraryOpen(true)}
            className="rounded-lg border border-indigo-200 bg-indigo-50 px-4 py-2 text-sm font-medium text-indigo-700 hover:bg-indigo-100"
          >
            📚 Kütüphane
          </button>
        </div>

        {docsQuery.isLoading ? (
          <div className="space-y-3">
            {[1, 2, 3].map((i) => (
              <div key={i} className="h-16 animate-pulse rounded-xl bg-slate-200/60" />
            ))}
          </div>
        ) : documents.length === 0 ? (
          <EmptyState
            icon="📄"
            title="Henüz doküman yok"
            description="Yukarıdan bir PDF yükleyin veya kütüphaneden hazır bir kitap seçin."
            action={
              <button
                onClick={() => setLibraryOpen(true)}
                className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
              >
                Kütüphaneye göz at
              </button>
            }
          />
        ) : (
          <div className="overflow-hidden rounded-2xl border border-slate-200 bg-white shadow-sm">
            <table className="w-full text-sm">
              <thead>
                <tr className="border-b border-slate-100 bg-slate-50/60 text-left text-xs font-medium uppercase tracking-wide text-slate-500">
                  <th className="px-5 py-3">Dosya</th>
                  <th className="px-5 py-3">Sayfa</th>
                  <th className="px-5 py-3">Durum</th>
                  <th className="px-5 py-3">Tarih</th>
                  <th className="px-5 py-3 text-right">İşlemler</th>
                </tr>
              </thead>
              <tbody>
                {documents.map((doc) => (
                  <tr key={doc.id} className="border-b border-slate-50 last:border-0 hover:bg-slate-50/40">
                    <td className="px-5 py-3.5">
                      <span className="font-medium text-slate-800">{doc.filename}</span>
                      {(doc.status === 'failed' || doc.status === 'expired') && (
                        <p className="mt-0.5 text-xs text-red-600">
                          {doc.status === 'expired' ? EXPIRED_HINT : doc.error}
                        </p>
                      )}
                    </td>
                    <td className="px-5 py-3.5 text-slate-500">{doc.page_count ?? '—'}</td>
                    <td className="px-5 py-3.5">
                      <StatusBadge status={doc.status} />
                    </td>
                    <td className="px-5 py-3.5 text-slate-500">
                      {new Date(doc.created_at).toLocaleDateString('tr-TR')}
                    </td>
                    <td className="px-5 py-3.5">
                      <div className="flex justify-end gap-2">
                        {doc.status === 'ready' && (
                          <>
                            <Link
                              to={`/documents/${doc.id}?tab=cards`}
                              className="rounded-lg bg-indigo-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-indigo-700"
                            >
                              Kart Üret
                            </Link>
                            <Link
                              to={`/documents/${doc.id}?tab=quiz`}
                              className="rounded-lg bg-teal-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-teal-700"
                            >
                              Quiz Üret
                            </Link>
                          </>
                        )}
                        <button
                          onClick={() => setDeleteTarget(doc)}
                          className="rounded-lg border border-slate-200 px-3 py-1.5 text-xs font-medium text-slate-600 hover:border-red-200 hover:bg-red-50 hover:text-red-700"
                        >
                          Sil
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </section>

      {/* Kütüphane modali */}
      <Modal
        open={libraryOpen}
        onClose={() => setLibraryOpen(false)}
        title="Kütüphane — Hazır Kitaplar"
        widthClass="max-w-2xl"
      >
        {booksQuery.isLoading ? (
          <div className="flex justify-center py-10">
            <Spinner size={8} />
          </div>
        ) : booksQuery.isError ? (
          <p className="py-6 text-center text-sm text-red-600">
            {(booksQuery.error as Error).message}
          </p>
        ) : (booksQuery.data?.books ?? []).length === 0 ? (
          <p className="py-6 text-center text-sm text-slate-500">
            Motorda önceden yüklenmiş kitap bulunmuyor.
          </p>
        ) : (
          <ul className="divide-y divide-slate-100">
            {booksQuery.data!.books.map((book) => (
              <li key={book.name} className="flex items-center justify-between gap-4 py-3">
                <div>
                  <p className="text-sm font-medium text-slate-800">{book.display}</p>
                  <p className="text-xs text-slate-500">
                    {book.pages} sayfa · {book.size_mb.toFixed(1)} MB
                  </p>
                </div>
                <button
                  onClick={() => loadBook.mutate(book.name)}
                  disabled={loadBook.isPending}
                  className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-1.5 text-xs font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
                >
                  {loadBook.isPending && loadBook.variables === book.name && (
                    <Spinner size={3} className="border-indigo-300 border-t-white" />
                  )}
                  Yükle
                </button>
              </li>
            ))}
          </ul>
        )}
      </Modal>

      {/* Silme onayı */}
      <ConfirmDialog
        open={deleteTarget !== null}
        title="Dokümanı sil"
        message={`"${deleteTarget?.filename}" silinecek. Bu işlem geri alınamaz. Devam edilsin mi?`}
        loading={deleteDoc.isPending}
        onConfirm={() => deleteTarget && deleteDoc.mutate(deleteTarget.id)}
        onCancel={() => setDeleteTarget(null)}
      />

      {/* navigate kullanılmıyor uyarısını önlemek için değil; hızlı erişim */}
      {stats && stats.due_now > 0 && (
        <div className="flex items-center justify-between rounded-2xl border border-teal-200 bg-teal-50 px-5 py-4">
          <p className="text-sm font-medium text-teal-800">
            Bugün çalışmanız gereken {stats.due_now} kart var.
          </p>
          <button
            onClick={() => navigate('/study')}
            className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700"
          >
            Şimdi çalış
          </button>
        </div>
      )}
    </div>
  )
}
