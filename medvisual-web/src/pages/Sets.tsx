import { useRef, useState } from 'react'
import type { FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import { useToast } from '../hooks/useToast'
import StatusBadge from '../components/StatusBadge'
import Modal from '../components/Modal'
import Spinner from '../components/Spinner'
import EmptyState from '../components/EmptyState'
import type { SetRow, SetsResponse } from '../types'

export default function Sets() {
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { toast } = useToast()
  const [createOpen, setCreateOpen] = useState(false)
  const [newTitle, setNewTitle] = useState('')
  const [newDescription, setNewDescription] = useState('')
  const importInputRef = useRef<HTMLInputElement>(null)

  const setsQuery = useQuery({
    queryKey: ['sets'],
    queryFn: () => api.get<SetsResponse>('/sets'),
    refetchInterval: (q) =>
      q.state.data?.sets.some((s) => s.status === 'generating') ? 2500 : false,
  })

  const createSet = useMutation({
    mutationFn: () =>
      api.post<SetRow>('/sets', {
        title: newTitle.trim(),
        ...(newDescription.trim() ? { description: newDescription.trim() } : {}),
      }),
    onSuccess: (set) => {
      toast('Deste oluşturuldu.', 'success')
      setCreateOpen(false)
      setNewTitle('')
      setNewDescription('')
      queryClient.invalidateQueries({ queryKey: ['sets'] })
      navigate(`/sets/${set.id}`)
    },
    onError: (err: Error) => toast(err.message),
  })

  const importCards = useMutation({
    mutationFn: (file: File) => {
      const fd = new FormData()
      fd.append('file', file)
      fd.append('set_title', file.name.replace(/\.[^.]+$/, ''))
      return api.postForm<SetRow>('/cards/import', fd, { timeoutMs: 120_000 })
    },
    onSuccess: (set) => {
      toast('Kartlar içe aktarıldı.', 'success')
      queryClient.invalidateQueries({ queryKey: ['sets'] })
      navigate(`/sets/${set.id}`)
    },
    onError: (err: Error) => toast(err.message),
  })

  const handleCreate = (e: FormEvent) => {
    e.preventDefault()
    if (!newTitle.trim()) return
    createSet.mutate()
  }

  const sets = setsQuery.data?.sets ?? []

  return (
    <div className="mx-auto max-w-6xl space-y-6">
      <div className="flex flex-wrap items-center justify-between gap-4">
        <div>
          <h1 className="text-2xl font-semibold tracking-tight text-slate-900">
            Kart Desteleri
          </h1>
          <p className="mt-1 text-sm text-slate-500">
            Üretilen, içe aktarılan veya elle oluşturulan tüm desteleriniz.
          </p>
        </div>
        <div className="flex gap-3">
          <input
            ref={importInputRef}
            type="file"
            accept=".csv,.json,.tsv,.apkg,.txt"
            className="hidden"
            onChange={(e) => {
              const file = e.target.files?.[0]
              if (file) importCards.mutate(file)
              e.target.value = ''
            }}
          />
          <button
            onClick={() => importInputRef.current?.click()}
            disabled={importCards.isPending}
            className="inline-flex items-center gap-2 rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50"
          >
            {importCards.isPending ? (
              <Spinner size={4} />
            ) : (
              <span aria-hidden>📥</span>
            )}
            Kart Dosyası İçe Aktar
          </button>
          <button
            onClick={() => setCreateOpen(true)}
            className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
          >
            + Yeni Deste
          </button>
        </div>
      </div>

      {setsQuery.isLoading ? (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {[1, 2, 3, 4, 5, 6].map((i) => (
            <div key={i} className="h-36 animate-pulse rounded-2xl bg-slate-200/60" />
          ))}
        </div>
      ) : sets.length === 0 ? (
        <EmptyState
          icon="🗂️"
          title="Henüz deste yok"
          description="Panelden bir PDF yükleyip kart üretin, bir kart dosyası içe aktarın ya da boş bir deste oluşturun."
          action={
            <button
              onClick={() => setCreateOpen(true)}
              className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              Yeni Deste Oluştur
            </button>
          }
        />
      ) : (
        <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-3">
          {sets.map((set) => (
            <Link
              key={set.id}
              to={`/sets/${set.id}`}
              className="group flex flex-col rounded-2xl border border-slate-200 bg-white p-5 shadow-sm transition-shadow hover:shadow-md"
            >
              <div className="flex items-start justify-between gap-3">
                <h3 className="font-semibold text-slate-900 group-hover:text-indigo-700">
                  {set.title}
                </h3>
                <StatusBadge status={set.status} />
              </div>
              {set.description && (
                <p className="mt-2 line-clamp-2 text-sm text-slate-500">{set.description}</p>
              )}
              {set.status === 'failed' && set.error && (
                <p className="mt-2 line-clamp-2 text-xs text-red-600">{set.error}</p>
              )}
              <div className="mt-auto pt-4 text-xs font-medium text-slate-400">
                {set.card_count} kart ·{' '}
                {new Date(set.created_at).toLocaleDateString('tr-TR')}
              </div>
            </Link>
          ))}
        </div>
      )}

      <Modal
        open={createOpen}
        onClose={() => setCreateOpen(false)}
        title="Yeni Deste"
        widthClass="max-w-md"
      >
        <form onSubmit={handleCreate} className="space-y-4">
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Başlık</label>
            <input
              type="text"
              required
              value={newTitle}
              onChange={(e) => setNewTitle(e.target.value)}
              placeholder="örn. Farmakoloji — Antibiyotikler"
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">
              Açıklama (isteğe bağlı)
            </label>
            <textarea
              value={newDescription}
              onChange={(e) => setNewDescription(e.target.value)}
              rows={3}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none"
            />
          </div>
          <div className="flex justify-end gap-3">
            <button
              type="button"
              onClick={() => setCreateOpen(false)}
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
            >
              Vazgeç
            </button>
            <button
              type="submit"
              disabled={createSet.isPending || !newTitle.trim()}
              className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
            >
              {createSet.isPending && (
                <Spinner size={4} className="border-indigo-300 border-t-white" />
              )}
              Oluştur
            </button>
          </div>
        </form>
      </Modal>
    </div>
  )
}
