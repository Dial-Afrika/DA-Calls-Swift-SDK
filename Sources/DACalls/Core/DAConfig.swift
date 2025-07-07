import Foundation

/// Configuration for initializing the DACalls SDK
public struct DAConfig {
    /// Debug level for logging
    public let debugLevel: DALogLevel

    /// Whether to use custom configuration directory
    public let useCustomConfigDir: Bool

    /// Custom configuration directory path (if useCustomConfigDir is true)
    public let configDirPath: String?

    /// Push notification configuration
    public let pushConfig: DAPushConfig

    /// Credentials for SipServer
    public let username: String
    public let password: String
    public let domain: String

    /// Initialize with default values
    public init(
        debugLevel: DALogLevel = .info,
        useCustomConfigDir: Bool = false,
        configDirPath: String? = nil,
        pushConfig: DAPushConfig = DAPushConfig(),
        username: String = "",
        password: String = "",
        domain: String = ""
    ) {
        self.debugLevel = debugLevel
        self.useCustomConfigDir = useCustomConfigDir
        self.configDirPath = configDirPath
        self.pushConfig = pushConfig
        self.username = username
        self.password = password
        self.domain = domain
    }
}

/// Log levels for the SDK
public enum DALogLevel {
    /// Debug level logging (most verbose)
    case debug
    /// Info level logging
    case info
    /// Warning level logging
    case warning
    /// Error level logging (least verbose)
    case error
    /// No logging
    case none
}

/// Push notification configuration
public struct DAPushConfig {
    /// Whether push notifications are enabled
    public let enabled: Bool

    /// Whether to use sandbox environment for push notifications
    public let sandbox: Bool

    /// Initialize with default values
    public init(enabled: Bool = true, sandbox: Bool = true) {
        self.enabled = enabled
        self.sandbox = sandbox
    }
}
