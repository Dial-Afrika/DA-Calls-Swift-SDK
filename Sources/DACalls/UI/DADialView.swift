import SwiftUI
import Foundation

/// View for initiating outgoing calls
public struct DADialView: View {
    @State private var destinationNumber: String = ""
    @State private var isCallInProgress: Bool = false
    
    /// Called when a call is initiated
    public var onCallStarted: (() -> Void)?
    
    /// Public initializer
    public init(onCallStarted: (() -> Void)? = nil) {
        self.onCallStarted = onCallStarted
    }
    
    public var body: some View {
        VStack(spacing: 20) {
            // Destination input
            TextField("Enter SIP address or phone number", text: $destinationNumber)
                .font(.title3)
                .padding()
                .background(Color.gray.opacity(0.1))
                .cornerRadius(10)
            
            // Dial pad
            DADialPadView(onDigitPressed: { digit in
                destinationNumber += digit
            })
            
            // Call button
            Button(action: {
                makeCall()
            }) {
                HStack {
                    Image(systemName: "phone.fill")
                    Text("Call")
                }
                .padding()
                .frame(maxWidth: .infinity)
                .background(Color.green)
                .foregroundColor(.white)
                .cornerRadius(10)
            }
            .disabled(destinationNumber.isEmpty)
        }
        .padding()
    }
    
    /// Make an outgoing call
    private func makeCall() {
        // Format the SIP address if needed
        var address = destinationNumber
        if !address.contains("sip:") && !address.contains("@") {
            // Assume this is a phone number, format accordingly
            address = "sip:\(address)@\(DACalls.shared.authService.currentDomain)"
        } else if !address.contains("sip:") {
            // Address has @ but no sip: prefix
            address = "sip:\(address)"
        }
        
        Task {
            let result = await DACalls.shared.callService.makeCall(to: address)
            switch result {
            case .success:
                isCallInProgress = true
                onCallStarted?()
            case .failure:
                isCallInProgress = false
            }
        }
    }
}

#Preview {
    DADialView()
}
