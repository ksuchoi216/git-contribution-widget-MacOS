import Foundation

public enum ContributionLevel: Int, Codable, Sendable, Comparable {
    case level0 = 0
    case level1 = 1
    case level2 = 2
    case level3 = 3
    case level4 = 4

    public static func < (lhs: ContributionLevel, rhs: ContributionLevel) -> Bool {
        lhs.rawValue < rhs.rawValue
    }

    public static func from(raw: Int) -> ContributionLevel {
        switch raw {
        case 1: return .level1
        case 2: return .level2
        case 3: return .level3
        case 4...: return .level4
        default: return .level0
        }
    }
}

public struct ContributionDay: Identifiable, Codable, Equatable, Sendable {
    public var id: String { dateString }
    public let dateString: String
    public let date: Date
    public let count: Int
    public let level: ContributionLevel
    public let weekday: Int // 1 (Sun) - 7 (Sat)

    public init(dateString: String, date: Date, count: Int, level: ContributionLevel, weekday: Int) {
        self.dateString = dateString
        self.date = date
        self.count = count
        self.level = level
        self.weekday = weekday
    }
}
