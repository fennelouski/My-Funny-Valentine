# Acceptance Criteria

## Overview

This document defines acceptance criteria for all features of the My Funny Valentine app. Each feature includes specific, testable criteria that must be met for the feature to be considered complete.

## Image Integration Features

### Apple Image Playground Integration

**AC1.1**: User can access Image Playground from within the app
- [ ] Button/link to Image Playground is visible when Apple Intelligence is available
- [ ] Tapping the button opens Image Playground interface
- [ ] Generated images can be imported back into the app
- [ ] Imported images appear in card editor

**AC1.2**: Graceful handling when Image Playground is unavailable
- [ ] App detects if Apple Intelligence is not available
- [ ] Image Playground option is hidden or disabled with explanation
- [ ] No crashes or errors when feature is unavailable

**AC1.3**: Image import functionality
- [ ] Images imported from Image Playground are stored correctly
- [ ] Images sync to iCloud
- [ ] Images can be used in multiple cards

### iPhone Sticker Support

**AC2.1**: User can access sticker library
- [ ] "Add Sticker" button is visible and functional
- [ ] Sticker picker interface appears when tapped
- [ ] User's stickers are displayed in picker

**AC2.2**: Sticker placement and manipulation
- [ ] Selected stickers can be added to card canvas
- [ ] Stickers can be positioned by dragging
- [ ] Stickers can be resized with aspect ratio maintained
- [ ] Stickers can be rotated
- [ ] Stickers can be deleted

**AC2.3**: Sticker persistence
- [ ] Stickers remain on card after saving
- [ ] Stickers sync across devices
- [ ] Stickers maintain position and size

### Smart Cutout Feature

**AC3.1**: Support for drag-and-drop from Photos app
- [ ] App accepts drag-and-drop from Photos app
- [ ] Long-press cutout from Photos can be dragged into app
- [ ] Cutout image is received correctly

**AC3.2**: Cutout image handling
- [ ] Cutout images maintain transparency
- [ ] Cutout images can be positioned on card
- [ ] Cutout images can be resized
- [ ] Multiple cutouts can be added to same card

**AC3.3**: Error handling
- [ ] App handles cutout failures gracefully
- [ ] User receives feedback if cutout fails
- [ ] Alternative import methods are available

### Face Detection and Import

**AC4.1**: Automatic face detection
- [ ] App detects faces in imported photos using Vision framework
- [ ] Face detection works on-device (no network required)
- [ ] Detection completes within 2 seconds per image
- [ ] Multiple faces are detected correctly

**AC4.2**: Face selection interface
- [ ] Detected faces are displayed for user selection
- [ ] User can select up to 2 faces
- [ ] Selected faces are extracted with proper padding
- [ ] Face orientation is corrected automatically

**AC4.3**: Face import workflow
- [ ] User can import their own face photo
- [ ] User can import a second face (optional)
- [ ] Imported faces are stored and synced
- [ ] Faces can be used in multiple cards

**AC4.4**: Error handling
- [ ] App handles cases where no faces are detected
- [ ] User can manually select face region if detection fails
- [ ] Poor quality images are handled gracefully
- [ ] User receives clear error messages

## AI Generation System

### Valentine's Sayings Generation

**AC5.1**: Sayings generation request
- [ ] User can enter inspiration text (max 50 characters)
- [ ] Input validation prevents text over 50 characters
- [ ] "Generate Sayings" button is functional
- [ ] Loading state is displayed during generation

**AC5.2**: Response handling
- [ ] App receives 10 sayings from API
- [ ] Sayings are displayed in user interface
- [ ] Sayings are unique and relevant to inspiration
- [ ] Error messages are shown if generation fails

**AC5.3**: Caching functionality
- [ ] Identical inspiration text returns cached results
- [ ] Cached results are returned faster than API calls
- [ ] Cache indicator is shown when cached results are used
- [ ] Cache works across app sessions

**AC5.4**: Rate limiting
- [ ] Free tier users are limited to 3 requests per day
- [ ] Paid tier users can make 20 requests per month
- [ ] Usage count is displayed to user
- [ ] Rate limit exceeded message is shown when limit reached

### Custom Image Generation

**AC6.1**: Premium feature access
- [ ] Custom image generation is only available to paid subscribers
- [ ] Free tier users see upgrade prompt when accessing feature
- [ ] Subscription status is validated before generation

**AC6.2**: Image generation workflow
- [ ] User can enter description (max 100 characters)
- [ ] User can select style (valentine, romantic, funny)
- [ ] Generated images are displayed
- [ ] Images can be added to cards

**AC6.3**: Usage limits
- [ ] Paid users have 10 image generations per month
- [ ] Usage count is displayed
- [ ] Limit exceeded message is shown when limit reached

## Card Creation & User Flow

### Face Import Workflow

**AC7.1**: Initial face import
- [ ] App prompts for face import on first launch
- [ ] User can import face from photo library
- [ ] User can take new photo for face import
- [ ] Face is detected and stored

**AC7.2**: Second face import
- [ ] App prompts for optional second face
- [ ] User can skip second face import
- [ ] Second face is detected and stored if provided

**AC7.3**: Immediate card generation
- [ ] Cards are generated immediately after face import
- [ ] 10-15 card options are displayed
- [ ] Cards show imported faces inserted into templates
- [ ] Generation completes within 1 second

### Template-Based Cards

**AC8.1**: Template card display
- [ ] Multiple card templates are available
- [ ] Templates show user's faces correctly inserted
- [ ] Cards are displayed in grid or list view
- [ ] User can scroll through card options

**AC8.2**: Card selection and customization
- [ ] User can select a card template
- [ ] Selected card opens in editor
- [ ] User can add text/sayings to card
- [ ] User can save card

### Custom Card Creation

**AC9.1**: Custom card workflow
- [ ] User can create custom cards
- [ ] User can add AI-generated sayings
- [ ] User can add images, stickers, and cutouts
- [ ] User can arrange elements on card

**AC9.2**: Card editing
- [ ] User can edit text on cards
- [ ] User can change font, size, and color
- [ ] User can reposition elements
- [ ] Changes are saved automatically

**AC9.3**: Card preview
- [ ] User can preview card before saving
- [ ] Preview shows final card appearance
- [ ] User can return to editor from preview
- [ ] User can share from preview

## Monetization & Subscriptions

### Free Tier

**AC10.1**: Free tier limitations
- [ ] Free users can create unlimited template cards
- [ ] Free users are limited to 3 AI requests per day
- [ ] Usage count is displayed
- [ ] Upgrade prompt is shown after limit reached

**AC10.2**: Free tier features
- [ ] All basic card creation features work
- [ ] iCloud sync works
- [ ] Sharing features work
- [ ] No ads displayed (if ads are not implemented)

### Paid Subscription

**AC11.1**: Subscription purchase
- [ ] User can view premium features
- [ ] User can initiate subscription purchase
- [ ] StoreKit purchase flow works correctly
- [ ] Purchase completion unlocks premium features

**AC11.2**: Premium features
- [ ] Premium users get 20 AI requests per month
- [ ] Premium users get 10 image generations per month
- [ ] Usage limits are tracked correctly
- [ ] Features unlock immediately after purchase

**AC11.3**: Subscription management
- [ ] User can view subscription status
- [ ] User can manage subscription in Settings
- [ ] User can restore purchases
- [ ] Subscription expiration is handled gracefully

## iCloud Sync

### CloudKit Integration

**AC12.1**: Automatic sync
- [ ] Cards sync automatically when created
- [ ] Changes sync across devices
- [ ] Sync status is indicated to user
- [ ] Sync completes within reasonable time

**AC12.2**: Cross-device access
- [ ] Cards created on iPhone appear on iPad
- [ ] Cards created on iPad appear on iPhone
- [ ] Edits sync to all devices
- [ ] Deletions sync to all devices

**AC12.3**: Conflict resolution
- [ ] Conflicts are detected when same card edited on multiple devices
- [ ] Conflict resolution UI is presented
- [ ] User can choose which version to keep
- [ ] Resolution syncs to all devices

**AC12.4**: Offline support
- [ ] App works when offline
- [ ] Changes are saved locally
- [ ] Changes sync when connection restored
- [ ] Offline status is indicated to user

## Export & Sharing

### Social Media Sharing

**AC13.1**: Instagram sharing
- [ ] User can share cards to Instagram
- [ ] Cards are optimized for Instagram format
- [ ] Sharing works if Instagram app is installed
- [ ] Error is shown if Instagram app is not installed

**AC13.2**: Facebook sharing
- [ ] User can share cards to Facebook
- [ ] Cards are optimized for Facebook format
- [ ] Sharing works correctly
- [ ] Error handling works

**AC13.3**: TikTok sharing
- [ ] User can share cards to TikTok
- [ ] Cards are optimized for TikTok format (vertical)
- [ ] Sharing works correctly
- [ ] Error handling works

**AC13.4**: Standard share sheet
- [ ] iOS share sheet appears when "Share" is tapped
- [ ] All standard share destinations work
- [ ] Cards can be saved to Photos
- [ ] Cards can be shared via Messages, Mail, etc.

### macOS GIF Export

**AC14.1**: GIF export functionality
- [ ] User can export cards as GIF on macOS
- [ ] Animation options are available
- [ ] GIF is generated correctly
- [ ] GIF can be saved to user-selected location

**AC14.2**: Animation quality
- [ ] Animations are smooth (10-15 fps)
- [ ] GIF file size is reasonable (<10MB)
- [ ] Colors are preserved
- [ ] Duration is appropriate (3-5 seconds)

## Performance Requirements

### Response Times

**AC15.1**: Face detection performance
- [ ] Face detection completes within 2 seconds per image
- [ ] Multiple faces detected within 5 seconds

**AC15.2**: Card generation performance
- [ ] Template cards generate within 1 second
- [ ] Card preview renders within 500ms
- [ ] Save operation completes within 1 second

**AC15.3**: API response times
- [ ] Cached API responses return within 500ms
- [ ] Uncached API responses return within 5 seconds
- [ ] Error responses return within 1 second

### Resource Usage

**AC16.1**: Memory usage
- [ ] App uses <200MB memory during normal use
- [ ] Memory is released when cards are closed
- [ ] No memory leaks

**AC16.2**: Storage usage
- [ ] Card data is optimized for storage
- [ ] Images are compressed appropriately
- [ ] Storage usage is reasonable per card (~100KB)

## Error Handling

### General Error Handling

**AC17.1**: Network errors
- [ ] Network errors are handled gracefully
- [ ] User receives clear error messages
- [ ] Retry options are provided
- [ ] Offline mode works

**AC17.2**: API errors
- [ ] API errors are handled gracefully
- [ ] User receives user-friendly error messages
- [ ] Technical errors are logged
- [ ] App doesn't crash on API errors

**AC17.3**: Data errors
- [ ] Corrupted data is handled
- [ ] Missing data is handled
- [ ] Invalid input is validated
- [ ] User receives feedback on errors

## User Experience

### Accessibility

**AC18.1**: VoiceOver support
- [ ] All UI elements are accessible via VoiceOver
- [ ] Labels are descriptive
- [ ] Navigation works with VoiceOver

**AC18.2**: Visual accessibility
- [ ] Text is readable (minimum size)
- [ ] Colors have sufficient contrast
- [ ] UI elements are appropriately sized

### Usability

**AC19.1**: Intuitive interface
- [ ] App is easy to use without instructions
- [ ] Common tasks are obvious
- [ ] Error messages are helpful
- [ ] Loading states are clear

**AC19.2**: Performance perception
- [ ] App feels responsive
- [ ] Loading indicators are shown
- [ ] Animations are smooth
- [ ] No unnecessary delays

## Testing Requirements

### Unit Tests
- [ ] Core functionality has unit tests
- [ ] Test coverage >70%
- [ ] Tests run in CI/CD

### Integration Tests
- [ ] API integration tests
- [ ] CloudKit sync tests
- [ ] StoreKit tests (if possible)

### UI Tests
- [ ] Critical user flows have UI tests
- [ ] Tests run on multiple devices
- [ ] Tests cover edge cases

### Manual Testing
- [ ] All features tested manually
- [ ] Tested on multiple devices
- [ ] Tested with different iOS versions
- [ ] Tested offline scenarios
