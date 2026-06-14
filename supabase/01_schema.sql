-- StickerMatch — Database schema
-- Run this first in the Supabase SQL editor (or `supabase db push`).
-- Postgres on Supabase already provides gen_random_uuid() and the auth schema.

-- ---------------------------------------------------------------------------
-- Enums
-- ---------------------------------------------------------------------------
do $$ begin
  create type sticker_status as enum ('missing', 'have', 'repeated');
exception
  when duplicate_object then null;
end $$;

do $$ begin
  create type post_sticker_kind as enum ('repeated', 'missing');
exception
  when duplicate_object then null;
end $$;

-- ---------------------------------------------------------------------------
-- profiles  (one row per auth user)
-- ---------------------------------------------------------------------------
create table if not exists public.profiles (
  id            uuid primary key references auth.users (id) on delete cascade,
  nickname      text,
  city          text,
  country       text,
  meeting_point text,
  contact_method text,
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- stickers  (global, shared album catalog — read-only to clients)
-- ---------------------------------------------------------------------------
create table if not exists public.stickers (
  id          uuid primary key default gen_random_uuid(),
  number      text not null unique,
  player_name text not null,
  team_text   text not null default '',
  category    text not null default '',
  created_at  timestamptz not null default now()
);

-- ---------------------------------------------------------------------------
-- user_stickers  (per-user status for each catalog sticker — PRIVATE)
-- ---------------------------------------------------------------------------
create table if not exists public.user_stickers (
  id           uuid primary key default gen_random_uuid(),
  user_id      uuid not null references public.profiles (id) on delete cascade,
  sticker_id   uuid not null references public.stickers (id) on delete cascade,
  status       sticker_status not null default 'missing',
  repeated_qty int not null default 0 check (repeated_qty >= 0),
  updated_at   timestamptz not null default now(),
  unique (user_id, sticker_id)
);

-- ---------------------------------------------------------------------------
-- posts  (published marketplace listing; expires after 7 days)
-- nickname / city / contact_method are snapshotted so reading other users'
-- profiles is never required.
-- ---------------------------------------------------------------------------
create table if not exists public.posts (
  id             uuid primary key default gen_random_uuid(),
  user_id        uuid not null references public.profiles (id) on delete cascade,
  nickname       text not null default '',
  city           text not null default '',
  country        text not null default '',
  latitude       double precision,
  longitude      double precision,
  meeting_point  text not null default '',
  meeting_time   text not null default '',
  price_note     text not null default '',
  contact_method text not null default '',
  created_at     timestamptz not null default now(),
  expires_at     timestamptz not null default (now() + interval '7 days')
);

-- ---------------------------------------------------------------------------
-- post_stickers  (the repeated/missing lines attached to a post)
-- sticker_number / player_name denormalized for display & matching.
-- ---------------------------------------------------------------------------
create table if not exists public.post_stickers (
  id             uuid primary key default gen_random_uuid(),
  post_id        uuid not null references public.posts (id) on delete cascade,
  sticker_id     uuid not null references public.stickers (id) on delete cascade,
  kind           post_sticker_kind not null,
  sticker_number text not null,
  player_name    text not null default ''
);

-- ---------------------------------------------------------------------------
-- Indexes
-- ---------------------------------------------------------------------------
create index if not exists idx_user_stickers_user      on public.user_stickers (user_id);
create index if not exists idx_user_stickers_status     on public.user_stickers (user_id, status);
create index if not exists idx_posts_expires_at         on public.posts (expires_at);
create index if not exists idx_posts_city               on public.posts (city);
create index if not exists idx_post_stickers_post       on public.post_stickers (post_id);
create index if not exists idx_post_stickers_kind       on public.post_stickers (sticker_id, kind);
