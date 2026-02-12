# Testing Setup Guide

This document describes the comprehensive testing infrastructure set up for the My Funny Valentine iOS app.

## Overview

The test suite includes:
- **Unit Tests**: Model and service tests (>70% coverage target)
- **Integration Tests**: API and CloudKit sync tests
- **UI Tests**: Critical user flow tests
- **Edge Case Tests**: Error handling and boundary conditions
- **Performance Tests**: Performance benchmarks

## Test Structure

```
My Funny ValentineTests/
├── Models/
│   ├── CardTests.swift
│   ├── FaceImageTests.swift
│   ├── CardImageTests.swift
│   ├── UserPreferencesTests.swift
│   └── StickerReferenceTests.swift
├── Services/
│   ├── APIServiceTests.swift
│   └── SubscriptionManagerTests.swift
├── Integration/
│   ├── APIIntegrationTests.swift
│   └── CloudKitIntegrationTests.swift
├── EdgeCases/
│   └── EdgeCaseTests.swift
├── Performance/
│   └── PerformanceTests.swift
├── Mocks/
│   ├── MockAPIService.swift
│   └── MockSubscriptionManager.swift
├── TestUtilities.swift
└── README.md

My Funny ValentineUITests/
├── CardCreationUITests.swift
├── CriticalFlowsUITests.swift
└── My_Funny_ValentineUITests.swift
```

## Running Tests

### In Xcode

1. **Run All Tests**: Press `Cmd+U` or Product > Test
2. **Run Specific Test**: Click the diamond icon next to a test method
3. **Run Test Suite**: Right-click on a test file > Run

### Command Line

```bash
# Run all tests
xcodebuild test \
  -project "My Funny Valentine.xcodeproj" \
  -scheme "My Funny Valentine" \
  -destination 'platform=iOS Simulator,name=iPhone 15,OS=latest'

# Run specific test suite
xcodebuild test \
  -project "My Funny Valentine.xcodeproj" \
  -scheme "My Funny Valentine" \
  -only-testing:MyFunnyValentineTests/CardTests
```

## Test Coverage

View coverage in Xcode:
1. Run tests
2. Open Report Navigator (Cmd+9)
3. Select latest test run
4. Click Coverage tab

**Target**: >70% code coverage

## Test Utilities

### TestUtilities.swift

Provides helper functions:
- `ModelContainer.testContainer()` - In-memory test container
- `TestData` - Sample data generators
- `Test.withModelContext()` - Async test helper

### Mock Objects

- `MockAPIService` - Mock API responses
- `MockSubscriptionManager` - Mock subscription states

## Test Data Fixtures

Use `TestData` struct for consistent test data:
```swift
let card = TestData.sampleCard()
let faceImage = TestData.sampleFaceImage(cardId: card.id)
let userPrefs = TestData.sampleUserPreferences()
```

## CI/CD

Tests run automatically via GitHub Actions:
- On push to main/develop branches
- On pull requests
- See `.github/workflows/ios-tests.yml`

## Test Requirements

### Unit Tests
- ✅ All data models tested
- ✅ Service layer tested
- ✅ Business logic tested
- ✅ Edge cases covered

### Integration Tests
- ⚠️ Requires backend API (configure baseURL in APIService)
- ⚠️ Requires CloudKit container setup
- ⚠️ Requires StoreKit Configuration for subscription tests

### UI Tests
- ⚠️ Requires accessibility identifiers on UI elements
- ⚠️ Requires UI implementation

## Known Limitations

1. **StoreKit Tests**: Require StoreKit Configuration files
2. **CloudKit Tests**: Require CloudKit container and iCloud account
3. **Network Tests**: Require URLProtocol mocking or test server
4. **UI Tests**: Require UI implementation with accessibility identifiers

## Next Steps

1. **Add Accessibility Identifiers**: Add identifiers to UI elements for UI tests
2. **Configure StoreKit**: Set up StoreKit Configuration for subscription tests
3. **Set Up Test Backend**: Configure test API endpoint or use mocks
4. **CloudKit Setup**: Configure CloudKit container for integration tests
5. **View Model Tests**: Add tests when view models are implemented
6. **Image Service Tests**: Add tests when ImageService is implemented

## Test Coverage Goals

- **Models**: 100% coverage ✅
- **Services**: >80% coverage (pending implementation)
- **View Models**: >70% coverage (pending implementation)
- **Overall**: >70% coverage

## Troubleshooting

### Tests Fail to Import Module
- Ensure test target includes all source files
- Check module name matches `My_Funny_Valentine`
- Verify `@testable import` statements

### SwiftData Tests Fail
- Ensure test container uses in-memory storage
- Check model schema includes all models
- Verify relationships are properly configured

### StoreKit Tests Fail
- Create StoreKit Configuration file
- Add to test target
- Configure test products

### CloudKit Tests Fail
- Ensure CloudKit container is configured
- Check entitlements file
- Verify iCloud account is available
