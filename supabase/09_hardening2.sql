-- StickerMatch — 09_hardening2.sql
-- Pre-launch API + UGC hardening (after a source-level security review).
-- Applied via MCP migration `api_ugc_hardening`; this file mirrors it.
--
-- What it does:
--   * Server-side post expiration (clients no longer trusted to hide expired posts).
--   * post_stickers readable only when its parent post is visible to the caller.
--   * Block-aware message select/insert + get_or_create_conversation.
--   * Length + coordinate-range CHECK constraints (anti-bloat / bad input).
--   * Sign-up safe: handle_new_user truncates the auto nickname.
--   * Lightweight UGC moderation: an admin-curated denylist + reject-on-match
--     triggers on the public surfaces (posts/messages/reports). The denylist
--     CONTENT is operational data populated by an admin (kept out of source);
--     populate `public.banned_terms(term)` with words to block.

-- 1) Posts: owner sees own (incl. expired); others see only active + non-blocked.
drop policy if exists "posts_select_all" on public.posts;
create policy "posts_select_all" on public.posts
  for select to authenticated using (
    user_id = auth.uid()
    or (
      expires_at > now()
      and not exists (
        select 1 from public.blocks b
        where (b.blocker_id = auth.uid() and b.blocked_id = posts.user_id)
           or (b.blocker_id = posts.user_id and b.blocked_id = auth.uid())
      )
    )
  );

-- 2) post_stickers readable only when its parent post is visible to the caller.
drop policy if exists "post_stickers_select_all" on public.post_stickers;
drop policy if exists "post_stickers_select_visible" on public.post_stickers;
create policy "post_stickers_select_visible" on public.post_stickers
  for select to authenticated using (
    exists (
      select 1 from public.posts p
      where p.id = post_stickers.post_id
        and (
          p.user_id = auth.uid()
          or (p.expires_at > now() and not exists (
            select 1 from public.blocks b
            where (b.blocker_id = auth.uid() and b.blocked_id = p.user_id)
               or (b.blocker_id = p.user_id and b.blocked_id = auth.uid())
          ))
        )
    )
  );

-- 3) Block-aware message select + insert (explicit defense-in-depth).
drop policy if exists "messages_select_participant" on public.messages;
create policy "messages_select_participant" on public.messages
  for select using (
    exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.user_a = auth.uid() or c.user_b = auth.uid())
        and not exists (
          select 1 from public.blocks b
          where (b.blocker_id = auth.uid() and (b.blocked_id = c.user_a or b.blocked_id = c.user_b))
             or (b.blocked_id = auth.uid() and (b.blocker_id = c.user_a or b.blocker_id = c.user_b))
        )
    )
  );

drop policy if exists "messages_insert_participant" on public.messages;
create policy "messages_insert_participant" on public.messages
  for insert with check (
    sender_id = auth.uid()
    and exists (
      select 1 from public.conversations c
      where c.id = messages.conversation_id
        and (c.user_a = auth.uid() or c.user_b = auth.uid())
        and not exists (
          select 1 from public.blocks b
          where (b.blocker_id = auth.uid() and (b.blocked_id = c.user_a or b.blocked_id = c.user_b))
             or (b.blocked_id = auth.uid() and (b.blocker_id = c.user_a or b.blocker_id = c.user_b))
        )
    )
  );

-- 4) get_or_create_conversation rejects blocked pairs.
create or replace function public.get_or_create_conversation(other_user uuid)
returns uuid language plpgsql security definer set search_path = public as $$
declare me uuid := auth.uid(); a uuid; b uuid; conv_id uuid;
begin
  if me is null then raise exception 'Not authenticated'; end if;
  if other_user is null or other_user = me then raise exception 'Invalid other user'; end if;
  if not exists (select 1 from public.profiles where id = other_user) then
    raise exception 'User not found';
  end if;
  if exists (
    select 1 from public.blocks b
    where (b.blocker_id = me and b.blocked_id = other_user)
       or (b.blocker_id = other_user and b.blocked_id = me)
  ) then raise exception 'Unavailable'; end if;
  a := least(me, other_user); b := greatest(me, other_user);
  select id into conv_id from public.conversations where user_a = a and user_b = b;
  if conv_id is not null then return conv_id; end if;
  insert into public.conversations (user_a, user_b, nickname_a, nickname_b)
  values (a, b,
    coalesce((select nickname from public.profiles where id = a), ''),
    coalesce((select nickname from public.profiles where id = b), ''))
  returning id into conv_id;
  return conv_id;
end; $$;
revoke all on function public.get_or_create_conversation(uuid) from public, anon;
grant execute on function public.get_or_create_conversation(uuid) to authenticated;

-- 5) Sign-up never blocked: truncate the auto-created nickname to fit constraints.
create or replace function public.handle_new_user()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  insert into public.profiles (id, nickname)
  values (new.id, left(coalesce(new.raw_user_meta_data ->> 'full_name',
                               new.raw_user_meta_data ->> 'name', ''), 60))
  on conflict (id) do nothing;
  return new;
end; $$;
revoke all on function public.handle_new_user() from public, anon, authenticated;

-- 6) Length + coordinate-range constraints (generous; existing data passes).
alter table public.profiles
  add constraint profiles_nickname_len  check (char_length(coalesce(nickname,''))       <= 60),
  add constraint profiles_city_len      check (char_length(coalesce(city,''))           <= 140),
  add constraint profiles_meeting_len   check (char_length(coalesce(meeting_point,''))  <= 200),
  add constraint profiles_contact_len   check (char_length(coalesce(contact_method,'')) <= 200),
  add constraint profiles_country_len   check (char_length(coalesce(country,''))        <= 8);

alter table public.posts
  add constraint posts_nickname_len  check (char_length(nickname)       <= 60),
  add constraint posts_city_len      check (char_length(city)           <= 140),
  add constraint posts_meeting_len   check (char_length(meeting_point)  <= 200),
  add constraint posts_time_len      check (char_length(meeting_time)   <= 80),
  add constraint posts_price_len     check (char_length(price_note)     <= 300),
  add constraint posts_contact_len   check (char_length(contact_method) <= 200),
  add constraint posts_country_len   check (char_length(country)        <= 8),
  add constraint posts_lat_range     check (latitude is null  or latitude  between -90  and 90),
  add constraint posts_lon_range     check (longitude is null or longitude between -180 and 180);

alter table public.reports
  add constraint reports_note_len    check (char_length(coalesce(note,'')) <= 500);

-- 7) Lightweight UGC moderation. The mechanism lives here; the denylist content
--    is operational data — populate public.banned_terms(term) via an admin.
create table if not exists public.banned_terms ( term text primary key );
alter table public.banned_terms enable row level security;
drop policy if exists "banned_terms_no_client_access" on public.banned_terms;
create policy "banned_terms_no_client_access" on public.banned_terms
  for all to authenticated, anon using (false) with check (false); -- admin/service-role only

create or replace function public.contains_banned_term(txt text)
returns boolean language plpgsql stable security definer set search_path = public as $$
declare t text;
begin
  if txt is null or txt = '' then return false; end if;
  for t in select term from public.banned_terms loop
    if txt ~* ('\m' || regexp_replace(t, '([.^$*+?()\[\]{}|\\])', '\\\1', 'g') || '\M') then
      return true;
    end if;
  end loop;
  return false;
end; $$;

create or replace function public.moderate_text()
returns trigger language plpgsql security definer set search_path = public as $$
begin
  if TG_TABLE_NAME = 'posts' then
    if public.contains_banned_term(new.nickname) or public.contains_banned_term(new.city)
       or public.contains_banned_term(new.meeting_point) or public.contains_banned_term(new.meeting_time)
       or public.contains_banned_term(new.price_note) then
      raise exception 'Content not allowed';
    end if;
  elsif TG_TABLE_NAME = 'messages' then
    if public.contains_banned_term(new.body) then raise exception 'Content not allowed'; end if;
  elsif TG_TABLE_NAME = 'reports' then
    if public.contains_banned_term(new.note) then raise exception 'Content not allowed'; end if;
  end if;
  return new;
end; $$;

revoke all on function public.contains_banned_term(text) from public, anon, authenticated;
revoke all on function public.moderate_text() from public, anon, authenticated;

drop trigger if exists moderate_posts on public.posts;
create trigger moderate_posts before insert or update on public.posts
  for each row execute function public.moderate_text();
drop trigger if exists moderate_messages on public.messages;
create trigger moderate_messages before insert or update on public.messages
  for each row execute function public.moderate_text();
drop trigger if exists moderate_reports on public.reports;
create trigger moderate_reports before insert or update on public.reports
  for each row execute function public.moderate_text();
