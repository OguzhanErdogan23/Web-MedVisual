import { useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { useTheme } from '../hooks/useTheme'
import { useToast } from '../hooks/useToast'
import { useProfile, useUpdateProfile } from '../hooks/useProfile'
import { supabase } from '../lib/supabase'
import Spinner from '../components/Spinner'
import ConfirmDialog from '../components/ConfirmDialog'

function Section({
  title,
  description,
  children,
}: {
  title: string
  description?: string
  children: React.ReactNode
}) {
  return (
    <section className="rounded-2xl border border-slate-200 bg-white p-6 shadow-sm dark:border-slate-700 dark:bg-slate-800">
      <h2 className="text-lg font-semibold text-slate-900 dark:text-slate-100">{title}</h2>
      {description && (
        <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">{description}</p>
      )}
      <div className="mt-5">{children}</div>
    </section>
  )
}

export default function Settings() {
  const navigate = useNavigate()
  const { session, signOut } = useAuth()
  const { theme, toggle } = useTheme()
  const { toast } = useToast()

  const profileQuery = useProfile()
  const updateProfile = useUpdateProfile()

  const [displayName, setDisplayName] = useState('')
  const [confirmSignOut, setConfirmSignOut] = useState(false)

  // Şifre değiştirme
  const [newPassword, setNewPassword] = useState('')
  const [repeatPassword, setRepeatPassword] = useState('')
  const [savingPassword, setSavingPassword] = useState(false)

  // Profil yüklendiğinde adı doldur
  useEffect(() => {
    if (profileQuery.data) {
      setDisplayName(profileQuery.data.display_name ?? '')
    }
  }, [profileQuery.data])

  const email = profileQuery.data?.email ?? session?.user.email ?? ''

  const handleSaveProfile = () => {
    updateProfile.mutate(
      { display_name: displayName.trim() },
      {
        onSuccess: () => toast('Adınız güncellendi.', 'success'),
        onError: (err: Error) => toast(err.message),
      },
    )
  }

  const handleSignOut = async () => {
    await signOut()
    navigate('/login')
  }

  const passwordTooShort = newPassword.length > 0 && newPassword.length < 6
  const passwordMismatch =
    repeatPassword.length > 0 && newPassword !== repeatPassword
  const canSavePassword =
    newPassword.length >= 6 && newPassword === repeatPassword && !savingPassword

  const handleChangePassword = async (e: React.FormEvent) => {
    e.preventDefault()
    if (!canSavePassword) return
    setSavingPassword(true)
    try {
      const { error } = await supabase.auth.updateUser({ password: newPassword })
      if (error) {
        toast(error.message)
        return
      }
      toast('Şifre güncellendi.', 'success')
      setNewPassword('')
      setRepeatPassword('')
    } catch (err) {
      toast((err as Error).message ?? 'Şifre güncellenemedi.')
    } finally {
      setSavingPassword(false)
    }
  }

  const inputClass =
    'w-full rounded-lg border border-slate-300 px-3 py-2 text-sm focus:border-indigo-500 focus:outline-none disabled:bg-slate-50 disabled:text-slate-500 dark:border-slate-600 dark:bg-slate-900 dark:text-slate-100 dark:disabled:bg-slate-800'

  return (
    <div className="mx-auto max-w-2xl space-y-6">
      <div>
        <h1 className="text-2xl font-semibold tracking-tight text-slate-900 dark:text-slate-100">
          Ayarlar
        </h1>
        <p className="mt-1 text-sm text-slate-500 dark:text-slate-400">
          Profil, görünüm ve hesap ayarlarınızı buradan yönetin.
        </p>
      </div>

      {/* Profil */}
      <Section title="Profil" description="Hesabınızın temel bilgileri.">
        {profileQuery.isLoading ? (
          <div className="flex justify-center py-6">
            <Spinner size={6} />
          </div>
        ) : (
          <div className="space-y-4">
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                E-posta
              </label>
              <input type="email" value={email} disabled className={inputClass} />
            </div>
            <div>
              <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
                Görünen ad
              </label>
              <input
                type="text"
                value={displayName}
                onChange={(e) => setDisplayName(e.target.value)}
                placeholder="Adınızı girin"
                className={inputClass}
              />
            </div>
            <div className="flex justify-end">
              <button
                onClick={handleSaveProfile}
                disabled={updateProfile.isPending}
                className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
              >
                {updateProfile.isPending && (
                  <Spinner size={4} className="border-indigo-300 border-t-white" />
                )}
                Kaydet
              </button>
            </div>
          </div>
        )}
      </Section>

      {/* Görünüm */}
      <Section title="Görünüm" description="Uygulamanın temasını ayarlayın.">
        <div className="flex items-center justify-between">
          <div>
            <p className="text-sm font-medium text-slate-800 dark:text-slate-200">
              Karanlık tema
            </p>
            <p className="text-xs text-slate-500 dark:text-slate-400">
              {theme === 'dark' ? 'Şu an koyu görünüm açık.' : 'Şu an açık görünüm etkin.'}
            </p>
          </div>
          <button
            type="button"
            role="switch"
            aria-checked={theme === 'dark'}
            aria-label="Karanlık tema"
            onClick={toggle}
            className={`relative inline-flex h-6 w-11 shrink-0 items-center rounded-full transition-colors ${
              theme === 'dark' ? 'bg-indigo-600' : 'bg-slate-300'
            }`}
          >
            <span
              className={`inline-block h-5 w-5 transform rounded-full bg-white shadow transition-transform ${
                theme === 'dark' ? 'translate-x-5' : 'translate-x-0.5'
              }`}
            />
          </button>
        </div>
      </Section>

      {/* Hesap / Güvenlik */}
      <Section title="Hesap ve Güvenlik" description="Şifrenizi değiştirin veya oturumu kapatın.">
        <form onSubmit={handleChangePassword} className="space-y-4">
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
              Yeni şifre
            </label>
            <input
              type="password"
              value={newPassword}
              onChange={(e) => setNewPassword(e.target.value)}
              autoComplete="new-password"
              placeholder="En az 6 karakter"
              className={inputClass}
            />
            {passwordTooShort && (
              <p className="mt-1 text-xs text-red-600 dark:text-red-400">
                Şifre en az 6 karakter olmalıdır.
              </p>
            )}
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-slate-700 dark:text-slate-300">
              Yeni şifre (tekrar)
            </label>
            <input
              type="password"
              value={repeatPassword}
              onChange={(e) => setRepeatPassword(e.target.value)}
              autoComplete="new-password"
              className={inputClass}
            />
            {passwordMismatch && (
              <p className="mt-1 text-xs text-red-600 dark:text-red-400">
                Şifreler eşleşmiyor.
              </p>
            )}
          </div>
          <div className="flex justify-end">
            <button
              type="submit"
              disabled={!canSavePassword}
              className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50"
            >
              {savingPassword && (
                <Spinner size={4} className="border-indigo-300 border-t-white" />
              )}
              Şifre Değiştir
            </button>
          </div>
        </form>

        <div className="mt-6 border-t border-slate-100 pt-5 dark:border-slate-700">
          <div className="flex items-center justify-between">
            <div>
              <p className="text-sm font-medium text-slate-800 dark:text-slate-200">Oturum</p>
              <p className="text-xs text-slate-500 dark:text-slate-400">
                Bu cihazda oturumu kapatın.
              </p>
            </div>
            <button
              onClick={() => setConfirmSignOut(true)}
              className="rounded-lg border border-slate-300 px-4 py-2 text-sm font-medium text-slate-700 hover:border-red-200 hover:bg-red-50 hover:text-red-700 dark:border-slate-600 dark:text-slate-200 dark:hover:border-red-900 dark:hover:bg-red-950/40 dark:hover:text-red-400"
            >
              Çıkış Yap
            </button>
          </div>
        </div>
      </Section>

      <ConfirmDialog
        open={confirmSignOut}
        title="Çıkış yap"
        message="Oturumunuz kapatılacak. Devam edilsin mi?"
        confirmLabel="Çıkış Yap"
        onConfirm={handleSignOut}
        onCancel={() => setConfirmSignOut(false)}
      />
    </div>
  )
}
