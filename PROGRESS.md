# StickerMatch — Progress

_Last updated: 2026-06-14_

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
| `03_seed.sql` / `stickers_seed.csv` | **442** catalog stickers (real WC players, our own numbering, confederation as category) |
| `04_triggers.sql` | `handle_new_user` → auto-create profile on sign-up |
| `05_messaging.sql` | `conversations`, `messages`, `get_or_create_conversation` RPC, last-message trigger, realtime publication |
| `06_location.sql` | `posts.latitude/longitude/country` |
| `07_safety.sql` | `blocks`, `reports`, `report_reason` enum; **block-aware** posts/conversations select policies |
| `08_hardening.sql` | revoke API EXECUTE on SECURITY DEFINER functions |
| `functions/delete-account/` | edge function: service-role account deletion (FK cascade wipes data) |

**Tables:** `profiles`, `stickers`, `user_stickers`, `posts`, `post_stickers`, `conversations`,
`messages`, `blocks`, `reports`. RLS on all. Realtime enabled on `messages`.
**Security advisors:** clean (no missing-RLS); the few SECURITY DEFINER warnings resolved in `08`.
Leaked-password protection = **dashboard toggle still pending**.

## iOS app

XcodeGen (`project.yml`); `Info.plist`, `*.entitlements`, `PrivacyInfo.xcprivacy`, `Assets.xcassets`
(AppIcon + AppLogo + AccentColor). `ResilientAuthStorage` makes auth work in unsigned sim builds.

| Area | Status | Notes |
|------|--------|-------|
| Auth | ✅ Google / ⚠️ Apple | Google OAuth working; Apple button scaffolded (needs paid program) |
| Album | ✅ | Browse-by-team, flags, progress hero + rings, global search, **copies counter** (0/1/2+) |
| Marketplace | ✅ | **Near-me** distance sort + radius (50/100/250/All), country fallback, My posts (edit/swipe-delete), Message button, excludes own |
| Matches | ✅ | Score-ranked ∩, distance-limited, Message button |
| Messages | ✅ | Realtime 1:1 chat (RealtimeV2); nicknames snapshotted (profiles stay private) |
| Safety | ✅ | Block (RLS hides both ways) + Report (reason+note) from post/match/chat; Blocked-users mgmt |
| Profile | ✅ | Nickname, **country picker** (all ISO), **city** (MapKit autocomplete), meeting point, **real account deletion** |
| Location | ✅ | CoreLocation when-in-use; flags via flagcdn |
| Theming | ✅ | **Adaptive light/dark**; one brand green (accent + hero top); hero gradient green→**icon blue**; soccerball empty states; app icon + login logo |

## Verified
Builds succeed; Google sign-in → profile created; album CRUD persists; matching verified via SQL;
messaging realtime confirmed in auth logs/MCP; distance sort/fallback; block RLS; delete-account
edge fn returns 401 unauthorized. See `TESTING.md`.

## Current data state
1 real user (eduar10nc), 442 stickers, 0 posts/conversations (test traders Marco/Sofia removed).

## Pending — App Store gates (mostly external, awaiting Apple Developer enrollment)
- Sign in with Apple (functional + configured) — required since Google login is offered.
- Real code signing + device/TestFlight build. (App icon ✅ done.)
- Privacy Policy URL + App Store privacy disclosures + UGC terms/EULA at sign-up.
- Publish/verify Google OAuth consent screen (currently "testing" mode).
- Age rating (17+) + legal review of player-name usage.

## Not built (intentional MVP scope)
Group chats, attachments, read receipts, push notifications, maps view, server-side geo,
Android client (architecture noted in README).
