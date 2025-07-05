import Foundation
import linphonesw
import UIKit
import UserNotifications

/// Handler for push notifications
@MainActor
public class DANotificationHandler: NSObject {
    /// The core session manager
    private let sessionManager: DASessionManager

    /// Initialize with session manager
    /// - Parameter sessionManager: The core session manager instance
    init(sessionManager: DASessionManager) {
        self.sessionManager = sessionManager
        super.init()
    }

    /// Register for push notifications
    public func registerForPushNotifications() {
        let center = UNUserNotificationCenter.current()
        center.delegate = self

        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
    }

    /// Handle the push token received from APNs
    /// - Parameter deviceToken: The device token data
    public func registerPushToken(_ deviceToken: Data) {
        // Format token as hex string
        var tokenString = deviceToken.map { String(format: "%02X", $0) }.joined()

        // Add the :voip suffix required by linphone for VoIP pushes
        tokenString.append(String(":voip"))

        // Register token with the core
        if let core = sessionManager.core {
            core.didRegisterForRemotePushWithStringifiedToken(deviceTokenStr: tokenString)
        }
    }

    /// Handle push token registration failure
    /// - Parameter error: The error that occurred during registration
    public func failedToRegisterPushToken(error: Error) {
        // Log the error or handle it appropriately
        print("Failed to register for push notifications: \(error.localizedDescription)")
        // You could also notify observers or store the error state
    }

    /// Process a remote notification
    /// - Parameter userInfo: The notification payload
    /// - Returns: Whether the notification was handled
    public func handlePushNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        // Extract call ID from notification payload
        var callId: String?

        // Try to extract call ID from various possible keys in the payload
        if let id = userInfo["call_id"] as? String {
            callId = id
        } else if let id = userInfo["callId"] as? String {
            callId = id
        } else if let aps = userInfo["aps"] as? [String: Any],
                  let alert = aps["alert"] as? [String: Any],
                  let title = alert["title"] as? String
        {
            callId = title
        }

        return processRemoteNotification(callId)
    }

    /// Process a remote notification with call ID
    /// - Parameter callId: The call ID from the notification
    /// - Returns: Whether the notification was handled
    public func processRemoteNotification(_ callId: String?) -> Bool {
        guard let core = sessionManager.core else {
            return false
        }

        // Process the push notification with the core
        // This will trigger the appropriate callbacks
        core.processPushNotification(callId: callId)
        return true
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension DANotificationHandler: @preconcurrency UNUserNotificationCenterDelegate {
    /// Handle notification presentation when app is in foreground
    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) ->
            Void
    ) {
        // Allow showing notification in foreground
        completionHandler([.sound, .badge])
    }

    /// Handle notification response (user tap)
    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Process the notification payload
        let callId = response.notification.request.content.title
        _ = processRemoteNotification(callId)

        completionHandler()
    }
}
