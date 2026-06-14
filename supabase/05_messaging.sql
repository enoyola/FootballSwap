-- StickerMatch — In-app messaging (conversations + messages)
-- Run after 01_schema.sql. Replaces sharing a public contact method: users
-- connect through in-app chat instead. Privacy: a user's profile stays private;
-- nicknames are snapshotted onto the conversation so partners can be shown
-- without reading each other's profiles.

create table if not exists public.conversations (
  id uuid primary key default gen_random_uuid(),
  user_a uuid not null references public.profiles (id) on delete cascade,
  user_b uuid not null references public.profiles (id) on delete cascade,
  nickname_a text not null default '',
  nickname_b text not null default '',
  created_at timestamptz not null default now(),
  last_message_at timestamptz not null default now(),
  last_message_preview text not null default '',
  constraint conversations_user_order check (user_a < user_b),
  unique (user_a, user_b)
);

create table if not exists public.messages (
  id uuid primary key default gen_random_uuid(),
  conversation_id uuid not null references public.conversations (id) on delete cascade,
  sender_id uuid not null references public.profiles (id) on delete cascade,
  body text not null check (char_length(body) between 1 and 2000),
  created_at timestamptz not null default now()
);

create index if not exists idx_messages_conversation on public.messages (conversation_id, created_at);
create index if not exists idx_conversations_user_a on public.conversations (user_a);
create index if not exists idx_conversations_user_b on public.conversations (user_b);

-- Only way to create a conversation: normalizes the pair and snapshots nicknames.
create or replace function public.get_or_create_conversation(other_user uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  me uuid := auth.uid();
  a uuid;
  b uuid;
  conv_id uuid;
begin
  if me is null then raise exception 'Not authenticated'; end if;
  if other_user is null or other_user = me then raise exception 'Invalid other user'; end if;
  if not exists (select 1 from public.profiles where id = other_user) then
    raise exception 'User not found';
  end if;

  a := least(me, other_user);
  b := greatest(me, other_user);

  select id into conv_id from public.conversations where user_a = a and user_b = b;
  if conv_id is not null then
    return conv_id;
  end if;

  insert into public.conversations (user_a, user_b, nickname_a, nickname_b)
  values (
    a, b,
    coalesce((select nickname from public.profiles where id = a), ''),
    coalesce((select nickname from public.profiles where id = b), '')
  )
  returning id into conv_id;
  return conv_id;
end;
$$;

grant execute on function public.get_or_create_conversation(uuid) to authenticated;

-- Keep the conversation's last-message summary fresh for the inbox.
create or replace function public.handle_new_message()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  update public.conversations
  set last_message_at = new.created_at,
      last_message_preview = left(new.body, 120)
  where id = new.conversation_id;
  return new;
end;
$$;

drop trigger if exists on_message_created on public.messages;
create trigger on_message_created
  after insert on public.messages
  for each row execute function public.handle_new_message();

-- ---------------------------------------------------------------------------
-- RLS: you only see conversations/messages you're a participant in.
-- Conversations are created via the RPC and updated via the trigger (both
-- security definer), so clients get no direct insert/update/delete.
-- ---------------------------------------------------------------------------
alter table public.conversations enable row level security;
alter table public.messages enable row level security;

drop policy if exists "conversations_select_participant" on public.conversations;
create policy "conversations_select_participant" on public.conversations
  for select using (auth.uid() = user_a or auth.uid() = user_b);

drop policy if exists "messages_select_participant" on public.messages;
create policy "messages_select_participant" on public.messages
  for select using (
    exists (select 1 from public.conversations c
            where c.id = conversation_id and (c.user_a = auth.uid() or c.user_b = auth.uid()))
  );

drop policy if exists "messages_insert_participant" on public.messages;
create policy "messages_insert_participant" on public.messages
  for insert with check (
    sender_id = auth.uid()
    and exists (select 1 from public.conversations c
                where c.id = conversation_id and (c.user_a = auth.uid() or c.user_b = auth.uid()))
  );

-- Realtime for messages (idempotent).
do $$ begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'messages'
  ) then
    alter publication supabase_realtime add table public.messages;
  end if;
end $$;
