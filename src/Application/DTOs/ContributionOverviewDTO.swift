import Foundation

public struct ContributionOverviewDTO: Codable, Equatable, Sendable {
    public let username: String
    public let calendar: ContributionCalendar
    public let stats: ContributionStats
    public let theme: Theme
    public let isCached: Bool
    public let lastFetched: Date

    public init(
        username: String,
        calendar: ContributionCalendar,
        stats: ContributionStats,
        theme: Theme,
        isCached: Bool = false,
        lastFetched: Date = Date()
    ) {
        self.username = username
        self.calendar = calendar
        self.stats = stats
        self.theme = theme
        self.isCached = isCached
        self.lastFetched = lastFetched
    }

    public static var empty: ContributionOverviewDTO {
        ContributionOverviewDTO(
            username: "",
            calendar: .empty,
            stats: .zero,
            theme: .darkModeGreen,
            isCached: false,
            lastFetched: Date()
        )
    }
}
