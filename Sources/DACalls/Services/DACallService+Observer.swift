import CallKit
import Foundation

// MARK: - Session State Observer

extension DACallService: DASessionStateObserver {
    public func onSessionEvent(_ event: DASessionEvent) {
        if case let .call(callEvent) = event {
            switch callEvent {
            case let .incoming(callId, from):
                // Report incoming call to CallKit if we have a core call
                if let core = sessionManager.core, let call = core.currentCall {
                    reportIncomingCall(call: call, fromAddress: from)
                }

            case .outgoingInit:
                setCallState(.outgoingInit)

            case .outgoingProgress:
                setCallState(.outgoingProgress)

            case .outgoingRinging:
                setCallState(.outgoingRinging)

            case .connected:
                setCallState(.connected)

            case .streamsRunning:
                setCallState(.active)

            case let .paused(_, byRemote):
                setCallState(byRemote ? .pausedByRemote : .paused)

            case .resuming:
                setCallState(.resuming)

            case .terminated:
                // Reset call state
                setCallState(.ended)
                setCurrentCall(nil)
                setCallUUID(nil)
                setMicMuted(false)
                setSpeakerEnabled(false)
            }
        }
    }
}
