import Foundation
import linphonesw

/// Main entry point to access all functionality of the DACalls SDK
@MainActor
public class DACalls {
    /// Shared instance of the SDK (Singleton)
    public static let shared = DACalls()

    /// The core session manager that handles the liblinphone integration
    public private(set) var sessionManager: DASessionManager

    /// The authentication service for SIP registration
    public private(set) var authService: DAAuthService

    /// The call service for managing voice calls
    public private(set) var callService: DACallService

    /// The notification handler for push notifications
    public private(set) var notificationHandler: DANotificationHandler

    /// Private initializer to ensure singleton pattern
    private init() {
        sessionManager = DASessionManager()
        authService = DAAuthService(sessionManager: sessionManager)
        callService = DACallService(sessionManager: sessionManager)
        notificationHandler = DANotificationHandler(sessionManager: sessionManager)
    }

    /// Initialize the SDK with specific configuration
    /// - Parameter config: The configuration for the SDK
    public func initialize(with config: DAConfig) {
        sessionManager.initialize(with: config)
    }

    /// Shut down the SDK gracefully
    public func shutdown() {
        sessionManager.shutdown()
    }
}
