import Foundation

public struct StreakCalculationEngine: Sendable {
    public init() {}

    /// Calculates contribution metrics and streaks from an array of ContributionDays.
    /// - Parameters:
    ///   - days: Chronologically sorted list of contribution days (from past to recent).
    ///   - referenceDate: The current reference date (defaults to now).
    ///   - calendar: User's calendar instance (defaults to current).
    /// - Returns: Calculated ContributionStats containing current streak, longest streak, today's count, and total.
    public func calculateStats(
        from days: [ContributionDay],
        referenceDate: Date = Date(),
        calendar: Calendar = .current
    ) -> ContributionStats {
        guard !days.isEmpty else {
            return .zero
        }

        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        dateFormatter.timeZone = calendar.timeZone

        let todayStr = dateFormatter.string(from: referenceDate)
        let yesterdayDate = calendar.date(byAdding: .day, value: -1, to: referenceDate) ?? referenceDate
        let yesterdayStr = dateFormatter.string(from: yesterdayDate)

        // Lookup dictionary by dateString
        var dayMap: [String: ContributionDay] = [:]
        for day in days {
            dayMap[day.dateString] = day
        }

        let todayCount = dayMap[todayStr]?.count ?? 0

        // Total count across all days
        let totalCount = days.reduce(0) { $0 + $1.count }

        // 1. Calculate Longest Streak
        var longestStreak = 0
        var currentRunningStreak = 0

        for day in days {
            if day.count > 0 {
                currentRunningStreak += 1
                if currentRunningStreak > longestStreak {
                    longestStreak = currentRunningStreak
                }
            } else {
                currentRunningStreak = 0
            }
        }

        // 2. Calculate Current Active Streak
        // Walk backwards starting from today (if active) or yesterday (if today not yet active)
        var currentStreak = 0
        var checkDate = referenceDate

        if todayCount > 0 {
            checkDate = referenceDate
        } else if let yesterdayDay = dayMap[yesterdayStr], yesterdayDay.count > 0 {
            checkDate = yesterdayDate
        } else {
            checkDate = referenceDate
        }

        while true {
            let dateKey = dateFormatter.string(from: checkDate)
            guard let day = dayMap[dateKey], day.count > 0 else {
                break
            }
            currentStreak += 1
            guard let previousDay = calendar.date(byAdding: .day, value: -1, to: checkDate) else {
                break
            }
            checkDate = previousDay
        }

        return ContributionStats(
            currentStreak: currentStreak,
            longestStreak: longestStreak,
            todayCount: todayCount,
            totalContributions: totalCount
        )
    }
}
