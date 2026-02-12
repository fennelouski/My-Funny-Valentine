# Technical Specifications

## Overview

This document outlines the technical requirements, dependencies, and specifications for the My Funny Valentine app.

## iOS Deployment Requirements

### Minimum iOS Version
- **iOS 18.0+** (required for Apple Intelligence/Image Playground features)
- **Deployment Target**: iOS 18.0

### Supported Devices
- iPhone (all models supporting iOS 18)
- iPad (all models supporting iOS 18)
- Apple Vision Pro (visionOS 2.0+)

### Xcode Requirements
- **Xcode 26.2+** (as of February 2026)
- **Swift Version**: 5.0+
- **Swift Concurrency**: Enabled

## Required Frameworks

### Core Frameworks
- **SwiftUI**: UI framework
- **SwiftData**: Data persistence
- **CloudKit**: iCloud sync
- **Foundation**: Core functionality

### Image & Media Frameworks
- **Vision**: Face detection (on-device)
- **PhotosUI**: Photo picker and smart cutout
- **UniformTypeIdentifiers**: File type handling
- **Core Graphics**: Image processing
- **Core Image**: Image manipulation

### Apple Intelligence (Optional)
- **Image Playground API**: Image generation (iOS 18+)
- Requires Apple Intelligence enabled device

### Subscription Framework
- **StoreKit 2**: In-app purchases and subscriptions

### Sharing Frameworks
- **UIKit**: Share sheet (`UIActivityViewController`)
- **LinkPresentation**: Rich link previews (optional)

## Third-Party Dependencies

### Backend Dependencies (Node.js)
```json
{
  "dependencies": {
    "@vercel/kv": "^0.2.0",
    "openai": "^4.0.0"
  },
  "devDependencies": {
    "@types/node": "^20.0.0",
    "typescript": "^5.0.0"
  }
}
```

### iOS Dependencies
- No external Swift packages required initially
- All functionality uses native Apple frameworks

## Database Schema

### SwiftData Models

#### Card Model
```swift
@Model
final class Card {
    var id: UUID
    var templateId: String?
    var saying: String?
    var customText: String?
    var createdAt: Date
    var modifiedAt: Date
    var faces: [FaceImage]
    var images: [CardImage]
    var stickers: [StickerReference]
    var layout: CardLayoutData
    var syncedToCloud: Bool
}
```

#### FaceImage Model
```swift
@Model
final class FaceImage {
    var id: UUID
    var cardId: UUID
    var imageData: Data // CloudKit asset
    var thumbnailData: Data
    var detectedAt: Date
    var position: CGPoint
    var size: CGSize
}
```

#### CardImage Model
```swift
@Model
final class CardImage {
    var id: UUID
    var cardId: UUID
    var source: ImageSource
    var imageData: Data // CloudKit asset
    var position: CGPoint
    var size: CGSize
    var rotation: Double
}

enum ImageSource: String, Codable {
    case imagePlayground
    case sticker
    case smartCutout
    case photoImport
}
```

#### UserPreferences Model
```swift
@Model
final class UserPreferences {
    var userId: String
    var subscriptionStatus: SubscriptionStatus
    var aiRequestsUsed: Int
    var imageGenerationsUsed: Int
    var lastResetDate: Date
    var syncEnabled: Bool
}

enum SubscriptionStatus: String, Codable {
    case free
    case premium
    case expired
}
```

### CloudKit Schema

#### Record Types
- **Card**: Card metadata
- **FaceImage**: Face image assets
- **CardImage**: Card image assets
- **UserPreferences**: User settings and usage

#### Indexes
- `Card.createdAt` (for sorting)
- `Card.id` (for lookups)
- `UserPreferences.userId` (for user queries)

## API Contracts

### Generate Sayings Endpoint

**Endpoint**: `POST /api/generate-sayings`

**Request**:
```typescript
{
  "inspiration": string, // max 50 chars
  "userId": string
}
```

**Response**:
```typescript
{
  "sayings": string[], // 10 sayings
  "cached": boolean,
  "timestamp": number,
  "remainingRequests": number
}
```

**Error Responses**:
- `400`: Invalid input
- `429`: Rate limit exceeded
- `500`: Server error

### Generate Image Endpoint

**Endpoint**: `POST /api/generate-image`

**Request**:
```typescript
{
  "description": string, // max 100 chars
  "userId": string,
  "style": "valentine" | "romantic" | "funny"
}
```

**Response**:
```typescript
{
  "imageUrl": string,
  "cached": boolean,
  "remainingGenerations": number
}
```

**Error Responses**:
- `403`: Premium subscription required
- `429`: Usage limit reached
- `500`: Server error

### Validate Subscription Endpoint

**Endpoint**: `POST /api/validate-subscription`

**Request**:
```typescript
{
  "userId": string,
  "receipt": string // optional
}
```

**Response**:
```typescript
{
  "isPremium": boolean,
  "expiresAt": number | null,
  "remainingAIRequests": number,
  "remainingImageGenerations": number
}
```

## Security Considerations

### Data Privacy
- All user data stored in private CloudKit database
- No server-side access to user data
- End-to-end encryption via CloudKit
- User controls data deletion

### API Security
- Input validation on all endpoints
- Rate limiting per user
- User ID validation
- HTTPS only
- Environment variables for secrets

### App Security
- Keychain for sensitive data (if needed)
- Certificate pinning (if needed)
- Input sanitization
- SQL injection prevention (SwiftData handles this)

## Performance Requirements

### Response Times
- Face detection: <2 seconds per image
- Template card generation: <1 second
- Card preview render: <500ms
- API response (cached): <500ms
- API response (uncached): <5 seconds
- Save operation: <1 second

### Resource Usage
- Memory: <200MB during normal use
- Storage: ~100KB per card
- Network: Optimize image sizes
- Battery: Efficient background sync

## Entitlements

### Required Entitlements
```xml
<!-- CloudKit -->
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.nathanfennel.My-Funny-Valentine</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>

<!-- Push Notifications (if needed) -->
<key>aps-environment</key>
<string>production</string>

<!-- App Groups (if needed) -->
<key>com.apple.security.application-groups</key>
<array>
    <string>group.com.nathanfennel.My-Funny-Valentine</string>
</array>
```

## Permissions

### Required Permissions
- **Photo Library**: Read and write access
  - Usage: Import photos, save cards to Photos
  - Privacy description: "We need access to your photos to create personalized Valentine's cards."

### Optional Permissions
- **Camera**: Take photos for face import
  - Usage: Capture new photos for cards
  - Privacy description: "We need camera access to take photos for your cards."

## Build Configuration

### App Identifier
- **Bundle ID**: `com.nathanfennel.My-Funny-Valentine`
- **App Group**: `group.com.nathanfennel.My-Funny-Valentine` (if needed)

### Version Information
- **Marketing Version**: 1.0
- **Build Number**: Auto-increment

### Capabilities
- iCloud (CloudKit)
- In-App Purchase
- Push Notifications (if needed)
- App Groups (if needed)

## Testing Requirements

### Unit Tests
- Core data models
- Business logic
- Utility functions
- Test coverage: >70%

### Integration Tests
- API integration
- CloudKit sync
- StoreKit (if possible)

### UI Tests
- Critical user flows
- Card creation workflow
- Sharing functionality

### Device Testing
- iPhone (multiple models)
- iPad
- Different iOS versions (18.0+)
- Offline scenarios

## Deployment

### App Store Requirements
- App Store Connect account
- App Store listing materials
- Privacy policy URL
- Support URL
- App Store review guidelines compliance

### Backend Deployment
- Vercel account
- Environment variables configured
- Domain setup (if custom domain)
- Monitoring and logging

## Future Technical Considerations

- Web app version (React/Next.js)
- Android version (if needed)
- Additional AI providers
- Advanced image processing
- Video card support
- Collaborative features
- Analytics integration
