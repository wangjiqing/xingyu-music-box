import SwiftUI

enum MacAppTheme: String, CaseIterable, Codable, Identifiable, Equatable {
    case springDawn
    case midsummerStarlight
    case autumnVinyl
    case winterMoonlight

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .springDawn:
            return "春日晨光"
        case .midsummerStarlight:
            return "仲夏星河"
        case .autumnVinyl:
            return "秋日唱片"
        case .winterMoonlight:
            return "冬夜雪境"
        }
    }

    var resourceFolder: String {
        switch self {
        case .springDawn:
            return "spring-dawn"
        case .midsummerStarlight:
            return "midsummer-starlight"
        case .autumnVinyl:
            return "autumn-vinyl"
        case .winterMoonlight:
            return "winter-moonlight"
        }
    }

    var backgroundTop: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.980, green: 0.988, blue: 0.969)
        case .midsummerStarlight:
            return Color(red: 0.965, green: 0.984, blue: 1.000)
        case .autumnVinyl:
            return Color(red: 1.000, green: 0.969, blue: 0.933)
        case .winterMoonlight:
            return Color(red: 0.039, green: 0.071, blue: 0.141)
        }
    }

    var backgroundMiddle: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.745, green: 0.906, blue: 0.882)
        case .midsummerStarlight:
            return Color(red: 0.557, green: 0.804, blue: 0.973)
        case .autumnVinyl:
            return Color(red: 0.910, green: 0.635, blue: 0.298)
        case .winterMoonlight:
            return Color(red: 0.067, green: 0.133, blue: 0.227)
        }
    }

    var backgroundBottom: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.886, green: 0.922, blue: 0.863)
        case .midsummerStarlight:
            return Color(red: 0.659, green: 0.902, blue: 0.882)
        case .autumnVinyl:
            return Color(red: 1.000, green: 0.945, blue: 0.882)
        case .winterMoonlight:
            return Color(red: 0.039, green: 0.071, blue: 0.141)
        }
    }

    var panel: Color {
        switch self {
        case .springDawn:
            return Color.white.opacity(0.82)
        case .midsummerStarlight:
            return Color.white.opacity(0.78)
        case .autumnVinyl:
            return Color(red: 1.000, green: 0.945, blue: 0.882).opacity(0.84)
        case .winterMoonlight:
            return Color(red: 0.067, green: 0.133, blue: 0.227).opacity(0.88)
        }
    }

    var panelDark: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.886, green: 0.922, blue: 0.863).opacity(0.90)
        case .midsummerStarlight:
            return Color(red: 0.867, green: 0.918, blue: 0.961).opacity(0.90)
        case .autumnVinyl:
            return Color(red: 0.902, green: 0.839, blue: 0.765).opacity(0.92)
        case .winterMoonlight:
            return Color(red: 0.125, green: 0.184, blue: 0.290).opacity(0.94)
        }
    }

    var text: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.141, green: 0.227, blue: 0.196)
        case .midsummerStarlight:
            return Color(red: 0.149, green: 0.220, blue: 0.302)
        case .autumnVinyl:
            return Color(red: 0.169, green: 0.114, blue: 0.078)
        case .winterMoonlight:
            return Color(red: 0.910, green: 0.941, blue: 1.000)
        }
    }

    var muted: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.424, green: 0.498, blue: 0.451)
        case .midsummerStarlight:
            return Color(red: 0.431, green: 0.506, blue: 0.596)
        case .autumnVinyl:
            return Color(red: 0.420, green: 0.341, blue: 0.275)
        case .winterMoonlight:
            return Color(red: 0.635, green: 0.698, blue: 0.788)
        }
    }

    var accent: Color {
        switch self {
        case .springDawn:
            return Color(red: 1.000, green: 0.875, blue: 0.651)
        case .midsummerStarlight:
            return Color(red: 0.969, green: 0.875, blue: 0.651)
        case .autumnVinyl:
            return Color(red: 0.957, green: 0.773, blue: 0.416)
        case .winterMoonlight:
            return Color(red: 0.969, green: 0.784, blue: 0.451)
        }
    }

    var line: Color {
        switch self {
        case .springDawn:
            return Color(red: 0.886, green: 0.922, blue: 0.863)
        case .midsummerStarlight:
            return Color(red: 0.867, green: 0.918, blue: 0.961)
        case .autumnVinyl:
            return Color(red: 0.902, green: 0.839, blue: 0.765)
        case .winterMoonlight:
            return Color(red: 0.122, green: 0.184, blue: 0.290)
        }
    }

    var colorScheme: ColorScheme? {
        self == .winterMoonlight ? .dark : .light
    }

    static var current: MacAppTheme {
        guard let rawValue = UserDefaults.standard.string(forKey: "macAppTheme") else {
            return seasonalDefault()
        }
        return MacAppTheme(rawValue: rawValue) ?? seasonalDefault()
    }

    static func seasonalDefault(date: Date = Date(), calendar: Calendar = .current) -> MacAppTheme {
        let month = calendar.component(.month, from: date)
        switch month {
        case 1...3:
            return .springDawn
        case 4...6:
            return .midsummerStarlight
        case 7...9:
            return .autumnVinyl
        default:
            return .winterMoonlight
        }
    }
}

@MainActor
final class MacThemeManager: ObservableObject {
    @Published var currentTheme: MacAppTheme {
        didSet {
            UserDefaults.standard.set(currentTheme.rawValue, forKey: "macAppTheme")
        }
    }

    init() {
        currentTheme = MacAppTheme.current
    }

    func select(_ theme: MacAppTheme) {
        currentTheme = theme
    }

    func selectNextTheme() {
        guard let currentIndex = MacAppTheme.allCases.firstIndex(of: currentTheme) else {
            currentTheme = MacAppTheme.seasonalDefault()
            return
        }

        let nextIndex = MacAppTheme.allCases.index(after: currentIndex)
        currentTheme = nextIndex == MacAppTheme.allCases.endIndex ? MacAppTheme.allCases[0] : MacAppTheme.allCases[nextIndex]
    }
}
