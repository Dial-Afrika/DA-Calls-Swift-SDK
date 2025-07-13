import Combine
import Foundation
import SwiftUI

/// View model for the call view
@MainActor
public class DACallViewModel: ObservableObject {
    @Published public var callStatusText: String = "Connecting..."
    @Published public var remoteParty: String = ""
    @Published public var callDuration: String = "00:00"
    @Published public var isIncomingCall: Bool = false
    @Published public var isOutgoingCall: Bool = false
    @Published public var isCallActive: Bool = false
    @Published public var isMuted: Bool = false
    @Published public var isSpeakerOn: Bool = false
    @Published public var isPaused: Bool = false
    @Published public var callEnded: Bool = false
    @Published public var showKeypad: Bool = false

    private var cancellables = Set<AnyCancellable>()
    private var durationTimer: Timer?
    private var callStartTime: Date?

    public init() {
        setupObservers()
    }

    deinit {
        durationTimer?.invalidate()
    }

    private func setupObservers() {
        // Observe current call
        DACalls.shared.callService.$currentCall
            .receive(on: DispatchQueue.main)
            .sink { [weak self] call in
                guard let self = self else { return }

                if let call = call {
                    self.remoteParty = call.remoteAddress
                    self.isIncomingCall = call.direction == .incoming
                    self.isOutgoingCall = call.direction == .outgoing
                } else {
                    // No call, view should be dismissed
                    self.stopTimer()
                    self.callEnded = true
                }
            }
            .store(in: &cancellables)

        // Observe call state
        DACalls.shared.callService.$callState
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self = self else { return }

                switch state {
                case .idle:
                    self.callStatusText = "No Call"
                    self.isCallActive = false
                    self.stopTimer()

                case .outgoingInit:
                    self.callStatusText = "Calling..."
                    self.isCallActive = false
                    self.isOutgoingCall = true

                case .outgoingProgress:
                    self.callStatusText = "Calling..."
                    self.isCallActive = false

                case .outgoingRinging:
                    self.callStatusText = "Ringing..."
                    self.isCallActive = false

                case .ringing:
                    self.callStatusText = "Incoming Call"
                    self.isCallActive = false

                case .connecting:
                    self.callStatusText = "Connecting..."
                    self.isCallActive = false

                case .connected, .active:
                    self.callStatusText = "Connected"
                    self.isCallActive = true
                    self.startTimer()

                case .paused:
                    self.callStatusText = "On Hold"
                    self.isCallActive = true

                case .pausedByRemote:
                    self.callStatusText = "On Hold by Remote"
                    self.isCallActive = true

                case .resuming:
                    self.callStatusText = "Resuming..."
                    self.isCallActive = true

                case .startingViaCallKit:
                    self.callStatusText = "Connecting..."
                    self.isCallActive = false

                case .ended:
                    self.callStatusText = "Call Ended"
                    self.isCallActive = false
                    self.stopTimer()

                case let .error(message):
                    self.callStatusText = "Call Failed: \(message)"
                    self.isCallActive = false
                    self.stopTimer()
                }
            }
            .store(in: &cancellables)

        // Observe mute state
        DACalls.shared.callService.$isMicMuted
            .receive(on: DispatchQueue.main)
            .sink { [weak self] muted in
                self?.isMuted = muted
            }
            .store(in: &cancellables)

        // Observe speaker state
        DACalls.shared.callService.$isSpeakerEnabled
            .receive(on: DispatchQueue.main)
            .sink { [weak self] speakerOn in
                self?.isSpeakerOn = speakerOn
            }
            .store(in: &cancellables)

        // Observe hold state
        DACalls.shared.callService.$isPaused
            .receive(on: DispatchQueue.main)
            .sink { [weak self] onHold in
                self?.isPaused = onHold
            }
            .store(in: &cancellables)
    }

    /// Start call duration timer
    private func startTimer() {
        stopTimer()
        callStartTime = Date()

        durationTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            Task { @MainActor in
                guard let self = self, let startTime = self.callStartTime else { return }

                let duration = Int(Date().timeIntervalSince(startTime))
                let minutes = duration / 60
                let seconds = duration % 60
                self.callDuration = String(format: "%02d:%02d", minutes, seconds)
            }
        }
    }

    /// Stop call duration timer
    private func stopTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
        callStartTime = nil
    }

    /// Answer an incoming call
    @MainActor
    public func answerCall() async {
        _ = await DACalls.shared.callService.answerCall()
    }

    /// End the current call
    @MainActor
    public func endCall() async {
        _ = await DACalls.shared.callService.endCall()
    }

    /// Toggle microphone mute state
    public func toggleMute() {
        isMuted = DACalls.shared.callService.toggleMicrophone()
    }

    /// Toggle microphone mute state
    public func toggleHold() {
        isMuted = DACalls.shared.callService.toggleCallHold()
    }

    /// Toggle speaker state
    public func toggleSpeaker() {
        isSpeakerOn = DACalls.shared.callService.toggleSpeaker()
    }

    /// Send DTMF tone
    public func sendDTMF(digit: CChar) {
        _ = DACalls.shared.callService.sendDTMF(digit: digit)
    }
}
