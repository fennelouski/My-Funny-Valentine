# My Funny Valentine

A complete iOS app for creating personalized Valentine's Day cards with AI-generated sayings and custom images. Includes a SwiftUI iOS app, backend API, and marketing website.

## Project Overview

My Funny Valentine is a full-stack iOS application that allows users to create custom Valentine's Day cards with:
- AI-generated romantic sayings based on user inspiration
- Custom image generation for premium subscribers
- Face detection and photo integration
- CloudKit sync for cross-device access
- Social sharing capabilities
- Subscription-based monetization

## Repository Structure

This repository contains three main components:

### 1. iOS App (`My Funny Valentine/`)
- **Framework**: SwiftUI + SwiftData
- **Platform**: iOS 17+
- **Features**:
  - Card creation and editing
  - AI-generated sayings
  - Image generation (premium)
  - CloudKit sync
  - Face detection
  - Social sharing
  - Subscription management

### 2. Backend API (`api/`, `lib/`)
- **Platform**: Vercel Serverless Functions
- **Runtime**: Node.js 18+
- **Features**:
  - AI sayings generation
  - Image generation (GPT Image 2)
  - Subscription validation
  - Rate limiting
  - Caching (Vercel KV)

### 3. Marketing Website (`website/`)
- **Framework**: Next.js/React
- **Platform**: Vercel
- **Purpose**: Marketing and landing page

## Tech Stack

### iOS App
- SwiftUI
- SwiftData
- CloudKit
- Vision Framework (face detection)
- StoreKit 2 (subscriptions)

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

2. **Configure CloudKit**:
   - Ensure CloudKit capability is enabled in Xcode
   - Set up CloudKit container in Apple Developer portal

3. **Configure API endpoint** (optional):
   - Add an `APIBaseURL` string to `Info.plist` pointing at your deployed backend.
   - Until that's set, the app treats the hosted AI as unconfigured and
     generates sayings **on-device**, so the app is fully usable with no backend.
     The same fallback kicks in when the device is offline.

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
     - `OPENAI_MODEL`: Optional chat model override (default: `gpt-5-nano`)
     - `OPENAI_FALLBACK_MODEL`: Optional fallback chat model (default: `gpt-5.4-nano`)
     - `OPENAI_IMAGE_MODEL`: Optional image model override (default: `gpt-image-2`)
     - `KV_REST_API_URL`: Vercel KV URL
     - `KV_REST_API_TOKEN`: Vercel KV token

3. **Deploy to Vercel**:
   ```bash
   vercel
   ```

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

### Free Tier
- 3 AI-generated sayings per day (unlimited on-device sayings when no backend is configured)
- Basic card creation
- CloudKit sync
- Social sharing

### Premium Tier
- 20 AI-generated sayings per month
- 10 custom image generations per month
- Advanced card templates
- Priority support

## Project Structure

```
.
├── My Funny Valentine/          # iOS app source
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

### iOS Development
- Minimum iOS version: 17.0
- Xcode 15+ required
- Swift 5.9+

### Backend Development
- Node.js 18+
- TypeScript 5+
- Vercel CLI for local development

## Deployment

### iOS App
- Deploy via Xcode to TestFlight or App Store
- Configure App Store Connect for distribution

### Backend API
- Automatic deployment via Vercel on git push
- Manual deployment: `vercel --prod`

### Website
- Automatic deployment via Vercel on git push

## Cost Optimization

- **Primary chat model**: `gpt-5-nano` (override with `OPENAI_MODEL`)
- **Fallback chat model**: `gpt-5.4-nano` (override with `OPENAI_FALLBACK_MODEL`)
- **Image model**: `gpt-image-2` with `quality: 'medium'` (override with `OPENAI_IMAGE_MODEL`)
- **Aggressive Caching**: Reduces API calls by ~90%
- Estimated costs: <$10/month for 1000 unique requests

## Security

- Input validation on all endpoints
- Rate limiting to prevent abuse
- User ID validation
- Environment variables for secrets
- HTTPS only (enforced by Vercel)
- CloudKit encryption for user data

## License

See LICENSE file for details.

## Contributing

This is a personal project. For questions or issues, please open an issue on GitHub.
