import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query'
import { api } from '../lib/api'
import type { Profile } from '../types'

/** Oturum açan kullanıcının profil bilgileri. */
export function useProfile() {
  return useQuery({
    queryKey: ['profile'],
    queryFn: () => api.get<Profile>('/profile'),
    staleTime: 60_000,
  })
}

/** Görünen adı (display_name) günceller ve profil sorgusunu tazeler. */
export function useUpdateProfile() {
  const queryClient = useQueryClient()
  return useMutation({
    mutationFn: (body: { display_name: string }) =>
      api.patch<Profile>('/profile', body),
    onSuccess: () => {
      queryClient.invalidateQueries({ queryKey: ['profile'] })
    },
  })
}
