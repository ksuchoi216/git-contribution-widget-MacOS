import Foundation

public struct ContributionStats: Codable, Equatable, Sendable {
    public let currentStreak: Int
    public let longestStreak: Int
    public let todayCount: Int
    public let totalContributions: Int

    public init(
        currentStreak: Int = 0,
        longestStreak: Int = 0,
        todayCount: Int = 0,
        totalContributions: Int = 0
    ) {
        self.currentStreak = currentStreak
        self.longestStreak = longestStreak
        self.todayCount = todayCount
        self.totalContributions = totalContributions
    }

    public static var zero: ContributionStats {
        ContributionStats(currentStreak: 0, longestStreak: 0, todayCount: 0, totalContributions: 0)
    }
}
