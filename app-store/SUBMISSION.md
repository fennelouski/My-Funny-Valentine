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
| Unit tests | ✅ 66 tests, all passing |
| UI tests | ✅ All passing, incl. create-card golden path |
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

**URLs** — all three must be live before submission:

| Field | Status |
|---|---|
| Support URL | ⚠️ Needs hosting |
| Marketing URL | ⚠️ Needs hosting (`website/` in this repo) |
| Privacy Policy URL | ⚠️ **Required.** Text is in `legal/privacy-policy.md`, needs a public URL |

---

## 4. Privacy

### On-device AI

Both generative features run locally, with graceful degradation:

| Feature | Framework | Requires | Fallback |
|---|---|---|---|
| Sayings | FoundationModels (`SystemLanguageModel`) | iOS 26 / macOS 26 + Apple Intelligence on | Hosted backend, then built-in templates |
| Artwork | ImagePlayground (`ImageCreator`) | iOS 18.4 / macOS 15.4 + Apple Intelligence on | Hosted backend (premium) |

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

| Field | Value |
|---|---|
| Product ID | `com.nathanfennel.My-Funny-Valentine.premium` |
| Type | Auto-renewable subscription |
| Duration | 1 month |

This product **must be created in App Store Connect** — it does not exist yet.
Until it does, `SubscriptionManager.purchasePremium()` throws
`SubscriptionError.productNotFound`.

### How entitlement works

The server grants premium on exactly one basis: a StoreKit 2 transaction
signed by Apple, verified with Apple's `app-store-server-library`.

1. `SubscriptionManager.checkSubscriptionStatus()` finds a verified entitlement
   and posts its `jwsRepresentation` to `/api/validate-subscription`.
2. `lib/app-store.ts` verifies the signature against Apple's root certificates,
   checks the bundle ID and product ID, and reads the expiry.
3. Only then does `redeemSignedTransaction` write `subscription:{userId}` to KV.

Nothing else writes that key, so a client cannot promote itself by sending a
chosen `userId`. If Apple root certificates are not configured, verification
**fails closed** — premium is never granted.

> ⚠️ **Decide what premium is actually for.** Image generation now runs on
> device via Image Playground, free and with no quota, on any device with
> Apple Intelligence. That removes the old rejection risk — the feature no
> longer 403s without a backend — but it also means the premium tier's original
> headline benefit is now free.
>
> Options, in rough order of least work:
> 1. **Ship 1.0 with no subscription.** Everything works on device. Simplest,
>    and nothing in the app is currently paywalled that users would miss.
> 2. **Reposition premium** around the cloud fallback: generation on devices
>    *without* Apple Intelligence, plus higher limits. This is a real benefit
>    for older hardware but needs the backend deployed.
> 3. **Keep it as-is** — premium buys the cloud path only. Weakest story; be
>    careful the subscription description doesn't promise what the free tier
>    already does, which invites a **Guideline 3.1.2** rejection.
>
> Whichever you pick, the subscription description in App Store Connect must
> describe only what premium *actually* adds over the free tier.

> ⚠️ **Not verified end to end.** The verification logic is unit-tested with a
> mocked verifier, but has never seen a real Apple-signed transaction. Make a
> sandbox purchase and confirm `/api/generate-image` returns 200 before you
> charge anyone.

---

## 6. Screenshots

Generated from the real app, at Apple's required dimensions:

| Platform | Size | Count | Location |
|---|---|---|---|
| iPhone 6.9" | 1320 × 2868 | 5 | `app-store/screenshots/iphone-6.9/` |
| iPad 13" | 2064 × 2752 | 5 | `app-store/screenshots/ipad-13/` |
| Mac | 1280 × 800 | 3 | `app-store/screenshots/mac/` |

Screens captured: Home, Card editor, AI sayings, My Cards, Settings.

These are **not committed to git** (see `.gitignore`) — they are build output.
Regenerate any time:

```bash
# iPhone / iPad
xcodebuild test -scheme "My Funny Valentine" \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro Max' \
  -only-testing:"My Funny ValentineUITests/ScreenshotUITests" \
  -resultBundlePath /tmp/shots.xcresult
xcrun xcresulttool export attachments --path /tmp/shots.xcresult --output-path /tmp/shots

# macOS (DEBUG build only)
open -a "My Funny Valentine.app" --args -screenshotTab 1 -seedSampleCards YES
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
`npm test` — 25 tests). Its production dependency tree has no known
vulnerabilities. It has still never been deployed or called by a real device,
so treat live behaviour as unproven until you exercise it.

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
launch.

Saying generation runs entirely on device in this build; the app makes no
network requests for it and works fully offline.

Face detection uses Apple's Vision framework and runs entirely on device.
Photos are never uploaded anywhere.

The remote-notification background mode is present only to support CloudKit
sync of the user's own cards. The app does not send push notifications.

To try the main flow: Home → "Create a Card" → "Generate with AI" → type any
word (e.g. "coffee") → Generate → pick a saying → Done → Save.
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

Still requires you:

- [ ] Set the signing team and create App Store provisioning profiles
- [ ] Create the app record in App Store Connect (§2)
- [ ] Host the privacy policy and support pages, add URLs (§3)
- [ ] Decide the subscription question in §5 — **this is the biggest open risk**
- [ ] Create the CloudKit production schema and deploy it
- [ ] Answer export compliance, or add the Info.plist key (§9)
- [ ] Decide whether macOS 26.2 minimum is intended (§2)
- [ ] Archive and upload: Product → Archive → Distribute App
