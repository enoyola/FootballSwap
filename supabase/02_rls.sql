-- StickerMatch — Row Level Security
-- Run after 01_schema.sql.
-- Privacy model: a user's raw album (user_stickers) is private. Only what they
-- deliberately publish in a post (posts + post_stickers) is visible to others.

-- ---------------------------------------------------------------------------
-- Enable RLS on every table
-- ---------------------------------------------------------------------------
alter table public.profiles      enable row level security;
alter table public.stickers      enable row level security;
alter table public.user_stickers enable row level security;
alter table public.posts         enable row level security;
alter table public.post_stickers enable row level security;

-- ---------------------------------------------------------------------------
-- profiles — owner only (no client delete)
-- ---------------------------------------------------------------------------
drop policy if exists "profiles_select_own" on public.profiles;
create policy "profiles_select_own" on public.profiles
  for select using (id = auth.uid());

drop policy if exists "profiles_insert_own" on public.profiles;
create policy "profiles_insert_own" on public.profiles
  for insert with check (id = auth.uid());

drop policy if exists "profiles_update_own" on public.profiles;
create policy "profiles_update_own" on public.profiles
  for update using (id = auth.uid()) with check (id = auth.uid());

-- ---------------------------------------------------------------------------
-- stickers — read-only catalog for any authenticated user
-- (writes happen via seed / service role only)
-- ---------------------------------------------------------------------------
drop policy if exists "stickers_select_all" on public.stickers;
create policy "stickers_select_all" on public.stickers
  for select to authenticated using (true);

-- ---------------------------------------------------------------------------
-- user_stickers — full CRUD, owner only
-- ---------------------------------------------------------------------------
drop policy if exists "user_stickers_select_own" on public.user_stickers;
create policy "user_stickers_select_own" on public.user_stickers
  for select using (user_id = auth.uid());

drop policy if exists "user_stickers_insert_own" on public.user_stickers;
create policy "user_stickers_insert_own" on public.user_stickers
  for insert with check (user_id = auth.uid());

drop policy if exists "user_stickers_update_own" on public.user_stickers;
create policy "user_stickers_update_own" on public.user_stickers
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "user_stickers_delete_own" on public.user_stickers;
create policy "user_stickers_delete_own" on public.user_stickers
  for delete using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- posts — public read (marketplace), owner-only writes
-- ---------------------------------------------------------------------------
drop policy if exists "posts_select_all" on public.posts;
create policy "posts_select_all" on public.posts
  for select to authenticated using (true);

drop policy if exists "posts_insert_own" on public.posts;
create policy "posts_insert_own" on public.posts
  for insert with check (user_id = auth.uid());

drop policy if exists "posts_update_own" on public.posts;
create policy "posts_update_own" on public.posts
  for update using (user_id = auth.uid()) with check (user_id = auth.uid());

drop policy if exists "posts_delete_own" on public.posts;
create policy "posts_delete_own" on public.posts
  for delete using (user_id = auth.uid());

-- ---------------------------------------------------------------------------
-- post_stickers — public read; writes only when parent post is owned by caller
-- ---------------------------------------------------------------------------
drop policy if exists "post_stickers_select_all" on public.post_stickers;
create policy "post_stickers_select_all" on public.post_stickers
  for select to authenticated using (true);

drop policy if exists "post_stickers_insert_own" on public.post_stickers;
create policy "post_stickers_insert_own" on public.post_stickers
  for insert with check (
    exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid())
  );

drop policy if exists "post_stickers_update_own" on public.post_stickers;
create policy "post_stickers_update_own" on public.post_stickers
  for update using (
    exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid())
  ) with check (
    exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid())
  );

drop policy if exists "post_stickers_delete_own" on public.post_stickers;
create policy "post_stickers_delete_own" on public.post_stickers
  for delete using (
    exists (select 1 from public.posts p where p.id = post_id and p.user_id = auth.uid())
  );
