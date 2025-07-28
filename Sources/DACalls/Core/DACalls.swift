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

    /// Call Client
    @Published public private(set) var client: DACallClient = .init(
        name: "", phoneNumber: "", remoteAddress: ""
    )

    /// Private initializer to ensure singleton pattern
    private init() {
        sessionManager = DASessionManager()
        authService = DAAuthService()
        callService = DACallService(sessionManager: sessionManager)
        notificationHandler = DANotificationHandler(
            sessionManager: sessionManager)
    }

    public func setClient(client: DACallClient) {
        self.client = client
    }

    /// Initialize the SDK with specific configuration
    /// - Parameter config: The configuration for the SDK
    public func initialize(
        config: DAConfig, client: DACallClient, logo: String? = "CallKitIcon"
    ) async -> DASessionState {
        sessionManager.initialize(with: config)
        callService.setLogo(logo: logo!)
        self.client = client
        requestMicrophonePermission { granted in
            if granted {
                await self.authService.initialize(
                    sessionManager: self.sessionManager,
                    username: config.username, password: config.password,
                    domain: config.domain
                )
                if await self.authService.registrationState == .registered {
                    await self.sessionManager.shutdown()
                }
            } else {
                if let settingsURL = URL(
                    string: UIApplication.openSettingsURLString)
                {
                    Task { @MainActor in
                        if await UIApplication.shared.canOpenURL(settingsURL) {
                            // Using empty options dictionary which is Sendable
                            await UIApplication.shared.open(
                                settingsURL, options: [:]
                            )
                        }
                    }
                }
            }
        }
        return sessionManager.state
    }

    /// Get microphone permission
    func requestMicrophonePermission(
        completion: @escaping @Sendable (Bool) async -> Void
    ) {
        switch AVAudioSession.sharedInstance().recordPermission {
        case .undetermined:
            AVAudioSession.sharedInstance().requestRecordPermission { granted in
                Task {
                    await completion(granted)
                }
            }
        case .granted, .denied:
            Task {
                await completion(
                    AVAudioSession.sharedInstance().recordPermission == .granted
                )
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
