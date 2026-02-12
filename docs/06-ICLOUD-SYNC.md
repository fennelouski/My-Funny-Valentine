# iCloud Sync

## Overview

The app uses CloudKit to synchronize cards, images, and user data across all user's Apple devices. This enables seamless access to cards on iPhone, iPad, and Mac.

## Core Features

### 1. CloudKit Integration

**Description**: Use CloudKit as the backend for iCloud sync, providing automatic synchronization across devices.

**Requirements**:
- CloudKit container configured in Apple Developer account
- CloudKit entitlements in app
- Data model compatible with CloudKit
- Conflict resolution strategy

**Technical Implementation**:
- Use SwiftData with CloudKit integration
- Configure CloudKit container in app
- Set up data model with CloudKit compatibility
- Handle sync status and errors

**Configuration**:
```swift
// Pseudo-code
let container = ModelContainer(
    for: Card.self,
    configurations: ModelConfiguration(
        schema: schema,
        cloudKitDatabase: .automatic
    )
)
```

### 2. Data Synchronization

**Description**: Sync cards, images, faces, and user preferences across devices.

**Data Types to Sync**:
- Cards (metadata and references)
- Face images
- User preferences
- Usage statistics
- Template selections

**Sync Strategy**:
- Automatic sync when app launches
- Background sync when data changes
- Manual sync option in settings
- Conflict resolution for simultaneous edits

**Technical Details**:
- Use CloudKit's automatic sync
- Monitor sync status
- Handle sync errors gracefully
- Show sync progress to user

### 3. Conflict Resolution

**Description**: Handle conflicts when the same card is edited on multiple devices simultaneously.

**Conflict Resolution Strategy**:
- **Last write wins**: Most recent edit takes precedence
- **Manual resolution**: Show both versions, let user choose
- **Merge strategy**: Attempt automatic merge for simple changes

**User Flow**:
1. User edits card on Device A
2. User edits same card on Device B
3. Sync detects conflict
4. App shows conflict resolution dialog
5. User chooses which version to keep
6. Sync completes with chosen version

**Technical Implementation**:
- Track modification timestamps
- Detect conflicts during sync
- Present conflict resolution UI
- Store resolution choice

### 4. Offline Support

**Description**: App works offline, with changes synced when connection is restored.

**Requirements**:
- Local storage for all data
- Queue changes when offline
- Sync when connection restored
- Show sync status to user

**User Flow**:
1. User makes changes offline
2. Changes saved locally
3. App shows "Offline" indicator
4. When connection restored, sync automatically
5. User sees sync completion notification

**Technical Implementation**:
- Use SwiftData for local storage
- Track pending sync operations
- Retry sync on connection restore
- Handle partial sync failures

### 5. File Synchronization

**Description**: Sync image files and assets across devices via CloudKit.

**File Types**:
- Face images (~500KB each)
- Card images (~100KB each)
- Template assets (bundled, not synced)
- Generated images

**Storage Strategy**:
- Use CloudKit asset storage
- Compress images before upload
- Generate thumbnails for preview
- Limit file sizes (max 10MB per file)

**Technical Implementation**:
- Store file references in CloudKit records
- Upload assets to CloudKit
- Download assets on other devices
- Cache downloaded assets locally

## User Stories

### As a user, I want to:
1. Create cards on my iPhone and see them on my iPad
2. Edit cards on any device and have changes sync
3. Access my cards even when offline
4. Know when sync is in progress
5. Resolve conflicts when editing on multiple devices
6. Have my data backed up automatically

## Data Model

### CloudKit Schema

```swift
// Pseudo-code
@Model
final class Card {
    var id: UUID
    var templateId: String?
    var saying: String?
    var customText: String?
    var createdAt: Date
    var modifiedAt: Date
    var faces: [FaceReference]
    var images: [ImageReference]
    var layout: CardLayout
}

@Model
final class FaceImage {
    var id: UUID
    var cardId: UUID
    var imageData: Data // CloudKit asset
    var thumbnailData: Data
    var detectedAt: Date
}

@Model
final class ImageReference {
    var id: UUID
    var cardId: UUID
    var source: ImageSource
    var imageData: Data // CloudKit asset
    var position: CGPoint
}
```

### CloudKit Record Types
- `Card`: Card metadata
- `FaceImage`: Face image assets
- `CardImage`: Card image assets
- `UserPreferences`: User settings

## Sync Status Display

### UI Indicators
- **Syncing**: Show spinner or progress indicator
- **Synced**: Show checkmark or "Synced" text
- **Error**: Show error icon with retry option
- **Offline**: Show "Offline" badge

### Settings Screen
- Sync status display
- Last sync time
- Manual sync button
- Sync data usage
- Conflict resolution preferences

## Technical Requirements

### CloudKit Configuration

**Container Setup**:
- Container identifier: `iCloud.com.nathanfennel.My-Funny-Valentine`
- Development and production environments
- Schema defined in CloudKit Dashboard
- Indexes configured for queries

**Entitlements**:
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.nathanfennel.My-Funny-Valentine</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```

### Storage Limits
- **Free tier**: 1GB per user (CloudKit free tier)
- **File size limit**: 10MB per asset
- **Record limit**: 1000 records per user (estimated)
- **Total storage**: ~500MB per user (with compression)

### Performance Requirements
- Initial sync: <30 seconds for 100 cards
- Incremental sync: <5 seconds
- Conflict detection: <1 second
- Asset download: <10 seconds per MB

## Error Handling

### Sync Errors
- **Network error**: Queue for retry, show offline indicator
- **Authentication error**: Prompt user to sign in to iCloud
- **Quota exceeded**: Show warning, suggest cleanup
- **Conflict error**: Present resolution UI
- **Corruption error**: Attempt recovery, log error

### Error Recovery
- Automatic retry for transient errors
- Manual retry option for persistent errors
- Data validation before sync
- Backup strategy for critical data

## Edge Cases

### Multiple Devices
- User edits on Device A while Device B is offline
- Both devices sync when online → Conflict resolution
- User deletes on Device A, edits on Device B → Deletion takes precedence

### Storage Limits
- User exceeds CloudKit quota → Show warning, suggest cleanup
- Large files fail to upload → Compress or split files
- Too many records → Implement pagination or archiving

### Account Changes
- User signs out of iCloud → Store locally, sync when signed in
- User switches Apple ID → Data remains with original account
- User enables/disables iCloud → Handle gracefully

## Dependencies

- CloudKit framework
- SwiftData with CloudKit integration
- iCloud account (user requirement)
- CloudKit container configured in developer account

## Privacy & Security

### Data Privacy
- All data stored in user's private CloudKit database
- No server-side access to user data
- End-to-end encryption (CloudKit default)
- User controls data deletion

### Security Considerations
- Validate data before sync
- Prevent injection attacks
- Secure asset storage
- Handle authentication securely

## Future Considerations

- Shared cards (family sharing)
- Export/import functionality
- Selective sync (choose what to sync)
- Sync analytics and monitoring
- Cross-platform sync (if web app added)
- Backup to external storage
