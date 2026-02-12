# Card Creation & User Flow

## Overview

The card creation system allows users to create personalized Valentine's cards using imported faces, templates, AI-generated sayings, and custom content. Cards are immediately available after face import using pre-made templates.

## Core Features

### 1. Face Import Workflow

**Description**: Users can import their face and up to one additional face to create personalized cards.

**User Flow**:
1. User opens app for the first time
2. App prompts: "Import your photo"
3. User selects photo from library or takes new photo
4. App detects face using Vision framework (on-device)
5. App prompts: "Import a loved one's photo (optional)"
6. User optionally selects second photo
7. App detects second face
8. App immediately generates card options using templates

**Technical Implementation**:
- Use `PHPickerViewController` for photo selection
- Use Vision framework for face detection
- Extract face regions with padding
- Store face images in app documents
- Sync faces to CloudKit

**Edge Cases**:
- No face detected → Show error, allow retry or manual selection
- Multiple faces in one photo → Show selection interface
- User skips second face → Generate cards with single face
- Face detection fails → Allow manual face region selection

### 2. Immediate Template-Based Card Generation

**Description**: After face import, users immediately see multiple card options using pre-made templates.

**Requirements**:
- 10+ pre-made card templates
- Automatic face insertion into templates
- Immediate generation (no API calls)
- Template variety (romantic, funny, cute)

**User Flow**:
1. User imports faces
2. App processes faces (on-device)
3. App generates 10-15 card previews instantly
4. Cards show user's faces inserted into templates
5. User can browse and select cards
6. User can customize selected card

**Template Structure**:
- Template images (PNG with transparent areas for faces)
- Face placement coordinates
- Text areas for sayings
- Design elements (hearts, flowers, etc.)

**Technical Implementation**:
```swift
// Pseudo-code
func generateTemplateCards(faces: [FaceImage]) -> [Card] {
    let templates = loadTemplates()
    var cards: [Card] = []
    
    for template in templates {
        let card = Card(
            template: template,
            faces: faces,
            saying: nil // User adds later
        )
        cards.append(card)
    }
    
    return cards
}
```

**Template Library**:
- Romantic templates (5)
- Funny templates (3)
- Cute templates (3)
- Classic templates (2)
- Modern templates (2)

### 3. Custom Card Creation with AI

**Description**: Users can create custom cards using AI-generated sayings and custom images.

**User Flow**:
1. User taps "Create Custom Card"
2. User enters inspiration text (max 50 characters)
3. User taps "Generate Sayings"
4. App shows 10 AI-generated sayings
5. User selects a saying
6. User can add custom images, stickers, or cutouts
7. User arranges elements on card
8. User previews and saves card

**Requirements**:
- Integration with AI generation system
- Text editing interface
- Image placement tools
- Card canvas editor
- Real-time preview

**Technical Implementation**:
- Use SwiftUI Canvas or custom drawing
- Support drag-and-drop for images
- Text editing with font selection
- Layer management for elements
- Export as image

### 4. Text Input and Editing

**Description**: Users can add, edit, and customize text on cards.

**Features**:
- Add AI-generated sayings
- Type custom text
- Edit existing text
- Change font, size, color
- Position text on card

**User Flow**:
1. User selects text area on card
2. User taps to edit
3. Text editor appears
4. User types or selects AI saying
5. User adjusts font properties
6. User positions text
7. Changes save automatically

**Text Editor Features**:
- Font selection (5-10 fonts)
- Size slider
- Color picker
- Alignment options
- Text effects (shadow, outline)

### 5. Card Preview and Editing Interface

**Description**: Users can preview cards and make edits before saving or sharing.

**User Flow**:
1. User views card in preview mode
2. User taps "Edit" button
3. Card opens in editor
4. User makes changes
5. User taps "Done"
6. Card saves and returns to preview

**Preview Features**:
- Full-screen preview
- Zoom in/out
- Share button
- Edit button
- Delete button
- Save to library

**Editor Features**:
- Canvas with card elements
- Toolbar with editing tools
- Undo/redo
- Layer list
- Property inspector
- Grid/snap guides

## User Stories

### As a user, I want to:
1. Import my face and see cards immediately
2. Import a loved one's face to create couple cards
3. Browse through multiple card options
4. Customize cards with my own text
5. Use AI-generated sayings in my cards
6. Add images, stickers, and cutouts to cards
7. Edit cards after creating them
8. Preview cards before sharing
9. Save cards to my library
10. Access my cards on all devices

## Card Data Model

```swift
// Pseudo-code
struct Card {
    var id: UUID
    var templateId: String? // If using template
    var faces: [FaceImage]
    var saying: String?
    var customText: String?
    var images: [CardImage]
    var stickers: [Sticker]
    var layout: CardLayout
    var createdAt: Date
    var modifiedAt: Date
    var syncedToCloud: Bool
}

struct CardLayout {
    var backgroundColor: Color
    var textPositions: [TextPosition]
    var imagePositions: [ImagePosition]
    var stickerPositions: [StickerPosition]
}

struct TextPosition {
    var text: String
    var font: Font
    var color: Color
    var position: CGPoint
    var size: CGFloat
}
```

## User Flows

### Flow 1: Quick Card Creation (Template-Based)
1. Open app
2. Import faces (2 steps)
3. View generated cards (instant)
4. Select card
5. Optionally add saying
6. Share or save

**Time**: ~30 seconds

### Flow 2: Custom Card Creation
1. Open app
2. Tap "Create Custom"
3. Import faces/images
4. Generate AI sayings
5. Select saying
6. Arrange elements
7. Edit text/images
8. Preview
9. Save

**Time**: ~2-3 minutes

### Flow 3: Editing Existing Card
1. Open card library
2. Select card
3. Tap "Edit"
4. Make changes
5. Save
6. Share

**Time**: ~1 minute

## Technical Requirements

### iOS Components
- `PHPickerViewController` - Photo selection
- `Vision` - Face detection
- `SwiftUI Canvas` - Card rendering
- `CloudKit` - Card sync
- `SwiftData` - Local storage

### Performance Requirements
- Template card generation: <1 second
- Face detection: <2 seconds per image
- Card preview render: <500ms
- Save operation: <1 second

### Storage Requirements
- Card data: ~100KB per card
- Face images: ~500KB per face
- Template images: ~2MB total (bundled)
- User limit: 100 cards per user

## Edge Cases

### Face Import
- User cancels import → Return to home screen
- Poor quality photo → Warn user, allow retry
- Face too small → Warn user, suggest better photo
- Face at angle → Auto-correct orientation

### Card Generation
- Template loading fails → Show error, retry
- Face insertion fails → Show card without face, allow manual add
- Storage full → Prompt user to delete old cards

### Editing
- Unsaved changes → Warn before leaving editor
- Sync conflict → Show both versions, let user choose
- Image load fails → Show placeholder, allow retry

## Dependencies

- Vision framework (iOS 11.0+)
- PhotosUI framework (iOS 14.0+)
- CloudKit configured
- SwiftData (iOS 17.0+)

## Future Considerations

- More template designs
- User-created templates
- Collaborative editing
- Card animations
- Video card support
- Print quality export
- Card templates marketplace
