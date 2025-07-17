import Combine
import Foundation
import SwiftUI

// MARK: DA Call View

public struct DACallView: View {
    @StateObject private var viewModel = DACallViewModel()
    var client: DACallClient
    @Environment(\.dismiss) private var dismiss

    public init(client: DACallClient) {
        self.client = client
    }

    public var body: some View {
        NavigationView {
            ZStack {
                // Background gradient
                LinearGradient(
                    gradient: Gradient(colors: [
                        Color(.systemGray6).opacity(0.3),
                        Color(.systemGray5).opacity(0.5),
                    ]),
                    startPoint: .top,
                    endPoint: .bottom
                )
                .ignoresSafeArea()

                VStack(spacing: 30) {
                    Spacer()
                    // Call Info Card
                    VStack(spacing: 20) {
                        // Contact Avatar
                        ZStack {
                            Circle()
                                .fill(
                                    LinearGradient(
                                        gradient: Gradient(colors: [
                                            .gray.opacity(0.5),
                                            .gray.opacity(0.2),
                                        ]),
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .frame(width: 180, height: 120)

                            Image(systemName: "person.fill")
                                .font(.system(size: 50))
                                .foregroundColor(
                                    viewModel.isCallActive
                                        ? Color.green
                                        : viewModel.isPaused
                                        ? Color.orange : Color.blue)
                        }

                        VStack(spacing: 8) {
                            Text(
                                client.name.isEmpty
                                    ? "Unknown" : client.name
                            )
                            .font(.title)
                            .fontWeight(.semibold)
                            .foregroundColor(.primary)
                            .multilineTextAlignment(.center)

                            Text(viewModel.callStatusText)
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .fontWeight(.medium)

                            if viewModel.isCallActive {
                                Text(viewModel.callDuration)
                                    .font(.title2)
                                    .fontWeight(.medium)
                                    .foregroundColor(.primary)
                                    .padding(.top, 4)
                            }
                        }
                    }
                    .padding(30)

                    Spacer()

                    // Call Controls
                    if viewModel.isCallActive {
                        VStack(spacing: 20) {
                            // Mute and Speaker buttons
                            if !viewModel.showKeypad {
                                HStack(spacing: 50) {
                                    ControlButton(
                                        icon: viewModel.isMuted
                                            ? "mic.slash.fill" : "mic.fill",
                                        isActive: viewModel.isMuted,
                                        color: .red
                                    ) {
                                        viewModel.toggleMute()
                                    }

                                    ControlButton(
                                        icon: viewModel.isSpeakerOn
                                            ? "speaker.wave.3.fill"
                                            : "speaker.fill",
                                        isActive: viewModel.isSpeakerOn,
                                        color: .blue
                                    ) {
                                        viewModel.toggleSpeaker()
                                    }
                                }
                                HStack(spacing: 50) {
                                    ControlButton(
                                        icon: viewModel.isPaused
                                            ? "play.fill" : "pause.fill",
                                        isActive: viewModel.isPaused,
                                        color: viewModel.isPaused
                                            ? Color.orange : Color.gray
                                    ) {
                                        viewModel.toggleHold()
                                    }

                                    ControlButton(
                                        icon: "square.grid.3x3.fill",
                                        isActive: viewModel.showKeypad,
                                        color: Color.gray
                                    ) {
                                        viewModel.showKeypad.toggle()
                                    }
                                }
                            }

                            // Dial pad (if shown)
                            if viewModel.showKeypad {
                                DADialPadView { digit in
                                    viewModel.sendDTMF(digit: digit)
                                }
                                .frame(maxWidth: 280)
                                .padding()
                            }
                        }
                    }

                    // Action Buttons
                    HStack(spacing: 30) {
                        if viewModel.isIncomingCall && !viewModel.isCallActive {
                            ActionButton(
                                icon: "phone.fill",
                                title: "Answer",
                                color: .green
                            ) {
                                Task {
                                    await viewModel.answerCall()
                                }
                            }
                        }

                        if viewModel.showKeypad {
                            ActionButton(
                                icon: "xmark",
                                title: "Hide Keypad",
                                color: .red
                            ) {
                                Task {
                                    viewModel.showKeypad.toggle()
                                }
                            }
                        } else {
                            ActionButton(
                                icon: "phone.down.fill",
                                title: "End Call",
                                color: .red
                            ) {
                                Task {
                                    await viewModel.endCall()
                                }
                            }
                        }
                    }

                    HStack {
                        Text(verbatim: "Powered by Bonga")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundColor(.primary)
                    }
                    Spacer()
                }
                .padding(.horizontal, 10)
            }
            .navigationTitle("")
            .navigationBarTitleDisplayMode(.inline)
            .moveDisabled(true)
            .padding(.horizontal)
            //            .tabViewSidebarBottomBar {
            //                Text(verbatim: "Powered by Bonga")
            //            }
        }
    }
}

// Helper Views for better organization
struct ControlButton: View {
    let icon: String
    let isActive: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(isActive ? .white : color)
                .frame(width: 70, height: 70)
                .background(
                    Circle()
                        .fill(isActive ? color : Color(.systemGray5))
                )
        }
    }
}

struct ActionButton: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.primary)
                    .frame(width: 70, height: 70)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: [
                                        color, color.opacity(0.8),
                                    ]),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .shadow(
                                color: color.opacity(0.3), radius: 10, x: 0,
                                y: 5
                            )
                    )

                Text(title)
                    .font(.caption)
                    .fontWeight(.medium)
                    .foregroundColor(.primary)
            }
        }
    }
}

public struct DACallButton: View {
    var client: DACallClient
    var callViewModel = DACallViewModel()
    let onInAppCall: () -> Void

    @State private var showOptions = false
//    @State private var sdkStatus = "Not Initialized"

    public init(
        client: DACallClient,
        onInAppCall: @escaping () -> Void, showOptions _: Bool = false
    ) {
        self.client = client
        self.onInAppCall = onInAppCall
    }

    public var body: some View {
        NavigationStack {
            Button(action: {
                showOptions = true
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                        .font(.system(size: 20, weight: .bold))
                    Text("Call \(client.name)")
                        .fontWeight(.semibold)
                }
                .foregroundStyle(.white)
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.accentColor)
                .cornerRadius(12)
                .shadow(
                    color: Color.accentColor.opacity(0.3), radius: 8, x: 0, y: 4
                )
            }
            .padding(.horizontal, 24)
            .confirmationDialog(
                "Call Options", isPresented: $showOptions,
                titleVisibility: .visible
            ) {
                Button {
                    makeCall()
                    onInAppCall()
                } label: {
                    HStack {
                        Image(systemName: "phone.fill")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("Call in-app")
                            .font(.title2)
                            .foregroundColor(.primary)
                    }
                    .frame(alignment: .leading)
                }
                .padding()
                Divider()
                Button {
                    initiatePhoneCall()
                } label: {
                    HStack {
                        Image(systemName: "phone.arrow.up.right")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Text("Call by phone")
                            .font(.title2)
                            .foregroundColor(.primary)
                        Spacer()
                    }
                    .frame(alignment: .leading)
                }
                .padding()
                Button("Cancel", role: .cancel) {}
            }
        }
        .background(.clear)
    }

    private func makeCall() {
        let addr = client.remoteAddress
        Task {
            let result = await DACalls.shared.callService.makeCall(
                to: addr)
            switch result {
            case .success:
                print(
                    "Call initiated: \(client.name)"
                )
            case let .failure(error):
                print("Call failed: \(error)")
            }
        }
    }

    private func initiatePhoneCall() {
        if let url = URL(string: "tel://\(client.phoneNumber)"),
           UIApplication.shared.canOpenURL(url)
        {
            UIApplication.shared.open(url)
        } else {
            print("Cannot initiate call to \(client.phoneNumber)")
        }
    }
}
