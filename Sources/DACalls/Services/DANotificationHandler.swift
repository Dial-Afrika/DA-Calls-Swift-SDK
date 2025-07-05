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
    /// - Returns: Result indicating success or failure
    // public func registerForPushNotifications() -> Result<Void, Error> {
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

        // return .success(())
    }

    /// Handle the push token received from APNs
    /// - Parameter deviceToken: The device token data
    public func handlePushToken(_ deviceToken: Data) {
        // Format token as hex string
        var tokenString = deviceToken.map { String(format: "%02X", $0) }.joined()

        // Add the :voip suffix required by linphone for VoIP pushes
        tokenString.append(String(":voip"))

        // Register token with the core
        if let core = sessionManager.core {
            core.didRegisterForRemotePushWithStringifiedToken(deviceTokenStr: tokenString)
        }
    }

    /// Process a remote notification
    /// - Parameter userInfo: The notification payload
    /// - Returns: Whether the notification was handled
    public func processRemoteNotification(_ callId: String?) -> Result<Void, Error> {
        if let core = sessionManager.core {
            // Process the push notification with the core
            // This will trigger the appropriate callbacks
            core.processPushNotification(callId: callId)
            return .success(())
        }
        return .failure()
    }
}

// MARK: - UNUserNotificationCenterDelegate

extension DANotificationHandler: @preconcurrency UNUserNotificationCenterDelegate {
    /// Handle notification presentation when app is in foreground
    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent _: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
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
        // let userInfo = response.notification.request.content.userInfo
        // TODO: Revisit this
        let callid = response.notification.request.content.title
        processRemoteNotification(callid)

        completionHandler()
    }
}
