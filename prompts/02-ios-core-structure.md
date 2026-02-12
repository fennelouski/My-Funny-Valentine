# Prompt 02: iOS Core App Structure

## Objective
Set up the core iOS app structure with SwiftUI, SwiftData, navigation, and basic UI components.

## Context
This is the main iOS app for My Funny Valentine. The app uses SwiftUI, SwiftData, and CloudKit for data persistence.

## Reference Documentation
- `docs/01-FEATURE-OVERVIEW.md` - Overall app structure
- `docs/10-TECHNICAL-SPECS.md` - Technical requirements
- `docs/06-ICLOUD-SYNC.md` - CloudKit setup

## Tasks

### 1. Update App Configuration
- Configure CloudKit container in entitlements
- Set deployment target to iOS 18.0+
- Update Info.plist with required permissions
- Configure app identifier and capabilities

### 2. Create Core Data Models (SwiftData)
- `Card` model with all properties
- `FaceImage` model
- `CardImage` model
- `UserPreferences` model
- `StickerReference` model
- Configure CloudKit integration for models

### 3. Set Up App Architecture
- Create main app file with SwiftData container
- Configure CloudKit database connection
- Set up dependency injection structure
- Create app-wide state management

### 4. Create Navigation Structure
- Main tab/navigation structure
- Home screen
- Card library/gallery screen
- Settings screen
- Navigation between screens

### 5. Create Core UI Components
- Reusable card preview component
- Loading indicators
- Error message components
- Button styles
- Text input components

### 6. Create View Models
- CardViewModel for card management
- SubscriptionViewModel for subscription status
- UsageTrackerViewModel for usage limits
- ImageManagerViewModel for image handling

### 7. Set Up Services Layer
- APIService for backend calls
- CloudKitService for sync
- SubscriptionService for StoreKit
- ImageService for image operations

### 8. Create Base Views
- ContentView (main entry)
- CardListView
- CardDetailView
- SettingsView
- Empty state views

## Deliverables
- Complete app structure with navigation
- All SwiftData models configured
- CloudKit integration set up
- Core UI components
- Service layer architecture
- View models for state management

## Notes
- Use SwiftUI best practices
- Follow MVVM pattern
- Ensure CloudKit container is properly configured
- All models should be CloudKit-compatible
- Use async/await for network calls
