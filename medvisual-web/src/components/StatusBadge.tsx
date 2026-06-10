import type { DocumentStatus, GenStatus } from '../types'

const config: Record<string, { label: string; classes: string; pulse?: boolean }> = {
  processing: { label: 'İşleniyor', classes: 'bg-amber-50 text-amber-700 border-amber-200', pulse: true },
  generating: { label: 'Üretiliyor', classes: 'bg-amber-50 text-amber-700 border-amber-200', pulse: true },
  ready: { label: 'Hazır', classes: 'bg-teal-50 text-teal-700 border-teal-200' },
  failed: { label: 'Hata', classes: 'bg-red-50 text-red-700 border-red-200' },
  expired: { label: 'Süresi doldu', classes: 'bg-slate-100 text-slate-500 border-slate-200' },
}

export default function StatusBadge({ status }: { status: DocumentStatus | GenStatus | string }) {
  const c = config[status] ?? { label: status, classes: 'bg-slate-100 text-slate-600 border-slate-200' }
  return (
    <span
      className={`inline-flex items-center gap-1.5 rounded-full border px-2.5 py-0.5 text-xs font-medium ${c.classes}`}
    >
      {c.pulse && <span className="h-1.5 w-1.5 rounded-full bg-amber-500 animate-pulse" />}
      {c.label}
    </span>
  )
}
