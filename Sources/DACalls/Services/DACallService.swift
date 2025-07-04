import Foundation
import linphonesw
import CallKit
import Combine
import AVFoundation

/// Service for managing voice calls with CallKit integration
@MainActor
public class DACallService: NSObject {
    /// The core session manager
    private let sessionManager: DASessionManager
    
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
    private var callUUID: UUID?
    
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
        providerConfiguration.supportsVideo = false  // Audio only
        providerConfiguration.supportedHandleTypes = [.generic, .phoneNumber, .emailAddress]
        providerConfiguration.maximumCallsPerCallGroup = 1
        providerConfiguration.maximumCallGroups = 1
        
        // You can customize these properties for your app
        providerConfiguration.iconTemplateImageData = nil  // Replace with your app's call icon
        providerConfiguration.ringtoneSound = "dialafrika_ringtone.wav"  // Custom ringtone
        
        provider = CXProvider(configuration: providerConfiguration)
        provider?.setDelegate(self, queue: nil)
    }
    
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
            let remoteAddress = try Factory.Instance.createAddress(addr: address)
            
            // Create call params
            let params = try core.createCallParams(call: nil)
            params.mediaEncryption = .None  // You can set this to .SRTP for encrypted audio
            params.videoEnabled = false  // Ensure video is disabled
            
            // Start the call using CallKit
            let uuid = UUID()
            self.callUUID = uuid
            
            let handle = CXHandle(type: .generic, value: remoteAddress.asStringUriOnly())
            let startCallAction = CXStartCallAction(call: uuid, handle: handle)
            
            let transaction = CXTransaction(action: startCallAction)
            try await callController.request(transaction).value
            
            // Now make the actual call with liblinphone
            // The core will connect this to the CallKit call
            let call = try core.inviteAddressWithParams(addr: remoteAddress, params: params)
            
            // Update state
            let daCall = DACall(
                callId: call.callLog?.callId ?? "",
                remoteAddress: remoteAddress.asStringUriOnly(),
                direction: .outgoing
            )
            
            self.currentCall = daCall
            self.callState = .outgoingInit
            
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
            if let callUUID = self.callUUID {
                // End call via CallKit
                let endCallAction = CXEndCallAction(call: callUUID)
                let transaction = CXTransaction(action: endCallAction)
                try await callController.request(transaction).value
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
    public func sendDTMF(digit: String) -> Result<Void, DAError> {
        guard let core = sessionManager.core, let call = core.currentCall else {
            return .failure(.noActiveCall)
        }
        
        do {
            try call.sendDtmf(dtmf: digit.first!)
            return .success(())
        } catch {
            return .failure(.callFailed(error.localizedDescription))
        }
    }
    
    /// Report an incoming call to CallKit
    /// - Parameters:
    ///   - call: The incoming call
    ///   - fromAddress: The caller's address
    private func reportIncomingCall(call: linphonesw.Call, fromAddress: String) {
        let uuid = UUID()
        self.callUUID = uuid
        
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: fromAddress)
        update.hasVideo = false
        update.supportsDTMF = true
        update.supportsHolding = true
        update.supportsGrouping = false
        update.supportsUngrouping = false
        
        provider?.reportNewIncomingCall(with: uuid, update: update) { error in
            if let error = error {
                print("Failed to report incoming call: \(error.localizedDescription)")
            }
        }
        
        // Create and update current call
        let daCall = DACall(
            callId: call.callLog?.callId ?? "",
            remoteAddress: fromAddress,
            direction: .incoming
        )
        
        self.currentCall = daCall
        self.callState = .ringing
    }
}
