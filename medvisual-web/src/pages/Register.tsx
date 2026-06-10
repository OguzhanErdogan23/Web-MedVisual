import { useState } from 'react'
import type { FormEvent } from 'react'
import { Link, useNavigate } from 'react-router-dom'
import { supabase } from '../lib/supabase'
import Spinner from '../components/Spinner'

export default function Register() {
  const navigate = useNavigate()
  const [email, setEmail] = useState('')
  const [password, setPassword] = useState('')
  const [error, setError] = useState<string | null>(null)
  const [info, setInfo] = useState<string | null>(null)
  const [loading, setLoading] = useState(false)

  const handleSubmit = async (e: FormEvent) => {
    e.preventDefault()
    setError(null)
    setInfo(null)
    if (password.length < 6) {
      setError('Şifre en az 6 karakter olmalıdır.')
      return
    }
    setLoading(true)
    const { data, error: err } = await supabase.auth.signUp({ email, password })
    setLoading(false)
    if (err) {
      setError(err.message)
      return
    }
    if (data.session) {
      // E-posta onayı kapalıysa oturum hemen açılır
      navigate('/')
    } else {
      setInfo(
        'Kayıt başarılı! E-posta adresinize bir onay bağlantısı gönderildi. Onayladıktan sonra giriş yapabilirsiniz.',
      )
    }
  }

  return (
    <div className="flex min-h-screen items-center justify-center bg-slate-50 p-4">
      <div className="w-full max-w-md">
        <div className="mb-8 text-center">
          <div className="mb-3 inline-flex h-12 w-12 items-center justify-center rounded-xl bg-indigo-600 text-xl font-bold text-white">
            M
          </div>
          <h1 className="text-2xl font-semibold tracking-tight text-slate-900">
            Med<span className="text-indigo-600">Visual</span>
          </h1>
          <p className="mt-1 text-sm text-slate-500">Ücretsiz hesap oluşturun.</p>
        </div>
        <div className="rounded-2xl border border-slate-200 bg-white p-8 shadow-sm">
          <h2 className="mb-6 text-lg font-semibold text-slate-900">Kayıt Ol</h2>
          {error && (
            <div className="mb-4 rounded-lg border border-red-200 bg-red-50 px-4 py-3 text-sm text-red-700">
              {error}
            </div>
          )}
          {info && (
            <div className="mb-4 rounded-lg border border-teal-200 bg-teal-50 px-4 py-3 text-sm text-teal-700">
              {info}
            </div>
          )}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div>
              <label htmlFor="email" className="mb-1 block text-sm font-medium text-slate-700">
                E-posta
              </label>
              <input
                id="email"
                type="email"
                required
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-100"
                placeholder="ornek@universite.edu.tr"
              />
            </div>
            <div>
              <label htmlFor="password" className="mb-1 block text-sm font-medium text-slate-700">
                Şifre
              </label>
              <input
                id="password"
                type="password"
                required
                minLength={6}
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                className="w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none focus:ring-2 focus:ring-indigo-100"
                placeholder="En az 6 karakter"
              />
            </div>
            <button
              type="submit"
              disabled={loading}
              className="flex w-full items-center justify-center gap-2 rounded-lg bg-indigo-600 px-4 py-2.5 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
            >
              {loading && <Spinner size={4} className="border-indigo-300 border-t-white" />}
              Kayıt Ol
            </button>
          </form>
          <p className="mt-4 text-xs text-slate-400">
            Not: E-posta onayı kapalıysa kayıt sonrası doğrudan giriş yapılır.
          </p>
          <p className="mt-4 text-center text-sm text-slate-500">
            Zaten hesabınız var mı?{' '}
            <Link to="/login" className="font-medium text-indigo-600 hover:underline">
              Giriş yapın
            </Link>
          </p>
        </div>
      </div>
    </div>
  )
}
