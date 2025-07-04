import Foundation

/// Representation of a call
public struct DACall {
    /// Unique identifier for the call
    public let callId: String
    
    /// Remote address (SIP URI or phone number)
    public let remoteAddress: String
    
    /// Direction of the call
    public let direction: DACallDirection
    
    /// Call duration in seconds (computed property)
    public var duration: Int {
        guard let core = DACalls.shared.sessionManager.core,
              let call = core.calls.first(where: { $0.callLog?.callId == callId }) else {
            return 0
        }
        return call.duration
    }
}

/// Direction of a call
public enum DACallDirection {
    /// Outgoing call (initiated by the user)
    case outgoing
    
    /// Incoming call (received from remote)
    case incoming
}

/// Call state
public enum DACallState {
    /// No active call
    case idle
    
    /// Outgoing call being initialized
    case outgoingInit
    
    /// Outgoing call in progress
    case outgoingProgress
    
    /// Outgoing call ringing
    case outgoingRinging
    
    /// Incoming call ringing
    case ringing
    
    /// Call is connecting
    case connecting
    
    /// Call is connected but streams not yet running
    case connected
    
    /// Call is active with media streams running
    case active
    
    /// Call is paused by local user
    case paused
    
    /// Call is paused by remote user
    case pausedByRemote
    
    /// Call is resuming
    case resuming
    
    /// Call has ended
    case ended
    
    /// Call failed with error
    case error(String)
}

/// Call-related errors
public enum DACallError: Error {
    /// No active call
    case noActiveCall
    
    /// Call failed with message
    case callFailed(String)
}
