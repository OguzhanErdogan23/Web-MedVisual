import { useQuery } from '@tanstack/react-query'
import { api } from '../lib/api'
import type { TermsResponse } from '../types'

/** Latince terim listesi (otomatik tamamlama için). Nadiren değişir. */
export function useTerms() {
  return useQuery({
    queryKey: ['terms'],
    queryFn: () => api.get<TermsResponse>('/terms'),
    staleTime: Infinity,
  })
}
