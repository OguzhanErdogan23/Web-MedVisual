export default function Spinner({ size = 5, className = '' }: { size?: number; className?: string }) {
  return (
    <span
      className={`inline-block animate-spin rounded-full border-2 border-indigo-200 border-t-indigo-600 ${className}`}
      style={{ width: `${size * 4}px`, height: `${size * 4}px` }}
      role="status"
      aria-label="Yükleniyor"
    />
  )
}
