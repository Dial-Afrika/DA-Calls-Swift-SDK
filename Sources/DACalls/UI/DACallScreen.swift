import Combine
import Foundation
import SwiftUI

/// A complete VoIP call screen with login, dialpad, and call management
@MainActor
public struct DACallScreen: View {
    @State private var isLoggedIn = false
    @State private var isCallActive = false

    /// Public initializer
    public init() {}

    public var body: some View {
        NavigationView {
            if !isLoggedIn {
                // Login screen
                DALoginView(onLoginComplete: { success in
                    if success {
                        isLoggedIn = true
                    }
                })
                .navigationTitle("DialAfrika Login")
            } else if !isCallActive {
                // Dial screen
                DADialView(onCallStarted: {
                    isCallActive = true
                })
                .navigationTitle("Make a Call")
                .navigationBarItems(trailing: Button("Logout") {
                    logout()
                })
            } else {
                // Active call screen
                DACallView(onCallEnded: {
                    isCallActive = false
                })
                .navigationBarHidden(true)
            }
        }
        .onAppear {
            // Check if already logged in
            checkLoginStatus()
        }
    }

    /// Check if user is already logged in
    private func checkLoginStatus() {
        isLoggedIn = DACalls.shared.authService.isLoggedIn
    }

    /// Logout and return to login screen
    private func logout() {
        Task {
            await DACalls.shared.authService.logout()
            isLoggedIn = false
        }
    }
}

/// View model for the call screen
@MainActor
public class DACallScreenViewModel: ObservableObject {
    @Published var isLoggedIn: Bool = false
    @Published var isCallActive: Bool = false

    private var cancellables = Set<AnyCancellable>()

    init() {
        // Subscribe to auth state changes
        DACalls.shared.authService.$isLoggedIn
            .receive(on: DispatchQueue.main)
            .assign(to: &$isLoggedIn)

        // Subscribe to call state changes
        DACalls.shared.callService.$callState
            .receive(on: DispatchQueue.main)
            .map { state in
                switch state {
                case .idle, .ended, .error:
                    return false
                default:
                    return true
                }
            }
            .assign(to: &$isCallActive)
    }
}

/// Navigation helper for presenting the call screen
public struct DACallNavigation: ViewModifier {
    @Binding var isPresented: Bool

    public func body(content: Content) -> some View {
        content
            .fullScreenCover(isPresented: $isPresented) {
                DACallScreen()
            }
    }
}

public extension View {
    /// Present the full call screen as a modal
    /// - Parameter isPresented: Binding to control the presentation state
    /// - Returns: Modified view with the call screen presentation
    func callScreen(isPresented: Binding<Bool>) -> some View {
        modifier(DACallNavigation(isPresented: isPresented))
    }
}

#Preview {
    DACallScreen()
}
