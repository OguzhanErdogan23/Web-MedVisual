// MedVisual API varlık tipleri

export type DocumentStatus = 'processing' | 'ready' | 'failed' | 'expired'
export type GenStatus = 'generating' | 'ready' | 'failed'

export interface DocumentRow {
  id: string
  dip_doc_id: string | null
  filename: string
  page_count: number | null
  has_text: boolean | null
  status: DocumentStatus
  error: string | null
  created_at: string
}

export interface DocumentsResponse {
  documents: DocumentRow[]
}

export interface Book {
  name: string
  display: string
  size_mb: number
  pages: number
}

export interface BooksResponse {
  books: Book[]
}

export interface CardRow {
  id: string
  front: string
  back: string
  term: string | null
  kind: string | null
  page: number | null
  image_url: string | null
  position: number
}

export interface SetRow {
  id: string
  title: string
  description: string | null
  status: GenStatus
  error: string | null
  document_id: string | null
  card_count: number
  created_at: string
}

export interface SetDetail extends SetRow {
  cards: CardRow[]
}

export interface SetsResponse {
  sets: SetRow[]
}

export interface QuizQuestion {
  question: string
  options: string[]
  answer_index: number
  position: number
}

export interface QuizRow {
  id: string
  title: string
  status: GenStatus
  error: string | null
  document_id: string | null
  question_count: number
  created_at: string
}

export interface QuizDetail extends QuizRow {
  questions: QuizQuestion[]
}

export interface QuizzesResponse {
  quizzes: QuizRow[]
}

export interface MatchCandidate {
  label: string
  page: number
  distance: number
  dip_doc_id: string
  path: string
  url: string
}

export interface MatchResponse {
  term: string
  matched: boolean
  similarity: number
  best_page: number | null
  candidates: MatchCandidate[]
}

export interface ReviewRow {
  id: string
  card_id: string
  grade: number
  due_at: string
  interval_days: number
}

export interface StudyCard extends CardRow {
  review?: ReviewRow | null
  set_id?: string
}

export interface DueResponse {
  cards: StudyCard[]
  total_due: number
  new_count: number
}

export interface StudyStats {
  documents: number
  sets: number
  cards: number
  quizzes: number
  due_now: number
  studied_cards: number
}

export interface HealthResponse {
  api: string
  dip_engine: { status: string; detail?: string }
  supabase_configured: boolean
}
