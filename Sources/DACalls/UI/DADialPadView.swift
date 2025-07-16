import Foundation
import SwiftUI

/// Dialpad view for DTMF input
public struct DADialPadView: View {
    var onDigitPressed: (CChar) -> Void

    private let buttons: [(number: String, letters: String)] = [
        ("1", ""), ("2", "ABC"), ("3", "DEF"),
        ("4", "GHI"), ("5", "JKL"), ("6", "MNO"),
        ("7", "PQRS"), ("8", "TUV"), ("9", "WXYZ"),
        ("*", ""), ("0", "+"), ("#", ""),
    ]

    public init(onDigitPressed: @escaping (CChar) -> Void) {
        self.onDigitPressed = onDigitPressed
    }

    private let columns = [GridItem(), GridItem(), GridItem()]

    public var body: some View {
        LazyVGrid(columns: columns, spacing: 12) {
            ForEach(buttons, id: \.number) { item in
                DialPadButton(number: item.number, letters: item.letters) {
                    if let ascii = item.number.first?.asciiValue {
                        onDigitPressed(CChar(ascii))
                    }
                }
            }
        }
    }
}

struct DialPadButton: View {
    let number: String
    let letters: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            VStack(spacing: 1) {
                Text(number)
                    .font(.system(size: 28, weight: .semibold))
                    .foregroundColor(.primary)
                if !letters.isEmpty {
                    Text(letters)
                        .font(.system(size: 8, weight: .medium))
                        .foregroundColor(.gray)
                        .tracking(0.5)
                }
            }
            .frame(width: 70, height: 70)
            .background(
                Circle()
                    .fill(Color(.systemGray6))
            )
        }
        .buttonStyle(DialPadButtonStyle())
    }
}

struct DialPadButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.95 : 1)
            .opacity(configuration.isPressed ? 0.8 : 1)
            .animation(.easeInOut(duration: 0.1), value: configuration.isPressed)
    }
}
