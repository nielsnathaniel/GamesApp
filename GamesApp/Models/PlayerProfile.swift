import Foundation
import SwiftUI

public struct PlayerProfile: Identifiable, Codable, Equatable {
    public var id: String { name.lowercased() }
    public var name: String
    public var colorHex: String
    public var emoji: String?
    public var photoData: Data?

    public init(name: String, colorHex: String = "#3B82F6", emoji: String? = nil, photoData: Data? = nil) {
        self.name = name
        self.colorHex = colorHex
        self.emoji = emoji
        self.photoData = photoData
    }

    public var color: Color {
        Color(hex: colorHex) ?? .blue
    }

    public var initials: String {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: " ").filter { !$0.isEmpty }
        if parts.count >= 2 {
            let first = parts[0].prefix(1)
            let second = parts[1].prefix(1)
            return "\(first)\(second)".uppercased()
        } else if let single = parts.first {
            return String(single.prefix(2)).uppercased()
        }
        return "?"
    }
}

public struct TableColorPalette {
    public static let colors: [String] = [
        "#EF4444", // Rood
        "#F97316", // Oranje
        "#F59E0B", // Amber / Warm Geel
        "#10B981", // Emerald Groen
        "#06B6D4", // Cyaan
        "#3B82F6", // Koningsblauw
        "#6366F1", // Indigo
        "#8B5CF6", // Paars
        "#EC4899", // Roze
        "#14B8A6", // Teal
        "#84CC16", // Lime
        "#64748B"  // Grafiet / Slate
    ]

    public static func defaultColorHex(for name: String) -> String {
        let hash = abs(name.lowercased().hashValue)
        return colors[hash % colors.count]
    }
}

public struct AvatarEmojiPalette {
    public static let emojis: [String] = [
        "🦁", "🦊", "👑", "🎲", "🚀", "🧙‍♂️", "🎯", "🐻",
        "🦄", "⚡️", "🍕", "🏆", "🃏", "🦫", "🐷", "🪱",
        "🐱", "🐶", "🐼", "🐲", "🤖", "⭐", "💎", "🔥"
    ]
}

extension Color {
    init?(hex: String) {
        var hexSanitized = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        hexSanitized = hexSanitized.replacingOccurrences(of: "#", with: "")

        var rgb: UInt64 = 0
        guard Scanner(string: hexSanitized).scanHexInt64(&rgb) else { return nil }

        let r, g, b, a: Double
        if hexSanitized.count == 6 {
            r = Double((rgb & 0xFF0000) >> 16) / 255.0
            g = Double((rgb & 0x00FF00) >> 8) / 255.0
            b = Double(rgb & 0x0000FF) / 255.0
            a = 1.0
        } else if hexSanitized.count == 8 {
            r = Double((rgb & 0xFF000000) >> 24) / 255.0
            g = Double((rgb & 0x00FF0000) >> 16) / 255.0
            b = Double((rgb & 0x0000FF00) >> 8) / 255.0
            a = Double(rgb & 0x000000FF) / 255.0
        } else {
            return nil
        }

        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }

    func toHex() -> String {
        guard let components = UIColor(self).cgColor.components, components.count >= 3 else {
            return "#3B82F6"
        }
        let r = Float(components[0])
        let g = Float(components[1])
        let b = Float(components[2])
        return String(format: "#%02lX%02lX%02lX", lroundf(r * 255), lroundf(g * 255), lroundf(b * 255))
    }
}
