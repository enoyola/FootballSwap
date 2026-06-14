# CLAUDE.md — StickerMatch project guide

StickerMatch is a native **iOS** (Swift/SwiftUI/MVVM) fan utility for completing a physical
football sticker album, backed by **Supabase**. This file is the working guide for the repo.

**Naming:** the **user-facing app name is "FootballSwap"** (display name, login title, safety
disclaimer, location prompt). The Xcode project/target, scheme, source folder, `@main` struct
(`StickerMatchApp`), and bundle id (`com.stickermatch.app` + `stickermatch://` scheme) all stay
**StickerMatch** — so build/deploy commands and OAuth redirects are unchanged. The repo lives on
GitHub (public) at **`enoyola/FootballSwap`**.

## Hard product constraints (do not violate)
- **Not an official app.** No FIFA / Panini / World Cup logos, player images, sticker artwork,
  or reproduction of an official album's numbering/compilation.
- **Plain text only** for sticker data. Real **player/country names are allowed** (facts); what
  to avoid is copying an official (e.g. Panini) checklist's full number↔player table. Our catalog
  uses real players with **our own sequential numbering** (`supabase/03_seed.sql`).
- No payments. No public personal contact — users connect via **in-app chat**.
- Always keep the safety disclaimer (`SafetyDisclaimerView`).

## Architecture & conventions
- **MVVM.** One `@MainActor` `ObservableObject` view model per screen, exposing `isLoading` /
  `errorMessage` and typed data (pattern: `AlbumViewModel`).
- **Services** wrap `SupabaseService.shared.client` (e.g. `AlbumService`, `PostService`,
  `MatchService`, `MessagingService`, `SafetyService`, `LocationService`, `AuthService`,
  `ProfileService`). Errors mapped via `AppError.from(_:)`.
- Shared UI in `Views/Components/` (`LoadingView`, `EmptyStateView`, `ErrorBanner`,
  `SafetyDisclaimerView`, `StatusBadge`, `ProgressRing`, `FlagView`, `CountryCatalog`,
  `DistanceRadius`, `PitchBackground`).
- **Pass UUID filters as `.uuidString`** to PostgREST (`.eq("id", value: x.uuidString)`).
- SDK is **supabase-swift v2.47** (Swift 5 language mode). **Before using an unfamiliar SDK API,
  verify it against the checked-out source** under `build/SourcePackages/checkouts/supabase-swift/`
  (we did this for Auth, RealtimeV2, and Functions).
- Secrets: `Config/Secrets.xcconfig` (gitignored) → Info.plist → `AppConfig`. `SUPABASE_HOST` is
  the host only (no scheme — xcconfig treats `//` as a comment). `AppConfig` `fatalError`s if missing.

## Theming
- **Adaptive light/dark** — follows the system (no forced color scheme).
- One **brand green** = the `AccentColor` asset, wired via
  `ASSETCATALOG_COMPILER_GLOBAL_ACCENT_COLOR_NAME` in `project.yml`. Used for tabs, links, rings.
- Neutral canvas: `PitchBackground` = `Color(.systemGroupedBackground)` (adaptive) applied with
  `.scrollContentBackground(.hidden)` on Lists/Forms so it shows behind white/dark cards.
- Album hero gradient = **accent green → app-icon blue** (`sRGB 0, 0.47, 0.96`); keep these in sync
  if the accent changes.
- App icon (`Assets.xcassets/AppIcon`, 1024 full-bleed, no alpha) and the login `AppLogo` share the
  same art. Flags via `FlagView` (flagcdn). Empty states use the `soccerball` SF Symbol.

## Project generation (XcodeGen)
- `project.yml` is the source of truth; **`StickerMatch.xcodeproj` is gitignored**. After adding/
  removing files run `xcodegen generate`. Sources are folder-globbed (excludes: Info.plist,
  *.entitlements, Secrets*.xcconfig).

## Build / run (this environment)
- Simulator build (unsigned, fastest): 
  `xcodebuild -project StickerMatch.xcodeproj -scheme StickerMatch -destination 'id=D903545D-2169-466B-98FF-2865FFC4030E' -derivedDataPath build CODE_SIGNING_ALLOWED=NO build`
  (that device id is the iPhone 17 simulator; `xcrun simctl list devices available` to pick another).
- Deploy: `xcrun simctl install booted <App>` then `xcrun simctl launch booted com.stickermatch.app`.
- **You cannot tap the simulator** (osascript→System Events is blocked: "Not authorized"). The user
  navigates tabs; verify the data side via the Supabase MCP. Screenshots: `xcrun simctl io booted screenshot`.

## Backend (Supabase)
- Project ref **`hyfrnjtbcnlrwkwwjpbx`**, reachable via the **Supabase MCP** (apply_migration,
  execute_sql, get_advisors, deploy_edge_function, get_logs, …).
- SQL lives in `supabase/01..08_*.sql` + `functions/delete-account/`. **Apply via MCP migrations
  AND mirror the same SQL into the repo file.** RLS is enabled on every table; blocking is enforced
  in `posts`/`conversations` select policies. Run `get_advisors(security)` after DDL.

## Key gotchas
- **Unsigned sim builds have no entitlements** → Keychain + Sign in with Apple fail. Hence
  `ResilientAuthStorage` (Keychain with a UserDefaults fallback) so OAuth/session work unsigned.
- **Emoji flags don't render in the Simulator** → `FlagView` loads flag images from flagcdn.com.
- **`simctl` location grant is flaky** → reset permission (`simctl privacy ... reset location`),
  let the in-app prompt grant it, and `simctl location ... set <lat>,<lon>`.
- Album status is a **copies counter**: 0 = missing, 1 = have, 2+ = repeated (status derived).

## Status
Feature-complete MVP; remaining work is App Store gating (Apple Developer enrollment pending —
Sign in with Apple, signing/device build, privacy policy, metadata). See `PROGRESS.md`.
