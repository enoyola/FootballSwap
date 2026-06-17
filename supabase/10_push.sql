-- StickerMatch — 10_push.sql
-- Push notifications for new chat messages.
-- Applied via MCP migration `push_notifications`; this file mirrors the DDL.
--
-- Flow: a new row in `messages` fires `notify_new_message`, which (via pg_net)
-- POSTs to the `notify-message` Edge Function. That function looks up the
-- recipient's APNs device tokens and sends the push.
--
-- OPERATIONAL CONFIG (NOT in source — set once via the dashboard / SQL):
--   * Vault secrets `push_function_url` and `push_function_secret`
--       select vault.create_secret('https://<ref>.supabase.co/functions/v1/notify-message', 'push_function_url');
--       select vault.create_secret('<random>', 'push_function_secret');
--   * Edge Function secrets: PUSH_FUNCTION_SECRET (== the vault secret),
--     APNS_KEY_ID, APNS_TEAM_ID, APNS_BUNDLE_ID, APNS_PRIVATE_KEY, APNS_ENV.

-- pg_net powers the async HTTP call below. (Optional advisor cleanup: it can be
-- relocated out of `public` with `alter extension pg_net set schema extensions;`
-- — its API stays in the `net` schema either way.)
create extension if not exists pg_net;

-- 1) Device token registry (one row per APNs device token).
create table if not exists public.device_tokens (
  token      text primary key,
  user_id    uuid not null references auth.users (id) on delete cascade,
  platform   text not null default 'ios',
  updated_at timestamptz not null default now(),
  constraint device_tokens_platform_chk check (platform in ('ios')),
  constraint device_tokens_token_len   check (char_length(token) between 32 and 400)
);
create index if not exists idx_device_tokens_user on public.device_tokens (user_id);

alter table public.device_tokens enable row level security;
-- Clients may only read/delete their OWN tokens; writes go through the RPC.
drop policy if exists device_tokens_select_own on public.device_tokens;
create policy device_tokens_select_own on public.device_tokens
  for select to authenticated using (user_id = auth.uid());
drop policy if exists device_tokens_delete_own on public.device_tokens;
create policy device_tokens_delete_own on public.device_tokens
  for delete to authenticated using (user_id = auth.uid());

-- 2) Register/unregister RPCs (SECURITY DEFINER so a device that switches
--    accounts re-points its token to the new owner via ON CONFLICT).
create or replace function public.register_device_token(p_token text, p_platform text default 'ios')
returns void language plpgsql security definer set search_path = public as $$
begin
  if auth.uid() is null then raise exception 'Not authenticated'; end if;
  if p_token is null or char_length(p_token) not between 32 and 400 then
    raise exception 'Invalid token';
  end if;
  insert into public.device_tokens (token, user_id, platform, updated_at)
  values (p_token, auth.uid(), 'ios', now())
  on conflict (token) do update
    set user_id = excluded.user_id, updated_at = now();
end; $$;
revoke all on function public.register_device_token(text, text) from public, anon;
grant execute on function public.register_device_token(text, text) to authenticated;

create or replace function public.unregister_device_token(p_token text)
returns void language plpgsql security definer set search_path = public as $$
begin
  delete from public.device_tokens where token = p_token and user_id = auth.uid();
end; $$;
revoke all on function public.unregister_device_token(text) from public, anon;
grant execute on function public.unregister_device_token(text) to authenticated;

-- 3) On new message, fire the push Edge Function (async, non-blocking).
--    URL + shared secret live in Vault (operational config, not in source).
create or replace function public.notify_new_message()
returns trigger language plpgsql security definer set search_path = public as $$
declare
  fn_url    text;
  fn_secret text;
begin
  select decrypted_secret into fn_url    from vault.decrypted_secrets where name = 'push_function_url';
  select decrypted_secret into fn_secret from vault.decrypted_secrets where name = 'push_function_secret';
  if fn_url is null then return new; end if; -- not configured yet: no-op
  perform net.http_post(
    url     := fn_url,
    headers := jsonb_build_object('Content-Type', 'application/json',
                                  'x-push-secret', coalesce(fn_secret, '')),
    body    := jsonb_build_object('conversation_id', new.conversation_id,
                                  'sender_id',       new.sender_id,
                                  'body',            new.body)
  );
  return new;
end; $$;
revoke all on function public.notify_new_message() from public, anon, authenticated;

drop trigger if exists on_message_push on public.messages;
create trigger on_message_push after insert on public.messages
  for each row execute function public.notify_new_message();
