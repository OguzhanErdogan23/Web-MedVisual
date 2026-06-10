import { createContext, useCallback, useContext, useRef, useState } from 'react'
import type { ReactNode } from 'react'

export interface Toast {
  id: number
  message: string
  type: 'error' | 'success' | 'info'
}

interface ToastContextValue {
  toasts: Toast[]
  toast: (message: string, type?: Toast['type']) => void
  dismiss: (id: number) => void
}

const ToastContext = createContext<ToastContextValue>({
  toasts: [],
  toast: () => {},
  dismiss: () => {},
})

export function ToastProvider({ children }: { children: ReactNode }) {
  const [toasts, setToasts] = useState<Toast[]>([])
  const counter = useRef(0)

  const dismiss = useCallback((id: number) => {
    setToasts((prev) => prev.filter((t) => t.id !== id))
  }, [])

  const toast = useCallback(
    (message: string, type: Toast['type'] = 'error') => {
      counter.current += 1
      const id = counter.current
      setToasts((prev) => [...prev, { id, message, type }])
      setTimeout(() => dismiss(id), 6000)
    },
    [dismiss],
  )

  return (
    <ToastContext.Provider value={{ toasts, toast, dismiss }}>
      {children}
      <ToastViewport toasts={toasts} dismiss={dismiss} />
    </ToastContext.Provider>
  )
}

function ToastViewport({
  toasts,
  dismiss,
}: {
  toasts: Toast[]
  dismiss: (id: number) => void
}) {
  if (toasts.length === 0) return null
  const colors: Record<Toast['type'], string> = {
    error: 'bg-red-50 border-red-200 text-red-800',
    success: 'bg-teal-50 border-teal-200 text-teal-800',
    info: 'bg-indigo-50 border-indigo-200 text-indigo-800',
  }
  return (
    <div className="fixed bottom-4 right-4 z-[100] flex flex-col gap-2 max-w-sm">
      {toasts.map((t) => (
        <div
          key={t.id}
          className={`animate-fade-in flex items-start gap-3 rounded-lg border px-4 py-3 shadow-lg text-sm ${colors[t.type]}`}
        >
          <span className="flex-1 break-words">{t.message}</span>
          <button
            onClick={() => dismiss(t.id)}
            className="shrink-0 opacity-60 hover:opacity-100"
            aria-label="Kapat"
          >
            ✕
          </button>
        </div>
      ))}
    </div>
  )
}

// eslint-disable-next-line react-refresh/only-export-components
export function useToast() {
  return useContext(ToastContext)
}
