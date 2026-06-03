import SwiftUI

enum Theme {
    static let backgroundLight = Color(hex: "#F8F6FF")
    static let primaryTextLight = Color(hex: "#2D2D3A")
    static let secondaryTextLight = Color(hex: "#8B8BA7")
    static let hoverLight = Color(hex: "#EDE9FE")

    static let backgroundDark = Color(hex: "#16162A")
    static let primaryTextDark = Color(hex: "#E8E8FF")
    static let secondaryTextDark = Color(hex: "#6B6B8A")

    static let accentStart = Color(hex: "#7C3AED")
    static let accentEnd = Color(hex: "#A855F7")
    static let accent = LinearGradient(
        colors: [accentStart, accentEnd],
        startPoint: .leading,
        endPoint: .trailing
    )

    static let spacingS: CGFloat = 10
    static let spacingM: CGFloat = 18
    static let spacingL: CGFloat = 28

    static let radiusItem: CGFloat = 10
    static let radiusPanel: CGFloat = 16

    static func rounded(_ style: Font.TextStyle, weight: Font.Weight = .regular) -> Font {
        .system(style, design: .rounded).weight(weight)
    }
}

extension Color {
    init(hex: String) {
        let trimmed = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        let sanitized: String
        if trimmed.hasPrefix("#") {
            sanitized = String(trimmed.dropFirst())
        } else if trimmed.hasPrefix("0x") || trimmed.hasPrefix("0X") {
            sanitized = String(trimmed.dropFirst(2))
        } else {
            sanitized = trimmed
        }

        guard [3, 6, 8].contains(sanitized.count),
              sanitized.allSatisfy({ $0.isHexDigit }) else {
            assertionFailure("Invalid hex color: \(hex)")
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
            return
        }

        let expanded: String
        if sanitized.count == 3 {
            expanded = sanitized.map { "\($0)\($0)" }.joined()
        } else {
            expanded = sanitized
        }

        guard let value = UInt64(expanded, radix: 16) else {
            assertionFailure("Invalid hex color: \(hex)")
            self.init(.sRGB, red: 0, green: 0, blue: 0, opacity: 1)
            return
        }

        let red: Double
        let green: Double
        let blue: Double
        let opacity: Double

        switch expanded.count {
        case 8:
            red = Double((value & 0xFF00_0000) >> 24) / 255
            green = Double((value & 0x00FF_0000) >> 16) / 255
            blue = Double((value & 0x0000_FF00) >> 8) / 255
            opacity = Double(value & 0x0000_00FF) / 255
        case 6:
            red = Double((value & 0xFF0000) >> 16) / 255
            green = Double((value & 0x00FF00) >> 8) / 255
            blue = Double(value & 0x0000FF) / 255
            opacity = 1
        default:
            assertionFailure("Invalid hex color: \(hex)")
            red = 0
            green = 0
            blue = 0
            opacity = 1
        }

        self.init(.sRGB, red: red, green: green, blue: blue, opacity: opacity)
    }
}
