import Foundation

public struct AppConfig: Codable, Equatable, Sendable {
    public var username: String
    public var themeId: String
    public var refreshIntervalSeconds: Int
    public var isDesktopWidgetEnabled: Bool
    public var isStartAtLoginEnabled: Bool
    public var showMenuBarCurrentStreak: Bool
    public var showMenuBarLongestStreak: Bool
    public var showMenuBarToday: Bool

    public init(
        username: String = "",
        themeId: String = "dark_green",
        refreshIntervalSeconds: Int = 60,
        isDesktopWidgetEnabled: Bool = false,
        isStartAtLoginEnabled: Bool = false,
        showMenuBarCurrentStreak: Bool = true,
        showMenuBarLongestStreak: Bool = false,
        showMenuBarToday: Bool = false
    ) {
        self.username = username
        self.themeId = themeId
        self.refreshIntervalSeconds = refreshIntervalSeconds
        self.isDesktopWidgetEnabled = isDesktopWidgetEnabled
        self.isStartAtLoginEnabled = isStartAtLoginEnabled
        self.showMenuBarCurrentStreak = showMenuBarCurrentStreak
        self.showMenuBarLongestStreak = showMenuBarLongestStreak
        self.showMenuBarToday = showMenuBarToday
    }

    // Custom decoder to handle backward compatibility
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        themeId = try container.decodeIfPresent(String.self, forKey: .themeId) ?? "dark_green"
        refreshIntervalSeconds = try container.decodeIfPresent(Int.self, forKey: .refreshIntervalSeconds) ?? 60
        isDesktopWidgetEnabled = try container.decodeIfPresent(Bool.self, forKey: .isDesktopWidgetEnabled) ?? false
        isStartAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .isStartAtLoginEnabled) ?? false
        showMenuBarCurrentStreak = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarCurrentStreak) ?? true
        showMenuBarLongestStreak = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarLongestStreak) ?? false
        showMenuBarToday = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarToday) ?? false
    }

    public static var `default`: AppConfig {
        AppConfig(
            username: "",
            themeId: Theme.darkModeGreen.id,
            refreshIntervalSeconds: 60,
            isDesktopWidgetEnabled: false,
            isStartAtLoginEnabled: false,
            showMenuBarCurrentStreak: true,
            showMenuBarLongestStreak: false,
            showMenuBarToday: false
        )
    }
}
