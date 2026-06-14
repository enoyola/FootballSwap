-- StickerMatch — Production hardening (from Supabase security advisors)
-- Run after the other SQL files.

-- Trigger functions never need direct EXECUTE (they run in trigger context),
-- so they shouldn't be callable via the REST API.
revoke execute on function public.handle_new_user() from anon, authenticated, public;
revoke execute on function public.handle_new_message() from anon, authenticated, public;

-- The conversation RPC should only be callable by signed-in users.
revoke execute on function public.get_or_create_conversation(uuid) from anon, public;
grant  execute on function public.get_or_create_conversation(uuid) to authenticated;

-- NOTE: also enable "Leaked password protection" in the dashboard
-- (Authentication → Policies) — it can't be toggled from SQL.
