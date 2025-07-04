import Foundation
import CallKit

// MARK: - Session State Observer
extension DACallService: DASessionStateObserver {
    public func onSessionEvent(_ event: DASessionEvent) {
        if case .call(let callEvent) = event {
            switch callEvent {
            case .incoming(let callId, let from):
                // Report incoming call to CallKit if we have a core call
                if let core = sessionManager.core, let call = core.currentCall {
                    reportIncomingCall(call: call, fromAddress: from)
                }
                
            case .outgoingInit:
                callState = .outgoingInit
                
            case .outgoingProgress:
                callState = .outgoingProgress
                
            case .outgoingRinging:
                callState = .outgoingRinging
                
            case .connected:
                callState = .connected
                
            case .streamsRunning:
                callState = .active
                
            case .paused(_, let byRemote):
                callState = byRemote ? .pausedByRemote : .paused
                
            case .resuming:
                callState = .resuming
                
            case .terminated:
                // Reset call state
                callState = .ended
                currentCall = nil
                callUUID = nil
                isMicMuted = false
                isSpeakerEnabled = false
                
            default:
                break
            }
        }
    }
}
