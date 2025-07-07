# DACalls SDK Integration Guide

## Overview

The DACalls SDK is a comprehensive VoIP calling solution for iOS applications built on top of the Linphone SDK. It provides a complete set of tools for implementing voice calls, including SIP registration, call management, push notifications, and CallKit integration.

## Table of Contents

1. [Installation](#installation)
2. [Project Setup](#project-setup)
3. [Basic Integration](#basic-integration)
4. [UI Components](#ui-components)
5. [Core Features](#core-features)
6. [Advanced Configuration](#advanced-configuration)
7. [Push Notifications](#push-notifications)
8. [CallKit Integration](#callkit-integration)
9. [Testing](#testing)
10. [Troubleshooting](#troubleshooting)

---

## Installation

### Requirements

- iOS 14.0+
- Xcode 13.0+
- Swift 5.5+

### Adding the SDK

#### Option 1: Swift Package Manager (Recommended)

1. Open your project in Xcode
2. File → Add Package Dependencies
3. Add the package URL or select local package
4. Select your target and add the package

#### Option 2: Manual Integration

1. Download the SDK source code
2. Drag the `DACalls` folder into your project
3. Ensure the target membership is set correctly

---

## Project Setup

### 1. App Permissions

Add these permissions to your `Info.plist`:

```xml
<key>NSMicrophoneUsageDescription</key>
<string>This app needs microphone access for voice calls</string>

<key>UIBackgroundModes</key>
<array>
    <string>audio</string>
    <string>voip</string>
</array>
```

### 2. App Delegate Setup

Create an `AppDelegate.swift` file:

```swift
import UIKit
import DACalls

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        // Initialize DACalls SDK
        return DAAppDelegateHelper.application(
            application,
            didFinishLaunchingWithOptions: launchOptions
        )
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        DAAppDelegateHelper.application(
            application,
            didRegisterForRemoteNotificationsWithDeviceToken: deviceToken
        )
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        DAAppDelegateHelper.application(
            application,
            didFailToRegisterForRemoteNotificationsWithError: error
        )
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        DAAppDelegateHelper.application(
            application,
            didReceiveRemoteNotification: userInfo,
            fetchCompletionHandler: completionHandler
        )
    }
}
```

### 3. Main App Integration

Update your main app file:

```swift
import SwiftUI

@main
struct YourApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

---

## Basic Integration

### 1. SDK Initialization

Initialize the SDK in your app:

```swift
import DACalls

// Initialize with default configuration
let config = DAConfig()
DACalls.shared.initialize(with: config)
```

### 2. SIP Registration

Register with your SIP server:

```swift
// Configure SIP credentials
let result = await DACalls.shared.authService.register(
    username: "your_username",
    password: "your_password",
    domain: "your_sip_domain.com"
)

switch result {
case .success:
    print("SIP registration successful")
case .failure(let error):
    print("SIP registration failed: \(error)")
}
```

### 3. Making Calls

```swift
// Make an outgoing call
let result = await DACalls.shared.callService.makeCall(to: "sip:user@domain.com")

switch result {
case .success(let call):
    print("Call initiated to: \(call.remoteAddress)")
case .failure(let error):
    print("Call failed: \(error)")
}
```

### 4. Handling Incoming Calls

```swift
// Answer an incoming call
let result = await DACalls.shared.callService.answerCall()

switch result {
case .success:
    print("Call answered")
case .failure(let error):
    print("Failed to answer call: \(error)")
}
```

---

## UI Components

The SDK provides pre-built UI components for common VoIP operations:

### 1. Call View Model

Use `DACallViewModel` to manage call state:

```swift
import SwiftUI
import DACalls

struct CallView: View {
    @StateObject private var viewModel = DACallViewModel()

    var body: some View {
        VStack {
            // Call status
            Text(viewModel.callStatusText)

            // Call duration (if active)
            if viewModel.isCallActive {
                Text(viewModel.callDuration)
            }

            // Call controls
            CallControlsView(viewModel: viewModel)
        }
    }
}
```

### 2. Dial Pad View

```swift
import SwiftUI
import DACalls

struct DialerView: View {
    @State private var phoneNumber = ""

    var body: some View {
        VStack {
            // Phone number display
            TextField("Phone Number", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            // Dial pad
            DADialPadView { digit in
                if let char = Character(UnicodeScalar(Int(digit))!) {
                    phoneNumber.append(char)
                }
            }

            // Call button
            Button("Call") {
                makeCall()
            }
            .disabled(phoneNumber.isEmpty)
        }
    }

    private func makeCall() {
        Task {
            await DACalls.shared.callService.makeCall(to: phoneNumber)
        }
    }
}
```

### 3. Call Controls

```swift
struct CallControlsView: View {
    @ObservedObject var viewModel: DACallViewModel

    var body: some View {
        HStack(spacing: 40) {
            // Mute button
            Button(action: {
                viewModel.toggleMute()
            }) {
                Image(systemName: viewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.isMuted ? .red : .primary)
            }
            .frame(width: 60, height: 60)
            .background(Color.gray.opacity(0.2))
            .clipShape(Circle())

            // Speaker button
            Button(action: {
                viewModel.toggleSpeaker()
            }) {
                Image(systemName: viewModel.isSpeakerOn ? "speaker.wave.3.fill" : "speaker.fill")
                    .font(.title2)
                    .foregroundColor(viewModel.isSpeakerOn ? .blue : .primary)
            }
            .frame(width: 60, height: 60)
            .background(Color.gray.opacity(0.2))
            .clipShape(Circle())

            // End call button
            Button("End Call") {
                Task {
                    await viewModel.endCall()
                }
            }
            .buttonStyle(.borderedProminent)
            .tint(.red)
        }
    }
}
```

---

## Core Features

### 1. Call Management

```swift
// Get current call state
let callState = DACalls.shared.callService.callState

// Check if call is active
let isActive = DACalls.shared.callService.isCallActive

// Get current call information
if let currentCall = DACalls.shared.callService.currentCall {
    print("Current call: \(currentCall.remoteAddress)")
}
```

### 2. Audio Controls

```swift
// Toggle microphone
let isMuted = DACalls.shared.callService.toggleMicrophone()

// Toggle speaker
let isSpeakerOn = DACalls.shared.callService.toggleSpeaker()

// Send DTMF tones
DACalls.shared.callService.sendDTMF(digit: CChar(UnicodeScalar("1")!.value))
```

### 3. Call State Observation

```swift
import Combine

class CallManager: ObservableObject {
    private var cancellables = Set<AnyCancellable>()

    init() {
        // Observe call state changes
        DACalls.shared.callService.$callState
            .receive(on: DispatchQueue.main)
            .sink { state in
                switch state {
                case .idle:
                    print("No active call")
                case .connecting:
                    print("Call is connecting")
                case .active:
                    print("Call is active")
                case .ended:
                    print("Call has ended")
                case .error(let message):
                    print("Call error: \(message)")
                default:
                    break
                }
            }
            .store(in: &cancellables)
    }
}
```

---

## Advanced Configuration

### Custom Configuration

```swift
// Create custom configuration
let config = DAConfig()

// Configure SIP transport
config.sipTransport = .tcp // or .udp, .tls

// Configure audio codecs
config.audioCodecs = ["PCMU", "PCMA", "G722"]

// Configure video codecs (if needed)
config.videoCodecs = ["H264", "VP8"]

// Configure STUN server
config.stunServer = "stun.example.com"

// Initialize with custom config
DACalls.shared.initialize(with: config)
```

### Network Configuration

```swift
// Configure network settings
config.networkSettings = DANetworkSettings(
    adaptiveRateControl: true,
    enableIpv6: true,
    mtu: 1300
)
```

---

## Push Notifications

### 1. Registration

Push notifications are automatically handled by the SDK when using `DAAppDelegateHelper`.

### 2. Custom Push Handling

If you need custom push notification handling:

```swift
// Register for push notifications
DACalls.shared.notificationHandler.registerForPushNotifications()

// Handle push token
func application(
    _ application: UIApplication,
    didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
) {
    DACalls.shared.notificationHandler.registerPushToken(deviceToken)
}

// Handle push notification
func application(
    _ application: UIApplication,
    didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
) {
    let handled = DACalls.shared.notificationHandler.handlePushNotification(userInfo)
    completionHandler(handled ? .newData : .noData)
}
```

---

## CallKit Integration

CallKit integration is automatically handled by the SDK. The SDK will:

- Register with CallKit for incoming calls
- Display native iOS call interface
- Handle call actions (answer, decline, hold, etc.)
- Manage audio session

### Customizing CallKit

```swift
// Access CallKit provider configuration
let callKitProvider = DACalls.shared.callService.callKitProvider

// Customize provider configuration
callKitProvider.configuration.localizedName = "Your App Name"
callKitProvider.configuration.ringtoneSound = "your_ringtone.caf"
```

---

## Testing

### 1. Simulator Testing

Limited functionality on simulator:

- UI components work
- SDK initialization works
- SIP registration may work
- Audio/CallKit features don't work

### 2. Device Testing

Full functionality on physical devices:

- Complete VoIP calling
- Push notifications
- CallKit integration
- Audio features

### 3. Test App Example

```swift
struct TestApp: View {
    @State private var phoneNumber = ""
    @StateObject private var callViewModel = DACallViewModel()

    var body: some View {
        VStack {
            TextField("Phone Number", text: $phoneNumber)
                .textFieldStyle(RoundedBorderTextFieldStyle())

            Button("Call") {
                Task {
                    await DACalls.shared.callService.makeCall(to: phoneNumber)
                }
            }

            if callViewModel.isCallActive {
                CallView(viewModel: callViewModel)
            }
        }
        .padding()
    }
}
```

---

## Troubleshooting

### Common Issues

1. **SDK Not Initializing**
   - Check if `DAAppDelegateHelper` is properly integrated
   - Verify permissions are granted
   - Check for initialization errors in logs

2. **Calls Not Connecting**
   - Verify SIP credentials are correct
   - Check network connectivity
   - Ensure SIP server is reachable

3. **Audio Issues**
   - Test on physical device (not simulator)
   - Check microphone permissions
   - Verify audio session configuration

4. **Push Notifications Not Working**
   - Test on physical device
   - Check push notification certificates
   - Verify VoIP push entitlements

### Debug Logging

Enable detailed logging:

```swift
// Enable debug logging
DACalls.shared.enableDebugLogging(true)
```

### Error Handling

```swift
// Handle errors gracefully
let result = await DACalls.shared.callService.makeCall(to: address)

switch result {
case .success(let call):
    // Handle successful call
    print("Call initiated: \(call.remoteAddress)")

case .failure(let error):
    // Handle error
    switch error {
    case .notInitialized:
        print("SDK not initialized")
    case .notRegistered:
        print("SIP not registered")
    case .callFailed(let message):
        print("Call failed: \(message)")
    case .noActiveCall:
        print("No active call")
    }
}
```

---

## API Reference

### Main Classes

- `DACalls` - Main SDK entry point
- `DACallService` - Call management
- `DAAuthService` - SIP authentication
- `DANotificationHandler` - Push notifications
- `DACallViewModel` - UI state management

### UI Components

- `DADialPadView` - Dial pad interface
- `DACallView` - Call interface
- `DALoginView` - SIP login interface

### Configuration

- `DAConfig` - SDK configuration
- `DANetworkSettings` - Network configuration

### Models

- `DACall` - Call information
- `DACallState` - Call state enumeration
- `DAError` - Error types

---

## Best Practices

1. **Always test on physical devices** for VoIP functionality
2. **Handle errors gracefully** with proper user feedback
3. **Use the provided UI components** for consistent experience
4. **Implement proper state management** with view models
5. **Test push notifications** thoroughly
6. **Follow iOS audio session guidelines**
7. **Implement CallKit properly** for native experience

---

## Support

For issues and questions:

1. Check the troubleshooting section
2. Review the example implementations
3. Test on physical devices
4. Check SIP server configuration
5. Verify network connectivity

This integration guide provides everything needed to successfully implement the DACalls SDK in your iOS application.
