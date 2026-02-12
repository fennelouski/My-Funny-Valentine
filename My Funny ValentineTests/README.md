# Testing Documentation

This directory contains comprehensive tests for the My Funny Valentine iOS app.

## Test Structure

### Unit Tests

#### Models (`Models/`)
- `CardTests.swift` - Tests for Card model
- `FaceImageTests.swift` - Tests for FaceImage model
- `CardImageTests.swift` - Tests for CardImage model
- `UserPreferencesTests.swift` - Tests for UserPreferences model
- `StickerReferenceTests.swift` - Tests for StickerReference model

#### Services (`Services/`)
- `APIServiceTests.swift` - Tests for API service
- `SubscriptionManagerTests.swift` - Tests for subscription management

### Integration Tests (`Integration/`)
- `APIIntegrationTests.swift` - API integration tests
- `CloudKitIntegrationTests.swift` - CloudKit sync tests

### Edge Case Tests (`EdgeCases/`)
- `EdgeCaseTests.swift` - Tests for error conditions and edge cases

### Performance Tests (`Performance/`)
- `PerformanceTests.swift` - Performance benchmarks

### UI Tests (`../My Funny ValentineUITests/`)
- `CardCreationUITests.swift` - Card creation workflow tests
- `CriticalFlowsUITests.swift` - Critical user flow tests

## Test Utilities

### TestUtilities.swift
Provides helper functions and test data:
- `ModelContainer.testContainer()` - Creates in-memory test container
- `TestData` - Sample data generators
- `Test.withModelContext()` - Helper for async tests with model context

### Mocks (`Mocks/`)
- `MockAPIService.swift` - Mock API service for testing
- `MockSubscriptionManager.swift` - Mock subscription manager

## Running Tests

### In Xcode
1. Press `Cmd+U` to run all tests
2. Or use Product > Test menu
3. Or click the diamond icon next to test methods

### Command Line
```bash
xcodebuild test \
  -project "My Funny Valentine.xcodeproj" \
  -scheme "My Funny Valentine" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'
```

### Specific Test Suite
```bash
xcodebuild test \
  -project "My Funny Valentine.xcodeproj" \
  -scheme "My Funny Valentine" \
  -only-testing:MyFunnyValentineTests/CardTests
```

## Code Coverage

To view code coverage:
1. Run tests in Xcode
2. Open Report Navigator (Cmd+9)
3. Select latest test run
4. Click Coverage tab

Target coverage: >70%

## Test Data

Test fixtures are provided in `TestData` struct:
- `sampleImageData()` - Sample image data
- `sampleCard()` - Sample card
- `sampleFaceImage()` - Sample face image
- `sampleCardImage()` - Sample card image
- `sampleStickerReference()` - Sample sticker
- `sampleUserPreferences()` - Sample user preferences

## Mocking External Dependencies

### API Service
Use `MockAPIService` to mock API responses:
```swift
let mockService = MockAPIService()
mockService.generateSayingsResult = .success(response)
```

### Subscription Manager
Use `MockSubscriptionManager` to mock subscription states:
```swift
let mockManager = MockSubscriptionManager()
mockManager.isPremium = true
```

## CI/CD

Tests run automatically on:
- Push to main/develop branches
- Pull requests

See `.github/workflows/ios-tests.yml` for configuration.

## Notes

- StoreKit tests require StoreKit Configuration files
- CloudKit tests require CloudKit container setup
- Network tests require URLProtocol mocking or test server
- UI tests require accessibility identifiers on UI elements

## Coverage Goals

- Unit Tests: >70% code coverage
- Integration Tests: All critical workflows
- UI Tests: All critical user flows
- Edge Cases: All error conditions
