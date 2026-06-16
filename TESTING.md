# StickerMatch — Testing & Verification

_Last updated: 2026-06-14_

A focused **XCTest suite** (`Tests/`, target `StickerMatchTests` — **13 tests**) covers the pure logic:
`MatchService.computeMatches` (overlap/score/ranking), the copies→status mapping, album search, and
distance radii. Run it with:
`xcodebuild -project StickerMatch.xcodeproj -scheme StickerMatch -destination 'id=<sim>' -derivedDataPath build CODE_SIGNING_ALLOWED=NO test`.
The rest of verification is **manual**: simulator runs + screenshots, Supabase MCP SQL/log
inspection, and HTTP checks. This doc records what was verified and the gotchas to know.

## Commands

```bash
# Build for the iPhone 17 simulator (unsigned — fastest in this env)
xcodebuild -project StickerMatch.xcodeproj -scheme StickerMatch \
  -destination 'id=D903545D-2169-466B-98FF-2865FFC4030E' \
  -derivedDataPath build CODE_SIGNING_ALLOWED=NO build

# Deploy + run
xcrun simctl install booted build/Build/Products/Debug-iphonesimulator/StickerMatch.app
xcrun simctl launch booted com.stickermatch.app
xcrun simctl io booted screenshot /tmp/shot.png

# Location testing
xcrun simctl privacy booted reset location com.stickermatch.app
xcrun simctl location booted set 13.9942,-89.5597     # e.g. Santa Ana, SV

# Theme (app follows the system; toggle to test both)
xcrun simctl ui booted appearance dark    # or: light
```
Backend checks use the Supabase MCP (`execute_sql`, `get_advisors`, `get_logs`).

## Verified
- **Build**: `BUILD SUCCEEDED` against real `supabase-swift` v2.47 (Auth, PostgREST, RealtimeV2,
  Functions APIs all compile).
- **Auth**: Google OAuth → `/token` 200, `user_signedup`+`login` in auth logs, `profiles` row
  auto-created (nickname from Google name).
- **Album**: status edits persist (copies counter); 504 stickers load grouped by team.
- **Matches**: intersection + score verified via SQL to equal the app's `MatchService` output.
- **Messaging**: realtime insert delivered; last-message trigger updates conversation preview.
- **Location**: distance sort + radius cutoff + country fallback exercised by setting sim GPS and
  seeding posts at known coords.
- **Safety**: blocking hides posts/conversations (RLS); `reports` insert; `delete-account` edge
  function returns **401** without a JWT.
- **Security advisors**: no missing-RLS errors; SECURITY DEFINER warnings fixed in `08_hardening.sql`.
- **Theme**: adaptive light/dark verified by toggling `simctl ui appearance` (both render correctly).

## Gotchas (important)
- **Cannot tap the Simulator programmatically** — `osascript`→System Events is "Not authorized."
  The user must navigate tabs; verify state via MCP/DB. (This is why several checks are DB-side.)
- **Unsigned sim builds have no entitlements** → Keychain and Sign in with Apple fail. PKCE/session
  break unless storage falls back off-Keychain → handled by `ResilientAuthStorage`.
- **Emoji flags don't render in the Simulator** → use `FlagView` (flagcdn images).
- **`simctl` location grant is unreliable** → reset + let the in-app prompt grant, then `location set`.
- **Distance is from device GPS, not profile city.** The profile city/country is the no-location fallback.
- Catalog count is **504** (not the original 30 sample).
- **App-name split:** the on-device display name is **FootballSwap**, but the scheme, product
  (`StickerMatch.app`), and bundle id (`com.stickermatch.app`) are still StickerMatch — the build/
  deploy commands above are unchanged. The FootballSwap display name **and** the login buttons
  (native black Apple + compliant Google "G" card) are **confirmed on a rebuilt sim app**.

## Suggested next tests (not yet done)
- Real-device pass for Sign in with Apple, location prompt, and Keychain (signed build).
- Account-deletion happy path with a throwaway account (cascade wipe).
- UI tests for the core flows (album status changes, posting, matching).
