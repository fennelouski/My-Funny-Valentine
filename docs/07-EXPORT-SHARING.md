# Export & Sharing

## Overview

The app provides multiple ways for users to share their Valentine's cards, including direct sharing to social media platforms and export options for different use cases.

## Core Features

### 1. Social Media Sharing

#### Instagram Sharing

**Description**: Share cards directly to Instagram Stories or Feed.

**Requirements**:
- Instagram app installed
- Support for image sharing
- Proper image dimensions and format

**User Flow**:
1. User taps "Share" on a card
2. User selects "Instagram"
3. App opens Instagram share sheet
4. User selects Story or Feed
5. Card is shared

**Technical Implementation**:
- Use iOS Share Sheet (`UIActivityViewController`)
- Support Instagram-specific sharing
- Optimize image for Instagram (1080x1080 for square, 1080x1350 for portrait)
- Handle Instagram app not installed (show error)

**Image Specifications**:
- **Square**: 1080x1080 pixels
- **Portrait**: 1080x1350 pixels
- **Format**: JPEG or PNG
- **Quality**: High (90%+)

#### Facebook Sharing

**Description**: Share cards to Facebook.

**Requirements**:
- Facebook app installed (optional)
- Support for image sharing
- Proper image format

**User Flow**:
1. User taps "Share" on a card
2. User selects "Facebook"
3. App opens Facebook share sheet or app
4. User adds caption (optional)
5. Card is shared

**Technical Implementation**:
- Use iOS Share Sheet
- Support Facebook sharing
- Optimize image for Facebook (1200x630 for link preview, or original for photo)
- Handle Facebook app not installed (web fallback)

**Image Specifications**:
- **Recommended**: 1200x630 pixels (for link previews)
- **Photo**: Original dimensions, max 8MB
- **Format**: JPEG
- **Quality**: High

#### TikTok Sharing

**Description**: Share cards to TikTok (as images or videos).

**Requirements**:
- TikTok app installed
- Support for image/video sharing
- Consider video format for better engagement

**User Flow**:
1. User taps "Share" on a card
2. User selects "TikTok"
3. App opens TikTok share sheet
4. User can add card as image or convert to video
5. Card is shared

**Technical Implementation**:
- Use iOS Share Sheet
- Support TikTok sharing
- Option to create video from card (animated)
- Optimize for TikTok (1080x1920 for vertical)

**Image Specifications**:
- **Vertical**: 1080x1920 pixels (9:16 aspect ratio)
- **Format**: JPEG or MP4 (for video)
- **Quality**: High

### 2. Standard iOS Share Sheet

**Description**: Use iOS native share sheet for sharing to any app.

**User Flow**:
1. User taps "Share" button
2. iOS share sheet appears
3. User selects destination (Messages, Mail, AirDrop, etc.)
4. Card is shared

**Technical Implementation**:
- Use `UIActivityViewController`
- Include card image in share items
- Support multiple formats (image, PDF)
- Handle all share destinations

**Supported Destinations**:
- Messages
- Mail
- AirDrop
- Save to Photos
- Files app
- Other apps that support image sharing

### 3. macOS GIF Export

**Description**: Export cards as animated GIFs on macOS with automated animation.

**Requirements**:
- macOS version of app
- GIF creation library
- Animation parameters

**User Flow**:
1. User opens card on Mac
2. User taps "Export as GIF"
3. App shows animation options
4. User selects animation style
5. App generates animated GIF
6. User saves GIF to location

**Animation Options**:
- **Fade in/out**: Cards fade in and out
- **Slide**: Cards slide in from sides
- **Zoom**: Cards zoom in/out
- **Heart animation**: Hearts float around card
- **Text reveal**: Text animates in

**Technical Implementation**:
- Use Core Animation or GIF library
- Create frame sequence
- Optimize GIF size (limit colors, optimize frames)
- Export to user-selected location

**GIF Specifications**:
- **Frame rate**: 10-15 fps
- **Duration**: 3-5 seconds
- **Size limit**: 10MB
- **Color palette**: 256 colors max
- **Dimensions**: Match card size or user-selected

**Animation Implementation**:
```swift
// Pseudo-code
func createAnimatedGIF(card: Card, animation: AnimationType) -> Data {
    let frames = generateFrames(card: card, animation: animation)
    let gifData = encodeGIF(frames: frames, fps: 12)
    return gifData
}
```

### 4. Image Format Optimization

**Description**: Optimize images for different sharing destinations.

**Optimization Strategy**:
- **Social media**: Compress for platform requirements
- **Email**: Further compress to reduce size
- **Print**: High resolution, uncompressed
- **Storage**: Balance quality and size

**Technical Implementation**:
- Detect sharing destination
- Apply appropriate compression
- Maintain aspect ratio
- Preserve quality where needed

**Compression Settings**:
- **Instagram/Facebook**: 90% quality, optimized dimensions
- **TikTok**: 85% quality, vertical format
- **Email**: 70% quality, max 2MB
- **Print**: 100% quality, 300 DPI
- **Storage**: 85% quality, original dimensions

### 5. Share Preview

**Description**: Show preview of card before sharing.

**User Flow**:
1. User taps "Share"
2. Preview screen appears
3. User can make last-minute edits
4. User confirms sharing
5. Share sheet appears

**Preview Features**:
- Full card preview
- Edit button (quick edits)
- Format selection (if multiple options)
- Destination selection
- Cancel option

## User Stories

### As a user, I want to:
1. Share my cards on Instagram
2. Share my cards on Facebook
3. Share my cards on TikTok
4. Share via Messages or Email
5. Export cards as GIFs on Mac
6. Save cards to my Photos library
7. See a preview before sharing
8. Choose the best format for each platform

## Technical Requirements

### iOS Frameworks
- `UIKit` / `SwiftUI` - Share sheet UI
- `UniformTypeIdentifiers` - File type handling
- `PhotosUI` - Save to Photos
- `Core Animation` - Animations (for GIF)

### macOS Frameworks
- `AppKit` - File dialogs
- `Core Animation` - GIF creation
- `ImageIO` - Image processing

### Image Processing
- Resize images for different platforms
- Compress images appropriately
- Convert formats (PNG to JPEG)
- Generate thumbnails

### Performance Requirements
- Share sheet appears: <500ms
- Image optimization: <2 seconds
- GIF generation: <5 seconds
- Export to file: <1 second

## Platform-Specific Considerations

### iOS
- Use native share sheet for best UX
- Support all standard share destinations
- Handle app not installed gracefully
- Optimize for mobile data usage

### macOS
- File dialog for export location
- GIF creation with animation options
- Batch export capability (future)
- Print support (future)

## Error Handling

### Sharing Errors
- **App not installed**: Show error, suggest alternative
- **Share fails**: Show error, allow retry
- **Image too large**: Auto-compress and retry
- **Network error**: Queue for retry when online

### Export Errors
- **Permission denied**: Request permissions
- **Disk full**: Show error, suggest cleanup
- **Format error**: Convert format and retry
- **Generation fails**: Show error, allow retry

## Edge Cases

### Multiple Formats
- User wants both image and GIF → Generate both
- User shares to multiple destinations → Handle each separately
- User cancels share → Return to card view

### Large Files
- Card too large for email → Auto-compress
- GIF too large → Reduce frame rate or duration
- Multiple cards → Share individually or as album

### Platform Limitations
- Instagram doesn't support certain formats → Convert format
- TikTok prefers video → Offer video conversion
- Email size limits → Compress appropriately

## Dependencies

- iOS 14.0+ for share sheet improvements
- macOS 11.0+ for app version
- Image processing libraries (if needed)
- GIF creation library (for macOS)

## Future Considerations

- Video export (MP4)
- Print-on-demand integration
- QR code generation for cards
- Link sharing (web view of card)
- Batch sharing (multiple cards)
- Scheduled sharing
- Analytics for shares
