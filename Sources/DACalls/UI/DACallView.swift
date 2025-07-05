import Combine
import Foundation
import SwiftUI

/// View for managing active calls
public struct DACallView: View {
    @StateObject private var viewModel = DACallViewModel()

    /// Called when a call ends and the view should be dismissed
    public var onCallEnded: (() -> Void)?

    /// Public initializer
    public init(onCallEnded: (() -> Void)? = nil) {
        self.onCallEnded = onCallEnded
    }

    public var body: some View {
        VStack(spacing: 30) {
            // Call status and remote identity
            VStack(spacing: 10) {
                Text(viewModel.callStatusText)
                    .font(.headline)
                    .foregroundColor(.secondary)

                Text(viewModel.remoteParty)
                    .font(.largeTitle)
                    .bold()

                if viewModel.isCallActive {
                    Text(viewModel.callDuration)
                        .font(.title3)
                }
            }
            .padding()

            Spacer()

            // Call controls
            if viewModel.isIncomingCall {
                // Incoming call controls
                HStack(spacing: 40) {
                    // Decline button
                    Button(action: {
                        Task {
                            await viewModel.endCall()
                        }
                    }) {
                        VStack {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "phone.down.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                )

                            Text("Decline")
                                .font(.caption)
                                .padding(.top, 5)
                        }
                    }

                    // Accept button
                    Button(action: {
                        Task {
                            await viewModel.answerCall()
                        }
                    }) {
                        VStack {
                            Circle()
                                .fill(Color.green)
                                .frame(width: 64, height: 64)
                                .overlay(
                                    Image(systemName: "phone.fill")
                                        .font(.system(size: 28))
                                        .foregroundColor(.white)
                                )

                            Text("Answer")
                                .font(.caption)
                                .padding(.top, 5)
                        }
                    }
                }
            } else if viewModel.isCallActive {
                // Active call controls
                VStack(spacing: 20) {
                    HStack(spacing: 30) {
                        // Mute button
                        Button(action: {
                            viewModel.toggleMute()
                        }) {
                            VStack {
                                Circle()
                                    .fill(viewModel.isMuted ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Image(systemName: viewModel.isMuted ? "mic.slash.fill" : "mic.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(viewModel.isMuted ? .white : .gray)
                                    )

                                Text("Mute")
                                    .font(.caption)
                                    .padding(.top, 5)
                            }
                        }

                        // Speaker button
                        Button(action: {
                            viewModel.toggleSpeaker()
                        }) {
                            VStack {
                                Circle()
                                    .fill(viewModel.isSpeakerOn ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Image(systemName: "speaker.wave.3.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(viewModel.isSpeakerOn ? .white : .gray)
                                    )

                                Text("Speaker")
                                    .font(.caption)
                                    .padding(.top, 5)
                            }
                        }

                        // Keypad button
                        Button(action: {
                            viewModel.showKeypad.toggle()
                        }) {
                            VStack {
                                Circle()
                                    .fill(viewModel.showKeypad ? Color.blue : Color.gray.opacity(0.3))
                                    .frame(width: 56, height: 56)
                                    .overlay(
                                        Image(systemName: "dial.fill")
                                            .font(.system(size: 24))
                                            .foregroundColor(viewModel.showKeypad ? .white : .gray)
                                    )

                                Text("Keypad")
                                    .font(.caption)
                                    .padding(.top, 5)
                            }
                        }
                    }

                    // Show keypad if enabled
                    if viewModel.showKeypad {
                        DADialPadView(onDigitPressed: { digit in
                            viewModel.sendDTMF(digit: digit)
                        })
                        .transition(.opacity)
                    }
                }
            }

            Spacer()

            // End call button (always visible for ongoing calls)
            if viewModel.isCallActive || viewModel.isOutgoingCall {
                Button(action: {
                    Task {
                        await viewModel.endCall()
                    }
                }) {
                    Circle()
                        .fill(Color.red)
                        .frame(width: 64, height: 64)
                        .overlay(
                            Image(systemName: "phone.down.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        )
                }
                .padding(.bottom, 30)
            }
        }
        .padding()
        .background(Color(.systemBackground).edgesIgnoringSafeArea(.all))
        .onReceive(viewModel.$callEnded) { ended in
            if ended {
                onCallEnded?()
            }
        }
    }
}

#Preview {
    DACallView()
}
