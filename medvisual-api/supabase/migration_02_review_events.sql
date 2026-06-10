-- ===========================================================================
-- MedVisual — Ek migration: calisma olay gecmisi (ilerleme grafikleri icin)
-- Calistirma: Supabase Dashboard -> SQL Editor -> bu dosyayi yapistir -> Run
-- (Ana migration.sql'den SONRA, bir kez calistirilir.)
-- ===========================================================================

create table if not exists public.review_events (
  id bigint generated always as identity primary key,
  user_id uuid not null references auth.users(id) on delete cascade,
  card_id uuid references public.flashcards(id) on delete set null,
  grade int not null,
  reviewed_at timestamptz not null default now()
);
create index if not exists idx_review_events_user_time
  on public.review_events(user_id, reviewed_at desc);

alter table public.review_events enable row level security;

drop policy if exists "own review events" on public.review_events;
create policy "own review events" on public.review_events
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);
