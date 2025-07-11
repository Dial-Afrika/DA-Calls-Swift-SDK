import AVFoundation
import Foundation
import linphonesw
import UIKit

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
        authService = DAAuthService()
        callService = DACallService(sessionManager: sessionManager)
        notificationHandler = DANotificationHandler(sessionManager: sessionManager)
    }

    /// Initialize the SDK with specific configuration
    /// - Parameter config: The configuration for the SDK
    public func initialize(with config: DAConfig) async {
        sessionManager.initialize(with: config)
        requestMicrophonePermission { granted in
            if granted {
                await self.authService.initialize(sessionManager: self.sessionManager, username: config.username, password: config.password, domain: config.domain)
            } else {
                if let settingsURL = URL(string: UIApplication.openSettingsURLString),
                   UIApplication.shared.canOpenURL(settingsURL)
                {
                    await UIApplication.shared.open(settingsURL)
                }
            }
        }
    }

    /// Get microphone permission
    func requestMicrophonePermission(completion: @escaping @Sendable (Bool) async -> Void) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task {
                    await completion(granted)
                }
            }
        case .granted, .denied:
            Task {
                await completion(AVAudioSession.sharedInstance().recordPermission == .granted)
            }
        @unknown default:
            Task {
                await completion(false)
            }
        }
    }

    /// Shut down the SDK gracefully
    public func shutdown() {
        sessionManager.shutdown()
    }
}
