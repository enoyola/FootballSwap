-- StickerMatch — Safety: blocking + reporting
-- Run after 05_messaging.sql. Required for user-to-user messaging / UGC:
-- users can block abusers (hides posts + conversations both ways) and report
-- content for moderation. Blocking is enforced in RLS so neither side leaks.

do $$ begin
  create type report_reason as enum ('spam', 'harassment', 'scam', 'other');
exception when duplicate_object then null; end $$;

create table if not exists public.blocks (
  id uuid primary key default gen_random_uuid(),
  blocker_id uuid not null references public.profiles (id) on delete cascade,
  blocked_id uuid not null references public.profiles (id) on delete cascade,
  blocked_nickname text not null default '',  -- snapshot, so the block list needs no profile read
  created_at timestamptz not null default now(),
  unique (blocker_id, blocked_id),
  check (blocker_id <> blocked_id)
);
create index if not exists idx_blocks_blocker on public.blocks (blocker_id);
create index if not exists idx_blocks_blocked on public.blocks (blocked_id);

create table if not exists public.reports (
  id uuid primary key default gen_random_uuid(),
  reporter_id uuid not null references public.profiles (id) on delete cascade,
  reported_user_id uuid not null references public.profiles (id) on delete cascade,
  post_id uuid references public.posts (id) on delete set null,
  reason report_reason not null,
  note text not null default '',
  created_at timestamptz not null default now()
);
create index if not exists idx_reports_reported on public.reports (reported_user_id);

alter table public.blocks  enable row level security;
alter table public.reports enable row level security;

-- You manage and see only your own blocks (never learn who blocked you).
drop policy if exists "blocks_select_own" on public.blocks;
create policy "blocks_select_own" on public.blocks
  for select using (blocker_id = auth.uid());
drop policy if exists "blocks_insert_own" on public.blocks;
create policy "blocks_insert_own" on public.blocks
  for insert with check (blocker_id = auth.uid());
drop policy if exists "blocks_delete_own" on public.blocks;
create policy "blocks_delete_own" on public.blocks
  for delete using (blocker_id = auth.uid());

-- Reports: insert + read your own.
drop policy if exists "reports_insert_own" on public.reports;
create policy "reports_insert_own" on public.reports
  for insert with check (reporter_id = auth.uid());
drop policy if exists "reports_select_own" on public.reports;
create policy "reports_select_own" on public.reports
  for select using (reporter_id = auth.uid());

-- Posts are invisible between blocked users (either direction).
drop policy if exists "posts_select_all" on public.posts;
create policy "posts_select_all" on public.posts
  for select to authenticated using (
    not exists (
      select 1 from public.blocks b
      where (b.blocker_id = auth.uid() and b.blocked_id = posts.user_id)
         or (b.blocker_id = posts.user_id and b.blocked_id = auth.uid())
    )
  );

-- Conversations with a blocked user are hidden (either direction).
drop policy if exists "conversations_select_participant" on public.conversations;
create policy "conversations_select_participant" on public.conversations
  for select using (
    (auth.uid() = user_a or auth.uid() = user_b)
    and not exists (
      select 1 from public.blocks b
      where (b.blocker_id = auth.uid() and (b.blocked_id = user_a or b.blocked_id = user_b))
         or (b.blocked_id = auth.uid() and (b.blocker_id = user_a or b.blocker_id = user_b))
    )
  );
