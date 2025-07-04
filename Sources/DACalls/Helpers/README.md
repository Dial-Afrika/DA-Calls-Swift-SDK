# DACalls Helpers

This directory contains helper classes and utilities for integrating the DACalls SDK into your iOS application.

## Available Helpers

### DAAppDelegateHelper

A helper class for integrating DACalls with your app's UIApplicationDelegate. It provides methods for handling application lifecycle events and push notifications.

Example usage in your AppDelegate:

```swift
import UIKit
import DACalls

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Initialize DACalls SDK
        return DAAppDelegateHelper.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        DAAppDelegateHelper.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
    }
    
    // Other app delegate methods
}
```

### DASwiftUIAppDelegate

A UIApplicationDelegate implementation for use with SwiftUI's @UIApplicationDelegateAdaptor property wrapper. It automatically handles the initialization of DACalls and processes push notifications.

Example usage in a SwiftUI app:

```swift
import SwiftUI
import DACalls

@main
struct MyApp: App {
    @UIApplicationDelegateAdaptor(DASwiftUIAppDelegate.self) var appDelegate
    
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
```

### DAPushNotificationDelegate

A delegate class for handling push notification events. This can be used to receive callbacks when push notifications are processed.

Example usage:

```swift
import SwiftUI
import DACalls

struct ContentView: View {
    @StateObject var notificationDelegate = DAPushNotificationDelegate()
    
    var body: some View {
        Text("DACalls Demo")
            .onAppear {
                // Register for push notifications
                UIApplication.shared.registerForRemoteNotifications()
            }
    }
}
```
