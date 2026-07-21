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
| Saying generation | On-device; no network call |
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

> 🚨 **Review risk.** The premium tier's headline benefit is AI *image*
> generation, which requires the backend in `api/`. That backend is not
> deployed. Shipping a paid subscription whose main feature cannot work is a
> likely rejection under **Guideline 2.1 / 3.1.1**. Either deploy the backend
> first, or ship 1.0 with no subscription and add it later.

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

The backend in `api/` + `lib/` has **not been verified** — it was never built or
tested in this repo's current state (Node isn't installed on the dev machine).
Treat it as unvalidated until you deploy and exercise it.

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
