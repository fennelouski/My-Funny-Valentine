# Subscription & Monetization Implementation

## Overview

This document describes the complete StoreKit 2 subscription system implementation for My Funny Valentine app.

## Architecture

### Core Components

1. **UserPreferences Model** (`Models/UserPreferences.swift`)
   - SwiftData model for storing subscription status and usage
   - Tracks AI requests and image generations
   - Handles subscription expiration dates
   - Syncs via CloudKit

2. **SubscriptionManager** (`Services/SubscriptionManager.swift`)
   - StoreKit 2 integration
   - Manages subscription purchase flow
   - Handles subscription status checks
   - Listens for transaction updates
   - Updates UserPreferences model

3. **UsageTracker** (`Services/UsageTracker.swift`)
   - Tracks AI request usage
   - Tracks image generation usage
   - Handles daily (free) and monthly (premium) resets
   - Provides usage limits checking

4. **APIService** (`Services/APIService.swift`)
   - Backend API integration
   - Validates subscription status
   - Handles API calls for sayings generation

## Subscription Tiers

### Free Tier
- 3 AI requests per day
- No image generation
- Unlimited template-based cards

### Premium Tier ($0.99/month)
- 20 AI requests per month
- 10 image generations per month
- All free tier features
- Priority support
- Early access to templates

## Product Configuration

**Product ID**: `com.nathanfennel.My-Funny-Valentine.premium`
**Price**: $0.99/month
**Duration**: 1 month (auto-renewable)

### App Store Connect Setup Required

1. Create subscription product in App Store Connect
2. Configure subscription group
3. Set pricing ($0.99)
4. Configure subscription duration (1 month)
5. Set up localization (if needed)

## Usage

### Checking Subscription Status

```swift
@EnvironmentObject var subscriptionManager: SubscriptionManager

// Check if user is premium
if subscriptionManager.isPremium {
    // Unlock premium features
}

// Check subscription status
switch subscriptionManager.subscriptionStatus {
case .premium:
    // Premium user
case .free:
    // Free user
case .expired:
    // Expired subscription
}
```

### Checking Usage Limits

```swift
@EnvironmentObject var usageTracker: UsageTracker

// Check if user can make AI request
if usageTracker.canMakeAIRequest() {
    // Make API call
    usageTracker.recordAIRequest()
}

// Check if user can generate image
if usageTracker.canGenerateImage() {
    // Generate image
    usageTracker.recordImageGeneration()
}
```

### Premium Feature Gates

```swift
// Using PremiumFeatureGate view
PremiumFeatureGate(subscriptionManager: subscriptionManager) {
    // Premium content
} premiumContent: {
    // Alternative content for premium users (optional)
}

// Using view modifier
SomeView()
    .premiumGate(subscriptionManager: subscriptionManager)
```

### Purchase Flow

```swift
// Show upgrade view
.sheet(isPresented: $showUpgrade) {
    PremiumUpgradeView(subscriptionManager: subscriptionManager)
}

// Or purchase directly
Task {
    do {
        try await subscriptionManager.purchasePremium()
        // Handle success
    } catch {
        // Handle error
    }
}
```

### Restore Purchases

```swift
Task {
    do {
        try await subscriptionManager.restorePurchases()
    } catch {
        // Handle error
    }
}
```

## UI Components

### SubscriptionStatusView
- Displays subscription status
- Shows usage statistics
- Provides upgrade/manage buttons
- Shows restore purchases option

### PremiumUpgradeView
- Premium benefits list
- Pricing display
- Purchase button
- Terms and conditions
- Restore purchases option

### ManageSubscriptionView
- Subscription status display
- Manage subscription button (opens App Store)
- Restore purchases option

### SubscriptionBadge
- Compact subscription status badge
- Shows Premium/Free status
- Tappable to show upgrade view

### PremiumFeatureGate
- Wraps premium content
- Shows lock overlay for non-premium users
- Provides upgrade prompt

## Backend Integration

### API Endpoint: `/api/validate-subscription`

**Request**:
```json
{
  "userId": "string",
  "receipt": "string (optional)"
}
```

**Response**:
```json
{
  "isPremium": boolean,
  "expiresAt": number | null,
  "remainingAIRequests": number,
  "remainingImageGenerations": number
}
```

### Usage in API Calls

The backend validates subscription status and enforces limits:
- Free users: 3 requests per day
- Premium users: 20 requests per month
- Image generation: Premium only, 10 per month

## Usage Tracking

### Reset Logic

- **Free Tier**: Resets daily at midnight
- **Premium Tier**: Resets monthly on subscription renewal date

### Storage

Usage is stored in `UserPreferences` model:
- `aiRequestsUsed`: Current period usage
- `imageGenerationsUsed`: Current period usage
- `lastResetDate`: Date of last reset
- `subscriptionStatus`: Current subscription status
- `subscriptionExpiresAt`: Subscription expiration date

## Error Handling

### Subscription Errors

- `productNotFound`: Product not configured in App Store Connect
- `userCancelled`: User cancelled purchase
- `pending`: Purchase pending approval
- `verificationFailed`: Transaction verification failed
- `unknown`: Unknown error

### Usage Errors

- Usage limit reached: Show upgrade prompt
- Subscription expired: Gracefully downgrade to free tier
- Sync errors: Handle gracefully, use local data

## Testing

### StoreKit Testing

1. Use StoreKit Configuration file for testing
2. Configure test products
3. Test purchase flow
4. Test restore purchases
5. Test subscription expiration

### Usage Testing

1. Test daily reset for free tier
2. Test monthly reset for premium tier
3. Test usage limit enforcement
4. Test usage display

## Integration Checklist

- [x] UserPreferences model created
- [x] SubscriptionManager service created
- [x] UsageTracker service created
- [x] Subscription UI views created
- [x] Premium feature gates implemented
- [x] API endpoint created
- [x] App integration completed
- [ ] App Store Connect configuration (manual)
- [ ] StoreKit testing configuration
- [ ] Backend API deployment
- [ ] Usage tracking validation
- [ ] Subscription flow testing

## Next Steps

1. Configure product in App Store Connect
2. Set up StoreKit testing configuration
3. Deploy backend API
4. Test complete subscription flow
5. Test usage tracking and limits
6. Test restore purchases
7. Test subscription expiration handling

## Notes

- Subscription status is checked on app launch
- Usage is synced via CloudKit across devices
- Backend validates subscription status for API calls
- StoreKit handles all purchase transactions
- User can manage subscription in App Store settings
