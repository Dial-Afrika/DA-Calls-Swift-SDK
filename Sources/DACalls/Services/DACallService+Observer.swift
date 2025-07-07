import CallKit
import Foundation

// MARK: - Session State Observer

extension DACallService: @preconcurrency DASessionStateObserver {
    public func onSessionEvent(_ event: DASessionEvent) {
        if case let .call(callEvent) = event {
            switch callEvent {
            case let .incoming(_, from):
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

            case let .terminated(_, reason):
                // Check if this is a call failure or normal termination
                if reason.lowercased().contains("failed") ||
                    reason.lowercased().contains("error") ||
                    reason.lowercased().contains("declined") ||
                    reason.lowercased().contains("rejected")
                {
                    // Handle call failure
                    setCallState(.error("Call failed: \(reason)"))
                } else {
                    // Normal call termination
                    setCallState(.ended)
                }

                // Clean up call state
                setCurrentCall(nil)

                // Clean up CallKit call if it exists
                if let uuid = callUUID {
                    endCallKitCall(uuid: uuid)
                }
                setCallUUID(nil)
                setMicMuted(false)
                setSpeakerEnabled(false)
            }
        }
    }
}
