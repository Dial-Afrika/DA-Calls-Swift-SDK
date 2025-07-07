import Foundation
#if canImport(UIKit)
    import SwiftUI
    import UIKit

    /// A UIApplicationDelegate class for use with SwiftUI's @UIApplicationDelegateAdaptor
    public class DASwiftUIAppDelegate: NSObject, UIApplicationDelegate {
        public func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) async -> Bool {
            return await DAAppDelegateHelper.application(application, didFinishLaunchingWithOptions: launchOptions)
        }

        public func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
            DAAppDelegateHelper.application(application, didRegisterForRemoteNotificationsWithDeviceToken: deviceToken)
        }

        public func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
            DAAppDelegateHelper.application(application, didFailToRegisterForRemoteNotificationsWithError: error)
        }

        public func application(_ application: UIApplication, didReceiveRemoteNotification userInfo: [AnyHashable: Any], fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void) {
            DAAppDelegateHelper.application(application, didReceiveRemoteNotification: userInfo, fetchCompletionHandler: completionHandler)
        }
    }

    /// A delegate class for handling push notification events
    public class DAPushNotificationDelegate: NSObject, ObservableObject {
        override public init() {
            super.init()
        }
    }
#endif
