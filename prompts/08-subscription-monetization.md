# Prompt 08: Subscription and Monetization

## Objective
Implement StoreKit 2 subscription system, usage tracking, and premium feature gates.

## Context
The app uses a freemium model with free tier (3 AI requests) and paid subscription ($0.99/month) with 20 AI requests and 10 image generations.

## Reference Documentation
- `docs/05-MONETIZATION.md` - Complete monetization requirements
- `docs/10-TECHNICAL-SPECS.md` - StoreKit requirements

## Tasks

### 1. Configure StoreKit 2
- Set up subscription product in App Store Connect
- Configure product ID: `com.nathanfennel.My-Funny-Valentine.premium`
- Set subscription duration (1 month)
- Set price ($0.99)
- Configure subscription group

### 2. Implement Subscription Service
- Create SubscriptionManager class
- Check subscription status
- Purchase subscription flow
- Restore purchases
- Handle purchase completion
- Handle purchase errors

### 3. Implement Usage Tracking
- Track AI requests per user
- Track image generations per user
- Store in UserPreferences model
- Reset logic (daily for free, monthly for paid)
- Sync usage across devices
- Display usage to user

### 4. Create Subscription UI
- Subscription status display
- Upgrade button (for free users)
- Manage subscription button
- Restore purchases button
- Usage statistics display
- Premium benefits list

### 5. Implement Premium Feature Gates
- Check subscription before premium features
- Show upgrade prompt for non-premium users
- Display premium badge
- Lock premium features
- Unlock features after purchase

### 6. Create Upgrade Flow
- Premium benefits screen
- Pricing display
- Purchase button
- StoreKit purchase flow
- Purchase confirmation
- Feature unlock animation

### 7. Handle Subscription States
- Active subscription
- Expired subscription
- Grace period handling
- Cancellation handling
- Refund handling
- Family sharing (if enabled)

### 8. Integrate with Backend
- Validate subscription on backend
- Send receipt for validation (optional)
- Sync subscription status
- Handle subscription webhooks (if implemented)

## Deliverables
- Complete StoreKit 2 integration
- Subscription purchase flow
- Usage tracking system
- Premium feature gates
- Subscription UI
- Upgrade flow
- Subscription state handling
- Backend integration

## Notes
- Use StoreKit 2 best practices
- Handle all subscription states
- Show clear upgrade prompts
- Track usage accurately
- Sync subscription status
- Handle errors gracefully
- Provide restore purchases option
