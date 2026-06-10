import { useEffect, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api, API_URL, getAccessToken } from '../lib/api'
import { useToast } from '../hooks/useToast'
import StatusBadge from '../components/StatusBadge'
import Modal from '../components/Modal'
import Spinner from '../components/Spinner'
import EmptyState from '../components/EmptyState'
import ConfirmDialog from '../components/ConfirmDialog'
import CandidateModal from '../components/CandidateModal'
import type { CardRow, SetDetail as SetDetailType } from '../types'

function resolveImageUrl(url: string, token: string | null): string {
  if (url.startsWith('http://') || url.startsWith('https://')) return url
  return `${API_URL}${url}?token=${token ?? ''}`
}

function downloadFile(filename: string, content: string, mime: string) {
  const blob = new Blob([content], { type: mime })
  const a = document.createElement('a')
  a.href = URL.createObjectURL(blob)
  a.download = filename
  a.click()
  URL.revokeObjectURL(a.href)
}

function csvEscape(value: string): string {
  if (/[",\n]/.test(value)) return `"${value.replace(/"/g, '""')}"`
  return value
}

function CardItem({
  card,
  setId,
  documentId,
  token,
}: {
  card: CardRow
  setId: string
  documentId: string | null
  token: string | null
}) {
  const queryClient = useQueryClient()
  const { toast } = useToast()
  const [flipped, setFlipped] = useState(false)
  const [editing, setEditing] = useState(false)
  const [front, setFront] = useState(card.front)
  const [back, setBack] = useState(card.back)
  const [matchOpen, setMatchOpen] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(false)

  const update = useMutation({
    mutationFn: () => api.patch<CardRow>(`/cards/${card.id}`, { front, back }),
    onSuccess: () => {
      toast('Kart güncellendi.', 'success')
      setEditing(false)
      queryClient.invalidateQueries({ queryKey: ['set', setId] })
    },
    onError: (err: Error) => toast(err.message),
  })

  const remove = useMutation({
    mutationFn: () => api.delete(`/cards/${card.id}`),
    onSuccess: () => {
      toast('Kart silindi.', 'success')
      setConfirmDelete(false)
      queryClient.invalidateQueries({ queryKey: ['set', setId] })
    },
    onError: (err: Error) => toast(err.message),
  })

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm">
      <div className="flex gap-4">
        {card.image_url && (
          <img
            src={resolveImageUrl(card.image_url, token)}
            alt="Kart görseli"
            className="h-24 w-28 shrink-0 rounded-lg border border-slate-100 bg-slate-50 object-contain"
            loading="lazy"
          />
        )}
        <div className="min-w-0 flex-1">
          {editing ? (
            <div className="space-y-3">
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-500">Ön yüz</label>
                <textarea
                  value={front}
                  onChange={(e) => setFront(e.target.value)}
                  rows={2}
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-500">Arka yüz</label>
                <textarea
                  value={back}
                  onChange={(e) => setBack(e.target.value)}
                  rows={3}
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none"
                />
              </div>
              <div className="flex gap-2">
                <button
                  onClick={() => update.mutate()}
                  disabled={update.isPending}
                  className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-3 py-1.5 text-xs font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
                >
                  {update.isPending && (
                    <Spinner size={3} className="border-indigo-300 border-t-white" />
                  )}
                  Kaydet
                </button>
                <button
                  onClick={() => {
                    setEditing(false)
                    setFront(card.front)
                    setBack(card.back)
                  }}
                  className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-50"
                >
                  Vazgeç
                </button>
              </div>
            </div>
          ) : (
            <button
              onClick={() => setFlipped((f) => !f)}
              className="block w-full cursor-pointer text-left"
              title="Çevirmek için tıklayın"
            >
              <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400">
                {flipped ? 'Arka yüz' : 'Ön yüz'} — çevirmek için tıklayın
              </p>
              <p className="mt-1 whitespace-pre-wrap text-sm text-slate-800">
                {flipped ? card.back : card.front}
              </p>
            </button>
          )}

          <div className="mt-3 flex flex-wrap items-center gap-2">
            {card.term && (
              <span className="rounded-full bg-indigo-50 px-2.5 py-0.5 text-xs font-medium text-indigo-700">
                {card.term}
              </span>
            )}
            {card.page !== null && (
              <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-500">
                Sayfa {card.page}
              </span>
            )}
            {card.kind && (
              <span className="rounded-full bg-teal-50 px-2.5 py-0.5 text-xs font-medium text-teal-700">
                {card.kind}
              </span>
            )}
          </div>
        </div>

        {!editing && (
          <div className="flex shrink-0 flex-col items-end gap-1.5">
            <button
              onClick={() => setMatchOpen(true)}
              className="rounded-lg border border-indigo-200 bg-indigo-50 px-2.5 py-1 text-xs font-medium text-indigo-700 hover:bg-indigo-100"
            >
              🔎 Görsel Bul
            </button>
            <button
              onClick={() => setEditing(true)}
              className="rounded-lg border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 hover:bg-slate-50"
            >
              Düzenle
            </button>
            <button
              onClick={() => setConfirmDelete(true)}
              className="rounded-lg border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 hover:border-red-200 hover:bg-red-50 hover:text-red-700"
            >
              Sil
            </button>
          </div>
        )}
      </div>

      <CandidateModal
        open={matchOpen}
        onClose={() => setMatchOpen(false)}
        card={card}
        setId={setId}
        documentId={documentId}
      />
      <ConfirmDialog
        open={confirmDelete}
        title="Kartı sil"
        message="Bu kart kalıcı olarak silinecek. Devam edilsin mi?"
        loading={remove.isPending}
        onConfirm={() => remove.mutate()}
        onCancel={() => setConfirmDelete(false)}
      />
    </div>
  )
}

export default function SetDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { toast } = useToast()
  const [token, setToken] = useState<string | null>(null)
  const [exportOpen, setExportOpen] = useState(false)
  const [editTitle, setEditTitle] = useState(false)
  const [titleDraft, setTitleDraft] = useState('')
  const [confirmDeleteSet, setConfirmDeleteSet] = useState(false)
  const [addOpen, setAddOpen] = useState(false)
  const [newFront, setNewFront] = useState('')
  const [newBack, setNewBack] = useState('')
  const [newTerm, setNewTerm] = useState('')

  useEffect(() => {
    getAccessToken().then(setToken)
  }, [])

  const setQuery = useQuery({
    queryKey: ['set', id],
    queryFn: () => api.get<SetDetailType>(`/sets/${id}`),
    enabled: !!id,
    refetchInterval: (q) => (q.state.data?.status === 'generating' ? 2500 : false),
  })

  const updateSet = useMutation({
    mutationFn: (body: { title?: string; description?: string }) =>
      api.patch<SetDetailType>(`/sets/${id}`, body),
    onSuccess: () => {
      toast('Deste güncellendi.', 'success')
      setEditTitle(false)
      queryClient.invalidateQueries({ queryKey: ['set', id] })
      queryClient.invalidateQueries({ queryKey: ['sets'] })
    },
    onError: (err: Error) => toast(err.message),
  })

  const deleteSet = useMutation({
    mutationFn: () => api.delete(`/sets/${id}`),
    onSuccess: () => {
      toast('Deste silindi.', 'success')
      queryClient.invalidateQueries({ queryKey: ['sets'] })
      navigate('/sets')
    },
    onError: (err: Error) => toast(err.message),
  })

  const addCard = useMutation({
    mutationFn: () =>
      api.post<CardRow>(`/sets/${id}/cards`, {
        front: newFront.trim(),
        back: newBack.trim(),
        ...(newTerm.trim() ? { term: newTerm.trim() } : {}),
      }),
    onSuccess: () => {
      toast('Kart eklendi.', 'success')
      setAddOpen(false)
      setNewFront('')
      setNewBack('')
      setNewTerm('')
      queryClient.invalidateQueries({ queryKey: ['set', id] })
    },
    onError: (err: Error) => toast(err.message),
  })

  const set = setQuery.data
  const cards = set?.cards ?? []

  const exportJson = () => {
    if (!set) return
    downloadFile(
      `${set.title}.json`,
      JSON.stringify(
        cards.map((c) => ({ front: c.front, back: c.back, term: c.term, page: c.page })),
        null,
        2,
      ),
      'application/json',
    )
    setExportOpen(false)
  }

  const exportCsv = () => {
    if (!set) return
    const rows = ['front,back,term,page']
    for (const c of cards) {
      rows.push(
        [csvEscape(c.front), csvEscape(c.back), csvEscape(c.term ?? ''), String(c.page ?? '')].join(
          ',',
        ),
      )
    }
    downloadFile(`${set.title}.csv`, rows.join('\n'), 'text/csv;charset=utf-8')
    setExportOpen(false)
  }

  if (setQuery.isLoading) {
    return (
      <div className="flex justify-center py-20">
        <Spinner size={9} />
      </div>
    )
  }

  if (setQuery.isError || !set) {
    return (
      <div className="mx-auto max-w-2xl rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700">
        Deste yüklenemedi: {(setQuery.error as Error)?.message ?? 'bilinmeyen hata'}
      </div>
    )
  }

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      {/* Başlık */}
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="min-w-0">
          {editTitle ? (
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={titleDraft}
                onChange={(e) => setTitleDraft(e.target.value)}
                className="rounded-lg border border-slate-300 px-3 py-1.5 text-lg font-semibold focus:border-indigo-500 focus:outline-none"
              />
              <button
                onClick={() => titleDraft.trim() && updateSet.mutate({ title: titleDraft.trim() })}
                disabled={updateSet.isPending}
                className="rounded-lg bg-indigo-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
              >
                Kaydet
              </button>
              <button
                onClick={() => setEditTitle(false)}
                className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50"
              >
                Vazgeç
              </button>
            </div>
          ) : (
            <h1
              className="cursor-pointer text-2xl font-semibold tracking-tight text-slate-900 hover:text-indigo-700"
              onClick={() => {
                setTitleDraft(set.title)
                setEditTitle(true)
              }}
              title="Başlığı düzenlemek için tıklayın"
            >
              {set.title} <span className="text-sm font-normal text-slate-400">✏️</span>
            </h1>
          )}
          <div className="mt-1.5 flex items-center gap-3 text-sm text-slate-500">
            <StatusBadge status={set.status} />
            <span>{cards.length} kart</span>
          </div>
          {set.description && <p className="mt-2 text-sm text-slate-500">{set.description}</p>}
        </div>

        <div className="flex flex-wrap gap-2">
          <Link
            to={`/study/${set.id}`}
            className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700"
          >
            🎓 Çalış
          </Link>
          <div className="relative">
            <button
              onClick={() => setExportOpen((o) => !o)}
              className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
            >
              Dışa Aktar ▾
            </button>
            {exportOpen && (
              <div className="absolute right-0 z-20 mt-1 w-40 overflow-hidden rounded-lg border border-slate-200 bg-white shadow-lg">
                <button
                  onClick={exportJson}
                  className="block w-full px-4 py-2 text-left text-sm text-slate-700 hover:bg-slate-50"
                >
                  JSON olarak indir
                </button>
                <button
                  onClick={exportCsv}
                  className="block w-full px-4 py-2 text-left text-sm text-slate-700 hover:bg-slate-50"
                >
                  CSV olarak indir
                </button>
              </div>
            )}
          </div>
          <button
            onClick={() => setAddOpen(true)}
            className="rounded-lg border border-indigo-200 bg-indigo-50 px-4 py-2 text-sm font-medium text-indigo-700 hover:bg-indigo-100"
          >
            + Kart Ekle
          </button>
          <button
            onClick={() => setConfirmDeleteSet(true)}
            className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-600 hover:border-red-200 hover:bg-red-50 hover:text-red-700"
          >
            Sil
          </button>
        </div>
      </div>

      {/* İçerik */}
      {set.status === 'generating' ? (
        <div className="space-y-4">
          <div className="flex items-center justify-center gap-3 rounded-2xl border border-indigo-100 bg-indigo-50/60 py-6">
            <Spinner size={6} />
            <p className="text-sm font-medium text-indigo-700">
              Kartlar üretiliyor... Bu sayfa otomatik güncellenecek.
            </p>
          </div>
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-28 animate-pulse rounded-2xl bg-slate-200/60" />
          ))}
        </div>
      ) : set.status === 'failed' ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-5 py-6 text-sm text-red-700">
          <p className="font-semibold">Üretim başarısız oldu</p>
          <p className="mt-1">{set.error ?? 'Bilinmeyen bir hata oluştu.'}</p>
        </div>
      ) : cards.length === 0 ? (
        <EmptyState
          icon="🃏"
          title="Bu destede henüz kart yok"
          description='"+ Kart Ekle" ile elle kart ekleyebilirsiniz.'
          action={
            <button
              onClick={() => setAddOpen(true)}
              className="rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              + Kart Ekle
            </button>
          }
        />
      ) : (
        <div className="space-y-3">
          {cards.map((card) => (
            <CardItem
              key={card.id}
              card={card}
              setId={set.id}
              documentId={set.document_id}
              token={token}
            />
          ))}
        </div>
      )}

      {/* Kart ekleme modali */}
      <Modal open={addOpen} onClose={() => setAddOpen(false)} title="Yeni Kart" widthClass="max-w-md">
        <form
          onSubmit={(e) => {
            e.preventDefault()
            if (newFront.trim() && newBack.trim()) addCard.mutate()
          }}
          className="space-y-4"
        >
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Ön yüz</label>
            <textarea
              required
              value={newFront}
              onChange={(e) => setNewFront(e.target.value)}
              rows={2}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">Arka yüz</label>
            <textarea
              required
              value={newBack}
              onChange={(e) => setNewBack(e.target.value)}
              rows={3}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700">
              Terim (isteğe bağlı)
            </label>
            <input
              type="text"
              value={newTerm}
              onChange={(e) => setNewTerm(e.target.value)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none"
            />
          </div>
          <div className="flex justify-end gap-3">
            <button
              type="button"
              onClick={() => setAddOpen(false)}
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50"
            >
              Vazgeç
            </button>
            <button
              type="submit"
              disabled={addCard.isPending || !newFront.trim() || !newBack.trim()}
              className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
            >
              {addCard.isPending && (
                <Spinner size={4} className="border-indigo-300 border-t-white" />
              )}
              Ekle
            </button>
          </div>
        </form>
      </Modal>

      <ConfirmDialog
        open={confirmDeleteSet}
        title="Desteyi sil"
        message={`"${set.title}" destesi ve tüm kartları silinecek. Devam edilsin mi?`}
        loading={deleteSet.isPending}
        onConfirm={() => deleteSet.mutate()}
        onCancel={() => setConfirmDeleteSet(false)}
      />
    </div>
  )
}
