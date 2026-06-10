import { useRef, useState } from 'react'
import { useMutation, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import { useToast } from '../hooks/useToast'
import Spinner from './Spinner'
import type { DocumentRow } from '../types'

export default function UploadDropzone() {
  const inputRef = useRef<HTMLInputElement>(null)
  const [dragOver, setDragOver] = useState(false)
  const queryClient = useQueryClient()
  const { toast } = useToast()

  const upload = useMutation({
    mutationFn: async (file: File) => {
      const fd = new FormData()
      fd.append('file', file)
      return api.postForm<DocumentRow>('/documents', fd, { timeoutMs: 120_000 })
    },
    onSuccess: (doc) => {
      toast(`"${doc.filename}" yüklendi, işleniyor...`, 'success')
      queryClient.invalidateQueries({ queryKey: ['documents'] })
    },
    onError: (err: Error) => toast(err.message),
  })

  const handleFiles = (files: FileList | null) => {
    if (!files || files.length === 0) return
    const file = files[0]
    if (!file.name.toLowerCase().endsWith('.pdf')) {
      toast('Lütfen bir PDF dosyası seçin.')
      return
    }
    upload.mutate(file)
  }

  return (
    <div
      onDragOver={(e) => {
        e.preventDefault()
        setDragOver(true)
      }}
      onDragLeave={() => setDragOver(false)}
      onDrop={(e) => {
        e.preventDefault()
        setDragOver(false)
        handleFiles(e.dataTransfer.files)
      }}
      onClick={() => inputRef.current?.click()}
      className={`flex cursor-pointer flex-col items-center justify-center rounded-2xl border-2 border-dashed px-6 py-10 text-center transition-colors ${
        dragOver
          ? 'border-indigo-400 bg-indigo-50'
          : 'border-slate-300 bg-white hover:border-indigo-300 hover:bg-indigo-50/40'
      }`}
    >
      <input
        ref={inputRef}
        type="file"
        accept="application/pdf,.pdf"
        className="hidden"
        onChange={(e) => {
          handleFiles(e.target.files)
          e.target.value = ''
        }}
      />
      {upload.isPending ? (
        <div className="flex flex-col items-center gap-3">
          <Spinner size={7} />
          <p className="text-sm font-medium text-slate-600">PDF yükleniyor...</p>
        </div>
      ) : (
        <>
          <div className="mb-2 text-3xl">📎</div>
          <p className="text-sm font-semibold text-slate-700">
            PDF dosyanızı buraya sürükleyin veya tıklayıp seçin
          </p>
          <p className="mt-1 text-xs text-slate-500">
            Ders notu, kitap bölümü veya makale — motor işledikten sonra kart ve quiz üretebilirsiniz.
          </p>
        </>
      )}
    </div>
  )
}
