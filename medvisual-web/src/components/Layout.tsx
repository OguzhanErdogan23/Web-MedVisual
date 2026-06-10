import { useEffect, useState } from 'react'
import { NavLink, Outlet, useNavigate } from 'react-router-dom'
import { useAuth } from '../hooks/useAuth'
import { useTheme } from '../hooks/useTheme'
import { useProfile } from '../hooks/useProfile'
import OnboardingTour, { isTourDone } from './OnboardingTour'

const navItems = [
  { to: '/', label: 'Panel', icon: '📊', end: true },
  { to: '/sets', label: 'Kart Desteleri', icon: '🗂️' },
  { to: '/quizzes', label: 'Quizler', icon: '❓' },
  { to: '/study', label: 'Çalış', icon: '🎓' },
]

export default function Layout() {
  const { session, signOut } = useAuth()
  const { theme, toggle } = useTheme()
  const profileQuery = useProfile()
  const navigate = useNavigate()
  const [tourOpen, setTourOpen] = useState(false)

  // İlk ziyarette turu otomatik göster
  useEffect(() => {
    if (!isTourDone()) setTourOpen(true)
  }, [])

  const handleSignOut = async () => {
    await signOut()
    navigate('/login')
  }

  return (
    <div className="flex min-h-screen">
      {/* Sol menü */}
      <aside className="fixed inset-y-0 left-0 z-40 flex w-60 flex-col border-r border-slate-200 bg-white dark:border-slate-700 dark:bg-slate-800">
        <div className="flex h-16 items-center gap-2 border-b border-slate-100 px-5 dark:border-slate-700">
          <span className="flex h-8 w-8 items-center justify-center rounded-lg bg-indigo-600 text-sm font-bold text-white">
            M
          </span>
          <span className="text-lg font-semibold tracking-tight text-slate-900 dark:text-slate-100">
            Med<span className="text-indigo-600 dark:text-indigo-400">Visual</span>
          </span>
        </div>
        <nav className="flex-1 space-y-1 p-3">
          {navItems.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                `flex items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-colors ${
                  isActive
                    ? 'bg-indigo-50 text-indigo-700 dark:bg-indigo-950/60 dark:text-indigo-300'
                    : 'text-slate-600 hover:bg-slate-50 hover:text-slate-900 dark:text-slate-300 dark:hover:bg-slate-700/60 dark:hover:text-white'
                }`
              }
            >
              <span className="text-base">{item.icon}</span>
              {item.label}
            </NavLink>
          ))}
        </nav>
        <div className="border-t border-slate-100 p-4 text-xs text-slate-400 dark:border-slate-700 dark:text-slate-500">
          Tıp eğitimi için görsel destekli tekrar
        </div>
      </aside>

      {/* İçerik */}
      <div className="ml-60 flex min-h-screen flex-1 flex-col">
        <header className="sticky top-0 z-30 flex h-16 items-center justify-end gap-3 border-b border-slate-200 bg-white/80 px-6 backdrop-blur dark:border-slate-700 dark:bg-slate-800/80">
          <button
            onClick={() => setTourOpen(true)}
            className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
            title="Tanıtım turunu yeniden başlat"
          >
            ? Tur
          </button>
          <button
            onClick={toggle}
            className="rounded-lg border border-slate-300 px-2.5 py-1.5 text-sm text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
            title={theme === 'dark' ? 'Aydınlık moda geç' : 'Karanlık moda geç'}
            aria-label="Tema değiştir"
          >
            {theme === 'dark' ? '☀️' : '🌙'}
          </button>
          <button
            onClick={() => navigate('/ayarlar')}
            className="rounded-lg border border-slate-300 px-2.5 py-1.5 text-sm text-slate-600 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-300 dark:hover:bg-slate-700"
            title="Ayarlar"
            aria-label="Ayarlar"
          >
            ⚙️
          </button>
          <span className="text-sm text-slate-500 dark:text-slate-400">
            {profileQuery.data?.display_name?.trim() || session?.user.email}
          </span>
          <button
            onClick={handleSignOut}
            className="rounded-lg border border-slate-300 px-3 py-1.5 text-sm font-medium text-slate-700 hover:bg-slate-50 dark:border-slate-600 dark:text-slate-200 dark:hover:bg-slate-700"
          >
            Çıkış
          </button>
        </header>
        <main className="flex-1 p-6 lg:p-8">
          <Outlet />
        </main>
      </div>

      <OnboardingTour open={tourOpen} onClose={() => setTourOpen(false)} />
    </div>
  )
}
