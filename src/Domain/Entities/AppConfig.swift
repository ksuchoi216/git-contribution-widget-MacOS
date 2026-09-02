import Foundation

public enum MenuBarDisplayMode: String, Codable, Sendable, CaseIterable {
    case iconAndStreak = "icon_streak"
    case iconAndToday = "icon_today"
    case iconOnly = "icon_only"

    public var title: String {
        switch self {
        case .iconAndStreak: return "Icon + Streak (🔥)"
        case .iconAndToday: return "Icon + Today (⚡)"
        case .iconOnly: return "Icon Only"
        }
    }
}

public struct AppConfig: Codable, Equatable, Sendable {
    public var username: String
    public var themeId: String
    public var refreshIntervalMinutes: Int
    public var isDesktopWidgetEnabled: Bool
    public var isStartAtLoginEnabled: Bool
    public var menuBarDisplayMode: MenuBarDisplayMode

    public init(
        username: String = "",
        themeId: String = "dark_green",
        refreshIntervalMinutes: Int = 30,
        isDesktopWidgetEnabled: Bool = false,
        isStartAtLoginEnabled: Bool = false,
        menuBarDisplayMode: MenuBarDisplayMode = .iconAndStreak
    ) {
        self.username = username
        self.themeId = themeId
        self.refreshIntervalMinutes = refreshIntervalMinutes
        self.isDesktopWidgetEnabled = isDesktopWidgetEnabled
        self.isStartAtLoginEnabled = isStartAtLoginEnabled
        self.menuBarDisplayMode = menuBarDisplayMode
    }

    public static var `default`: AppConfig {
        AppConfig(
            username: "",
            themeId: Theme.darkModeGreen.id,
            refreshIntervalMinutes: 30,
            isDesktopWidgetEnabled: false,
            isStartAtLoginEnabled: false,
            menuBarDisplayMode: .iconAndStreak
        )
    }
}
