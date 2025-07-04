# Changelog

All notable changes to the DACalls SDK will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2025-07-04

### Changed
- Refactored project structure into a proper Swift package
- Split UI components into separate files for better maintainability
- Improved public API documentation
- Enhanced Swift Package Manager support

## [1.0.0] - 2025-07-04

### Added
- Initial release of DACalls SDK
- Core session management module with `DASessionManager` for liblinphone integration
- Authentication service with `DAAuthService` for SIP registration
- Call management with `DACallService` and CallKit integration
- Push notification handling with `DANotificationHandler`
- Ready-to-use SwiftUI components:
  - Login view (`DALoginView`)
  - Call management view (`DACallView`) with mute, speaker, DTMF controls
  - Dialer view (`DADialView`)
  - All-in-one call screen (`DACallScreen`)
- Integration helpers:
  - AppDelegate integration (`DAAppDelegate`)
  - SwiftUI app integration (`DASwiftUIAppDelegate`)
  - Push notification delegate (`DAPushNotificationDelegate`)
- Sample app demonstrating SDK usage (`DASampleApp`)
- Swift Package Manager support

### Features
- SIP registration with customizable transport (TLS/TCP/UDP)
- Outgoing and incoming calls with CallKit integration
- Call controls (mute, speaker, DTMF)
- Push notification support for background call reception
- Modern Swift implementation with:
  - Swift concurrency (async/await)
  - Actor-based concurrency with @MainActor
  - Combine for reactive state management
  - SwiftUI for the UI layer
  - Proper access control for SDK components

### Technical Details
- Modern Swift 6.0 best practices
- Thread isolation with @MainActor
- Observer pattern for state changes
- Reactive UI updates with Combine publishers
- CallKit integration for native iOS call experience
- iOS 14+ support
