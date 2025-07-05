import Foundation
import linphonesw

/// Core session manager handling the liblinphone integration
@MainActor
public class DASessionManager {
    /// The underlying linphone Core instance
    @Published public private(set) var core: Core?

    /// The core delegate for handling callbacks
    private var coreDelegate: CoreDelegate?

    /// Current state of the session
    @Published public private(set) var state: DASessionState = .uninitialized

    /// Observers for state changes
    private var stateObservers = [DASessionStateObserver]()

    /// Initialize a new DASessionManager
    init() {}

    /// Configuration used for this session
    public var config: DAConfig?

    /// Initialize the session manager with configuration
    /// - Parameter config: The configuration for the SDK
    @MainActor
    public func initialize(with config: DAConfig) {
        guard state == .uninitialized else {
            print("Session manager is already initialized")
            return
        }

        self.config = config

        // Set logging level
        switch config.debugLevel {
        case .debug:
            LoggingService.Instance.logLevel = .Debug
        case .info:
            LoggingService.Instance.logLevel = .Message
        case .warning:
            LoggingService.Instance.logLevel = .Warning
        case .error:
            LoggingService.Instance.logLevel = .Error
        case .none:
            LoggingService.Instance.logLevel = .Fatal
        }

        do {
            // Initialize the Core
            let factory = Factory.Instance

            if config.useCustomConfigDir, let configDirPath = config.configDirPath {
                core = try factory.createCore(configPath: "\(configDirPath)/config", factoryConfigPath: "", systemContext: nil)
            } else {
                let configDir = factory.getConfigDir(context: nil)
                core = try factory.createCore(configPath: "\(configDir)/config", factoryConfigPath: "", systemContext: nil)
            }

            // Configure core settings
            if let core = core {
                // Configure basic settings
                core.videoCaptureEnabled = false // No video for this SDK
                core.videoDisplayEnabled = false // No video for this SDK

                // Configure CallKit and Push Notifications
                core.callkitEnabled = true
                core.pushNotificationEnabled = config.pushConfig.enabled

                // Configure audio settings
                core.useInfoForDtmf = true
                core.useRfc2833ForDtmf = true

                // Set up the delegate
                setupCoreDelegate()

                try core.start()

                updateState(.ready)
            }
        } catch {
            print("Failed to initialize Core: \(error.localizedDescription)")
            updateState(.error(error.localizedDescription))
        }
    }

    /// Shut down the session manager and release resources
    @MainActor
    public func shutdown() {
        if let core = core {
            core.stop()
            self.core = nil
            updateState(.uninitialized)
        }
    }

    /// Set up the core delegate to handle callbacks
    private func setupCoreDelegate() {
        coreDelegate = CoreDelegateStub(
            onGlobalStateChanged: { [weak self] _, state, _ in
                if state == .On {
                    self?.updateState(.ready)
                } else if state == .Off {
                    self?.updateState(.uninitialized)
                }
            },
            onCallStateChanged: { [weak self] _, call, state, message in
                guard let self = self else { return }

                let callId = String(call.callLog?.callId ?? "")
                switch state {
                case .IncomingReceived, .PushIncomingReceived:
                    let remoteAddress = call.remoteAddress?.asStringUriOnly() ?? "Unknown"
                    self.notifyObservers(event: .call(.incoming(callId: callId, from: remoteAddress)))

                case .OutgoingInit:
                    self.notifyObservers(event: .call(.outgoingInit(callId: callId)))

                case .OutgoingProgress:
                    self.notifyObservers(event: .call(.outgoingProgress(callId: callId)))

                case .OutgoingRinging:
                    self.notifyObservers(event: .call(.outgoingRinging(callId: callId)))

                case .Connected:
                    self.notifyObservers(event: .call(.connected(callId: callId)))

                case .StreamsRunning:
                    self.notifyObservers(event: .call(.streamsRunning(callId: callId)))

                case .Paused, .PausedByRemote:
                    self.notifyObservers(event: .call(.paused(callId: callId, byRemote: state == .PausedByRemote)))

                case .Resuming:
                    self.notifyObservers(event: .call(.resuming(callId: callId)))

                case .End, .Released, .Error:
                    self.notifyObservers(event: .call(.terminated(callId: callId, reason: message)))

                default:
                    break
                }
            },
            onNetworkReachable: { [weak self] _, reachable in
                if reachable {
                    self?.notifyObservers(event: .network(.available))
                } else {
                    self?.notifyObservers(event: .network(.unavailable))
                }
            },
            onAccountRegistrationStateChanged: { [weak self] _, _, state, message in
                guard let self = self else { return }

                switch state {
                case .Ok:
                    self.notifyObservers(event: .registration(.registered))
                case .Progress:
                    self.notifyObservers(event: .registration(.inProgress))
                case .Failed:
                    self.notifyObservers(event: .registration(.failed(message)))
                case .Cleared:
                    self.notifyObservers(event: .registration(.unregistered))
                default:
                    break
                }
            }
        )

        core?.addDelegate(delegate: coreDelegate!)
    }

    /// Update the session state and notify observers
    private func updateState(_ newState: DASessionState) {
        state = newState
        notifyObservers(event: .session(newState))
    }

    /// Add an observer for session events
    /// - Parameter observer: The observer to add
    public func addObserver(_ observer: DASessionStateObserver) {
        if !stateObservers.contains(where: { $0 === observer }) {
            stateObservers.append(observer)
        }
    }

    /// Remove an observer for session events
    /// - Parameter observer: The observer to remove
    public func removeObserver(_ observer: DASessionStateObserver) {
        stateObservers.removeAll(where: { $0 === observer })
    }

    /// Notify all observers of a session event
    /// - Parameter event: The event that occurred
    private func notifyObservers(event: DASessionEvent) {
        for observer in stateObservers {
            observer.onSessionEvent(event)
        }
    }
}

/// Session state representing the current state of the SDK
public enum DASessionState: Equatable {
    /// SDK is not initialized
    case uninitialized

    /// SDK is initializing
    case initializing

    /// SDK is ready for use
    case ready

    /// SDK encountered an error
    case error(String)

    public static func == (lhs: DASessionState, rhs: DASessionState) -> Bool {
        switch (lhs, rhs) {
        case (.uninitialized, .uninitialized),
             (.initializing, .initializing),
             (.ready, .ready):
            return true
        case let (.error(lhsMsg), .error(rhsMsg)):
            return lhsMsg == rhsMsg
        default:
            return false
        }
    }
}

/// Protocol for observing session state changes
public protocol DASessionStateObserver: AnyObject {
    /// Called when a session event occurs
    func onSessionEvent(_ event: DASessionEvent)
}

/// Events that can occur in the session
public enum DASessionEvent {
    /// Session state changed
    case session(DASessionState)

    /// Registration state changed
    case registration(DARegistrationEvent)

    /// Call state changed
    case call(DACallEvent)

    /// Network state changed
    case network(DANetworkEvent)
}

/// Registration events
public enum DARegistrationEvent {
    /// Registration in progress
    case inProgress

    /// Registration successful
    case registered

    /// Registration failed with error message
    case failed(String)

    /// Unregistered
    case unregistered
}

/// Call events
public enum DACallEvent {
    /// Incoming call received
    case incoming(callId: String, from: String)

    /// Outgoing call initiated
    case outgoingInit(callId: String)

    /// Outgoing call in progress
    case outgoingProgress(callId: String)

    /// Outgoing call ringing
    case outgoingRinging(callId: String)

    /// Call connected
    case connected(callId: String)

    /// Media streams running
    case streamsRunning(callId: String)

    /// Call paused
    case paused(callId: String, byRemote: Bool)

    /// Call resuming
    case resuming(callId: String)

    /// Call terminated
    case terminated(callId: String, reason: String)
}

/// Network events
public enum DANetworkEvent {
    /// Network available
    case available

    /// Network unavailable
    case unavailable
}
