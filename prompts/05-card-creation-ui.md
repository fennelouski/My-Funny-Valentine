# Prompt 05: Card Creation UI

## Objective
Create the card creation and editing interface, including templates, face insertion, text editing, and card preview.

## Context
Users need to create cards using templates, imported faces, AI sayings, and custom content. Cards should be editable and previewable.

## Reference Documentation
- `docs/04-CARD-CREATION.md` - Card creation requirements
- `docs/02-IMAGE-INTEGRATION.md` - Image integration

## Tasks

### 1. Create Card Template System
- Load template images (bundled in app)
- Define template structure (face positions, text areas)
- Create template data model
- Template selection interface
- 10-15 templates (romantic, funny, cute, etc.)

### 2. Implement Face Import Workflow
- First-time user onboarding flow
- Photo picker for user's face
- Photo picker for second face (optional)
- Face detection and extraction
- Face selection UI
- Store faces for card generation

### 3. Create Immediate Card Generation
- Generate cards instantly after face import
- Insert faces into templates
- Create 10-15 card previews
- Display cards in grid/list view
- Card selection interface

### 4. Create Card Editor
- Canvas for card editing
- Layer management (faces, images, text, stickers)
- Drag-and-drop for elements
- Resize and rotate controls
- Undo/redo functionality
- Property inspector for selected elements

### 5. Implement Text Editing
- Text input fields
- Font selection (5-10 fonts)
- Font size slider
- Color picker
- Text alignment options
- Text effects (shadow, outline)
- Position text on card

### 6. Create Card Preview
- Full-screen preview mode
- Zoom in/out
- Share button
- Edit button
- Save button
- Delete button
- Export options

### 7. Implement Card Canvas
- SwiftUI Canvas or custom drawing
- Render card elements
- Handle touch interactions
- Support multiple layers
- Grid/snap guides
- Background color/image

### 8. Create Card Library View
- Display all user's cards
- Grid/list layout options
- Search/filter functionality
- Sort options (date, name)
- Card thumbnails
- Empty state

## Deliverables
- Complete template system
- Face import workflow
- Immediate card generation
- Card editor with all tools
- Text editing interface
- Card preview functionality
- Card canvas rendering
- Card library view

## Notes
- Templates should be high quality
- Face insertion should be seamless
- Editor should be intuitive
- Support undo/redo
- Auto-save changes
- Optimize rendering performance
