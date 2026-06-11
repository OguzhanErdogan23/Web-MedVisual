import { useEffect, useMemo, useState } from 'react'
import { Link, useNavigate, useParams } from 'react-router-dom'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import { useToast } from '../hooks/useToast'
import { useTerms } from '../hooks/useTerms'
import StatusBadge from '../components/StatusBadge'
import Modal from '../components/Modal'
import Spinner from '../components/Spinner'
import EmptyState from '../components/EmptyState'
import ConfirmDialog from '../components/ConfirmDialog'
import CandidateModal from '../components/CandidateModal'
import ExportMenu from '../components/ExportMenu'
import AuthImage from '../components/AuthImage'
import type {
  CardRow,
  DocumentsResponse,
  SetDetail as SetDetailType,
} from '../types'

const TERMS_LIST_ID = 'medvisual-terms'

const SET_EXPORT_FORMATS = [
  { value: 'json', label: 'JSON', ext: 'json' },
  { value: 'csv', label: 'CSV', ext: 'csv' },
  { value: 'tsv', label: 'TSV', ext: 'tsv' },
  { value: 'anki', label: 'Anki', ext: 'tsv' },
  { value: 'txt', label: 'TXT', ext: 'txt' },
  { value: 'pdf', label: 'PDF', ext: 'pdf' },
  { value: 'apkg', label: 'APKG', ext: 'apkg' },
]

/** Set açıklamasındaki "uretim: X" bilgisini ayıklar (llm_enhanced rozeti). */
function productionBadge(description: string | null): { label: string; gemini: boolean } | null {
  const m = /uretim:\s*([\w.\-/]+)/i.exec(description ?? '')
  if (!m) return null
  const model = m[1]
  if (model === 'offline') return { label: 'Offline üretim', gemini: false }
  return { label: `✨ ${model}`, gemini: true }
}

function CardItem({
  card,
  setId,
  documentId,
}: {
  card: CardRow
  setId: string
  documentId: string | null
}) {
  const queryClient = useQueryClient()
  const { toast } = useToast()
  const [flipped, setFlipped] = useState(false)
  const [editing, setEditing] = useState(false)
  const [front, setFront] = useState(card.front)
  const [back, setBack] = useState(card.back)
  const [term, setTerm] = useState(card.term ?? '')
  const [matchOpen, setMatchOpen] = useState(false)
  const [confirmDelete, setConfirmDelete] = useState(false)
  const [confirmRemoveImage, setConfirmRemoveImage] = useState(false)

  const update = useMutation({
    mutationFn: () =>
      api.patch<CardRow>(`/cards/${card.id}`, { front, back, term: term.trim() || null }),
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

  const removeImage = useMutation({
    mutationFn: () => api.delete<CardRow>(`/cards/${card.id}/image`),
    onSuccess: () => {
      toast('Görsel kaldırıldı.', 'success')
      setConfirmRemoveImage(false)
      queryClient.invalidateQueries({ queryKey: ['set', setId] })
    },
    onError: (err: Error) => toast(err.message),
  })

  return (
    <div className="rounded-2xl border border-slate-200 bg-white p-5 shadow-sm dark:border-slate-700 dark:bg-slate-800">
      <div className="flex gap-4">
        {card.image_url && (
          <div className="flex shrink-0 flex-col items-center gap-1.5">
            <AuthImage
              src={card.image_url}
              alt="Kart görseli"
              className="h-24 w-28 rounded-lg border border-slate-100 bg-slate-50 object-contain dark:border-slate-700 dark:bg-slate-900"
            />
            <div className="flex gap-1">
              <button
                onClick={() => setMatchOpen(true)}
                className="rounded-md border border-slate-200 px-2 py-0.5 text-[11px] font-medium text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
              >
                Değiştir
              </button>
              <button
                onClick={() => setConfirmRemoveImage(true)}
                className="rounded-md border border-slate-200 px-2 py-0.5 text-[11px] font-medium text-slate-600 hover:border-red-200 hover:bg-red-50 hover:text-red-700 dark:border-slate-600 dark:text-slate-300 dark:hover:border-red-900 dark:hover:bg-red-950/40 dark:hover:text-red-400"
              >
                Kaldır
              </button>
            </div>
          </div>
        )}
        <div className="min-w-0 flex-1">
          {editing ? (
            <div className="space-y-3">
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-500 dark:text-slate-400">Ön yüz</label>
                <textarea
                  value={front}
                  onChange={(e) => setFront(e.target.value)}
                  rows={2}
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-500 dark:text-slate-400">Arka yüz</label>
                <textarea
                  value={back}
                  onChange={(e) => setBack(e.target.value)}
                  rows={3}
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
                />
              </div>
              <div>
                <label className="mb-1 block text-xs font-medium text-slate-500 dark:text-slate-400">Terim</label>
                <input
                  type="text"
                  value={term}
                  onChange={(e) => setTerm(e.target.value)}
                  list={TERMS_LIST_ID}
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
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
                    setTerm(card.term ?? '')
                  }}
                  className="rounded-lg border border-slate-300 px-3 py-1.5 text-xs font-medium text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
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
              <p className="text-[10px] font-semibold uppercase tracking-wide text-slate-400 dark:text-slate-500">
                {flipped ? 'Arka yüz' : 'Ön yüz'} — çevirmek için tıklayın
              </p>
              <p className="mt-1 whitespace-pre-wrap text-sm text-slate-800 dark:text-slate-200">
                {flipped ? card.back : card.front}
              </p>
            </button>
          )}

          <div className="mt-3 flex flex-wrap items-center gap-2">
            {card.term && (
              <span className="rounded-full bg-indigo-50 px-2.5 py-0.5 text-xs font-medium text-indigo-700 dark:bg-indigo-950/60 dark:text-indigo-300">
                {card.term}
              </span>
            )}
            {card.page !== null && (
              <span className="rounded-full bg-slate-100 px-2.5 py-0.5 text-xs font-medium text-slate-500 dark:bg-slate-700 dark:text-slate-300">
                Sayfa {card.page}
              </span>
            )}
            {card.kind && (
              <span className="rounded-full bg-teal-50 px-2.5 py-0.5 text-xs font-medium text-teal-700 dark:bg-teal-950/60 dark:text-teal-300">
                {card.kind}
              </span>
            )}
          </div>
        </div>

        {!editing && (
          <div className="flex shrink-0 flex-col items-end gap-1.5">
            {!card.image_url && (
              <button
                onClick={() => setMatchOpen(true)}
                className="rounded-lg border border-indigo-200 bg-indigo-50 px-2.5 py-1 text-xs font-medium text-indigo-700 hover:bg-indigo-100 dark:border-indigo-900 dark:bg-indigo-950/60 dark:text-indigo-300 dark:hover:bg-indigo-900/60"
              >
                🔎 Görsel Bul
              </button>
            )}
            <button
              onClick={() => {
                // Düzenlemeye o anki güncel kart verisiyle başla (bayat state'i önler)
                setFront(card.front)
                setBack(card.back)
                setTerm(card.term ?? '')
                setEditing(true)
              }}
              className="rounded-lg border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
            >
              Düzenle
            </button>
            <button
              onClick={() => setConfirmDelete(true)}
              className="rounded-lg border border-slate-200 px-2.5 py-1 text-xs font-medium text-slate-600 hover:border-red-200 hover:bg-red-50 hover:text-red-700 dark:border-slate-600 dark:text-slate-300 dark:hover:border-red-900 dark:hover:bg-red-950/40 dark:hover:text-red-400"
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
      <ConfirmDialog
        open={confirmRemoveImage}
        title="Görseli kaldır"
        message="Bu kartın görseli kaldırılacak. Devam edilsin mi?"
        confirmLabel="Kaldır"
        loading={removeImage.isPending}
        onConfirm={() => removeImage.mutate()}
        onCancel={() => setConfirmRemoveImage(false)}
      />
    </div>
  )
}

export default function SetDetail() {
  const { id } = useParams<{ id: string }>()
  const navigate = useNavigate()
  const queryClient = useQueryClient()
  const { toast } = useToast()
  const termsQuery = useTerms()
  const [editTitle, setEditTitle] = useState(false)
  const [titleDraft, setTitleDraft] = useState('')
  const [confirmDeleteSet, setConfirmDeleteSet] = useState(false)
  const [addOpen, setAddOpen] = useState(false)
  const [newFront, setNewFront] = useState('')
  const [newBack, setNewBack] = useState('')
  const [newTerm, setNewTerm] = useState('')

  // Toplu otomatik görsel
  const [autoConfirm, setAutoConfirm] = useState(false)
  const [autoPickerOpen, setAutoPickerOpen] = useState(false)
  const [autoDocId, setAutoDocId] = useState<string | null>(null)
  const [autoRange, setAutoRange] = useState('')

  const setQuery = useQuery({
    queryKey: ['set', id],
    queryFn: () => api.get<SetDetailType>(`/sets/${id}`),
    enabled: !!id,
    refetchInterval: (q) => (q.state.data?.status === 'generating' ? 2500 : false),
  })

  const set = setQuery.data
  const cards = useMemo(() => set?.cards ?? [], [set])

  // Otomatik görsel için doküman seçimi (deste dokümana bağlı değilse)
  const docsQuery = useQuery({
    queryKey: ['documents'],
    queryFn: () => api.get<DocumentsResponse>('/documents'),
    enabled: autoPickerOpen,
  })
  const readyDocs = useMemo(
    () => (docsQuery.data?.documents ?? []).filter((d) => d.status === 'ready'),
    [docsQuery.data],
  )
  const autoSelectedDoc = useMemo(
    () => readyDocs.find((d) => d.id === autoDocId) ?? null,
    [readyDocs, autoDocId],
  )

  useEffect(() => {
    if (autoPickerOpen) {
      setAutoRange(`1-${autoSelectedDoc?.page_count ?? 40}`)
    }
  }, [autoPickerOpen, autoSelectedDoc?.page_count])

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

  const autoImages = useMutation({
    mutationFn: (body: { range?: string; document_id?: string }) =>
      api.post<{ status: string; set_id: string }>(`/sets/${id}/auto-images`, body),
    onSuccess: () => {
      toast('Otomatik görsel üretimi başladı. Kartlar hazır olunca güncellenecek.', 'success')
      setAutoConfirm(false)
      setAutoPickerOpen(false)
      queryClient.invalidateQueries({ queryKey: ['set', id] })
    },
    onError: (err: Error) => toast(err.message),
  })

  const startAutoImages = () => {
    if (!set) return
    if (set.document_id) {
      setAutoConfirm(true)
    } else {
      setAutoPickerOpen(true)
    }
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
      <div className="mx-auto max-w-2xl rounded-xl border border-red-200 bg-red-50 px-5 py-4 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/40 dark:text-red-300">
        Deste yüklenemedi: {(setQuery.error as Error)?.message ?? 'bilinmeyen hata'}
      </div>
    )
  }

  const autoRangeValid = /^\d+(-\d+)?$/.test(autoRange.trim())

  return (
    <div className="mx-auto max-w-4xl space-y-6">
      {/* Terim otomatik tamamlama listesi */}
      <datalist id={TERMS_LIST_ID}>
        {(termsQuery.data?.terms ?? []).map((t) => (
          <option key={t} value={t} />
        ))}
      </datalist>

      {/* Başlık */}
      <div className="flex flex-wrap items-start justify-between gap-4">
        <div className="min-w-0">
          {editTitle ? (
            <div className="flex items-center gap-2">
              <input
                type="text"
                value={titleDraft}
                onChange={(e) => setTitleDraft(e.target.value)}
                className="rounded-lg border border-slate-300 px-3 py-1.5 text-lg font-semibold focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
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
                className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
              >
                Vazgeç
              </button>
            </div>
          ) : (
            <h1
              className="cursor-pointer text-2xl font-semibold tracking-tight text-slate-900 hover:text-indigo-700 dark:text-slate-100 dark:hover:text-indigo-400"
              onClick={() => {
                setTitleDraft(set.title)
                setEditTitle(true)
              }}
              title="Başlığı düzenlemek için tıklayın"
            >
              {set.title} <span className="text-sm font-normal text-slate-400">✏️</span>
            </h1>
          )}
          <div className="mt-1.5 flex items-center gap-3 text-sm text-slate-500 dark:text-slate-400">
            <StatusBadge status={set.status} />
            <span>{cards.length} kart</span>
            {(() => {
              const badge = productionBadge(set.description)
              if (!badge) return null
              return (
                <span
                  className={`rounded-full px-2.5 py-0.5 text-xs font-medium ${
                    badge.gemini
                      ? 'bg-indigo-50 text-indigo-700 dark:bg-indigo-950/60 dark:text-indigo-300'
                      : 'bg-slate-100 text-slate-600 dark:bg-slate-700 dark:text-slate-300'
                  }`}
                  title="Kart üretiminde kullanılan yöntem"
                >
                  {badge.label}
                </span>
              )
            })()}
          </div>
          {set.description && (
            <p className="mt-2 text-sm text-slate-500 dark:text-slate-400">{set.description}</p>
          )}
        </div>

        <div className="flex flex-wrap gap-2">
          <Link
            to={`/study/${set.id}`}
            className="rounded-lg bg-teal-600 px-4 py-2 text-sm font-medium text-white hover:bg-teal-700"
          >
            🎓 Çalış
          </Link>
          <Link
            to={`/study/${set.id}?mode=cram`}
            title="Tüm kartlarla pratik — tekrar zamanlamasını etkilemez"
            className="rounded-lg border border-teal-200 bg-teal-50 px-4 py-2 text-sm font-medium text-teal-700 hover:bg-teal-100 dark:border-teal-800 dark:bg-teal-950/50 dark:text-teal-300 dark:hover:bg-teal-900/50"
          >
            🎯 Serbest
          </Link>
          <button
            onClick={startAutoImages}
            disabled={autoImages.isPending || set.status === 'generating'}
            className="inline-flex items-center gap-2 rounded-lg border border-indigo-200 bg-indigo-50 px-4 py-2 text-sm font-medium text-indigo-700 hover:bg-indigo-100 disabled:opacity-50 dark:border-indigo-900 dark:bg-indigo-950/60 dark:text-indigo-300 dark:hover:bg-indigo-900/60"
          >
            {autoImages.isPending && <Spinner size={4} />}
            🖼️ Tüm kartlara otomatik görsel
          </button>
          <ExportMenu
            basePath={`/sets/${set.id}/export`}
            fallbackBaseName={set.title}
            formats={SET_EXPORT_FORMATS}
          />
          <button
            onClick={() => setAddOpen(true)}
            className="rounded-lg border border-indigo-200 bg-indigo-50 px-4 py-2 text-sm font-medium text-indigo-700 hover:bg-indigo-100 dark:border-indigo-900 dark:bg-indigo-950/60 dark:text-indigo-300 dark:hover:bg-indigo-900/60"
          >
            + Kart Ekle
          </button>
          <button
            onClick={() => setConfirmDeleteSet(true)}
            className="rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-600 hover:border-red-200 hover:bg-red-50 hover:text-red-700 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-300 dark:hover:border-red-900 dark:hover:bg-red-950/40 dark:hover:text-red-400"
          >
            Sil
          </button>
        </div>
      </div>

      {/* İçerik */}
      {set.status === 'generating' ? (
        <div className="space-y-4">
          <div className="flex items-center justify-center gap-3 rounded-2xl border border-indigo-100 bg-indigo-50/60 py-6 dark:border-indigo-900 dark:bg-indigo-950/40">
            <Spinner size={6} />
            <p className="text-sm font-medium text-indigo-700 dark:text-indigo-300">
              Kartlar hazırlanıyor... Bu sayfa otomatik güncellenecek.
            </p>
          </div>
          {[1, 2, 3, 4].map((i) => (
            <div key={i} className="h-28 animate-pulse rounded-2xl bg-slate-200/60 dark:bg-slate-700/40" />
          ))}
        </div>
      ) : set.status === 'failed' ? (
        <div className="rounded-2xl border border-red-200 bg-red-50 px-5 py-6 text-sm text-red-700 dark:border-red-900 dark:bg-red-950/40 dark:text-red-300">
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
            <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">Ön yüz</label>
            <textarea
              required
              value={newFront}
              onChange={(e) => setNewFront(e.target.value)}
              rows={2}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">Arka yüz</label>
            <textarea
              required
              value={newBack}
              onChange={(e) => setNewBack(e.target.value)}
              rows={3}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
              Terim (isteğe bağlı)
            </label>
            <input
              type="text"
              value={newTerm}
              onChange={(e) => setNewTerm(e.target.value)}
              list={TERMS_LIST_ID}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
            />
          </div>
          <div className="flex justify-end gap-3">
            <button
              type="button"
              onClick={() => setAddOpen(false)}
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700"
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

      {/* Otomatik görsel — doküman seçici (deste dokümana bağlı değilse) */}
      <Modal
        open={autoPickerOpen}
        onClose={() => setAutoPickerOpen(false)}
        title="Toplu otomatik görsel"
        widthClass="max-w-md"
      >
        <p className="mb-4 text-sm text-slate-600 dark:text-slate-300">
          Görseli olmayan tüm kartlara, seçilen dokümandan otomatik figür eklenecek.
        </p>
        {docsQuery.isLoading ? (
          <div className="flex justify-center py-6">
            <Spinner size={6} />
          </div>
        ) : readyDocs.length === 0 ? (
          <p className="text-sm text-slate-500 dark:text-slate-400">
            Hazır durumda doküman yok. Önce panelden bir PDF yükleyin.
          </p>
        ) : (
          <div className="space-y-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                Doküman
              </label>
              <select
                value={autoDocId ?? ''}
                onChange={(e) => setAutoDocId(e.target.value || null)}
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
              >
                <option value="">— Doküman seçin —</option>
                {readyDocs.map((d) => (
                  <option key={d.id} value={d.id}>
                    {d.filename} ({d.page_count ?? '?'} sayfa)
                  </option>
                ))}
              </select>
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                Sayfa aralığı
              </label>
              <input
                type="text"
                value={autoRange}
                onChange={(e) => setAutoRange(e.target.value)}
                placeholder="örn. 1-40"
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
              />
            </div>
            <div className="flex justify-end gap-3">
              <button
                onClick={() => setAutoPickerOpen(false)}
                className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700"
              >
                Vazgeç
              </button>
              <button
                onClick={() =>
                  autoDocId &&
                  autoImages.mutate({ document_id: autoDocId, range: autoRange.trim() })
                }
                disabled={!autoDocId || !autoRangeValid || autoImages.isPending}
                className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
              >
                {autoImages.isPending && (
                  <Spinner size={4} className="border-indigo-300 border-t-white" />
                )}
                Başlat
              </button>
            </div>
          </div>
        )}
      </Modal>

      <ConfirmDialog
        open={autoConfirm}
        title="Toplu otomatik görsel"
        message="Görseli olmayan tüm kartlara otomatik figür eklenecek, bu bir dakika sürebilir."
        confirmLabel="Başlat"
        loading={autoImages.isPending}
        onConfirm={() => autoImages.mutate({})}
        onCancel={() => setAutoConfirm(false)}
      />

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
