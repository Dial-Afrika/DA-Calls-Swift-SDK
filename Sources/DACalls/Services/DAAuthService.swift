import Combine
import Foundation
import linphonesw

/// Service for handling authentication and SIP registration
@MainActor
public class DAAuthService {
    /// The core session manager
    private var sessionManager: DASessionManager = .init()

    /// Current registration state
    @Published public private(set) var registrationState: DARegistrationState = .none

    /// Current username
    @Published public private(set) var currentUsername: String = ""

    /// Current domain
    @Published public private(set) var currentDomain: String = ""

    /// Whether user is logged in
    @Published public private(set) var isLoggedIn: Bool = false

    /// Authentication credentials
    public struct Credentials {
        /// Username for SIP authentication
        public var username: String

        /// Password for SIP authentication
        public var password: String

        /// Domain for SIP authentication
        public var domain: String

        /// Transport type for SIP (defaults to TLS)
        public var transportType: DATransportType

        /// Initialize with the required credentials
        public init(
            username: String,
            password: String,
            domain: String,
            transportType: DATransportType = .udp
        ) {
            self.username = username
            self.password = password
            self.domain = domain
            self.transportType = transportType
        }
    }

    /// Initialize a new authentication service
    init() {}

    /// Initialize with configs
    /// - Parameter sessionManager: The session manager instance
    /// - Parameter username: The SIP extension
    /// - Parameter password: The Sip Account Password
    /// - Parameter Domain: The SIP server
    @MainActor
    public func initialize(sessionManager: DASessionManager, username: String, password: String, domain: String) async {
        self.sessionManager = sessionManager
        // Register as observer for session events
        sessionManager.addObserver(self)
        let credentials = Credentials(username: username, password: password, domain: domain)
        await login(with: credentials)
    }

    /// Login to the SIP server with the provided credentials
    /// - Parameter credentials: The authentication credentials
    /// - Returns: A result indicating success or failure
    @discardableResult
    public func login(with credentials: Credentials) async -> Result<Void, DAError> {
        guard let core = sessionManager.core else {
            return .failure(.notInitialized)
        }

        // Update published properties
        currentUsername = credentials.username
        currentDomain = credentials.domain

        // Convert transport type
        let transport: TransportType
        switch credentials.transportType {
        case .tls:
            transport = .Tls
        case .tcp:
            transport = .Tcp
        case .udp:
            transport = .Udp
        }

        do {
            // Create auth info
            let authInfo = try Factory.Instance.createAuthInfo(
                username: credentials.username,
                userid: "",
                passwd: credentials.password,
                ha1: "",
                realm: "",
                domain: credentials.domain
            )

            // Create account params
            let accountParams = try core.createAccountParams()

            // Set identity address
            let identity = try Factory.Instance.createAddress(
                addr: "sip:\(credentials.username)@\(credentials.domain)")
            try accountParams.setIdentityaddress(newValue: identity)

            // Set server address
            let address = try Factory.Instance.createAddress(addr: "sip:\(credentials.domain)")
            try address.setTransport(newValue: transport)
            try accountParams.setServeraddress(newValue: address)

            // Enable registration
            accountParams.registerEnabled = true

            let config = sessionManager.config
            // Enable push notifications if configured
            if config.pushConfig.enabled {
                accountParams.pushNotificationAllowed = true

                // Set appropriate push provider based on sandbox setting
                if config.pushConfig.sandbox {
                    accountParams.pushNotificationConfig?.provider = "apns.dev"
                } else {
                    accountParams.pushNotificationConfig?.provider = "apns"
                }
            }

            // Create account
            let account = try core.createAccount(params: accountParams)

            // Add auth info and account to core
            core.addAuthInfo(info: authInfo)
            try core.addAccount(account: account)

            // Set as default account
            core.defaultAccount = account

            // Update registration state
            registrationState = .inProgress

            return .success(())
        } catch {
            return .failure(.loginFailed(error.localizedDescription))
        }
    }

    /// Logout from the SIP server
    /// - Returns: A result indicating success or failure
    @discardableResult
    public func logout() async -> Result<Void, DAError> {
        guard let core = sessionManager.core else {
            return .failure(.notInitialized)
        }

        if let account = core.defaultAccount {
            // Disable registration
            let params = account.params
            let clonedParams = params?.clone()
            clonedParams?.registerEnabled = false
            account.params = clonedParams

            registrationState = .unregistered
            isLoggedIn = false

            return .success(())
        } else {
            return .failure(.notLoggedIn)
        }
    }

    /// Delete the current account and clear all auth info
    /// - Returns: A result indicating success or failure
    @discardableResult
    public func deleteAccount() async -> Result<Void, DAError> {
        guard let core = sessionManager.core else {
            return .failure(.notInitialized)
        }

        if let account = core.defaultAccount {
            core.removeAccount(account: account)
            core.clearAccounts()
            core.clearAllAuthInfo()

            // Reset state
            currentUsername = ""
            currentDomain = ""
            registrationState = .none
            isLoggedIn = false

            return .success(())
        } else {
            return .failure(.notLoggedIn)
        }
    }
}

// MARK: - Session State Observer

extension DAAuthService: @preconcurrency DASessionStateObserver {
    public func onSessionEvent(_ event: DASessionEvent) {
        if case let .registration(registrationEvent) = event {
            switch registrationEvent {
            case .inProgress:
                registrationState = .inProgress
                isLoggedIn = false
            case .registered:
                registrationState = .registered
                isLoggedIn = true
            case let .failed(message):
                registrationState = .failed(message)
                isLoggedIn = false
            case .unregistered:
                registrationState = .unregistered
                isLoggedIn = false
            }
        }
    }
}

/// Registration state for SIP accounts
public enum DARegistrationState: Equatable {
    /// No registration attempt
    case none

    /// Registration in progress
    case inProgress

    /// Successfully registered
    case registered

    /// Registration failed with error message
    case failed(String)

    /// Unregistered
    case unregistered

    public static func == (lhs: DARegistrationState, rhs: DARegistrationState) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none),
             (.inProgress, .inProgress),
             (.registered, .registered),
             (.unregistered, .unregistered):
            return true
        case let (.failed(lhsMsg), .failed(rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

/// Transport type for SIP communication
public enum DATransportType {
    /// TLS transport (recommended for security)
    case tls

    /// TCP transport
    case tcp

    /// UDP transport
    case udp
}

/// Errors that can occur during authentication
public enum DAError: Error {
    /// SDK is not initialized
    case notInitialized

    /// User is not logged in
    case notLoggedIn

    /// Login failed with error message
    case loginFailed(String)

    /// Invalid parameters
    case invalidParameters(String)

    /// Unknown error
    case unknown(String)

    /// Call failed with error message
    case callFailed(String)

    /// No active call
    case noActiveCall

    /// Not Configured
    case notConfigured
}
