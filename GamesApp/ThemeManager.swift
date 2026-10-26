import SwiftUI

enum AppTheme: String, CaseIterable, Identifiable {
    case system = "Systeem"
    case light = "Licht"
    case dark = "Donker"
    case amoled = "Spelavond AMOLED"

    var id: String { rawValue }

    var icon: String {
        switch self {
        case .system: return "circle.lefthalf.filled"
        case .light: return "sun.max.fill"
        case .dark: return "moon.fill"
        case .amoled: return "moon.stars.fill"
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light: return .light
        case .dark, .amoled: return .dark
        }
    }
}

final class ThemeManager: ObservableObject {
    static let shared = ThemeManager()

    @AppStorage("app_theme") var selectedTheme: AppTheme = .system {
        didSet {
            objectWillChange.send()
        }
    }

    var isAMOLED: Bool {
        selectedTheme == .amoled
    }
}
