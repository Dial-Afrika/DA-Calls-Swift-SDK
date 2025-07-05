import CallKit
import Foundation

// MARK: - CXProviderDelegate

extension DACallService: @preconcurrency CXProviderDelegate {
    /// Called when the provider has been reset
    public func providerDidReset(_: CXProvider) {
        // Handle provider reset - terminate all calls
        if let core = sessionManager.core, core.callsNb > 0 {
            for call in core.calls {
                do {
                    try call.terminate()
                } catch {
                    print("Error terminating call: \(error.localizedDescription)")
                }
            }
        }
    }

    /// Called when a call is started from CallKit
    public func provider(_: CXProvider, perform action: CXStartCallAction) {
        // The actual call is made in makeCall method
        // Just fulfill the action here
        action.fulfill()
    }

    /// Called when a call is answered from CallKit
    public func provider(_: CXProvider, perform action: CXAnswerCallAction) {
        guard let core = sessionManager.core, let call = core.currentCall else {
            action.fail()
            return
        }

        // Configure audio session before answering
        core.configureAudioSession()

        do {
            try call.accept()
            action.fulfill()
        } catch {
            print("Error accepting call: \(error.localizedDescription)")
            action.fail()
        }
    }

    /// Called when a call is ended from CallKit
    public func provider(_: CXProvider, perform action: CXEndCallAction) {
        guard let core = sessionManager.core else {
            action.fail()
            return
        }

        // Find and terminate the call
        if let call = core.currentCall {
            do {
                try call.terminate()
                action.fulfill()
            } catch {
                print("Error terminating call: \(error.localizedDescription)")
                action.fail()
            }
        } else if core.callsNb > 0 {
            // Try the first call if current call is not available
            do {
                try core.calls[0].terminate()
                action.fulfill()
            } catch {
                print("Error terminating call: \(error.localizedDescription)")
                action.fail()
            }
        } else {
            // No calls to terminate
            action.fulfill()
        }
    }

    /// Called when a call is put on hold from CallKit
    public func provider(_: CXProvider, perform action: CXSetHeldCallAction) {
        guard let core = sessionManager.core, let call = core.currentCall else {
            action.fail()
            return
        }

        do {
            if action.isOnHold {
                try call.pause()
            } else {
                try call.resume()
            }
            action.fulfill()
        } catch {
            print("Error changing call hold state: \(error.localizedDescription)")
            action.fail()
        }
    }

    /// Called when mute is toggled from CallKit
    public func provider(_: CXProvider, perform action: CXSetMutedCallAction) {
        guard let core = sessionManager.core else {
            action.fail()
            return
        }

        core.micEnabled = !action.isMuted
        setMicMuted(action.isMuted)
        action.fulfill()
    }

    /// Called when DTMF is sent from CallKit
    public func provider(_: CXProvider, perform action: CXPlayDTMFCallAction) {
        guard let core = sessionManager.core, let call = core.currentCall else {
            action.fail()
            return
        }

        do {
            for digit in action.digits {
                // Convert each character to CChar for DTMF
                if let asciiValue = digit.asciiValue {
                    let cChar = CChar(asciiValue)
                    try call.sendDtmf(dtmf: cChar)
                }
            }
            action.fulfill()
        } catch {
            print("Error sending DTMF: \(error.localizedDescription)")
            action.fail()
        }
    }
}
