# DACalls UI Components

This directory contains all the UI components used in the DACalls SDK. These components are built using SwiftUI and are designed to be easily integrated into your iOS app.

## Available Components

### DACallView

A view for managing active calls. It displays the call status, remote party information, and provides controls for call management (mute, speaker, keypad, etc.).

### DACallViewModel

The view model for the call view. It manages the state of the call and provides methods for call control.

### DADialPadView

A reusable dial pad component that displays a standard telephone keypad and provides callbacks for digit presses.

### DADialView

A view for initiating outgoing calls. It includes a text field for entering the destination address and a dial pad for entering numbers.

### DACallScreen

An all-in-one VoIP call screen that includes login, dialpad, and call management functionality.

## Usage

These components can be used individually or together depending on your app's needs. For example:

```swift
// Using the dial view
struct ContentView: View {
    @State private var showCallView = false

    var body: some View {
        DADialView(onCallStarted: {
            showCallView = true
        })
        .sheet(isPresented: $showCallView) {
            DACallView(onCallEnded: {
                showCallView = false
            })
        }
    }
}

// Using the all-in-one call screen
struct ContentView: View {
    @State private var showCallScreen = false

    var body: some View {
        Button("Start Call") {
            showCallScreen = true
        }
        .callScreen(isPresented: $showCallScreen)
    }
}
```
