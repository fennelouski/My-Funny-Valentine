> ⚠️ **SUPERSEDED — do not use for submission.** This document predates the
> decision to ship 1.0 **free with no in-app purchases**, with on-device
> generation (Apple Intelligence / Image Playground) as the primary path.
> The authoritative submission reference is `app-store/SUBMISSION.md`; the
> published privacy policy is
> <https://nathanfennel.com/my-funny-valentine/privacy>. Anything here about
> subscriptions, premium tiers, or pricing no longer applies.

# App Store Connect Configuration Guide

This guide walks you through setting up your app in App Store Connect for submission.

## Prerequisites

- Apple Developer Account (paid membership required)
- App Store Connect access
- Completed app development
- All assets ready (icon, screenshots, descriptions)

## Step 1: Create App Record

### Initial Setup

1. **Log in to App Store Connect**
   - Go to https://appstoreconnect.apple.com
   - Sign in with your Apple Developer account

2. **Create New App**
   - Click "+" button or "My Apps" → "New App"
   - Select platform: iOS
   - Fill in required information:
     - **Name**: My Funny Valentine
     - **Primary Language**: English (U.S.)
     - **Bundle ID**: com.nathanfennel.My-Funny-Valentine
     - **SKU**: my-funny-valentine-001 (unique identifier)
     - **User Access**: Full Access (or Admin)

3. **App Information**
   - **Category**: 
     - Primary: Photo & Video
     - Secondary: Lifestyle
   - **Age Rating**: Complete questionnaire (likely 4+)
   - **App Privacy**: Complete privacy questionnaire

## Step 2: Configure Subscription Products

### Create Subscription Group

1. **Navigate to Subscriptions**
   - Go to "Features" → "In-App Purchases"
   - Click "+" to create subscription group
   - Name: "Premium"

### Create Subscription Product

1. **Product Details**
   - **Reference Name**: Premium Monthly
   - **Product ID**: com.nathanfennel.My-Funny-Valentine.premium
   - **Subscription Duration**: 1 Month
   - **Price**: $0.99 USD

2. **Localization**
   - **Display Name**: Premium
   - **Description**: 
     ```
     Unlock unlimited creativity with Premium:
     • 20 AI-generated sayings per month
     • 10 custom AI image generations per month
     • Early access to new templates
     • Priority support
     ```

3. **Subscription Information**
   - **Free Trial**: None (or 7 days if desired)
   - **Introductory Offer**: None
   - **Promotional Offers**: None (initially)

4. **Review Information**
   - Provide screenshot showing subscription benefits
   - Explain subscription value

### Pricing

- Set price for all territories
- Use "Match Price Tier" for consistency
- Price Tier: Tier 1 ($0.99 USD)

## Step 3: App Store Listing

### App Information

1. **Name**: My Funny Valentine
2. **Subtitle**: Create personalized Valentine's cards with AI
3. **Promotional Text**: Create heartfelt Valentine's cards with AI-powered sayings and face detection. Free to try, upgrade for unlimited creativity!
4. **Description**: (See `app-store/listing/app-store-description.md`)
5. **Keywords**: valentine,card,AI,romantic,love,photo,personalized,custom,face detection,sticker,share
6. **Support URL**: https://myfunnyvalentine.app/support
7. **Marketing URL**: https://myfunnyvalentine.app
8. **Privacy Policy URL**: https://myfunnyvalentine.app/privacy

### App Preview & Screenshots

#### iPhone 6.7" Display
- Upload at least 3 screenshots (1290x2796 pixels)
- Show: Card creation, AI generation, face detection, sharing

#### iPhone 6.5" Display
- Upload at least 3 screenshots (1284x2778 pixels)
- Same content as 6.7" display

#### iPhone 5.5" Display
- Upload at least 3 screenshots (1242x2208 pixels)
- Same content as other iPhone sizes

#### iPad Pro 12.9" Display
- Upload at least 3 screenshots (2048x2732 pixels)
- Optimized for iPad interface

### App Icon
- Upload 1024x1024 PNG
- No transparency
- No rounded corners (Apple adds them)

### App Preview Video (Optional)
- Duration: 15-30 seconds
- Show key features
- No sound required (but can include)

## Step 4: Version Information

### Version Details

1. **Version Number**: 1.0
2. **Copyright**: © 2026 Nathan Fennel (or your name/company)
3. **Trade Representative Contact**: Your contact information

### What's New in This Version

```
🎉 Welcome to My Funny Valentine!

Create personalized Valentine's Day cards with:
• AI-powered sayings generation
• Smart face detection
• Beautiful card templates
• Multiple image sources (stickers, cutouts, photos)
• iCloud sync across devices
• Easy social media sharing

Free to try with 3 AI requests per day. Upgrade to Premium for unlimited creativity!
```

## Step 5: Build Submission

### Upload Build

1. **Archive in Xcode**
   - Product → Archive
   - Wait for archive to complete

2. **Distribute to App Store**
   - Click "Distribute App"
   - Select "App Store Connect"
   - Choose "Upload"
   - Select your distribution certificate
   - Upload the build

3. **Wait for Processing**
   - Build processing takes 15-60 minutes
   - Check App Store Connect for status

### Select Build for Review

1. **Go to Version Page**
   - Navigate to your app version
   - Scroll to "Build" section

2. **Select Build**
   - Click "+" next to Build
   - Select your processed build

## Step 6: App Review Information

### Contact Information

- **First Name**: [Your first name]
- **Last Name**: [Your last name]
- **Phone Number**: [Your phone number]
- **Email**: [Your email]

### Demo Account (if needed)

- **Username**: [If app requires login]
- **Password**: [If app requires login]
- **Notes**: Explain any special requirements

### Notes for Review

```
Thank you for reviewing My Funny Valentine!

This app allows users to create personalized Valentine's Day cards using:
- AI-generated sayings (via OpenAI API)
- Face detection (on-device using Vision framework)
- Photo import and card templates
- iCloud sync for cross-device access

Key points for testing:
1. Free tier: Users get 3 AI requests per day
2. Premium subscription: $0.99/month unlocks 20 AI requests + 10 image generations per month
3. Face detection works automatically when photos are imported
4. Cards sync via CloudKit (requires iCloud account)
5. Sharing works via standard iOS share sheet

The app uses:
- CloudKit for data sync (private user database)
- StoreKit 2 for subscriptions
- Vision framework for face detection (on-device)
- OpenAI API for AI text generation

All user data is stored privately in the user's CloudKit account. We do not access user photos or personal data.

If you need any additional information or have questions, please contact us at support@myfunnyvalentine.app
```

### Attachment (Optional)

- Upload demo video if helpful
- Include any additional documentation

## Step 7: Export Compliance

### Encryption

1. **Does your app use encryption?**
   - Yes (HTTPS for API calls, CloudKit encryption)

2. **Export Compliance Information**
   - Select: "My app uses encryption but is exempt"
   - Reason: Uses standard encryption (HTTPS, CloudKit)

## Step 8: Age Rating

### Complete Questionnaire

1. **Unrestricted Web Access**: No
2. **User Generated Content**: Yes (photos, text)
3. **Violence**: None
4. **Sexual Content**: None
5. **Profanity**: None
6. **Gambling**: No
7. **Alcohol/Tobacco**: No
8. **Mature Themes**: None

**Expected Rating**: 4+

## Step 9: App Privacy

### Privacy Practices

1. **Data Collection**
   - Photos: Yes (stored in CloudKit, not accessed by us)
   - User Content: Yes (cards, text - stored in CloudKit)
   - Usage Data: Yes (for subscription management)
   - Diagnostics: Optional (for crash reporting)

2. **Data Usage**
   - App Functionality: Yes
   - Analytics: Optional
   - Advertising: No
   - Third-Party Advertising: No

3. **Data Linked to User**: Yes (via CloudKit)
4. **Tracking**: No

### Privacy Policy URL
- https://myfunnyvalentine.app/privacy

## Step 10: Submit for Review

### Final Checklist

Before submitting, verify:

- [ ] All required screenshots uploaded
- [ ] App icon uploaded
- [ ] Description complete and accurate
- [ ] Keywords set
- [ ] Support URL working
- [ ] Privacy Policy URL working
- [ ] Subscription products configured
- [ ] Build selected and processed
- [ ] Review notes completed
- [ ] Age rating completed
- [ ] App privacy information completed
- [ ] Export compliance completed

### Submit

1. **Review All Information**
   - Double-check all fields
   - Verify URLs work
   - Test subscription flow

2. **Submit for Review**
   - Click "Submit for Review" button
   - Confirm submission

3. **Wait for Review**
   - Typical review time: 24-48 hours
   - Check email for updates
   - Respond promptly to any questions

## Post-Submission

### Monitor Status

- Check App Store Connect regularly
- Respond to any review questions
- Fix any issues if rejected

### Common Issues

- **Missing Information**: Complete all required fields
- **Subscription Issues**: Verify subscription configuration
- **Privacy Concerns**: Ensure privacy policy is accessible
- **Build Issues**: Verify build is valid and not expired

## Resources

- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [App Store Review Guidelines](https://developer.apple.com/app-store/review/guidelines/)
- [Human Interface Guidelines](https://developer.apple.com/design/human-interface-guidelines/)
