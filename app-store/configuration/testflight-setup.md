> ⚠️ **SUPERSEDED — do not use for submission.** This document predates the
> decision to ship 1.0 **free with no in-app purchases**, with on-device
> generation (Apple Intelligence / Image Playground) as the primary path.
> The authoritative submission reference is `app-store/SUBMISSION.md`; the
> published privacy policy is
> <https://nathanfennel.com/my-funny-valentine/privacy>. Anything here about
> subscriptions, premium tiers, or pricing no longer applies.

# TestFlight Setup Guide

This guide explains how to set up TestFlight for beta testing before App Store submission.

## Prerequisites

- App Store Connect account
- App record created in App Store Connect
- Build uploaded to App Store Connect
- TestFlight enabled for your app

## Step 1: Enable TestFlight

### Initial Setup

1. **Navigate to TestFlight**
   - Go to App Store Connect
   - Select your app: "My Funny Valentine"
   - Click "TestFlight" tab

2. **Enable TestFlight**
   - TestFlight is automatically enabled for new apps
   - If not enabled, follow prompts to enable it

## Step 2: Upload Beta Build

### Archive and Upload

1. **Archive in Xcode**
   - Open your project in Xcode
   - Select "Any iOS Device" as destination
   - Product → Archive
   - Wait for archive to complete

2. **Distribute to TestFlight**
   - In Organizer window, select your archive
   - Click "Distribute App"
   - Select "App Store Connect"
   - Choose "Upload"
   - Select your distribution certificate
   - Upload the build

3. **Wait for Processing**
   - Build processing takes 15-60 minutes
   - You'll receive an email when processing completes
   - Check TestFlight tab for status

## Step 3: Create Internal Testing Group

### Add Internal Testers

1. **Navigate to Internal Testing**
   - Go to TestFlight tab
   - Click "Internal Testing" section

2. **Create Group**
   - Click "+" to create group
   - Name: "Internal Team"
   - Add testers:
     - Must be added to your App Store Connect team
     - Up to 100 internal testers
     - They get builds immediately (no review)

3. **Add Testers**
   - Click "Add Testers"
   - Enter email addresses of team members
   - They'll receive invitation emails

4. **Select Build**
   - Choose the build you want to test
   - Click "Start Testing"
   - Testers can install via TestFlight app

## Step 4: Create External Testing Group

### Add External Testers

1. **Navigate to External Testing**
   - Go to TestFlight tab
   - Click "External Testing" section

2. **Create Group**
   - Click "+" to create group
   - Name: "Beta Testers"
   - Can have up to 10,000 external testers
   - Requires App Review (first build only)

3. **Configure Testing Details**
   - **What to Test**: 
     ```
     Please test the following features:
     - Card creation with face detection
     - AI-generated sayings (free tier: 3 per day)
     - Premium subscription purchase flow
     - iCloud sync across devices
     - Sharing to social media
     - Image import (stickers, cutouts, photos)
     ```
   - **Feedback Email**: support@myfunnyvalentine.app
   - **Description**: Brief description of what's being tested

4. **Add Testers**
   - Click "Add Testers"
   - Enter email addresses (up to 10,000)
   - Or share public link (if enabled)

5. **Select Build**
   - Choose the build you want to test
   - Submit for Beta App Review (first time only)
   - Review typically takes 24-48 hours
   - After approval, testers can install

## Step 5: Beta App Review (External Testing)

### First External Build

1. **Submit for Review**
   - First external build requires App Review
   - Similar to App Store review process
   - Review focuses on compliance, not bugs

2. **Provide Information**
   - **What to Test**: Describe key features
   - **Demo Account**: If needed
   - **Notes**: Any special instructions

3. **Wait for Approval**
   - Review takes 24-48 hours typically
   - You'll receive email notification
   - Once approved, all future builds auto-approve (unless major changes)

## Step 6: TestFlight Notes

### Version Release Notes

For each build, provide release notes:

**Example:**
```
Version 1.0 (Build 1)

🎉 First beta release of My Funny Valentine!

Features:
- Create personalized Valentine's cards
- AI-powered sayings generation (3 free per day)
- Face detection and photo import
- Beautiful card templates
- iCloud sync
- Social media sharing

Known Issues:
- None at this time

Please test:
- Card creation flow
- AI generation
- Subscription purchase
- iCloud sync
- Sharing functionality

Report any bugs or feedback to support@myfunnyvalentine.app
```

### Update Notes for Each Build

Keep notes concise but informative:
- What's new
- What's fixed
- What to test
- Known issues

## Step 7: Manage Testers

### Internal Testers

- **Add/Remove**: Manage in App Store Connect
- **Automatic Access**: Get builds immediately
- **No Limit**: Up to 100 internal testers
- **No Review**: Internal builds don't need review

### External Testers

- **Add/Remove**: Manage in App Store Connect
- **Invitation**: Send via email or public link
- **Limit**: Up to 10,000 external testers
- **Review Required**: First build needs review

### Public Link (Optional)

1. **Enable Public Link**
   - Go to External Testing group
   - Enable "Public Link"
   - Share link with testers
   - Anyone with link can join

2. **Manage Link**
   - Can disable anytime
   - Can set expiration date
   - Can limit number of testers

## Step 8: Collect Feedback

### TestFlight Feedback

1. **In-App Feedback**
   - Testers can submit feedback via TestFlight app
   - Feedback appears in App Store Connect
   - Respond to feedback promptly

2. **Crash Reports**
   - Automatic crash reporting
   - View in App Store Connect
   - Fix critical crashes before release

3. **Analytics**
   - View tester engagement
   - See which builds are installed
   - Monitor crash rates

## Step 9: Beta Testing Checklist

### Before Starting Beta

- [ ] Build uploaded and processed
- [ ] Internal testing group created
- [ ] Internal testers added
- [ ] External testing group created (if needed)
- [ ] Release notes written
- [ ] Feedback email configured
- [ ] Known issues documented

### During Beta

- [ ] Monitor feedback regularly
- [ ] Respond to tester questions
- [ ] Fix critical bugs
- [ ] Update release notes for new builds
- [ ] Track crash reports
- [ ] Collect feature requests

### Before App Store Submission

- [ ] All critical bugs fixed
- [ ] Feedback incorporated
- [ ] Performance optimized
- [ ] Final build tested
- [ ] Ready for App Store review

## Step 10: Transition to App Store

### Final Build

1. **Upload Production Build**
   - Archive final version
   - Upload to App Store Connect
   - Select for App Store submission (not TestFlight)

2. **Keep TestFlight Active**
   - Continue beta testing future versions
   - Use TestFlight for pre-release testing
   - Gather feedback for updates

## Best Practices

### Testing Strategy

1. **Internal Testing First**
   - Test with team before external release
   - Fix major issues early
   - Validate core functionality

2. **External Testing**
   - Start with small group (10-20 testers)
   - Expand gradually
   - Focus on diverse devices and iOS versions

3. **Feedback Management**
   - Respond to all feedback
   - Prioritize critical bugs
   - Document feature requests

### Communication

- **Clear Instructions**: Tell testers what to test
- **Regular Updates**: Keep testers informed
- **Quick Responses**: Respond to feedback promptly
- **Thank Testers**: Show appreciation for their time

## Resources

- [TestFlight Documentation](https://developer.apple.com/testflight/)
- [App Store Connect Help](https://help.apple.com/app-store-connect/)
- [Beta Testing Best Practices](https://developer.apple.com/app-store/testflight/)
