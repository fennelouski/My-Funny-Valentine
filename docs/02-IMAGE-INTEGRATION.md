# Image Integration Features

## Overview

The app integrates multiple image sources and manipulation features to allow users to create personalized Valentine's cards with various image assets.

## Features

### 1. Apple Image Playground Integration

**Description**: Integration with Apple's Image Playground feature (part of Apple Intelligence) to generate and add images to cards.

**Requirements**:
- iOS 18.0+ (Apple Intelligence required)
- User must have Apple Intelligence enabled
- Access to Image Playground API

**User Flow**:
1. User taps "Add Image from Playground" button
2. App opens Image Playground interface
3. User generates or selects an image
4. Image is imported into the card editor

**Technical Implementation**:
- Use `ImagePlayground` framework (when available) or deep link to Image Playground
- Handle image import via URL scheme or app extension
- Store imported images in app's document directory
- Sync via CloudKit

**Edge Cases**:
- User doesn't have Apple Intelligence enabled → Show fallback message
- Image Playground unavailable → Hide option or show alternative
- Image import fails → Show error message with retry option

### 2. iPhone Sticker Support

**Description**: Allow users to add stickers from their iPhone's sticker collection to cards.

**Requirements**:
- Access to user's sticker library
- Support for animated stickers
- Sticker positioning and resizing

**User Flow**:
1. User taps "Add Sticker" button
2. App presents sticker picker interface
3. User selects sticker(s) from their collection
4. Sticker is added to card canvas
5. User can position, resize, and rotate sticker

**Technical Implementation**:
- Use `Messages` framework to access sticker library (if available)
- Alternative: Use Photos picker with sticker filter
- Support drag-and-drop for sticker placement
- Store sticker references in card data model

**Edge Cases**:
- No stickers available → Show message suggesting how to add stickers
- Sticker format not supported → Skip or convert format
- Sticker too large → Auto-resize with aspect ratio maintained

### 3. Smart Cutout Feature

**Description**: Support iOS's smart cutout feature where users can long-press on a person in a photo and drag the masked area into the app.

**Requirements**:
- iOS 16.0+ (smart cutout feature)
- Support for drag-and-drop from Photos app
- Handle masked image data

**User Flow**:
1. User opens Photos app
2. User long-presses on a person in a photo
3. User drags the cutout to My Funny Valentine app
4. App receives the masked image
5. Image is added to card editor

**Technical Implementation**:
- Implement `UIDropInteraction` or `NSItemProvider` handling
- Support `UIImage` and `NSItemProvider` types
- Handle transparent background PNG from cutout
- Store cutout images with card data

**Edge Cases**:
- Cutout fails → Show error, suggest manual import
- Multiple cutouts dragged → Handle each separately
- Cutout quality poor → Allow user to retry or use original image

### 4. Face Detection and Import

**Description**: On-device face detection to identify and extract faces from imported images.

**Requirements**:
- Vision framework for face detection
- Support for up to 2 faces (user + 1 other)
- Face extraction and positioning

**User Flow**:
1. User imports a photo
2. App automatically detects faces using Vision framework
3. App presents detected faces for selection
4. User selects up to 2 faces
5. Faces are extracted and prepared for card templates

**Technical Implementation**:
- Use `VNDetectFaceRectanglesRequest` from Vision framework
- Process images on-device (no backend calls)
- Extract face regions with padding
- Store face images separately from source images
- Support face orientation correction

**Technical Details**:
```swift
// Pseudo-code structure
let request = VNDetectFaceRectanglesRequest { request, error in
    // Handle detected faces
    // Extract face regions
    // Store for card generation
}
```

**Edge Cases**:
- No faces detected → Show message, allow manual selection
- More than 2 faces detected → Show selection interface
- Face detection fails → Fallback to manual face selection
- Poor image quality → Warn user, allow retry

### 5. Image Asset Management

**Description**: Manage all imported images, stickers, and generated assets within the app.

**Requirements**:
- Local storage for images
- CloudKit sync for images
- Image compression and optimization
- Cache management

**User Flow**:
1. User imports various image types
2. Images are stored locally and synced to iCloud
3. User can view and manage imported images
4. Images are available across devices

**Technical Implementation**:
- Store images in app's document directory
- Use CloudKit for sync (with size limits)
- Compress images before upload
- Implement image cache with size limits
- Support image deletion

**Storage Strategy**:
- Local: App document directory
- Cloud: CloudKit with asset storage
- Cache: In-memory cache for frequently used images
- Limits: Max 10MB per image, 100MB total per user

**Edge Cases**:
- iCloud storage full → Show warning, allow local-only storage
- Image sync fails → Store locally, retry sync later
- Image corrupted → Validate on import, show error
- Storage limit reached → Prompt user to delete old images

## User Stories

### As a user, I want to:
1. Generate images using Apple's Image Playground and add them to my cards
2. Use my iPhone stickers to decorate my Valentine's cards
3. Extract faces from photos using smart cutout
4. Import photos and have faces automatically detected
5. Access my imported images on all my devices
6. Manage my image library within the app

## Technical Requirements

### iOS Frameworks Required
- `Vision` - Face detection
- `PhotosUI` - Photo picker and smart cutout
- `UniformTypeIdentifiers` - File type handling
- `CloudKit` - Image sync
- `UIKit` / `SwiftUI` - UI components

### Permissions Required
- Photo Library access (read/write)
- iCloud Drive access (for CloudKit)

### Data Model
```swift
// Pseudo-code
struct CardImage {
    var id: UUID
    var source: ImageSource // playground, sticker, cutout, photo
    var imageData: Data
    var thumbnailData: Data
    var faceRegions: [FaceRegion]? // if applicable
    var createdAt: Date
    var syncedToCloud: Bool
}

enum ImageSource {
    case imagePlayground
    case sticker
    case smartCutout
    case photoImport
}
```

## Dependencies

- iOS 18.0+ for Image Playground
- iOS 16.0+ for smart cutout
- Vision framework (iOS 11.0+)
- CloudKit configured in developer account

## Future Considerations

- Support for video stickers
- AI-powered image enhancement
- Custom sticker creation within app
- Integration with more image sources
- Batch image import
- Image editing tools (filters, adjustments)
