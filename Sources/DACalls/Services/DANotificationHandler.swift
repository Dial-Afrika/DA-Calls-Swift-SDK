import Foundation
import UIKit
import UserNotifications
import linphonesw

/// Handler for push notifications
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
    public func registerForPushNotifications() -> Result<Void, Error> {
        let center = UNUserNotificationCenter.current()
        center.delegate = self
        
        center.requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        }
        
        return .success(())
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
    @discardableResult
    public func processRemoteNotification(_ userInfo: [AnyHashable: Any]) -> Bool {
        guard let core = sessionManager.core else {
            return false
        }
        
        // Process the push notification with the core
        // This will trigger the appropriate callbacks
        return core.handlePushNotification(userInfo: userInfo)
    }
}

// MARK: - UNUserNotificationCenterDelegate
extension DANotificationHandler: UNUserNotificationCenterDelegate {
    /// Handle notification presentation when app is in foreground
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Allow showing notification in foreground
        completionHandler([.alert, .sound, .badge])
    }
    
    /// Handle notification response (user tap)
    public func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Process the notification payload
        let userInfo = response.notification.request.content.userInfo
        processRemoteNotification(userInfo)
        
        completionHandler()
    }
}
