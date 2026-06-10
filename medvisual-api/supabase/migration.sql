-- ===========================================================================
-- MedVisual — Supabase semasi (Single Source of Truth)
-- Calistirma: Supabase Dashboard -> SQL Editor -> bu dosyayi yapistir -> Run
-- ===========================================================================

-- ---------------------------------------------------------------------------
-- Profiller (auth.users'a 1:1; kayit olunca trigger ile otomatik olusur)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  created_at timestamptz not null default now()
);

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer set search_path = public
as $$
begin
  insert into public.profiles (id, display_name)
  values (
    new.id,
    coalesce(new.raw_user_meta_data->>'display_name', split_part(new.email, '@', 1))
  )
  on conflict (id) do nothing;
  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();

-- ---------------------------------------------------------------------------
-- Dokumanlar (PDF'in kendisi DIP motorunun lokal work/ dizininde kalir;
-- burada yalnizca metadata + dip_doc_id tutulur — ucretsiz kota disiplini)
-- ---------------------------------------------------------------------------
create table if not exists public.documents (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  dip_doc_id text,
  filename text not null,
  page_count int,
  has_text boolean,
  status text not null default 'processing'
    check (status in ('processing','ready','failed','expired')),
  error text,
  created_at timestamptz not null default now()
);
create index if not exists idx_documents_user on public.documents(user_id);

-- ---------------------------------------------------------------------------
-- Kart desteleri (status: kart uretimi arka planda calisirken 'generating')
-- ---------------------------------------------------------------------------
create table if not exists public.flashcard_sets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  document_id uuid references public.documents(id) on delete set null,
  title text not null,
  description text,
  status text not null default 'ready'
    check (status in ('generating','ready','failed')),
  error text,
  created_at timestamptz not null default now()
);
create index if not exists idx_sets_user on public.flashcard_sets(user_id);

-- ---------------------------------------------------------------------------
-- Bilgi kartlari (image_url: Storage'daki SECILMIS gorsel; adaylar kalici degil)
-- ---------------------------------------------------------------------------
create table if not exists public.flashcards (
  id uuid primary key default gen_random_uuid(),
  set_id uuid not null references public.flashcard_sets(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  front text not null,
  back text not null,
  term text,
  kind text,
  page int,
  image_url text,
  position int not null default 0,
  created_at timestamptz not null default now()
);
create index if not exists idx_flashcards_set on public.flashcards(set_id);
create index if not exists idx_flashcards_user on public.flashcards(user_id);

-- ---------------------------------------------------------------------------
-- Quizler ve sorulari
-- ---------------------------------------------------------------------------
create table if not exists public.quizzes (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users(id) on delete cascade,
  document_id uuid references public.documents(id) on delete set null,
  title text,
  status text not null default 'ready'
    check (status in ('generating','ready','failed')),
  error text,
  created_at timestamptz not null default now()
);
create index if not exists idx_quizzes_user on public.quizzes(user_id);

create table if not exists public.quiz_questions (
  id uuid primary key default gen_random_uuid(),
  quiz_id uuid not null references public.quizzes(id) on delete cascade,
  question text not null,
  options jsonb not null,
  answer_index int not null,
  position int not null default 0
);
create index if not exists idx_questions_quiz on public.quiz_questions(quiz_id);

-- ---------------------------------------------------------------------------
-- SM-2 aralikli tekrar durumu (kart basina tek satir; otorite: API)
-- ---------------------------------------------------------------------------
create table if not exists public.card_reviews (
  card_id uuid primary key references public.flashcards(id) on delete cascade,
  user_id uuid not null references auth.users(id) on delete cascade,
  ease_factor real not null default 2.5,
  interval_days real not null default 0,
  repetitions int not null default 0,
  due_at timestamptz not null default now(),
  last_grade int,
  updated_at timestamptz not null default now()
);
create index if not exists idx_reviews_user_due on public.card_reviews(user_id, due_at);

-- ---------------------------------------------------------------------------
-- RLS: kullanici yalnizca kendi satirlarini gorur/degistirir.
-- (Backend service_role ile calisip RLS'i bypass eder ve sahipligi user_id
-- filtresiyle zorlar; RLS dogrudan istemci erisimine karsi savunma katmanidir.)
-- ---------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.documents enable row level security;
alter table public.flashcard_sets enable row level security;
alter table public.flashcards enable row level security;
alter table public.quizzes enable row level security;
alter table public.quiz_questions enable row level security;
alter table public.card_reviews enable row level security;

drop policy if exists "own profile" on public.profiles;
create policy "own profile" on public.profiles
  for all using (auth.uid() = id) with check (auth.uid() = id);

drop policy if exists "own documents" on public.documents;
create policy "own documents" on public.documents
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own sets" on public.flashcard_sets;
create policy "own sets" on public.flashcard_sets
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own cards" on public.flashcards;
create policy "own cards" on public.flashcards
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own quizzes" on public.quizzes;
create policy "own quizzes" on public.quizzes
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

drop policy if exists "own quiz questions" on public.quiz_questions;
create policy "own quiz questions" on public.quiz_questions
  for all using (
    exists (
      select 1 from public.quizzes q
      where q.id = quiz_id and q.user_id = auth.uid()
    )
  );

drop policy if exists "own reviews" on public.card_reviews;
create policy "own reviews" on public.card_reviews
  for all using (auth.uid() = user_id) with check (auth.uid() = user_id);

-- ---------------------------------------------------------------------------
-- Storage: secilen kart gorselleri icin public-read bucket
-- ---------------------------------------------------------------------------
insert into storage.buckets (id, name, public)
values ('card-images', 'card-images', true)
on conflict (id) do nothing;
