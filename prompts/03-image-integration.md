# Prompt 03: Image Integration Features

## Objective
Implement image integration features including Image Playground, stickers, smart cutout, and face detection.

## Context
Users need to import images from various sources to create personalized cards. This includes Apple's Image Playground, iPhone stickers, smart cutout from Photos, and face detection.

## Reference Documentation
- `docs/02-IMAGE-INTEGRATION.md` - Complete image integration requirements
- `docs/10-TECHNICAL-SPECS.md` - Technical specifications

## Tasks

### 1. Implement Photo Picker Integration
- Use PHPickerViewController for photo selection
- Support camera capture
- Handle photo library permissions
- Store selected photos

### 2. Implement Face Detection (Vision Framework)
- Use VNDetectFaceRectanglesRequest for face detection
- Process images on-device (no network calls)
- Extract face regions with padding
- Handle multiple faces in one image
- Correct face orientation
- Store detected faces

### 3. Implement Face Selection UI
- Display detected faces to user
- Allow selection of up to 2 faces
- Show face previews
- Handle manual face selection if detection fails

### 4. Implement Smart Cutout Support
- Support drag-and-drop from Photos app
- Handle UIDropInteraction or NSItemProvider
- Accept UIImage and NSItemProvider types
- Preserve transparency from cutouts
- Store cutout images

### 5. Implement Sticker Support
- Access user's sticker library (if available)
- Display stickers in picker interface
- Allow sticker selection and placement
- Support sticker positioning, resizing, rotation
- Store sticker references

### 6. Implement Image Playground Integration
- Detect if Apple Intelligence is available
- Provide access to Image Playground (deep link or API)
- Handle image import from Image Playground
- Store imported images
- Gracefully handle when unavailable

### 7. Create Image Management System
- Store images in app documents directory
- Compress images before storage
- Generate thumbnails for preview
- Manage image cache
- Sync images via CloudKit
- Handle storage limits

### 8. Create Image Editor Components
- Image placement UI
- Resize and rotate controls
- Position adjustment
- Layer management
- Image preview

## Deliverables
- Complete photo picker integration
- Face detection working on-device
- Smart cutout drag-and-drop support
- Sticker integration (if available)
- Image Playground integration
- Image management and storage
- Image editor UI components

## Notes
- All face detection must be on-device (privacy)
- Handle cases where features are unavailable
- Optimize image storage (compression)
- Support CloudKit sync for images
- Handle errors gracefully (no faces detected, etc.)
