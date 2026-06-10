import { useEffect, useState } from 'react'

const STORAGE_KEY = 'medvisual_tour_done'

interface TourStep {
  icon: string
  title: string
  body: string
}

const STEPS: TourStep[] = [
  {
    icon: '📄',
    title: 'Doküman yükle',
    body: 'Panelden bir PDF (ders notu, kitap bölümü, makale) yükleyin veya hazır kütüphaneden bir kitap seçin. Motor dokümanı işledikten sonra üretime hazır olursunuz.',
  },
  {
    icon: '🃏',
    title: 'Kart veya quiz üret',
    body: 'Doküman "Hazır" olunca sayfa aralığı seçip bilgi kartı ya da çoktan seçmeli quiz üretin. Daha tutarlı ve klinik odaklı sorular için "Gemini ile zenginleştir" önerilir.',
  },
  {
    icon: '🔎',
    title: 'Görselli kart',
    body: 'Kartlara dokümandaki şekil ve figürleri ekleyin. Tek tek "Görsel Bul" ile seçebilir ya da "Tüm kartlara otomatik görsel" ile toplu olarak ekleyebilirsiniz.',
  },
  {
    icon: '🎓',
    title: 'Çalış — aralıklı tekrar',
    body: 'SM-2 algoritmasıyla kartlarınızı en doğru zamanda tekrar edersiniz. Kartı çevirip Tekrar / Zor / İyi / Kolay olarak değerlendirin; sistem bir sonraki tekrarı planlar.',
  },
  {
    icon: '📤',
    title: 'Dışa aktar',
    body: 'Destelerinizi ve quizlerinizi Anki (APKG), PDF, CSV, JSON ve daha fazlası olarak indirin. Başka uygulamalarda da çalışmaya devam edin.',
  },
]

export function isTourDone(): boolean {
  return localStorage.getItem(STORAGE_KEY) === '1'
}

interface OnboardingTourProps {
  open: boolean
  onClose: () => void
}

export default function OnboardingTour({ open, onClose }: OnboardingTourProps) {
  const [step, setStep] = useState(0)

  useEffect(() => {
    if (open) setStep(0)
  }, [open])

  if (!open) return null

  const finish = () => {
    localStorage.setItem(STORAGE_KEY, '1')
    onClose()
  }

  const current = STEPS[step]
  const isFirst = step === 0
  const isLast = step === STEPS.length - 1

  return (
    <div
      className="fixed inset-0 z-[60] flex items-center justify-center bg-slate-900/50 p-4"
      onClick={finish}
    >
      <div
        className="animate-fade-in w-full max-w-md rounded-2xl bg-white p-6 shadow-xl dark:bg-slate-800"
        onClick={(e) => e.stopPropagation()}
        role="dialog"
        aria-modal="true"
      >
        <div className="flex items-start justify-between">
          <span className="text-[11px] font-semibold uppercase tracking-wide text-indigo-500 dark:text-indigo-400">
            Tanıtım turu · {step + 1}/{STEPS.length}
          </span>
          <button
            onClick={finish}
            className="rounded-md px-2 py-0.5 text-xs font-medium text-slate-400 hover:bg-slate-100 hover:text-slate-600 dark:hover:bg-slate-700 dark:hover:text-slate-200"
          >
            Atla
          </button>
        </div>

        <div className="mt-4 text-center">
          <div className="mb-3 text-4xl">{current.icon}</div>
          <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">
            {current.title}
          </h2>
          <p className="mt-2 text-sm leading-relaxed text-slate-600 dark:text-slate-300">
            {current.body}
          </p>
        </div>

        {/* Adım göstergesi */}
        <div className="mt-5 flex justify-center gap-1.5">
          {STEPS.map((_, i) => (
            <span
              key={i}
              className={`h-1.5 rounded-full transition-all ${
                i === step
                  ? 'w-5 bg-indigo-600'
                  : 'w-1.5 bg-slate-300 dark:bg-slate-600'
              }`}
            />
          ))}
        </div>

        <div className="mt-6 flex items-center justify-between gap-3">
          <button
            onClick={() => setStep((s) => s - 1)}
            disabled={isFirst}
            className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:bg-slate-50 disabled:opacity-40 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700"
          >
            Geri
          </button>
          {isLast ? (
            <button
              onClick={finish}
              className="rounded-lg bg-indigo-600 px-5 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              Bitir
            </button>
          ) : (
            <button
              onClick={() => setStep((s) => s + 1)}
              className="rounded-lg bg-indigo-600 px-5 py-2 text-sm font-medium text-white hover:bg-indigo-700"
            >
              {isFirst ? 'Başla' : 'İleri'}
            </button>
          )}
        </div>
      </div>
    </div>
  )
}
