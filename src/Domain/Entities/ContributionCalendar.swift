import Foundation

public struct MonthHeader: Codable, Equatable, Sendable, Identifiable {
    public var id: String { "\(name)-\(weekIndex)" }
    public let name: String
    public let weekIndex: Int

    public init(name: String, weekIndex: Int) {
        self.name = name
        self.weekIndex = weekIndex
    }
}

public struct ContributionCalendar: Codable, Equatable, Sendable {
    public let username: String
    public let days: [ContributionDay]
    public let weeks: [[ContributionDay]]
    public let monthHeaders: [MonthHeader]
    public let totalContributions: Int
    public let updatedAt: Date

    public init(
        username: String,
        days: [ContributionDay],
        weeks: [[ContributionDay]],
        monthHeaders: [MonthHeader],
        totalContributions: Int,
        updatedAt: Date = Date()
    ) {
        self.username = username
        self.days = days
        self.weeks = weeks
        self.monthHeaders = monthHeaders
        self.totalContributions = totalContributions
        self.updatedAt = updatedAt
    }

    public static var empty: ContributionCalendar {
        ContributionCalendar(
            username: "",
            days: [],
            weeks: [],
            monthHeaders: [],
            totalContributions: 0,
            updatedAt: Date()
        )
    }
}
