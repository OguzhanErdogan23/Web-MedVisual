import { supabase } from './supabase'

export const API_URL = (import.meta.env.VITE_API_URL as string) || 'http://localhost:8000'

export async function getAccessToken(): Promise<string | null> {
  const { data } = await supabase.auth.getSession()
  return data.session?.access_token ?? null
}

interface RequestOptions {
  body?: unknown
  /** FormData gönderimi için */
  formData?: FormData
  /** ms cinsinden zaman aşımı (varsayılan 30 sn) */
  timeoutMs?: number
}

async function request<T>(
  method: 'GET' | 'POST' | 'PATCH' | 'DELETE',
  path: string,
  options: RequestOptions = {},
): Promise<T> {
  const token = await getAccessToken()
  const headers: Record<string, string> = {}
  if (token) headers['Authorization'] = `Bearer ${token}`

  let body: BodyInit | undefined
  if (options.formData) {
    // FormData için Content-Type'ı tarayıcı belirler (boundary dahil)
    body = options.formData
  } else if (options.body !== undefined) {
    headers['Content-Type'] = 'application/json'
    body = JSON.stringify(options.body)
  }

  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), options.timeoutMs ?? 30_000)

  let res: Response
  try {
    res = await fetch(`${API_URL}${path}`, {
      method,
      headers,
      body,
      signal: controller.signal,
    })
  } catch (err) {
    if (err instanceof DOMException && err.name === 'AbortError') {
      throw new Error('İstek zaman aşımına uğradı. Sunucuya ulaşılamıyor olabilir.')
    }
    throw new Error('Sunucuya bağlanılamadı. API çalışıyor mu?')
  } finally {
    clearTimeout(timeout)
  }

  if (!res.ok) {
    let message = `İstek başarısız oldu (${res.status})`
    try {
      const data = await res.json()
      if (data?.detail !== undefined) {
        message =
          typeof data.detail === 'string' ? data.detail : JSON.stringify(data.detail)
      }
    } catch {
      // gövde JSON değilse varsayılan mesaj kalır
    }
    throw new Error(message)
  }

  if (res.status === 204) return undefined as T
  return (await res.json()) as T
}

/** Content-Disposition başlığından dosya adını ayıklar (varsa). */
function filenameFromDisposition(header: string | null): string | null {
  if (!header) return null
  // RFC 5987: filename*=UTF-8''...
  const star = /filename\*=(?:UTF-8'')?([^;]+)/i.exec(header)
  if (star?.[1]) {
    try {
      return decodeURIComponent(star[1].trim().replace(/^"|"$/g, ''))
    } catch {
      /* yoksay */
    }
  }
  const plain = /filename="?([^";]+)"?/i.exec(header)
  return plain?.[1]?.trim() ?? null
}

/**
 * Kimlik doğrulamalı GET ile ikili (binary) dosya indirir.
 * Blob'u ve Content-Disposition başlığından önerilen dosya adını döndürür.
 */
export async function getBlob(
  path: string,
  fallbackName: string,
  opts: { timeoutMs?: number } = {},
): Promise<{ blob: Blob; filename: string }> {
  const token = await getAccessToken()
  const headers: Record<string, string> = {}
  if (token) headers['Authorization'] = `Bearer ${token}`

  const controller = new AbortController()
  const timeout = setTimeout(() => controller.abort(), opts.timeoutMs ?? 120_000)

  let res: Response
  try {
    res = await fetch(`${API_URL}${path}`, {
      method: 'GET',
      headers,
      signal: controller.signal,
    })
  } catch (err) {
    if (err instanceof DOMException && err.name === 'AbortError') {
      throw new Error('İstek zaman aşımına uğradı. Sunucuya ulaşılamıyor olabilir.')
    }
    throw new Error('Sunucuya bağlanılamadı. API çalışıyor mu?')
  } finally {
    clearTimeout(timeout)
  }

  if (!res.ok) {
    let message = `İndirme başarısız oldu (${res.status})`
    try {
      const data = await res.json()
      if (data?.detail !== undefined) {
        message = typeof data.detail === 'string' ? data.detail : JSON.stringify(data.detail)
      }
    } catch {
      /* gövde JSON değilse varsayılan mesaj kalır */
    }
    throw new Error(message)
  }

  const blob = await res.blob()
  const filename =
    filenameFromDisposition(res.headers.get('Content-Disposition')) ?? fallbackName
  return { blob, filename }
}

/** Bir Blob'u geçici nesne URL'i ile tarayıcıda indirir. */
export function downloadBlob(blob: Blob, filename: string): void {
  const url = URL.createObjectURL(blob)
  const a = document.createElement('a')
  a.href = url
  a.download = filename
  document.body.appendChild(a)
  a.click()
  a.remove()
  URL.revokeObjectURL(url)
}

export const api = {
  get: <T>(path: string, opts?: RequestOptions) => request<T>('GET', path, opts),
  post: <T>(path: string, body?: unknown, opts?: RequestOptions) =>
    request<T>('POST', path, { ...opts, body }),
  postForm: <T>(path: string, formData: FormData, opts?: RequestOptions) =>
    request<T>('POST', path, { ...opts, formData }),
  patch: <T>(path: string, body?: unknown, opts?: RequestOptions) =>
    request<T>('PATCH', path, { ...opts, body }),
  delete: <T = void>(path: string, opts?: RequestOptions) =>
    request<T>('DELETE', path, opts),
}
