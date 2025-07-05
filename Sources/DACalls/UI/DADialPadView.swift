import Foundation
import SwiftUI

/// Dialpad view for DTMF input
public struct DADialPadView: View {
    var onDigitPressed: (CChar) -> Void

    let buttons: [[Int8]] = [
        [1, 2, 3],
        [4, 5, 6],
        [7, 8, 9],
        [0, 0, 0],
    ]

    public init(onDigitPressed: @escaping (CChar) -> Void) {
        self.onDigitPressed = onDigitPressed
    }

    public var body: some View {
        VStack(spacing: 8) {
            ForEach(buttons, id: \.self) { row in
                HStack(spacing: 8) {
                    ForEach(row, id: \.self) { digit in
                        Button(action: {
                            onDigitPressed(digit)
                        }) {
                            Text(digit)
                                .font(.title)
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(30)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    DADialPadView { digit in
        print("Pressed \(digit)")
    }
}
