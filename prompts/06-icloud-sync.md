# Prompt 06: iCloud Sync Implementation

## Objective
Implement CloudKit sync for cards, images, and user data across all devices.

## Context
Users need their cards to sync automatically across iPhone, iPad, and Mac. This uses CloudKit with SwiftData integration.

## Reference Documentation
- `docs/06-ICLOUD-SYNC.md` - Complete sync requirements
- `docs/10-TECHNICAL-SPECS.md` - CloudKit configuration

## Tasks

### 1. Configure CloudKit Container
- Set up CloudKit container in developer account
- Configure container identifier in entitlements
- Set up CloudKit schema in dashboard
- Create record types (Card, FaceImage, CardImage, UserPreferences)
- Configure indexes for queries

### 2. Set Up SwiftData CloudKit Integration
- Configure ModelContainer with CloudKit
- Enable automatic sync
- Set up CloudKit database connection
- Handle sync status

### 3. Implement Sync Status Display
- Show sync status indicator
- Display "Syncing" state
- Show "Synced" confirmation
- Display "Offline" badge
- Show last sync time
- Error state display

### 4. Implement Conflict Resolution
- Detect conflicts during sync
- Compare modification timestamps
- Present conflict resolution UI
- Allow user to choose version
- Implement "last write wins" as default
- Store resolution choice

### 5. Handle Offline Support
- Save changes locally when offline
- Queue sync operations
- Detect when connection restored
- Automatically sync when online
- Show offline indicator
- Handle partial sync failures

### 6. Implement Asset Sync
- Sync image assets via CloudKit
- Compress images before upload
- Generate thumbnails
- Download assets on other devices
- Cache downloaded assets
- Handle large file uploads

### 7. Create Sync Settings UI
- Sync status display
- Manual sync button
- Sync data usage display
- Conflict resolution preferences
- Enable/disable sync option
- Storage usage information

### 8. Handle Sync Errors
- Network error handling
- Authentication error handling
- Quota exceeded handling
- Corruption error handling
- Retry logic for transient errors
- User-friendly error messages

## Deliverables
- CloudKit container configured
- SwiftData CloudKit integration
- Sync status display
- Conflict resolution UI
- Offline support
- Asset sync working
- Sync settings UI
- Error handling

## Notes
- All sync should be automatic
- Handle errors gracefully
- Show clear sync status
- Optimize for performance
- Respect storage limits
- Handle edge cases (account changes, etc.)
