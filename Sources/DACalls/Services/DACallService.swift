import AVFoundation
import CallKit

// import Combine
import Foundation
import linphonesw
import UIKit

/// Service for managing voice calls with CallKit integration
@MainActor
public class DACallService: NSObject {
    /// The CallKit provider
    private var provider: CXProvider?

    /// The CallKit call controller
    private let callController = CXCallController()

    /// Current active call
    @Published public private(set) var currentCall: DACall?

    /// Current call state
    @Published public private(set) var callState: DACallState = .idle

    /// Whether microphone is muted
    @Published public private(set) var isMicMuted: Bool = false

    /// Whether speaker is enabled
    @Published public private(set) var isSpeakerEnabled: Bool = false

    /// UUID for CallKit to identify the call
    @Published public private(set) var callUUID: UUID?

    /// Whether Call is on hold
    @Published public private(set) var isPaused: Bool = false

    /// Call Kit App Logo
    @Published public private(set) var logo: Data = .init()

    /// Call Client
    @Published public private(set) var client: DACallClient = .init(
        name: "", phoneNumber: "", remoteAddress: ""
    )

    /// Set the current call
    /// - Parameter call: The call to set as current
    public func setCurrentCall(_ call: DACall?) {
        currentCall = call
    }

    /// Set the call state
    /// - Parameter state: The new call state
    public func setCallState(_ state: DACallState) {
        callState = state
    }

    /// Set the microphone mute state
    /// - Parameter isMuted: Whether the microphone is muted
    public func setMicMuted(_ isMuted: Bool) {
        isMicMuted = isMuted
    }

    /// Set  call isPaused or on Hold
    /// - Parameter isPaused: Where the call is paused
    public func setIsPaused(_ state: Bool) {
        isPaused = state
    }

    /// Set the CallUUID
    /// - Parameter uuid: the new uuid
    public func setCallUUID(_ uuid: UUID?) {
        callUUID = uuid
    }

    /// Set the speaker state
    /// - Parameter isEnabled: Whether the speaker is enabled
    public func setSpeakerEnabled(_ isEnabled: Bool) {
        isSpeakerEnabled = isEnabled
    }

    /// Set the Sevice Client
    /// - Parameter client: service client
    public func setClient(client: DACallClient) {
        self.client = client
    }

    /// Set the Sevice Client
    /// - Parameter client: service client
    public func setLogo(logo: String) {
        if let uiImage = UIImage(named: logo),
           let data = uiImage.pngData()
        {
            self.logo = data
        }
    }

    /// Initialize the call service
    /// - Parameter sessionManager: The core session manager
    init(sessionManager: DASessionManager) {
        self.sessionManager = sessionManager
        super.init()

        // Register as observer for session events
        sessionManager.addObserver(self)

        // Set up CallKit provider
        setupCallKitProvider()
    }

    /// Set up the CallKit provider with configuration
    private func setupCallKitProvider() {
        let providerConfiguration = CXProviderConfiguration()
        providerConfiguration.supportsVideo = false
        providerConfiguration.supportedHandleTypes = [
            .generic, .phoneNumber, .emailAddress,
        ]
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1

        providerConfiguration.iconTemplateImageData = logo

        provider = CXProvider(configuration: providerConfiguration)
        provider?.setDelegate(self, queue: nil)
    }

    /// The core session manager
    public let sessionManager: DASessionManager

    // MARK: Make Call

    /// Make an outgoing call
    /// - Parameter address: The SIP address to call
    /// - Returns: Result with the call object or an error
    @discardableResult
    public func makeCall(to address: String) async -> Result<DACall, DAError> {
        guard let core = sessionManager.core else {
            return .failure(.notInitialized)
        }

        do {
            // Create the remote address
            let addr = "sip:\(address)@\(sessionManager.config.domain)"
            let remoteAddress = try Factory.Instance.createAddress(addr: addr)
            try remoteAddress.setDisplayname(newValue: client.name)
            // Create call params
            let params = try core.createCallParams(call: nil)
            params.mediaEncryption = .None
            params.videoEnabled = false
            params.audioEnabled = true

            // CallKit
            let uuid = UUID()
            callUUID = uuid
            let handle = CXHandle(
                type: .generic,
                value: remoteAddress.username ?? "Unknown"
            )

            let startCallAction = CXStartCallAction(call: uuid, handle: handle)

            let transaction = CXTransaction(action: startCallAction)
            try await callController.request(transaction)

            let call = core.inviteAddressWithParams(
                addr: remoteAddress, params: params
            )

            // Update state
            let daCall = DACall(
                callId: call?.callLog?.callId ?? "",
                remoteAddress: remoteAddress.asStringUriOnly(),
                direction: .outgoing,
                client: client
            )

            currentCall = daCall
            callState = .outgoingInit

            return .success(daCall)
        } catch {
            return .failure(.callFailed(error.localizedDescription))
        }
    }

    /// Answer an incoming call
    /// - Returns: Result indicating success or failure
    @discardableResult
    public func answerCall() async -> Result<Void, DAError> {
        guard let core = sessionManager.core, let call = core.currentCall else {
            return .failure(.noActiveCall)
        }

        do {
            // Configure audio session before answering the call
            core.configureAudioSession()

            // Answer the call
            try call.accept()

            // Update state
            callState = .connecting

            return .success(())
        } catch {
            return .failure(.callFailed(error.localizedDescription))
        }
    }

    /// End the current call
    /// - Returns: Result indicating success or failure
    @discardableResult
    public func endCall() async -> Result<Void, DAError> {
        guard let core = sessionManager.core else {
            return .failure(.notInitialized)
        }

        do {
            if let callUUID = callUUID {
                // End call via CallKit
                let endCallAction = CXEndCallAction(call: callUUID)
                let transaction = CXTransaction(action: endCallAction)
                try await callController.request(transaction)
            }

            // Also terminate the call in the core
            if let call = core.currentCall {
                try call.terminate()
            }

            return .success(())
        } catch {
            return .failure(.callFailed(error.localizedDescription))
        }
    }

    /// Toggle microphone mute state
    /// - Returns: New mute state
    @discardableResult
    public func toggleMicrophone() -> Bool {
        guard let core = sessionManager.core else {
            return false
        }

        core.micEnabled = !core.micEnabled
        isMicMuted = !core.micEnabled
        return isMicMuted
    }

    /// Toggle call paused state
    /// - Returns: New paused state
    @discardableResult
    public func toggleCallHold(targetRemote: String? = nil) -> Bool {
        guard let core = sessionManager.core else {
            return false
        }

        let calls = core.calls

        // 1️⃣ If any call is active, pause it
        if let active = calls.first(where: { $0.state == .StreamsRunning }) {
            do {
                try active.pause()
                isPaused = true
                return true
            } catch {
                return false
            }
        }

        // 2️⃣ Look for a paused call to resume
        let pausedCalls = calls.filter { $0.state == .Paused }

        // 3️⃣ Choose the correct paused call
        let callToResume: Call?
        if let remote = targetRemote {
            callToResume = pausedCalls.first {
                $0.remoteAddress?.asString() == remote
            }
        } else {
            callToResume = pausedCalls.first
        }

        guard let call = callToResume else {
            return false
        }

        do {
            try call.resume()
            isPaused = false
            return true
        } catch {
            print("Error resuming call:", error)
            return false
        }
    }

    /// Toggle speaker state
    /// - Returns: New speaker state
    @discardableResult
    public func toggleSpeaker() -> Bool {
        guard let core = sessionManager.core, let call = core.currentCall else {
            return false
        }

        // Get current audio device
        let currentAudioDevice = call.outputAudioDevice
        let speakerEnabled = currentAudioDevice?.type == .Speaker

        // Toggle between speaker and earpiece
        for audioDevice in core.audioDevices {
            if speakerEnabled && audioDevice.type == .Microphone {
                call.outputAudioDevice = audioDevice
                isSpeakerEnabled = false
                return false
            } else if !speakerEnabled && audioDevice.type == .Speaker {
                call.outputAudioDevice = audioDevice
                isSpeakerEnabled = true
                return true
            }
        }

        return isSpeakerEnabled
    }

    /// Send DTMF tone
    /// - Parameter digit: The DTMF digit to send
    /// - Returns: Result indicating success or failure
    @discardableResult
    public func sendDTMF(digit: Int8) -> Result<Void, DAError> {
        guard let core = sessionManager.core, let call = core.currentCall else {
            return .failure(.noActiveCall)
        }

        do {
            try call.sendDtmf(dtmf: digit)
            return .success(())
        } catch {
            return .failure(.callFailed(error.localizedDescription))
        }
    }

    // MARK: Report Incoming Call

    /// Report an incoming call to CallKit
    /// - Parameters:
    ///   - call: The incoming call
    ///   - fromAddress: The caller's address
    public func reportIncomingCall(call: Call, fromAddress _: String) {
        let uuid = UUID()
        callUUID = uuid

        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(
            type: .generic,
            value: call.remoteAddress?.displayName ?? call.remoteAddress?
                .username ?? "Unknown"
        )
        update.hasVideo = false
        update.supportsDTMF = true
        update.supportsHolding = true
        update.supportsGrouping = false
        update.supportsUngrouping = false
        update.localizedCallerName =
            call.remoteAddress?.displayName?.capitalized ?? call.remoteAddress?.username?.capitalized
                ?? "Unknown"

        provider?.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print(
                    "Failed to report incoming call: \(error.localizedDescription)"
                )
            }
        }

        // Create and update current call
        let daCall = DACall(
            callId: call.callLog?.callId ?? "",
            remoteAddress: call.remoteAddress?.displayName ?? call
                .remoteAddress?.username ?? "Unknown",
            direction: .incoming,
            client: client
        )

        currentCall = daCall
        callState = .ringing
    }

    /// End a CallKit call programmatically
    /// - Parameter uuid: The UUID of the call to end
    public func endCallKitCall(uuid: UUID) {
        let endCallAction = CXEndCallAction(call: uuid)
        let transaction = CXTransaction(action: endCallAction)

        callController.request(transaction) { error in
            if let error = error {
                print(
                    "Failed to end CallKit call: \(error.localizedDescription)")
            }
        }
    }
}
