import { useEffect, useRef, useState } from 'react'
import { downloadBlob, getBlob } from '../lib/api'
import { useToast } from '../hooks/useToast'
import Spinner from './Spinner'

export interface ExportFormat {
  /** API'ye gönderilen format değeri, örn. 'json' | 'anki' | 'apkg' */
  value: string
  /** Menüde gösterilen etiket */
  label: string
  /** İndirilen dosya için yedek uzantı (Content-Disposition yoksa) */
  ext: string
}

interface ExportMenuProps {
  /** format değeri eklenmeden önceki yol, örn. `/sets/123/export` */
  basePath: string
  /** Content-Disposition yoksa kullanılacak dosya adı (uzantısız) */
  fallbackBaseName: string
  formats: ExportFormat[]
  /** Buton etiketi */
  label?: string
  className?: string
}

export default function ExportMenu({
  basePath,
  fallbackBaseName,
  formats,
  label = 'Dışa Aktar',
  className = '',
}: ExportMenuProps) {
  const { toast } = useToast()
  const [open, setOpen] = useState(false)
  const [busy, setBusy] = useState<string | null>(null)
  const ref = useRef<HTMLDivElement>(null)

  useEffect(() => {
    if (!open) return
    const handler = (e: MouseEvent) => {
      if (ref.current && !ref.current.contains(e.target as Node)) setOpen(false)
    }
    window.addEventListener('mousedown', handler)
    return () => window.removeEventListener('mousedown', handler)
  }, [open])

  const handleExport = async (fmt: ExportFormat) => {
    if (busy) return
    setBusy(fmt.value)
    try {
      const sep = basePath.includes('?') ? '&' : '?'
      const { blob, filename } = await getBlob(
        `${basePath}${sep}format=${fmt.value}`,
        `${fallbackBaseName}.${fmt.ext}`,
        { timeoutMs: 120_000 },
      )
      downloadBlob(blob, filename)
      setOpen(false)
    } catch (err) {
      toast((err as Error).message)
    } finally {
      setBusy(null)
    }
  }

  return (
    <div ref={ref} className={`relative ${className}`}>
      <button
        onClick={() => setOpen((o) => !o)}
        className="inline-flex items-center gap-1.5 rounded-lg border border-slate-300 bg-white px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-600 dark:bg-slate-800 dark:text-slate-200 dark:hover:bg-slate-700"
      >
        {busy && <Spinner size={4} />}
        {label} ▾
      </button>
      {open && (
        <div className="absolute right-0 z-30 mt-1 w-44 overflow-hidden rounded-lg border border-slate-200 bg-white shadow-lg dark:border-slate-700 dark:bg-slate-800">
          {formats.map((fmt) => (
            <button
              key={fmt.value}
              onClick={() => handleExport(fmt)}
              disabled={busy !== null}
              className="flex w-full items-center justify-between gap-2 px-4 py-2 text-left text-sm text-slate-700 hover:bg-slate-50 disabled:opacity-50 dark:text-slate-200 dark:hover:bg-slate-700"
            >
              <span>{fmt.label}</span>
              {busy === fmt.value && <Spinner size={3} />}
            </button>
          ))}
        </div>
      )}
    </div>
  )
}
