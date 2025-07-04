# DialAfrika Calls SDK

A simple SDK wrapper for liblinphone-sdk-swift-ios that allows iOS developers to easily integrate VoIP calling functionality with a custom SIP server. This SDK focuses on voice calls with push notifications (without video or chat functionality).

## Features

- SIP registration and authentication
- Incoming and outgoing calls
- CallKit integration for native iOS call experience
- Push notification support for receiving calls while app is in background
- Ready-to-use UI components for login, dialing, and call management
- Swift 6.0 compatible with modern concurrency support

## Requirements

- iOS 14.0+
- Swift 5.7+
- Xcode 14.0+
- liblinphone-sdk-swift-ios (packaged as dependency)

## Installation

### Swift Package Manager

Add this to your `Package.swift` file:

```swift
dependencies: [
    .package(url: "https://github.com/dialafrika/dacalls-ios-sdk.git", from: "1.0.0")
]
```

### CocoaPods

Add this to your Podfile:

```ruby
pod 'DACalls', '~> 1.0.0'
```

## Usage

### Initialization

Initialize the SDK in your AppDelegate:

```swift
import DACalls

class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize SDK with default configuration
        DACalls.shared.initialize(with: DAConfig())
        
        return true
    }
    
    // Handle push notification token registration
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        DACalls.shared.notificationHandler.handlePushToken(deviceToken)
    }
    
    // Handle incoming push notifications
    func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
        let handled = DACalls.shared.notificationHandler.processRemoteNotification(userInfo)
        completionHandler(handled ? .newData : .noData)
    }
}
```

For SwiftUI apps, you can use our helper:

```swift
import DACalls
import SwiftUI

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(DASwiftUIAppDelegate.self) var appDelegate
    @StateObject var notificationDelegate = DAPushNotificationDelegate()
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### User Authentication

```swift
import DACalls

// Login with SIP credentials
Task {
    let credentials = DAAuthService.Credentials(
        username: "your_username",
        password: "your_password",
        domain: "your_sip_domain.com",
        transportType: .tls
    )
    
    let result = await DACalls.shared.authService.login(with: credentials)
    switch result {
    case .success:
        print("Login successful")
    case .failure(let error):
        print("Login failed: \(error)")
    }
}

// Logout
Task {
    let result = await DACalls.shared.authService.logout()
}
```

### Making and Receiving Calls

```swift
import DACalls

// Make an outgoing call
Task {
    let result = await DACalls.shared.callService.makeCall(to: "sip:user@domain.com")
    switch result {
    case .success(let call):
        print("Call initiated to \(call.remoteAddress)")
    case .failure(let error):
        print("Call failed: \(error)")
    }
}

// Answer an incoming call
Task {
    let result = await DACalls.shared.callService.answerCall()
}

// End a call
Task {
    let result = await DACalls.shared.callService.endCall()
}

// Call control during a call
DACalls.shared.callService.toggleMicrophone() // Mute/unmute
DACalls.shared.callService.toggleSpeaker()    // Enable/disable speaker
DACalls.shared.callService.sendDTMF(digit: "1") // Send DTMF tone
```

### Using the Ready-Made UI Components

For quick integration, you can use our pre-built UI components:

```swift
import SwiftUI
import DACalls

struct ContentView: View {
    var body: some View {
        DACallScreen()  // Complete call screen with login, dialing and call management
    }
}
```

Or use individual components:

```swift
import SwiftUI
import DACalls

struct ContentView: View {
    @State private var showCallView = false
    
    var body: some View {
        if !DACalls.shared.authService.isLoggedIn {
            // Show login screen
            DALoginView(onLoginComplete: { success in
                // Handle login completion
            })
        } else if showCallView {
            // Show active call screen
            DACallView(onCallEnded: {
                showCallView = false
            })
        } else {
            // Show dialer
            DADialView(onCallStarted: {
                showCallView = true
            })
        }
    }
}
```

## Advanced Configuration

You can customize the SDK behavior with the configuration:

```swift
let config = DAConfig(
    debugLevel: .debug,  // More verbose logging
    useCustomConfigDir: true,
    configDirPath: FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!.path,
    pushConfig: DAPushConfig(enabled: true, sandbox: true)
)

DACalls.shared.initialize(with: config)
```

## Observer Pattern for Call Events

To receive call events, implement the observer protocol:

```swift
import DACalls

class CallObserver: DASessionStateObserver {
    init() {
        DACalls.shared.sessionManager.addObserver(self)
    }
    
    func onSessionEvent(_ event: DASessionEvent) {
        switch event {
        case .call(let callEvent):
            switch callEvent {
            case .incoming(let callId, let from):
                print("Incoming call from \(from)")
            case .connected:
                print("Call connected")
            case .terminated(_, let reason):
                print("Call ended: \(reason)")
            default:
                break
            }
        default:
            break
        }
    }
}
```

## Required App Capabilities

Ensure your app has these capabilities enabled in Xcode:

1. Background Modes:
   - Voice over IP
   - Remote notifications
   
2. Push Notifications

3. Add these entries to your Info.plist:
   - Privacy - Microphone Usage Description
   - Privacy - Camera Usage Description (even though we don't use video)

## License

This SDK is provided for exclusive use with DialAfrika services. Contact sales@dialafrika.com for licensing information.

## Support

For support, please contact support@dialafrika.com or visit our developer portal at https://developers.dialafrika.com
