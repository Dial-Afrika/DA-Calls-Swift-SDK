import Foundation
import SwiftUI

/// Dialpad view for DTMF input
public struct DADialPadView: View {
    var onDigitPressed: (CChar) -> Void

    let buttons: [[String]] = [
        ["1", "2", "3"],
        ["4", "5", "6"],
        ["7", "8", "9"],
        ["*", "0", "#"],
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
                            // Convert string to CChar for DTMF
                            if let firstChar = digit.first {
                                onDigitPressed(CChar(firstChar.asciiValue ?? 0))
                            }
                        }, label: {
                            Text(digit)
                                .font(.title)
                                .frame(width: 60, height: 60)
                                .background(Color.gray.opacity(0.2))
                                .cornerRadius(30)
                        })
                    }
                }
            }
        }
    }
}
