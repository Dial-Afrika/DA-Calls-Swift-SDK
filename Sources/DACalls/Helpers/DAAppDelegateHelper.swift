import Foundation

#if canImport(UIKit)
    import UIKit
#endif

/// Helper methods for integrating DACalls with app delegate methods
@MainActor
public struct DAAppDelegateHelper {
    /// Initialize DACalls SDK in the application delegate
    /// - Parameter application: The UIApplication instance
    /// - Parameter launchOptions: The launch options dictionary
    @MainActor public static func application(
        _: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) async -> Bool {
        // Initialize DACalls SDK with default configuration
        let config = DAConfig()
        await DACalls.shared.initialize(with: config)

        // Handle any push notification in the launch options
        if let remoteNotification = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            _ = DACalls.shared.notificationHandler.handlePushNotification(remoteNotification)
        }

        return true
    }

    /// Handle push notifications registration success
    /// - Parameter application: The UIApplication instance
    /// - Parameter deviceToken: The device token for push notifications
    public static func application(
        _: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        DACalls.shared.notificationHandler.registerPushToken(deviceToken)
    }

    /// Handle push notifications registration failure
    /// - Parameter application: The UIApplication instance
    /// - Parameter error: The error that occurred during registration
    public static func application(
        _: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error
    ) {
        DACalls.shared.notificationHandler.failedToRegisterPushToken(error: error)
    }

    /// Handle received push notifications
    /// - Parameter application: The UIApplication instance
    /// - Parameter userInfo: The notification payload
    /// - Parameter completionHandler: Completion handler to execute when finished processing notification
    public static func application(
        _: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        // Process the notification payload
        let handled = DACalls.shared.notificationHandler.handlePushNotification(userInfo)

        // Call the completion handler
        completionHandler(handled ? .newData : .noData)
    }
}
