import Foundation

public struct AppConfig: Codable, Equatable, Sendable {
    public var utcOffsetHours: Int
    public var username: String
    public var themeId: String
    public var refreshIntervalMinutes: Int
    public var isDesktopWidgetEnabled: Bool
    public var isStartAtLoginEnabled: Bool
    public var showMenuBarCurrentStreak: Bool
    public var showMenuBarLongestStreak: Bool
    public var showMenuBarToday: Bool
    public var showMenuBarEmojis: Bool

    public init(
        utcOffsetHours: Int = 9,
        username: String = "",
        themeId: String = "dark_green",
        refreshIntervalMinutes: Int = 30,
        isDesktopWidgetEnabled: Bool = false,
        isStartAtLoginEnabled: Bool = false,
        showMenuBarCurrentStreak: Bool = false,
        showMenuBarLongestStreak: Bool = false,
        showMenuBarToday: Bool = true,
        showMenuBarEmojis: Bool = true
    ) {
        self.utcOffsetHours = min(14, max(-12, utcOffsetHours))
        self.username = username
        self.themeId = themeId
        self.refreshIntervalMinutes = refreshIntervalMinutes
        self.isDesktopWidgetEnabled = isDesktopWidgetEnabled
        self.isStartAtLoginEnabled = isStartAtLoginEnabled
        self.showMenuBarCurrentStreak = showMenuBarCurrentStreak
        self.showMenuBarLongestStreak = showMenuBarLongestStreak
        self.showMenuBarToday = showMenuBarToday
        self.showMenuBarEmojis = showMenuBarEmojis
    }

    // Custom decoder to handle backward compatibility
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        utcOffsetHours = min(14, max(-12, try container.decodeIfPresent(Int.self, forKey: .utcOffsetHours) ?? 9))
        username = try container.decodeIfPresent(String.self, forKey: .username) ?? ""
        themeId = try container.decodeIfPresent(String.self, forKey: .themeId) ?? "dark_green"
        refreshIntervalMinutes = try container.decodeIfPresent(Int.self, forKey: .refreshIntervalMinutes) ?? 30
        isDesktopWidgetEnabled = try container.decodeIfPresent(Bool.self, forKey: .isDesktopWidgetEnabled) ?? false
        isStartAtLoginEnabled = try container.decodeIfPresent(Bool.self, forKey: .isStartAtLoginEnabled) ?? false
        showMenuBarCurrentStreak = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarCurrentStreak) ?? false
        showMenuBarLongestStreak = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarLongestStreak) ?? false
        showMenuBarToday = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarToday) ?? true
        showMenuBarEmojis = try container.decodeIfPresent(Bool.self, forKey: .showMenuBarEmojis) ?? true
    }

    public var contributionCalendar: Calendar {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: utcOffsetHours * 3600) ?? TimeZone(secondsFromGMT: 9 * 3600)!
        return calendar
    }

    public static var `default`: AppConfig {
        AppConfig(
            username: "",
            themeId: Theme.darkModeGreen.id,
            refreshIntervalMinutes: 30,
            isDesktopWidgetEnabled: false,
            isStartAtLoginEnabled: false,
            showMenuBarCurrentStreak: false,
            showMenuBarLongestStreak: false,
            showMenuBarToday: true,
            showMenuBarEmojis: true
        )
    }
}
