# StickerMatch — Progress

_Last updated: 2026-06-16_

Native iOS (Swift/SwiftUI/MVVM) sticker-album + trading app on Supabase. Built end-to-end this
session from two prompt specs. **Feature-complete MVP**; remaining work is App Store gating.

**Repo:** now under git and pushed to GitHub (public) at `enoyola/FootballSwap`.
**Naming:** user-facing app name is **FootballSwap** (display name, login title, disclaimer,
location prompt); the Xcode project/target, source folder, and bundle id (`com.stickermatch.app`)
stay **StickerMatch** internally — build/deploy commands and OAuth redirects unchanged.

## Backend (Supabase project `hyfrnjtbcnlrwkwwjpbx`)

SQL files applied via MCP migrations and mirrored in `supabase/`:

| File | Contents |
|------|----------|
| `01_schema.sql` | enums (`sticker_status`, `post_sticker_kind`) + tables + indexes |
| `02_rls.sql` | base RLS (owner-only album/profile; public-read marketplace) |
| `03_seed.sql` / `stickers_seed.csv` | **504** catalog stickers (42 teams × 11 real players + a text "Team Crest"/"Escudo"; our own numbering, confederation as category) |
| `04_triggers.sql` | `handle_new_user` → auto-create profile on sign-up |
| `05_messaging.sql` | `conversations`, `messages`, `get_or_create_conversation` RPC, last-message trigger, realtime publication |
| `06_location.sql` | `posts.latitude/longitude/country` |
| `07_safety.sql` | `blocks`, `reports`, `report_reason` enum; **block-aware** posts/conversations select policies |
| `08_hardening.sql` | revoke API EXECUTE on SECURITY DEFINER functions |
| `09_hardening2.sql` | pre-launch hardening: server-side post expiration, block-aware messaging, length/coord CHECK constraints, UGC moderation denylist + reject triggers |
| `10_push.sql` | `device_tokens` registry + register/unregister RPCs + on-message trigger (pg_net → `notify-message`) |
| `functions/delete-account/` | edge function: service-role account deletion (FK cascade wipes data) |
| `functions/notify-message/` | edge function: signs an APNs JWT and pushes new-message alerts to the recipient's devices |

**Tables:** `profiles`, `stickers`, `user_stickers`, `posts`, `post_stickers`, `conversations`,
`messages`, `blocks`, `reports`. RLS on all. Realtime enabled on `messages`.
**Security advisors:** clean (no missing-RLS); the few SECURITY DEFINER warnings resolved in `08`.
**Auth = OAuth-only** (Apple + Google); the **Email/password provider is disabled** in the
dashboard, so leaked-password protection is **N/A** (no passwords exist).

## iOS app

XcodeGen (`project.yml`); `Info.plist`, `*.entitlements`, `PrivacyInfo.xcprivacy`, `Assets.xcassets`
(AppIcon + AppLogo + AccentColor). `ResilientAuthStorage` makes auth work in unsigned sim builds.

| Area | Status | Notes |
|------|--------|-------|
| Auth | ✅ Google / ⚠️ Apple | Google OAuth working; Apple button scaffolded (needs paid program) |
| Album | ✅ | Browse-by-team, flags, progress hero + rings, global search, **copies counter** (0/1/2+) |
| Marketplace | ✅ | **Near-me** distance sort + radius (50/100/250/All), country fallback, My posts (edit/swipe-delete), Message button, excludes own |
| Matches | ✅ | Score-ranked ∩, distance-limited, Message button |
| Messages | ✅ | Realtime 1:1 chat (RealtimeV2); **APNs push on new message** (tap deep-links to the chat) + unread tab badge; nicknames snapshotted |
| Safety | ✅ | Block (RLS hides both ways) + Report (reason+note) from post/match/chat; Blocked-users mgmt |
| Profile | ✅ | Nickname, **country picker** (all ISO), **city** (MapKit autocomplete), meeting point, **real account deletion** |
| Location | ✅ | CoreLocation when-in-use; flags via flagcdn |
| Theming | ✅ | **Adaptive light/dark**; one brand green (accent + hero top); hero gradient green→**icon blue**; soccerball empty states; app icon + login logo |

## Verified
Builds succeed; Google sign-in → profile created; album CRUD persists; matching verified via SQL;
messaging realtime confirmed in auth logs/MCP; distance sort/fallback; block RLS; delete-account
edge fn returns 401 unauthorized. See `TESTING.md`.

## Current data state
1 real user (Eduardo Noyola, Santa Ana SV), **504** stickers. Demo traders (Carla/Diego/Lucía/Marco)
+ 4 posts + a sample chat seeded near El Salvador for testing Market/Intercambio + matches.

## Pending — App Store gates (mostly external, awaiting Apple Developer enrollment)
- Sign in with Apple (functional + configured) — required since Google login is offered.
- Real code signing + device/TestFlight build. (App icon ✅ done.)
- Privacy Policy URL + App Store privacy disclosures + UGC terms/EULA at sign-up.
- Publish/verify Google OAuth consent screen (currently "testing" mode).
- Age rating (17+) + legal review of player-name usage.

## Push notifications — ✅ live (verified 2026-06-17)
Backend (`10_push.sql` + `notify-message`) and the iOS client (registration, deep-link, unread
badge) are live. **APNs delivery confirmed end-to-end** on a sandbox device build (HTTP 200,
`sent:1`). APNs Auth Key `Y5P6SZD85G` (unrestricted env — a prior production-only key failed sandbox
with `BadEnvironmentKeyInToken`). Edge secrets (`APNS_*`, `PUSH_FUNCTION_SECRET`) are set; the
function **auto-falls back** between sandbox/production hosts and prunes only on `410 Unregistered`.
**For TestFlight/App Store:** flip the `aps-environment` entitlement + `APNS_ENV` to `production`.

## Not built (intentional MVP scope)
Group chats, attachments, read receipts, maps view, server-side geo,
Android client (architecture noted in README).
