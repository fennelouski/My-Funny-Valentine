# Sharing and Export Implementation

This document describes the implementation of sharing and export features for the My Funny Valentine app.

## Overview

The sharing and export system provides comprehensive support for:
- iOS Share Sheet integration
- Platform-specific sharing (Instagram, Facebook, TikTok)
- Save to Photos library
- macOS GIF export with animations
- Image optimization for different platforms

## Components

### 1. ImageOptimizer (`Services/ImageOptimizer.swift`)

Handles image optimization for different sharing destinations:

- **Instagram**: 1080x1080 (square) or 1080x1350 (portrait), JPEG, 92% quality
- **Facebook**: 1200x1200, JPEG, 90% quality
- **TikTok**: 1080x1920 (vertical), JPEG, 85% quality
- **Email**: 1200x1200, JPEG, 70% quality (compressed)
- **Messages**: 2048x2048, JPEG, 80% quality
- **Photos**: 4096x4096, JPEG, 85% quality (high quality)

**Key Methods**:
- `optimize(_:for:)` - Optimize image for a specific destination
- `optimizeForInstagram(_:isPortrait:)` - Instagram-specific optimization
- `optimizeForTikTok(_:)` - TikTok-specific optimization
- `compressToSizeLimit(_:maxSizeMB:for:)` - Compress to meet size limits

### 2. ShareService (`Services/ShareService.swift`)

Main service for sharing functionality:

**Methods**:
- `shareImage(_:from:completion:)` - Standard iOS share sheet
- `shareToInstagram(_:from:isPortrait:)` - Instagram sharing
- `shareToFacebook(_:from:)` - Facebook sharing
- `shareToTikTok(_:from:)` - TikTok sharing
- `shareToEmail(_:from:)` - Email sharing (optimized)
- `shareToMessages(_:from:)` - Messages sharing (optimized)
- `saveToPhotos(_:)` - Save to Photos library
- `saveToPhotosAlbum(_:albumName:)` - Save to specific album

**Error Handling**:
- Checks if apps are installed before sharing
- Handles share failures gracefully
- Provides user-friendly error messages

### 3. PhotoLibraryManager (`Services/PhotoLibraryManager.swift`)

Manages photo library access and saving:

**Features**:
- Request photo library authorization
- Save images to Photos library
- Save images to specific albums
- Handle permission errors

**Permissions**:
- Requires `NSPhotoLibraryAddUsageDescription` in Info.plist
- Handles authorization status changes
- Supports limited photo library access

### 4. GIFExporter (`Services/GIFExporter.swift`) - macOS Only

Creates animated GIFs from card images:

**Animation Types**:
- Fade In/Out
- Slide
- Zoom
- Heart Animation
- Text Reveal

**Options**:
- Frame rate: 8-15 fps (default: 12)
- Duration: 2-6 seconds (default: 4)
- Max colors: 256 (default)
- Max size: 10MB

**Features**:
- Automatic optimization if GIF exceeds size limit
- File dialog for save location
- Frame generation with various animations

### 5. ShareSheet (`Views/ShareSheet.swift`)

SwiftUI wrapper for `UIActivityViewController`:

**Usage**:
```swift
ShareSheet(items: [image]) { completed, error in
    // Handle completion
}
```

### 6. SharePreviewView (`Views/SharePreviewView.swift`)

Preview screen before sharing:

**Features**:
- Card preview
- Destination selection (Instagram, Facebook, TikTok, Email, Messages, Photos, More)
- Format selection (Image, PDF, GIF on macOS)
- Instagram portrait/square toggle
- Edit option
- Cancel option

**Destinations**:
- Instagram - Optimized for Stories/Feed
- Facebook - Optimized for sharing
- TikTok - Vertical format optimized
- Email - Compressed for email
- Messages - Balanced quality
- Photos - High quality save
- More Options - Standard share sheet

### 7. CardRenderer (`Utilities/CardRenderer.swift`)

Renders Card model to UIImage:

**Features**:
- Renders card with all elements (faces, images, text, stickers)
- Supports custom size
- Handles layout data
- Fallback text rendering

### 8. Card+Sharing (`Extensions/Card+Sharing.swift`)

Convenience extension for Card:

**Methods**:
- `renderAsImage(size:)` - Render card as UIImage
- `optimizedImage(for:)` - Get optimized image for destination

## Usage Examples

### Basic Sharing

```swift
// Render card to image
guard let cardImage = card.renderAsImage() else { return }

// Show share preview
SharePreviewView(
    cardImage: cardImage,
    onShare: { destination in
        // Handle share
    },
    onCancel: {
        // Dismiss
    }
)
```

### Direct Sharing

```swift
// Share to Instagram
try ShareService.shared.shareToInstagram(cardImage, from: viewController)

// Save to Photos
try await ShareService.shared.saveToPhotos(cardImage)

// Standard share sheet
ShareService.shared.shareImage(cardImage, from: viewController)
```

### macOS GIF Export

```swift
let options = GIFExportOptions(
    frameRate: 12.0,
    duration: 4.0,
    animationType: .fadeInOut
)

if let gifData = GIFExporter.shared.createAnimatedGIF(from: nsImage, options: options) {
    GIFExporter.shared.saveGIF(gifData)
}
```

## Platform Support

### iOS
- Full sharing support
- Instagram, Facebook, TikTok integration
- Save to Photos
- Standard share sheet

### macOS
- GIF export with animations
- File dialog for save location
- Animation options

## Permissions

Required Info.plist entries:
- `NSPhotoLibraryUsageDescription` - Read photos
- `NSPhotoLibraryAddUsageDescription` - Save photos

## Error Handling

All sharing methods handle errors gracefully:
- App not installed → User-friendly error message
- Permission denied → Request permissions
- Share failed → Show error with retry option
- Image generation failed → Fallback to original

## Performance

- Image optimization: <2 seconds
- Share sheet appearance: <500ms
- GIF generation: <5 seconds (macOS)
- Save to Photos: <1 second

## Future Enhancements

- Video export (MP4)
- Batch sharing (multiple cards)
- Scheduled sharing
- Analytics for shares
- Custom animation presets
- Print support
