> ⚠️ **SUPERSEDED — do not use for submission.** This document predates the
> decision to ship 1.0 **free with no in-app purchases**, with on-device
> generation (Apple Intelligence / Image Playground) as the primary path.
> The authoritative submission reference is `app-store/SUBMISSION.md`; the
> published privacy policy is
> <https://nathanfennel.com/my-funny-valentine/privacy>. Anything here about
> subscriptions, premium tiers, or pricing no longer applies.

# App Review Notes

## Contact Information

**First Name**: Nathan  
**Last Name**: Fennel  
**Phone Number**: [Your phone number]  
**Email**: support@myfunnyvalentine.app

## Demo Account (Not Required)

This app does not require a demo account. Users sign in with their Apple ID, and all functionality is available immediately.

## Notes for Reviewers

### App Overview

Thank you for reviewing My Funny Valentine! This app allows users to create personalized Valentine's Day cards using AI-powered sayings, face detection, and various image integration features.

### Key Features to Test

1. **Card Creation**
   - Users can import photos and create cards using templates
   - Face detection automatically places faces on cards
   - Multiple customization options available

2. **AI-Generated Sayings**
   - Free tier: Users get 3 AI-generated sayings per day
   - Premium tier: 20 AI-generated sayings per month
   - Users provide optional inspiration text (max 50 characters)
   - AI generates 10 sayings per request

3. **Premium Subscription**
   - Price: $0.99/month
   - Unlocks: 20 AI requests/month + 10 custom image generations/month
   - Purchase flow uses StoreKit 2
   - Subscription can be managed in App Store settings

4. **Face Detection**
   - Uses Apple's Vision framework (on-device processing)
   - Automatically detects faces when photos are imported
   - No server-side face processing

5. **iCloud Sync**
   - Cards sync automatically via CloudKit
   - Requires user to be signed into iCloud
   - Data is stored in user's private CloudKit container

6. **Sharing**
   - Standard iOS share sheet integration
   - Can share to Instagram, Facebook, TikTok, Photos, etc.
   - Works with any app that accepts images

### Testing Instructions

#### Basic Flow
1. Launch the app
2. Import a photo (tap photo button)
3. Select a card template
4. Tap "Generate Sayings" to test AI feature (free tier: 3 per day)
5. Customize the card with text or images
6. Tap share to test sharing functionality

#### Premium Subscription Flow
1. Tap "Upgrade to Premium" button
2. View premium benefits
3. Tap "Subscribe for $0.99/month"
4. Complete StoreKit purchase flow
5. Verify premium features unlock
6. Test premium features (20 AI requests, image generation)

#### Free Tier Limits
- After 3 AI requests, users see upgrade prompt
- Can still create unlimited template-based cards
- Limits reset daily at midnight (local time)

### Technical Details

#### Backend API
- Hosted on Vercel Serverless Functions
- Uses OpenAI API for text generation
- Responses are cached to minimize API costs
- All API calls use HTTPS

#### Data Storage
- Local: SwiftData for on-device storage
- Cloud: CloudKit for sync (user's private database)
- We do not access user's CloudKit data
- All data encrypted end-to-end by Apple

#### Permissions
- **Photo Library**: Required to import photos for cards
- **iCloud**: Required for CloudKit sync (automatic with Apple ID)

#### Third-Party Services
- **CloudKit**: Apple's cloud storage (user's private database)
- **OpenAI API**: For AI text generation
- **Vercel**: Backend hosting
- **StoreKit 2**: For subscription management

### Privacy & Security

- All user photos stored locally and in user's private CloudKit account
- We do not access user photos or personal data
- Face detection performed entirely on-device
- AI prompts sent securely to backend API
- No tracking or analytics beyond basic usage (for subscription management)
- Privacy Policy available at: https://myfunnyvalentine.app/privacy

### Known Issues

None at this time. All features are fully functional.

### Special Considerations

1. **iCloud Requirement**: App requires iCloud account for sync. If reviewer doesn't have iCloud, sync features won't work, but core functionality (card creation, AI generation) still works.

2. **AI Generation**: Requires internet connection. If offline, users can still create template-based cards.

3. **Face Detection**: Works best with clear, front-facing photos. May not detect faces in very dark or obscured photos.

4. **Subscription**: Uses StoreKit 2 sandbox environment for testing. Ensure reviewer uses sandbox test account.

### Support

If you have any questions or encounter any issues during review, please contact us at:
- **Email**: support@myfunnyvalentine.app
- **Support URL**: https://myfunnyvalentine.app/support

We're happy to provide additional information or assistance as needed.

### Compliance

- ✅ Follows App Store Review Guidelines
- ✅ Privacy Policy provided and accessible
- ✅ Subscription terms clearly disclosed
- ✅ Age rating appropriate (4+)
- ✅ No prohibited content
- ✅ Proper permissions usage
- ✅ Export compliance completed

---

**Thank you for your time and consideration!**
