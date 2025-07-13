import SwiftUI
#if canImport(UIKit)
    import UIKit
#endif
import DACalls

@main
struct DACallsExampleApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}

struct ContentView: View {
    @State private var showLoginView = false
    @State private var showDialView = false
    @State private var showCallView = true
    @State private var isLoggedIn = true

    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("DACalls SDK Example")
                    .font(.largeTitle)
                    .padding()

                if isLoggedIn {
                    Button("Make a Call") {
                        showDialView = true
                    }
                    .buttonStyle(.borderedProminent)

                    Button("Logout") {
                        Task {
                            await DACalls.shared.authService.logout()
                            isLoggedIn = false
                        }
                    }
                    .buttonStyle(.bordered)
                } else {
                    Button("Login") {
                        showLoginView = true
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
            .padding()
            .sheet(isPresented: $showLoginView) {
                // LoginView implementation would go here
                Text("Login View Placeholder")
                    .onDisappear {
                        // For demo purposes, assume login was successful
                        isLoggedIn = true
                    }
            }
            .sheet(isPresented: $showDialView) {
                DADialView {
                    showDialView = false
                    showCallView = true
                }
            }
            .sheet(isPresented: $showCallView) {
                DACallView {
                    showCallView = false
                }
            }
            .navigationTitle("DACalls SDK")
        }
    }
}
