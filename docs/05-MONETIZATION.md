# Monetization & Subscriptions

## Overview

The app uses a freemium model with a free tier offering limited AI requests and a paid subscription tier providing additional AI requests and custom image generation capabilities.

## Subscription Tiers

### Free Tier

**Features**:
- Unlimited template-based card creation
- 3 AI-generated saying requests per day
- Basic card editing
- iCloud sync
- Social media sharing
- Standard export formats

**Limitations**:
- No custom image generation
- Limited AI requests (3 per day)
- No priority support

**User Experience**:
- Users can use app fully for basic card creation
- After 3 AI requests, show upgrade prompt
- Track usage and display remaining requests

### Paid Tier: Premium Subscription

**Price**: $0.99/month (minimum App Store subscription tier)

**Features**:
- All free tier features
- 20 additional AI-generated saying requests per month
- 10 custom AI image generations per month
- Priority support
- Early access to new templates
- Ad-free experience (if ads are added later)

**Benefits Over Free Tier**:
- 20x more AI requests (20 vs 3)
- Custom image generation capability
- Better value for power users

## Subscription Management

### StoreKit 2 Integration

**Requirements**:
- StoreKit 2 framework
- App Store Connect configuration
- Product IDs configured
- Subscription group setup

**Product Configuration**:
- Product ID: `com.nathanfennel.My-Funny-Valentine.premium`
- Subscription Duration: 1 month
- Price: $0.99 USD
- Free Trial: 7 days (optional)
- Introductory Offer: None (keep price low)

**Technical Implementation**:
```swift
// Pseudo-code
import StoreKit

class SubscriptionManager: ObservableObject {
    @Published var isPremium: Bool = false
    @Published var remainingAIRequests: Int = 3
    @Published var remainingImageGenerations: Int = 0
    
    func checkSubscriptionStatus() {
        // Check StoreKit subscription status
        // Update isPremium flag
        // Update usage limits
    }
    
    func purchasePremium() {
        // Present StoreKit purchase flow
        // Handle purchase completion
        // Update subscription status
    }
    
    func restorePurchases() {
        // Restore previous purchases
        // Update subscription status
    }
}
```

### Usage Tracking

**Track Per User**:
- AI saying requests (daily for free, monthly for paid)
- Custom image generations (monthly, paid only)
- Reset dates (daily for free tier, monthly for paid)

**Storage**:
- Use CloudKit or local storage
- Key: `usage:${userId}:${date}` or `usage:${userId}:${month}`
- Track: `aiRequests`, `imageGenerations`

**Implementation**:
```swift
// Pseudo-code
struct UsageTracker {
    func canMakeAIRequest(userId: String) -> Bool {
        let usage = getUsage(userId: userId)
        let limit = isPremium ? 20 : 3
        return usage.aiRequests < limit
    }
    
    func recordAIRequest(userId: String) {
        incrementUsage(userId: userId, type: .aiRequest)
    }
    
    func resetUsage(userId: String) {
        // Reset daily (free) or monthly (paid)
    }
}
```

## User Flows

### Free Tier User Flow
1. User opens app
2. User creates cards (unlimited templates)
3. User requests AI sayings (up to 3 per day)
4. After 3 requests, show upgrade prompt
5. User can continue with templates or upgrade

### Upgrade Flow
1. User taps "Upgrade to Premium"
2. App shows premium benefits
3. User taps "Subscribe for $0.99/month"
4. StoreKit purchase flow appears
5. User completes purchase
6. App unlocks premium features
7. Usage limits reset

### Paid Tier User Flow
1. Premium user opens app
2. User sees remaining requests (20 AI, 10 images)
3. User uses features freely
4. When limits reached, show renewal prompt
5. User can wait for next month or manage subscription

## Subscription Status Display

### Home Screen
- Show subscription status badge
- Display remaining requests
- Show upgrade button (if free tier)

### Settings Screen
- Subscription status
- Manage subscription button
- Restore purchases button
- Usage statistics
- Billing history (if available)

## Revenue Model

### Pricing Strategy
- **$0.99/month**: Low barrier to entry
- Matches iCloud+ pricing tier (familiar to users)
- Affordable for casual users
- Sustainable for power users

### Cost Analysis
- Average API cost per user: ~$0.05/month (with caching)
- Free tier: 3 requests = ~$0.0001 cost
- Paid tier: 20 requests = ~$0.0006 cost
- Custom images: ~$0.02 per generation
- **Break-even**: ~5% conversion rate needed

### Revenue Projections
- 1000 free users: $0 revenue, ~$0.10 cost
- 50 paid users (5% conversion): $49.50 revenue, ~$1.50 cost
- **Net profit**: ~$48/month per 1000 users

## App Store Requirements

### Subscription Configuration
- Auto-renewable subscription
- Subscription group: "Premium"
- Localized pricing for all regions
- Privacy policy URL required
- Terms of service URL required

### Subscription Management
- Users can manage in App Store settings
- Support cancellation and refunds
- Handle subscription expiration
- Grace period handling (if enabled)

### Compliance
- Clear pricing display
- Terms of service
- Privacy policy
- Subscription terms explanation
- Cancellation instructions

## User Stories

### As a free user, I want to:
1. Use the app for basic card creation
2. Try AI features with limited requests
3. Understand what I get with premium
4. Easily upgrade when ready

### As a premium user, I want to:
1. Use AI features freely
2. Generate custom images
3. See my usage and limits
4. Manage my subscription easily
5. Restore my subscription on new devices

## Technical Requirements

### Backend Integration
- Validate subscription status on server
- Track usage server-side
- Enforce limits
- Handle subscription webhooks (if using server-side validation)

### API Endpoints
```
POST /api/validate-subscription
{
  "userId": string,
  "receipt": string // App Store receipt
}

Response:
{
  "isPremium": boolean,
  "expiresAt": number,
  "remainingAIRequests": number,
  "remainingImageGenerations": number
}
```

### Error Handling
- Subscription purchase fails → Show error, allow retry
- Receipt validation fails → Show error, contact support
- Usage limit reached → Show upgrade prompt
- Subscription expired → Gracefully downgrade to free tier

## Edge Cases

### Subscription Issues
- Purchase succeeds but validation fails → Retry validation, show pending state
- Subscription expires → Show expiration notice, allow renewal
- Family sharing → Handle shared subscriptions (if enabled)
- Refund requested → Handle gracefully, maintain user data

### Usage Tracking
- Usage data lost → Default to free tier limits
- Clock manipulation → Use server time for validation
- Multiple devices → Sync usage across devices via CloudKit

## Dependencies

- StoreKit 2 framework
- App Store Connect account
- Backend validation (optional but recommended)
- CloudKit for usage sync

## Future Considerations

- Annual subscription option ($9.99/year, 2 months free)
- Lifetime purchase option
- Family sharing support
- Gift subscriptions
- Promotional pricing
- Referral program
- Additional subscription tiers
