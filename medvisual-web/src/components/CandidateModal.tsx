import { useEffect, useMemo, useState } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import Modal from './Modal'
import Spinner from './Spinner'
import { api, API_URL, getAccessToken } from '../lib/api'
import { useToast } from '../hooks/useToast'
import type {
  CardRow,
  DocumentsResponse,
  MatchCandidate,
  MatchResponse,
} from '../types'

interface CandidateModalProps {
  open: boolean
  onClose: () => void
  card: CardRow
  setId: string
  /** destenin bağlı olduğu doküman (varsa) */
  documentId: string | null
}

function defaultRange(page: number | null, pageCount: number | null): string {
  const total = pageCount ?? 40
  if (page && page > 0) {
    const start = Math.max(1, page - 15)
    const end = Math.min(total, start + 30)
    return `${start}-${end}`
  }
  return `1-${Math.min(total, 40)}`
}

export default function CandidateModal({
  open,
  onClose,
  card,
  setId,
  documentId,
}: CandidateModalProps) {
  const queryClient = useQueryClient()
  const { toast } = useToast()
  const [token, setToken] = useState<string | null>(null)
  const [docId, setDocId] = useState<string | null>(documentId)
  const [range, setRange] = useState('')
  const [selected, setSelected] = useState<MatchCandidate | null>(null)
  const [result, setResult] = useState<MatchResponse | null>(null)

  useEffect(() => {
    if (open) {
      getAccessToken().then(setToken)
      setSelected(null)
      setResult(null)
      setDocId(documentId)
    }
  }, [open, documentId])

  // Doküman listesi: hem seçim için hem de sayfa sayısını öğrenmek için
  const docsQuery = useQuery({
    queryKey: ['documents'],
    queryFn: () => api.get<DocumentsResponse>('/documents'),
    enabled: open,
  })
  const readyDocs = useMemo(
    () => (docsQuery.data?.documents ?? []).filter((d) => d.status === 'ready'),
    [docsQuery.data],
  )

  const selectedDoc = useMemo(() => {
    const all = docsQuery.data?.documents ?? []
    return all.find((d) => d.id === docId) ?? null
  }, [docsQuery.data, docId])

  useEffect(() => {
    if (open) {
      setRange(defaultRange(card.page, selectedDoc?.page_count ?? null))
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [open, docId, selectedDoc?.page_count])

  const match = useMutation({
    mutationFn: () =>
      api.post<MatchResponse>(
        `/cards/${card.id}/match`,
        {
          range,
          ...(documentId ? {} : { document_id: docId }),
        },
        { timeoutMs: 180_000 },
      ),
    onSuccess: (data) => {
      setResult(data)
      setSelected(null)
      if (data.candidates.length === 0) {
        toast('Bu aralıkta uygun görsel bulunamadı. Farklı bir sayfa aralığı deneyin.', 'info')
      }
    },
    onError: (err: Error) => toast(err.message),
  })

  const selectImage = useMutation({
    mutationFn: (c: MatchCandidate) =>
      api.post<CardRow>(`/cards/${card.id}/select-image`, {
        dip_doc_id: c.dip_doc_id,
        path: c.path,
      }),
    onSuccess: () => {
      toast('Görsel karta eklendi.', 'success')
      queryClient.invalidateQueries({ queryKey: ['set', setId] })
      onClose()
    },
    onError: (err: Error) => toast(err.message),
  })

  const rangeValid = /^\d+(-\d+)?$/.test(range.trim())

  return (
    <Modal open={open} onClose={onClose} title="Görsel Bul" widthClass="max-w-3xl">
      <p className="mb-4 text-sm text-slate-600">
        <span className="font-medium text-slate-800">
          {card.term || card.front.slice(0, 60)}
        </span>{' '}
        için doküman sayfalarında şekil/figür aranacak.
      </p>

      {!documentId && (
        <div className="mb-4">
          <label className="mb-1 block text-sm font-medium text-slate-700">
            Doküman seç
          </label>
          {docsQuery.isLoading ? (
            <Spinner size={5} />
          ) : readyDocs.length === 0 ? (
            <p className="text-sm text-slate-500">
              Hazır durumda doküman yok. Önce panelden bir PDF yükleyin.
            </p>
          ) : (
            <select
              value={docId ?? ''}
              onChange={(e) => setDocId(e.target.value || null)}
              className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none"
            >
              <option value="">— Doküman seçin —</option>
              {readyDocs.map((d) => (
                <option key={d.id} value={d.id}>
                  {d.filename} ({d.page_count ?? '?'} sayfa)
                </option>
              ))}
            </select>
          )}
        </div>
      )}

      <div className="mb-4 flex items-end gap-3">
        <div className="flex-1">
          <label className="mb-1 block text-sm font-medium text-slate-700">
            Sayfa aralığı
          </label>
          <input
            type="text"
            value={range}
            onChange={(e) => setRange(e.target.value)}
            placeholder="örn. 10-40"
            className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none"
          />
        </div>
        <button
          onClick={() => match.mutate()}
          disabled={match.isPending || !rangeValid || (!documentId && !docId)}
          className="inline-flex h-[38px] items-center gap-2 rounded-lg bg-indigo-600 px-5 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
        >
          {match.isPending && <Spinner size={4} className="border-indigo-300 border-t-white" />}
          Ara
        </button>
      </div>
      {!rangeValid && range.length > 0 && (
        <p className="-mt-2 mb-3 text-xs text-red-600">
          Geçerli bir aralık girin, örn. "10-40" veya tek sayfa "25".
        </p>
      )}

      {match.isPending && (
        <div className="flex flex-col items-center gap-3 rounded-xl border border-indigo-100 bg-indigo-50/50 py-10">
          <Spinner size={8} />
          <p className="text-sm font-medium text-indigo-700">
            Sayfalar taranıyor, bu 1-2 dakika sürebilir...
          </p>
        </div>
      )}

      {result && !match.isPending && (
        <div>
          {result.candidates.length > 0 ? (
            <>
              <p className="mb-2 text-sm text-slate-600">
                {result.candidates.length} aday görsel bulundu
                {result.best_page ? ` (en iyi eşleşme: sayfa ${result.best_page})` : ''}. Birini
                seçin:
              </p>
              <div className="flex gap-3 overflow-x-auto pb-2">
                {result.candidates.map((c, i) => (
                  <button
                    key={`${c.path}-${i}`}
                    onClick={() => setSelected(c)}
                    className={`shrink-0 rounded-xl border-2 p-2 text-left transition-colors ${
                      selected === c
                        ? 'border-indigo-600 bg-indigo-50'
                        : 'border-slate-200 hover:border-indigo-300'
                    }`}
                  >
                    <img
                      src={`${API_URL}${c.url}?token=${token ?? ''}`}
                      alt={c.label}
                      className="h-40 w-48 rounded-lg object-contain bg-slate-100"
                      loading="lazy"
                    />
                    <div className="mt-2 flex items-center justify-between gap-2">
                      <span className="max-w-[140px] truncate text-xs font-medium text-slate-700">
                        {c.label}
                      </span>
                      <span className="rounded-full bg-slate-100 px-2 py-0.5 text-[10px] font-medium text-slate-500">
                        s. {c.page}
                      </span>
                    </div>
                  </button>
                ))}
              </div>
              <div className="mt-4 flex justify-end">
                <button
                  onClick={() => selected && selectImage.mutate(selected)}
                  disabled={!selected || selectImage.isPending}
                  className="inline-flex items-center gap-2 rounded-lg bg-teal-600 px-5 py-2 text-sm font-medium text-white hover:bg-teal-700 disabled:opacity-50"
                >
                  {selectImage.isPending && (
                    <Spinner size={4} className="border-teal-300 border-t-white" />
                  )}
                  Bu görseli kullan
                </button>
              </div>
            </>
          ) : (
            <p className="rounded-lg bg-slate-50 px-4 py-6 text-center text-sm text-slate-500">
              Bu aralıkta aday görsel bulunamadı.
            </p>
          )}
        </div>
      )}
    </Modal>
  )
}
