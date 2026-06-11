import { useEffect, useMemo, useRef, useState } from 'react'
import type { CSSProperties, PointerEvent as ReactPointerEvent } from 'react'
import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import Modal from './Modal'
import Spinner from './Spinner'
import AuthImage from './AuthImage'
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

/** Kırpma dikdörtgeni (piksel cinsinden) */
interface CropRect {
  x: number
  y: number
  w: number
  h: number
}

type DragState =
  | { mode: 'draw'; startX: number; startY: number }
  | { mode: 'move'; dx: number; dy: number }
  | { mode: 'resize'; anchorX: number; anchorY: number }

function clamp(v: number, min: number, max: number): number {
  return Math.min(Math.max(v, min), Math.max(min, max))
}

const HANDLE_POS: Record<'nw' | 'ne' | 'sw' | 'se', CSSProperties> = {
  nw: { left: -6, top: -6, cursor: 'nwse-resize' },
  ne: { right: -6, top: -6, cursor: 'nesw-resize' },
  sw: { left: -6, bottom: -6, cursor: 'nesw-resize' },
  se: { right: -6, bottom: -6, cursor: 'nwse-resize' },
}

interface CropViewProps {
  src: string
  alt: string
  pending: boolean
  /** Doğal (natural) görüntü koordinatlarında kırpma alanı */
  onConfirm: (rect: CropRect) => void
  onCancel: () => void
}

function CropView({ src, alt, pending, onConfirm, onCancel }: CropViewProps) {
  const imgRef = useRef<HTMLImageElement>(null)
  const overlayRef = useRef<HTMLDivElement>(null)
  const dragRef = useRef<DragState | null>(null)
  const [rect, setRect] = useState<CropRect | null>(null)

  const getPos = (e: ReactPointerEvent) => {
    const el = overlayRef.current
    if (!el) return { x: 0, y: 0 }
    const r = el.getBoundingClientRect()
    return {
      x: clamp(e.clientX - r.left, 0, r.width),
      y: clamp(e.clientY - r.top, 0, r.height),
    }
  }

  const onPointerDown = (e: ReactPointerEvent) => {
    if (pending) return
    e.preventDefault()
    const target = e.target as HTMLElement
    const pos = getPos(e)
    if (target.dataset.handle && rect) {
      // Sürüklenen köşenin karşısındaki köşe sabit kalır
      const corner = target.dataset.handle
      dragRef.current = {
        mode: 'resize',
        anchorX: corner.includes('w') ? rect.x + rect.w : rect.x,
        anchorY: corner.includes('n') ? rect.y + rect.h : rect.y,
      }
    } else if (target.dataset.rect && rect) {
      dragRef.current = { mode: 'move', dx: pos.x - rect.x, dy: pos.y - rect.y }
    } else {
      dragRef.current = { mode: 'draw', startX: pos.x, startY: pos.y }
      setRect({ x: pos.x, y: pos.y, w: 0, h: 0 })
    }
    overlayRef.current?.setPointerCapture(e.pointerId)
  }

  const onPointerMove = (e: ReactPointerEvent) => {
    const drag = dragRef.current
    const el = overlayRef.current
    if (!drag || !el) return
    e.preventDefault()
    const pos = getPos(e)
    const bounds = el.getBoundingClientRect()
    if (drag.mode === 'move') {
      setRect((r) =>
        r
          ? {
              ...r,
              x: clamp(pos.x - drag.dx, 0, bounds.width - r.w),
              y: clamp(pos.y - drag.dy, 0, bounds.height - r.h),
            }
          : r,
      )
    } else {
      const sx = drag.mode === 'draw' ? drag.startX : drag.anchorX
      const sy = drag.mode === 'draw' ? drag.startY : drag.anchorY
      setRect({
        x: Math.min(sx, pos.x),
        y: Math.min(sy, pos.y),
        w: Math.abs(pos.x - sx),
        h: Math.abs(pos.y - sy),
      })
    }
  }

  const onPointerUp = () => {
    dragRef.current = null
    // Çok küçük (yanlışlıkla tıklanan) alanları temizle
    setRect((r) => (r && (r.w < 5 || r.h < 5) ? null : r))
  }

  const confirm = () => {
    const img = imgRef.current
    if (!img || !rect || rect.w < 5 || rect.h < 5) return
    // Ekranda gösterilen koordinatları doğal görüntü koordinatlarına çevir
    const sx = img.naturalWidth / img.clientWidth
    const sy = img.naturalHeight / img.clientHeight
    const nx = clamp(Math.round(rect.x * sx), 0, img.naturalWidth - 1)
    const ny = clamp(Math.round(rect.y * sy), 0, img.naturalHeight - 1)
    onConfirm({
      x: nx,
      y: ny,
      w: clamp(Math.round(rect.w * sx), 1, img.naturalWidth - nx),
      h: clamp(Math.round(rect.h * sy), 1, img.naturalHeight - ny),
    })
  }

  const rectValid = !!rect && rect.w >= 5 && rect.h >= 5

  return (
    <div>
      <p className="mb-2 text-sm text-slate-600">
        Görsel üzerinde fareyle sürükleyerek kırpılacak alanı çizin. Alanı içinden
        tutup taşıyabilir, köşelerinden boyutlandırabilirsiniz.
      </p>
      <div className="flex justify-center rounded-xl bg-slate-100 p-3">
        <div className="relative inline-block select-none">
          <img
            ref={imgRef}
            src={src}
            alt={alt}
            draggable={false}
            className="block max-h-[55vh] max-w-full rounded-lg"
          />
          <div
            ref={overlayRef}
            className="absolute inset-0 cursor-crosshair overflow-hidden rounded-lg"
            style={{ touchAction: 'none' }}
            onPointerDown={onPointerDown}
            onPointerMove={onPointerMove}
            onPointerUp={onPointerUp}
          >
            {rect && (
              <div
                data-rect="true"
                className="absolute cursor-move border-2 border-indigo-500"
                style={{
                  left: rect.x,
                  top: rect.y,
                  width: rect.w,
                  height: rect.h,
                  boxShadow: '0 0 0 9999px rgba(15, 23, 42, 0.45)',
                }}
              >
                {(Object.keys(HANDLE_POS) as Array<keyof typeof HANDLE_POS>).map(
                  (corner) => (
                    <div
                      key={corner}
                      data-handle={corner}
                      className="absolute h-3 w-3 rounded-sm border border-indigo-600 bg-white"
                      style={HANDLE_POS[corner]}
                    />
                  ),
                )}
              </div>
            )}
          </div>
        </div>
      </div>
      <div className="mt-4 flex justify-end gap-3">
        <button
          onClick={onCancel}
          disabled={pending}
          className="rounded-lg border border-slate-300 px-5 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-50"
        >
          Vazgeç
        </button>
        <button
          onClick={confirm}
          disabled={!rectValid || pending}
          className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-5 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
        >
          {pending && <Spinner size={4} className="border-indigo-300 border-t-white" />}
          Kırpmayı Onayla
        </button>
      </div>
    </div>
  )
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
  const [docId, setDocId] = useState<string | null>(documentId)
  const [range, setRange] = useState('')
  const [rangeDirty, setRangeDirty] = useState(false)
  const [selected, setSelected] = useState<MatchCandidate | null>(null)
  const [selectedBlob, setSelectedBlob] = useState<Blob | null>(null)
  const [selectedSrc, setSelectedSrc] = useState<string | null>(null)
  const [result, setResult] = useState<MatchResponse | null>(null)
  const [step, setStep] = useState<'search' | 'confirm' | 'crop'>('search')

  useEffect(() => {
    if (open) {
      setSelected(null)
      setResult(null)
      setDocId(documentId)
      setStep('search')
      setRangeDirty(false)
    }
  }, [open, documentId])

  // Seçilen adayı Authorization başlıklı fetch ile indir (token URL'e sızmaz,
  // kırpma da aynı blob'u kullanır)
  useEffect(() => {
    if (!selected) {
      setSelectedBlob(null)
      setSelectedSrc(null)
      return
    }
    let cancelled = false
    let url: string | null = null
    ;(async () => {
      try {
        const token = await getAccessToken()
        const res = await fetch(`${API_URL}${selected.url}`, {
          headers: token ? { Authorization: `Bearer ${token}` } : undefined,
        })
        if (!res.ok) throw new Error(`Görsel indirilemedi (${res.status}).`)
        const blob = await res.blob()
        if (cancelled) return
        url = URL.createObjectURL(blob)
        setSelectedBlob(blob)
        setSelectedSrc(url)
      } catch (err) {
        if (!cancelled) toast((err as Error).message)
      }
    })()
    return () => {
      cancelled = true
      if (url) URL.revokeObjectURL(url)
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [selected])

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
    // Kullanıcı aralığı elle değiştirdiyse (dirty) sorgu çözülünce üzerine yazma
    if (open && !rangeDirty) {
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
      setStep('search')
      if (data.candidates.length === 0) {
        toast('Bu aralıkta uygun görsel bulunamadı. Farklı bir sayfa aralığı deneyin.', 'info')
      }
    },
    onError: (err: Error) => toast(err.message),
  })

  const handleSuccess = () => {
    toast('Görsel karta eklendi.', 'success')
    queryClient.invalidateQueries({ queryKey: ['set', setId] })
    onClose()
  }

  const selectImage = useMutation({
    mutationFn: (c: MatchCandidate) =>
      api.post<CardRow>(`/cards/${card.id}/select-image`, {
        dip_doc_id: c.dip_doc_id,
        path: c.path,
      }),
    onSuccess: handleSuccess,
    onError: (err: Error) => toast(err.message),
  })

  const uploadCrop = useMutation({
    mutationFn: async (rect: CropRect) => {
      if (!selectedBlob) throw new Error('Önce bir görsel seçin.')
      const bitmap = await createImageBitmap(selectedBlob)
      try {
        const canvas = document.createElement('canvas')
        canvas.width = rect.w
        canvas.height = rect.h
        const ctx = canvas.getContext('2d')
        if (!ctx) throw new Error('Tarayıcı canvas desteklemiyor.')
        ctx.drawImage(bitmap, rect.x, rect.y, rect.w, rect.h, 0, 0, rect.w, rect.h)
        const cropBlob = await new Promise<Blob | null>((resolve) =>
          canvas.toBlob(resolve, 'image/png'),
        )
        if (!cropBlob) throw new Error('Kırpılan görsel oluşturulamadı.')
        const fd = new FormData()
        fd.append('file', cropBlob, 'crop.png')
        return api.postForm<CardRow>(`/cards/${card.id}/upload-image`, fd)
      } finally {
        bitmap.close()
      }
    },
    onSuccess: handleSuccess,
    onError: (err: Error) => toast(err.message),
  })

  const rangeValid = /^\d+(-\d+)?$/.test(range.trim())
  const busy = selectImage.isPending || uploadCrop.isPending

  return (
    <Modal open={open} onClose={onClose} title="Görsel Bul" widthClass="max-w-3xl">
      {selected && selectedSrc && step === 'crop' ? (
        <CropView
          src={selectedSrc}
          alt={selected.label}
          pending={uploadCrop.isPending}
          onConfirm={(rect) => uploadCrop.mutate(rect)}
          onCancel={() => setStep('confirm')}
        />
      ) : selected && selectedSrc && step === 'confirm' ? (
        <div>
          <button
            onClick={() => {
              setSelected(null)
              setStep('search')
            }}
            disabled={busy}
            className="mb-3 text-sm font-medium text-indigo-600 hover:text-indigo-800 disabled:opacity-50"
          >
            &larr; Adaylara dön
          </button>
          <div className="flex justify-center rounded-xl bg-slate-100 p-3">
            <img
              src={selectedSrc}
              alt={selected.label}
              className="max-h-[55vh] max-w-full rounded-lg object-contain"
            />
          </div>
          <div className="mt-2 flex items-center justify-between text-xs text-slate-500">
            <span className="truncate font-medium text-slate-700">{selected.label}</span>
            <span>sayfa {selected.page}</span>
          </div>
          <div className="mt-4 flex justify-end gap-3">
            <button
              onClick={() => setStep('crop')}
              disabled={busy}
              className="rounded-lg border border-indigo-300 px-5 py-2 text-sm font-medium text-indigo-700 hover:bg-indigo-50 disabled:opacity-50"
            >
              Kırp
            </button>
            <button
              onClick={() => selectImage.mutate(selected)}
              disabled={busy}
              className="inline-flex items-center gap-2 rounded-lg bg-teal-600 px-5 py-2 text-sm font-medium text-white hover:bg-teal-700 disabled:opacity-50"
            >
              {selectImage.isPending && (
                <Spinner size={4} className="border-teal-300 border-t-white" />
              )}
              Olduğu gibi kullan
            </button>
          </div>
        </div>
      ) : (
        <>
          <p className="mb-4 text-sm text-slate-600 dark:text-slate-300">
            <span className="font-medium text-slate-800 dark:text-slate-100">
              {card.term || card.front.slice(0, 60)}
            </span>{' '}
            için doküman sayfalarında şekil/figür aranacak.
          </p>

          {!documentId && (
            <div className="mb-4">
              <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                Doküman seç
              </label>
              {docsQuery.isLoading ? (
                <Spinner size={5} />
              ) : readyDocs.length === 0 ? (
                <p className="text-sm text-slate-500 dark:text-slate-400">
                  Hazır durumda doküman yok. Önce panelden bir PDF yükleyin.
                </p>
              ) : (
                <select
                  value={docId ?? ''}
                  onChange={(e) => setDocId(e.target.value || null)}
                  className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
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
              <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                Sayfa aralığı
              </label>
              <input
                type="text"
                value={range}
                onChange={(e) => {
                  setRange(e.target.value)
                  setRangeDirty(true)
                }}
                placeholder="örn. 10-40"
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100"
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
                        onClick={() => {
                          setSelected(c)
                          setStep('confirm')
                        }}
                        className="shrink-0 rounded-xl border-2 border-slate-200 p-2 text-left transition-colors hover:border-indigo-300"
                      >
                        <AuthImage
                          src={c.url}
                          alt={c.label}
                          className="h-40 w-48 rounded-lg object-contain bg-slate-100"
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
                </>
              ) : (
                <p className="rounded-lg bg-slate-50 px-4 py-6 text-center text-sm text-slate-500">
                  Bu aralıkta aday görsel bulunamadı.
                </p>
              )}
            </div>
          )}
        </>
      )}
    </Modal>
  )
}
