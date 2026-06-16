# FootballSwap — App Store submission pack

Reference for the App Store Connect listing + review. Not hosted; repo doc only.
Replace `support@footballswap.app` with a real address you control before submitting.

## URLs (after enabling GitHub Pages on `main` → `/docs`)
- **Privacy Policy:** `https://enoyola.github.io/FootballSwap/privacy.html`
- **Terms of Use (EULA):** `https://enoyola.github.io/FootballSwap/terms.html`
- **Support / Marketing URL:** `https://enoyola.github.io/FootballSwap/`

> In App Store Connect, set the **Privacy Policy URL** and a **Support URL**. If you use a custom
> EULA, paste the Terms URL in the app's **License Agreement** field (otherwise Apple's standard EULA
> applies — but the custom one above carries the user-content clauses).

## Listing copy

- **Name:** FootballSwap
- **Subtitle (≤30 chars):** `Trade football stickers nearby`
- **Promotional text (≤170):**
  `Mark what you have and need, publish your list, and find collectors near you to swap with. Track your album to 100%.`

- **Keywords (≤100 chars, comma-separated, no spaces):**
  `stickers,album,football,soccer,collector,swap,trade,collection,sticker album,trading,nearby`

- **Category:** Primary **Sports**, Secondary **Utilities**

- **Description:**
```
FootballSwap helps you finish your physical football sticker album faster.

Track every sticker as missing, have, or repeated, see your album fill up by team, then connect
with collectors near you to trade the ones you need.

• My Album — mark stickers by team and watch your progress to 100%
• Market — browse trade posts from people near you, filtered by distance
• Swap — smart matches: see exactly who has what you need and needs what you have
• Messages — arrange trades through private in-app chat (no phone number needed)
• Safety first — block and report tools, and a reminder to meet only in public places

FootballSwap is a fan-made utility. It is not affiliated with, endorsed by, or sponsored by FIFA,
Panini, or any league, federation, or club. It contains no official logos, crests, or images —
just plain-text player and country names and public national flags.

No payments are processed in the app. Trades happen directly between users; always meet in public.
```

## Age rating (App Store Connect questionnaire → 17+)
- Unrestricted web access: **No**
- User-generated content / users can communicate: **Yes** (posts + chat) → triggers the UGC questions
- Confirm you provide content filtering, reporting, and blocking: **Yes** (the app has report + block)
- Result target: **17+**

## App Privacy ("nutrition label")
Declare these data types (all **linked to the user's identity**, **not** used for tracking):

| Data type | Collected? | Purpose | Linked to user |
|---|---|---|---|
| Email address | Yes (from Apple/Google sign-in) | App functionality (account) | Yes |
| Name / nickname | Yes | App functionality | Yes |
| Coarse location | Yes (only if permission granted) | App functionality (nearby trades) | Yes |
| User content (posts) | Yes | App functionality | Yes |
| Messages | Yes | App functionality | Yes |
| User ID | Yes | App functionality | Yes |

- **Used for tracking:** No
- **Used for third-party advertising:** No

## Review notes (paste into "App Review Information")
```
FootballSwap is a fan utility for tracking a physical football sticker album and arranging
in-person trades. It is NOT an official app and contains no FIFA/Panini logos, crests, or images —
only plain-text real player/country names (factual references) and public-domain national flags.

Sign-in: Sign in with Apple and Google are both supported.
Demo account for review: <ADD a demo Apple ID / or a pre-seeded test account + how to use it>.

User-generated content safety: users can Report posts/users and Block users (Profile and on each
post/match/chat). Reports are reviewed and acted on within 24 hours. A Terms of Use (EULA) requiring
users not to post objectionable content is presented at sign-in.

No payments are processed. Trades are coordinated via in-app chat; the app shows a safety disclaimer
to meet only in public places.
```

## Screenshots needed (per required display sizes)
Capture on device or simulator (Spanish or English):
- Album (progress hero + teams), Market (a few posts), Swap (matches), a chat, Profile.
- Required sizes: **6.9"/6.7"** (e.g., iPhone 16 Pro Max) and **6.5"** (older Plus/Max). 5.5" no longer required.

## Pre-submission checklist
- [ ] Replace contact email everywhere with a real address.
- [ ] Enable GitHub Pages (Settings → Pages → main / `docs`) and confirm the two URLs load.
- [ ] Verify Sign in with Apple works on a device end-to-end.
- [ ] Publish the Google OAuth consent screen (out of "Testing").
- [ ] App Store Connect: create app record, confirm "FootballSwap" name is available.
- [ ] Add screenshots + the copy above + Privacy/Support URLs + App Privacy answers + 17+ rating.
- [ ] Provide a working demo account in Review notes.
- [ ] (Recommended) Upload a TestFlight build and beta test first.
- [ ] (Recommended) Move Supabase to a paid plan (no 7-day auto-pause + backups).
