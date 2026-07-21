# App Store Connect — Submission Guide

Everything that needs to go into App Store Connect for **My Funny Valentine 1.0**,
plus the items that still need a human before you can ship.

Detailed background lives alongside this file:
`listing/` (copy), `configuration/` (step-by-step ASC setup), `legal/` (policy text),
`compliance/` (review notes and checklist). This document is the authoritative
summary of what is *actually true of the current build*.

---

## 1. Build status (verified)

| Check | Result |
|---|---|
| iOS build (iPhone/iPad) | ✅ Succeeds, **0 warnings** |
| macOS build | ✅ Succeeds, **0 warnings** |
| iOS tests | ✅ 89 tests, all passing (unit + UI) |
| Backend tests | ✅ 27 tests, `tsc --noEmit` clean |
| Onboarding | ✅ First-launch flow, 5 UI tests |
| App icon | ✅ Present for iOS + macOS (`AppIcon` asset catalog) |
| Screenshots | ✅ Captured at required sizes (§6) |

Reproduce:

```bash
xcodebuild test -scheme "My Funny Valentine" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
xcodebuild build -scheme "My Funny Valentine" \
  -destination 'platform=macOS,arch=arm64'
```

---

## 2. App identity

| Field | Value |
|---|---|
| App name | My Funny Valentine |
| Bundle ID | `com.nathanfennel.My-Funny-Valentine` |
| SKU | `MYFUNNYVALENTINE001` (any unique string) |
| Primary category | Photo & Video |
| Secondary category | Lifestyle |
| Version | `1.0` |
| Build | `1` |
| Copyright | © 2026 Nathan Fennel |
| Age rating | 4+ (no objectionable content) |

### Platforms and minimum OS

| Platform | Minimum | Device families |
|---|---|---|
| iOS / iPadOS | 18.0 | iPhone, iPad |
| macOS | 26.2 | Apple silicon + Intel |

> ⚠️ **macOS 26.2 is a very aggressive minimum** and will exclude most Macs.
> This is a deliberate build setting (`MACOSX_DEPLOYMENT_TARGET`), not an
> accident — lower it if you want a wider audience. visionOS was removed from
> `SUPPORTED_PLATFORMS` because it does not currently build or ship.

---

## 3. Listing copy

**Subtitle (30 chars max)**
```
Valentine's cards, made funny
```

**Promotional text (170 chars max)**
```
Make a Valentine's card in seconds. Type a word you love — coffee, tacos, your dog — and get sweet, silly sayings to put on a card worth sending.
```

**Description**

```
My Funny Valentine turns one word into a card worth sending.

Tell it what you love — coffee, tacos, bad puns, your dog — and it writes
sweet, silly Valentine's sayings built around it. Pick a favourite, drop it on
a card, and share it.

MAKE A CARD IN SECONDS
• Type a word, tap generate, pick the saying that makes you laugh
• Write your own message instead — the card is yours
• Every card is saved to your library, ready to send

BUILD CARDS FROM YOUR PHOTOS
• Pick a photo and the app finds the face in it
• Faces are detected entirely on your device — photos are never uploaded

YOURS, EVERYWHERE
• Cards sync across your iPhone, iPad, and Mac with iCloud
• Works offline — saying generation runs on your device

Made for anyone who would rather send something funny than something generic.
```

**Keywords (100 chars max)**
```
valentine,card,love,funny,romantic,greeting,anniversary,couple,ai,saying,quote,photo,gift
```

**What's New (1.0)**
```
First release. Create Valentine's cards with generated sayings, build cards from
your photos, and sync everything across your devices.
```

**URLs** — live on nathanfennel.com (deployed via Vercel from that repo's `main`):

| Field | URL |
|---|---|
| Support URL | `https://nathanfennel.com/my-funny-valentine/support` |
| Marketing URL | `https://nathanfennel.com/my-funny-valentine` |
| Privacy Policy URL | `https://nathanfennel.com/my-funny-valentine/privacy` |

The pages live in the `nathanfennel.com` repo under
`src/app/my-funny-valentine/` and reflect the actual 1.0 behaviour (free, no
IAP, on-device generation, capped server fallback). The `website/` directory
in this repo is an unused earlier standalone site — the nathanfennel.com pages
supersede it.

> 🚨 **Not live yet.** The pages are committed and pushed (`cb6893c1`) and the
> site builds locally with all three routes, but Vercel deployments for
> nathanfennel.com are stuck: every deploy since mid-July sits in status
> UNKNOWN with no build logs, and production still serves a build from before
> these pages (checked 21 Jul 2026 — `/giant-text` is 200, everything newer
> 404s). This smells like an account-level build block; unblock it in the
> Vercel dashboard, and once any deploy of current `main` succeeds these URLs
> go live with no further work. **Verify all three URLs return 200 before
> submitting** — App Review follows the privacy link.

---

## 4. Privacy

### On-device AI

Both generative features run locally, with graceful degradation:

| Feature | Framework | Requires | Fallback |
|---|---|---|---|
| Sayings | FoundationModels (`SystemLanguageModel`) | iOS 26 / macOS 26 + Apple Intelligence on | Hosted backend, then built-in templates |
| Artwork | ImagePlayground (`ImageCreator`) | iOS 18.4 / macOS 15.4 + Apple Intelligence on | Hosted backend, capped 3/day |

Nothing the user types or photographs leaves the device on the default path.
Every tier degrades rather than dead-ends, so the app still works on a device
with Apple Intelligence disabled or unsupported.

Verified running in the iOS 26.5 simulator — the foundation model produces
thematic sayings rather than template fills.

### Usage description strings (already in `Info.plist`)

| Key | Purpose |
|---|---|
| `NSPhotoLibraryUsageDescription` | Choosing a photo to build a card from |
| `NSPhotoLibraryAddUsageDescription` | Saving a finished card to Photos |
| `NSCameraUsageDescription` | Taking a photo for a card (iOS only) |

### App Privacy ("nutrition label") answers

For the app **as it currently ships** (no backend deployed — see §7):

| Question | Answer |
|---|---|
| Do you collect data? | **No** |
| Photos | Processed on device, never transmitted |
| Face detection | On-device via the Vision framework |
| Saying generation | On-device (Apple foundation model or templates); no network call |
| Image generation | On-device via Image Playground; no network call |
| Analytics / tracking / ads | None |
| iCloud sync | User's own private CloudKit database, not accessible to the developer |

> If you later deploy the backend and set `APIBaseURL`, this changes: the app
> then sends the user's inspiration text and an anonymous per-install UUID to
> your server. You must update the privacy answers before shipping that build.

---

## 5. In-app purchase

**None. Version 1.0 ships free with no in-app purchases.**

In App Store Connect, answer **No** to "Does your app contain in-app
purchases?" There is no subscription product to create, no paywall in the app,
and no restore-purchases flow for review to test. This removes the whole class
of Guideline 3.1 rejections.

Everything is available to every user:

| Feature | Availability |
|---|---|
| Card creation | Unlimited |
| On-device sayings | Unlimited |
| On-device artwork | Unlimited |
| Backend sayings (fallback) | 3/day per install |
| Backend artwork (fallback) | 3/day per install |

The backend caps exist purely to bound OpenAI spend on devices that can't
generate locally. They are not an upsell and the app never asks for money.

### Re-enabling a subscription later

The server-side machinery is still in the repo and still tested:
`lib/app-store.ts` verifies StoreKit 2 transactions against Apple's root
certificates, and `redeemSignedTransaction` is the only writer of the
entitlement key, so a client cannot promote itself with a chosen `userId`. It
fails closed when certificates aren't configured.

What was removed is the client: the paywall views, `SubscriptionViewModel`, and
all premium gating. To bring a subscription back you would create the product
in App Store Connect, restore a purchase UI, and have `SubscriptionManager`
post `jwsRepresentation` to `/api/validate-subscription` again.

> ⚠️ That path has never been exercised against a real Apple-signed
> transaction. If you re-enable it, make a sandbox purchase and confirm the
> entitlement lands before charging anyone.

---

## 6. Screenshots

Generated from the real app, at Apple's required dimensions:

| Platform | Size | Count | Location |
|---|---|---|---|
| iPhone 6.9" | 1320 × 2868 | 6 | `app-store/screenshots/iphone-6.9/` |
| iPad 13" | 2064 × 2752 | 6 | `app-store/screenshots/ipad-13/` |
| Mac | 1280 × 800 | 3 | `app-store/screenshots/mac/` |

Screens captured: Welcome (onboarding), Home, Card editor, AI sayings,
My Cards, Settings.

**Marketing variants** — each screenshot composed onto a branded gradient
with a headline, at the same exact dimensions, in
`app-store/screenshots/marketing/<device>/`. Regenerate with
`swift scripts/make-marketing-images.swift`. Upload either set to App Store
Connect; the marketing set is the stronger listing. Suggested order:
AI sayings → Card editor → Home → My Cards → Settings → Welcome.

These are **not committed to git** (see `.gitignore`) — they are build output.
Regenerate any time:

```bash
# iPhone / iPad
xcodebuild test -scheme "My Funny Valentine" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:"My Funny ValentineUITests/ScreenshotUITests" \
  -resultBundlePath /tmp/shots.xcresult
xcrun xcresulttool export attachments --path /tmp/shots.xcresult --output-path /tmp/shots

# macOS (DEBUG build only) — captures all three tabs at exact 1280x800
scripts/capture-mac-screenshots.sh "<DerivedData>/Build/Products/Debug/My Funny Valentine.app"
```

The `-screenshotTab` / `-seedSampleCards` launch arguments are compiled out of
Release builds (`ScreenshotSupport.swift`, guarded by `#if DEBUG`).

---

## 7. Backend configuration

The app ships with **no backend configured**. `APIService.placeholderBaseURL`
is still the placeholder, so the app detects this and generates sayings
on-device instead of making a network call. This is deliberate: the app is
fully functional out of the box and offline.

To point at a deployed backend, add to `Info.plist`:

```xml
<key>APIBaseURL</key>
<string>https://your-app.vercel.app</string>
```

### Backend environment variables

| Variable | Required | Purpose |
|---|---|---|
| `OPENAI_API_KEY` | ✅ | Sayings and image generation |
| `KV_REST_API_URL` / `KV_REST_API_TOKEN` | ✅ | Vercel KV (cache, rate limits, entitlements) |
| `APPLE_ROOT_CERTS` | ✅ *for premium* | Comma-separated base64 DER of Apple's root CAs, from <https://www.apple.com/certificateauthority/>. Without these, premium is never granted. |
| `APP_STORE_ENVIRONMENT` | recommended | `Sandbox` (default) or `Production` |
| `APP_APPLE_ID` | production only | Numeric App ID from App Store Connect |
| `APP_BUNDLE_ID` | optional | Defaults to `com.nathanfennel.My-Funny-Valentine` |
| `PREMIUM_PRODUCT_ID` | optional | Defaults to the subscription ID in §5 |
| `OPENAI_MODEL` / `OPENAI_IMAGE_MODEL` | optional | Model overrides |

The backend now **builds and its tests pass** (`npm run type-check`,
`npm test` — 27 tests). Its production dependency tree has no known
vulnerabilities. It has still never been deployed or called by a real device —
follow `docs/DEPLOYMENT.md` for the full Vercel runbook, including post-deploy
smoke tests that prove the endpoints, caps, and image hosting actually work.

Verify the OpenAI model IDs in `lib/openai.ts` against the current model list
before deploying — a wrong name fails every request at runtime, and
type-checking cannot catch it.

---

## 8. Capabilities and entitlements

| Capability | Notes |
|---|---|
| iCloud / CloudKit | Container `iCloud.com.nathanfennel.My-Funny-Valentine`. Must exist in the Developer portal for the production environment, and the schema must be **deployed to Production** in the CloudKit Console. |
| Push notifications | `aps-environment` is `development` in the entitlements file. Xcode rewrites this to `production` during App Store export — normal, no action needed. |
| Background modes | `remote-notification` — required for CloudKit sync, not for user-facing push. The app registers no notification handlers. Mention this in review notes if asked. |
| In-App Purchase | Enable on the App ID once the subscription product exists. |

---

## 9. Export compliance

The app uses only HTTPS and standard hashing (CryptoKit SHA-256 for cache
keys) — no custom or non-exempt cryptography.

App Store Connect asks this on **every** upload. To answer it once, you may add
to `Info.plist`:

```xml
<key>ITSAppUsesNonExemptEncryption</key>
<false/>
```

This is left for you to add deliberately — export compliance is a legal
declaration that should be made by the developer, not generated.

---

## 10. Review notes (paste into App Store Connect)

```
No demo account is required — all functionality is available immediately on
launch. The app is free with no in-app purchases and never asks for payment.

On first launch a short three-page welcome appears; tap "Skip" or step through
it to reach the app.

Saying generation runs entirely on device in this build; the app makes no
network requests for it and works fully offline.

Face detection uses Apple's Vision framework and runs entirely on device.
Photos are never uploaded anywhere.

The remote-notification background mode is present only to support CloudKit
sync of the user's own cards. The app does not send push notifications.

To try the main flow: Home → "Create a Card" → "Generate with AI" → type any
word (e.g. "coffee") → Generate → pick a saying → Done → Save.

To replay the welcome flow: Settings → "Show Welcome Again".
```

---

## 11. Pre-submission checklist

Verified in this repo:

- [x] Builds clean for iOS and macOS, zero warnings
- [x] Unit + UI tests pass
- [x] App icon present for all required sizes
- [x] Screenshots at required dimensions for iPhone, iPad, Mac
- [x] Privacy usage strings present
- [x] App is fully functional with no backend
- [x] First-launch onboarding, replayable from Settings
- [x] No in-app purchases — answer "No" in App Store Connect

Still requires you:

- [ ] Set the signing team and create App Store provisioning profiles
- [ ] Create the app record in App Store Connect (§2)
- [x] Privacy policy, support, and marketing pages live on nathanfennel.com (§3)
- [ ] Create the CloudKit production schema and deploy it
- [ ] Answer export compliance, or add the Info.plist key (§9)
- [ ] Decide whether macOS 26.2 minimum is intended (§2)
- [ ] Archive and upload: Product → Archive → Distribute App

---

## 12. App Store Connect walkthrough (click-by-click)

The exact order to fill everything in. Each step names the ASC screen and the
section of this document holding the values.

**A. Create the app record** — ASC → My Apps → **+** → New App
1. Platforms: check **iOS** and **macOS**.
2. Name / Bundle ID / SKU: from §2. The bundle ID must already exist in the
   Developer portal with the CloudKit capability.
3. Primary language: English (U.S.).

**B. App Information** (sidebar → General)
1. Categories: Photo & Video, secondary Lifestyle (§2).
2. Age rating questionnaire: answer **None/No** to every content question →
   rating 4+.
3. Content rights: does not use third-party content.

**C. Pricing & Availability**
1. Price: **Free** (Tier 0).
2. Availability: all territories (default).

**D. App Privacy** (sidebar → App Privacy)
1. Privacy Policy URL: `https://nathanfennel.com/my-funny-valentine/privacy`.
2. "Do you or your third-party partners collect data from this app?" —
   answer per §4. For the default build (no `APIBaseURL`): **No, we do not
   collect data**. If you ship with the backend enabled: answer **Yes** →
   "Other User Content" (the typed prompt) + "Other IDs" (the install UUID),
   both **App Functionality**, both **Not linked to identity**, **No
   tracking**.

**E. In-App Purchases** — skip entirely. §5: there are none. Do not create
products.

**F. Prepare the version** (sidebar → 1.0 Prepare for Submission)
1. Screenshots: upload from `app-store/screenshots/marketing/` (or the raw
   set) — iPhone 6.9" and iPad 13" slots; the Mac listing takes the 1280×800
   set. Order per §6.
2. Description / Promotional Text / Keywords / What's New: paste from §3.
3. Support URL + Marketing URL: from §3.
4. Version `1.0`, Copyright `© 2026 Nathan Fennel`.
5. App Review notes: paste the block in §10. No sign-in credentials needed.

**G. Build**
1. Xcode: Product → Archive (each platform), Distribute App → App Store
   Connect. Signing must be set to your team first (§11).
2. Back in ASC, attach the processed build to the version.
3. Export compliance: standard encryption only → answer per §9 (or ship the
   Info.plist key and skip the question).

**H. Submit** — Add for Review → Submit. Both platforms can go in one
submission from the same app record.
