import { useEffect, useState } from 'react'
import { API_URL, getAccessToken } from '../lib/api'

/**
 * Kimlik doğrulamalı görsel: göreli yolları (/dip-images/...) Authorization
 * başlıklı fetch ile indirir ve nesne URL'i olarak gösterir. Böylece JWT
 * query string'e sızmaz ve token süresi dolsa bile her yüklemede taze token
 * kullanılır. Mutlak URL'ler (Supabase Storage public) aynen <img> ile çizilir.
 */
export default function AuthImage({
  src,
  alt = '',
  className,
}: {
  src: string
  alt?: string
  className?: string
}) {
  const absolute = src.startsWith('http://') || src.startsWith('https://')
  const [objectUrl, setObjectUrl] = useState<string | null>(null)
  const [failed, setFailed] = useState(false)

  useEffect(() => {
    if (absolute) return
    let cancelled = false
    let created: string | null = null
    setObjectUrl(null)
    setFailed(false)
    ;(async () => {
      try {
        const token = await getAccessToken()
        const res = await fetch(`${API_URL}${src}`, {
          headers: token ? { Authorization: `Bearer ${token}` } : undefined,
        })
        if (!res.ok) throw new Error(String(res.status))
        const blob = await res.blob()
        if (cancelled) return
        created = URL.createObjectURL(blob)
        setObjectUrl(created)
      } catch {
        if (!cancelled) setFailed(true)
      }
    })()
    return () => {
      cancelled = true
      if (created) URL.revokeObjectURL(created)
    }
  }, [src, absolute])

  if (absolute) return <img src={src} alt={alt} className={className} />
  if (failed) return null
  if (!objectUrl)
    return <div className={`animate-pulse bg-slate-100 dark:bg-slate-700 ${className ?? ''}`} />
  return <img src={objectUrl} alt={alt} className={className} />
}
