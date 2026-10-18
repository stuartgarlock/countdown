import SwiftUI

extension EventTheme {
    var colors: [Color] {
        switch self {
        case .sunset:   [Color(hex: 0xFF8A5B), Color(hex: 0xE8457C)]
        case .rose:     [Color(hex: 0xF7797D), Color(hex: 0xC6426E)]
        case .berry:    [Color(hex: 0xC2549D), Color(hex: 0x6A3093)]
        case .lavender: [Color(hex: 0x8E9BFF), Color(hex: 0x6C5DD3)]
        case .ocean:    [Color(hex: 0x3FC5F0), Color(hex: 0x3A6FD8)]
        case .teal:     [Color(hex: 0x2BC0A4), Color(hex: 0x167A8B)]
        case .forest:   [Color(hex: 0x6BA34A), Color(hex: 0x2F5D3A)]
        case .gold:     [Color(hex: 0xF7C04A), Color(hex: 0xE07B24)]
        case .slate:    [Color(hex: 0x6B7C8F), Color(hex: 0x2C3E50)]
        }
    }

    var gradient: LinearGradient {
        LinearGradient(colors: colors, startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var name: String { rawValue.capitalized }
}

extension Color {
    init(hex: UInt32) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}
