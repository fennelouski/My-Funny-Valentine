# My Funny Valentine

A native iPhone, iPad and Mac app for making personalized Valentine's cards. The current app has 30 editable illustrated starters, optional photos and Apple generation. The repository also contains optional backend and website code; the default app has no hosted API configured.

## Project Overview

The current native app supports:

- 30 editable starters across six illustrated collections
- Built-in messages and optional Apple Intelligence sayings on compatible devices
- Optional artwork creation through Apple's Image Playground sheet
- Face detection and photo integration
- Persistent cards and photos saved on this device
- PNG sharing and face animation as a GIF
- Free card editing with no in-app purchases

## Repository Structure

This repository contains three main components:

### 1. Native app (`My Funny Valentine/`)

- **Framework**: SwiftUI + SwiftData
- **Configured minimums**: iOS/iPadOS 18.0 and macOS 15.1; representative iOS18.5 checks passed23/23, exact18.0/macOS15.1 runtimes unavailable
- **Features**:
  - Card creation and editing
  - Built-in messages and optional on-device Apple Intelligence sayings
  - Artwork creation with Image Playground when the system supports it
  - Persistent local card storage
  - Face detection
  - Social sharing
  - Welcome flow replayable from Settings

### 2. Legacy backend reference (`api/`, `lib/`)

These optional endpoints are not configured in the native release. Their dependencies, model defaults and deployment requirements need separate verification before activation.
- **Platform**: Vercel Serverless Functions
- **Runtime**: Node.js 18+
- **Features**:
  - AI sayings generation
  - Image generation (GPT Image 2)
  - Subscription validation
  - Rate limiting
  - Caching (Vercel KV)

### 3. Historical marketing website (`website/`)
- **Framework**: Next.js/React
- **Platform**: Vercel
- **Purpose**: Marketing and landing page

## Tech Stack

### Native app

- SwiftUI
- SwiftData with persistent local storage
- Vision for face detection and optional foreground masking
- ImageIO for GIF export
- Optional Apple FoundationModels and the Image Playground sheet

### Backend API
- Vercel Serverless Functions
- Node.js 18+
- TypeScript
- OpenAI API (gpt-5-nano, gpt-image-2)
- Vercel KV (Redis-compatible caching)

## Getting Started

### iOS App Setup

1. **Open the project**:
   ```bash
   open "My Funny Valentine.xcodeproj"
   ```

2. **Check local storage**:
   - Cards and photos use the existing persistent SwiftData store on this device.
   - If the store cannot open, the app shows a retry screen before the editor.

3. **Configure API endpoint** (optional):
   - Add an `APIBaseURL` string to `Info.plist` pointing at your deployed backend.
   - The default app has no hosted API configured. Built-in messages and card editing work offline.
   - Optional FoundationModels sayings require compatible hardware, iOS 26 or macOS 26, enabled Apple Intelligence and a ready model. Built-in messages remain available when generation fails or is unavailable.

4. **Run the app**:
   - Build and run in Xcode (⌘R)

### Backend API Setup

1. **Install dependencies**:
   ```bash
   npm install
   ```

2. **Set up environment variables**:
   - Create `.env.local` with:
     - `OPENAI_API_KEY`: Your OpenAI API key
     - `KV_REST_API_URL` / `KV_REST_API_TOKEN`: Vercel KV credentials
     - `APPLE_ROOT_CERTS`: Comma-separated base64 DER of Apple's root CAs
       (from <https://www.apple.com/certificateauthority/>). Required to grant
       premium — subscription verification fails closed without it.
     - `APP_STORE_ENVIRONMENT`: `Sandbox` (default) or `Production`
     - `APP_APPLE_ID`: Numeric App ID, required in production
     - `OPENAI_MODEL` / `OPENAI_FALLBACK_MODEL` / `OPENAI_IMAGE_MODEL`: optional overrides

   Backend configuration is separate from the current native release. The current release draft is in `app-store/SUBMISSION.md`.

3. **Deployment**:
   The backend is outside the current native release and is not configured in the app. Before enabling or deploying it, read the workspace deployment policy and repository deployment record. Verify AWS and Vercel releases from the same committed revision during the parallel-testing period. This repository has no verified backend dual-deployment command yet.

4. **Local development**:
   ```bash
   vercel dev
   ```

## API Endpoints

### POST `/api/generate-sayings`

Generate 10 Valentine's sayings based on user inspiration.

**Request Body**:
```json
{
  "inspiration": "coffee and books",
  "userId": "user-123"
}
```

**Response**:
```json
{
  "sayings": [
    "You're my favorite chapter in the book of life",
    "Every morning with you is like the perfect cup of coffee",
    ...
  ],
  "cached": false,
  "timestamp": 1707782400000,
  "remainingRequests": 19,
  "resetAt": 1707868800000
}
```

**Rate Limits**:
- Free tier: 3 requests per day
- Premium tier: 20 requests per month

### POST `/api/generate-image`

Generate a custom image for premium subscribers.

**Request Body**:
```json
{
  "description": "two cats cuddling",
  "userId": "user-123",
  "style": "valentine"
}
```

**Requirements**:
- Premium subscription required
- 10 generations per month limit

### POST `/api/validate-subscription`

Validate user's subscription status.

## Features

The app is **free with no in-app purchases**.

| Feature | Availability |
|---|---|
| Card creation | Unlimited |
| Apple sayings | Available when the on-device model is ready; built-in messages otherwise |
| Image Playground artwork | Compatible device and Apple Intelligence required; Apple manages limits |
| Backend sayings | Only with a configured backend; 3/day per app-provided ID |
| Backend artwork | Only with a configured backend; 3/day per app-provided ID |

The default app has no hosted API configured. Photos and built-in messages
work without Apple Intelligence. Image Playground is optional and can use
Apple's Private Cloud Compute; it is not an offline or unlimited artwork
promise. Apple's supported path is the interactive system sheet, not the
discontinued `ImageCreator` API. See [Apple's migration notice](https://developer.apple.com/news/?id=dz9wvq0r)
and [Image Playground guidance](https://developer.apple.com/videos/play/wwdc2026/375/).

Backend per-ID caps do not replace verified client identity or a global
spending limit. Add and verify those controls before enabling hosted
generation. Server-side subscription verification remains in `lib/app-store.ts`
if a paid tier is added later.

## Project Structure

```
.
├── My Funny Valentine/          # Native iPhone, iPad and Mac app source
│   ├── Components/              # Reusable UI components
│   ├── Models/                  # SwiftData models
│   ├── Services/                # Business logic services
│   ├── ViewModels/              # View models
│   ├── Views/                   # SwiftUI views
│   └── Utilities/               # Helper utilities
├── api/                         # Backend API endpoints
├── lib/                         # Backend utilities
├── website/                     # Marketing website
├── docs/                        # Documentation
├── app-store/                   # App Store assets and docs
└── My Funny ValentineTests/     # Unit tests
```

## Testing

### iOS Tests
Run tests in Xcode (⌘U) or via command line:
```bash
xcodebuild test -scheme "My Funny Valentine" -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Backend Tests
```bash
npm test
```

## Development

### Native development

- Configured minimum iOS/iPadOS version: 18.0
- Configured minimum macOS version: 15.1
- Use an Xcode SDK that supports the project's Apple generation APIs and availability checks.
- Compilation, native behavior and oldest-OS results must be recorded for the release build.

### Backend Development
- Node.js 18+
- TypeScript 5+
- Vercel CLI for local development

## Deployment

### iOS App
- Deploy via Xcode to TestFlight or App Store
- Configure App Store Connect for distribution

### Backend API

The current native app has no hosted API configured. Backend release work must follow the workspace AWS migration policy. Implement and verify the repository's dual-deployment command before a hosted release; Git push alone is not deployment evidence.

### Website

Current privacy/support pages are maintained in the separate `nathanfennel.com` repository. Its verified command is `npm exec --yes --package=node@22 -- python3 scripts/deploy-app-privacy.py`, run from that repository after its clean committed revision and AWS authentication are verified. Record both AWS and Vercel live checks. The older `website/` directory is not the current release's public policy source.

## Legacy backend model defaults

The inactive backend code has defaults for `gpt-5-nano`, `gpt-5.4-nano` and `gpt-image-2`, with environment overrides. These values describe the code, not verified current API availability or a budget. Current native cards use bundled starter art, local suggestions and optional Apple generation. There is no developer-hosted generation bill in the configured app flow.

## Security

- Input validation on all endpoints
- Rate limiting to prevent abuse
- User ID validation
- Environment variables for secrets
- HTTPS only (enforced by Vercel)
- Cards and photos stored locally on this device

## Release status and public links

The [creative-card candidate](app-store-audit/2026-10-04-creative-cards/README.md) adds six illustrated styles, manual opening, thirty editable starters and six local export formats. Version 1.0 build 3 passed the recorded iPhone/iPad tests and actual Mac flows. All thirty matching marketing images and the generated PNG, GIF, PDF, sticker and interactive HTML files passed their recorded checks. Both signed 1.0(3) distribution packages uploaded successfully and now show Waiting for Review: [iPhone/iPad](https://appstoreconnect.apple.com/apps/6818700756/distribution/reviewsubmissions/details/47549909-fb61-4389-8e52-a60ea5054adc) and [Mac](https://appstoreconnect.apple.com/apps/6818700756/distribution/reviewsubmissions/details/96b81211-1e5d-4a1e-8523-4d5056c8f548). The earlier candidates were withdrawn and replaced. The app remains free in all 175 countries, future countries enabled, with automatic release after approval. [The release receipt](app-store-audit/2026-10-04-creative-cards/release/submission-verification.json) ties the builds to source commit `1351adb9edf8b0f76670487f203daca6647324eb`, package verification and the thirty ordered marketing images.

The unlisted [privacy](https://nathanfennel.com/my-funny-valentine/privacy.html) and [support](https://nathanfennel.com/my-funny-valentine/support.html) pages are published and verified on both Vercel and AWS. Cards save on this device; sharing sends an exported copy. The App Store marketing URL stays unset because there is no app directory marketing page.

## License

See LICENSE file for details.

## Contributing

This is a personal project. For questions or issues, please open an issue on GitHub.


### Creative-card behavior and verification

The submitted release adds six illustrated scene families, tap/drag opening, complete-card GIFs, readable PDF/print output, transparent PNG chat images and self-contained browser cards. Original card IDs and saved classic layouts remain compatible. See [DESIGN.md](DESIGN.md) and [the exact release audit](app-store-audit/2026-10-04-creative-cards/README.md).

The DEBUG bootstrap uses private UUID preferences and Store/Media directories, with blank unit and refused-session hosts. Current native verification records 28 passing units, four iPhone flows, one actual largest-text/dark/high-contrast flow, three landscape iPad flows, and actual Mac editing, persistence, opening, keyboard, exports and native sharing. Provider generation, a physical Duo hinge, recipient delivery and print jobs were not exercised. The older prepared QA plan remains historical.
