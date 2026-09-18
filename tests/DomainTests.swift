import Foundation

@main
struct DomainTestRunner {
    static func main() {
        print("--- Running Domain Tests ---")

        let engine = StreakCalculationEngine()
        let calendar = Calendar.current
        let dateFormatter = ISO8601DateFormatter()
        dateFormatter.formatOptions = [.withFullDate]
        dateFormatter.timeZone = calendar.timeZone

        let refDate = Date()
        var testDays: [ContributionDay] = []

        // Generate 10 days in past:
        // Day -9..-5 (5 days active)
        // Day -4 (0 active)
        // Day -3..-1 (3 days active)
        // Today (active, count=4)
        for offset in stride(from: -9, through: 0, by: 1) {
            let date = calendar.date(byAdding: .day, value: offset, to: refDate)!
            let dateStr = dateFormatter.string(from: date)
            let count: Int
            if offset >= -9 && offset <= -5 {
                count = 2 // 5-day streak
            } else if offset == -4 {
                count = 0
            } else if offset >= -3 && offset <= -1 {
                count = 3 // 3 days
            } else {
                count = 4 // today
            }
            let level = ContributionLevel.from(raw: count)
            testDays.append(ContributionDay(dateString: dateStr, date: date, count: count, level: level, weekday: 1))
        }

        let stats = engine.calculateStats(from: testDays, referenceDate: refDate, calendar: calendar)

        assert(stats.todayCount == 4, "Expected todayCount to be 4, got \(stats.todayCount)")
        assert(stats.currentStreak == 4, "Expected currentStreak to be 4 (days -3, -2, -1, 0), got \(stats.currentStreak)")
        assert(stats.longestStreak == 5, "Expected longestStreak to be 5 (days -9..-5), got \(stats.longestStreak)")
        assert(stats.totalContributions == (5*2 + 0 + 3*3 + 4), "Expected total to match, got \(stats.totalContributions)")

        let legacyConfig = try! JSONDecoder().decode(AppConfig.self, from: Data("{}".utf8))
        assert(legacyConfig.utcOffsetHours == 9)
        var utcConfig = legacyConfig
        utcConfig.utcOffsetHours = 0
        let restored = try! JSONDecoder().decode(AppConfig.self, from: JSONEncoder().encode(utcConfig))
        assert(restored.utcOffsetHours == 0)

        let boundary = ISO8601DateFormatter().date(from: "2026-09-18T21:30:00Z")!
        let boundaryDays = [
            ContributionDay(dateString: "2026-09-18", date: boundary, count: 8, level: .level1, weekday: 6),
            ContributionDay(dateString: "2026-09-19", date: boundary, count: 3, level: .level1, weekday: 7)
        ]
        let koreanStats = engine.calculateStats(
            from: boundaryDays, referenceDate: boundary, calendar: legacyConfig.contributionCalendar
        )
        let utcStats = engine.calculateStats(
            from: boundaryDays, referenceDate: boundary, calendar: utcConfig.contributionCalendar
        )
        assert(koreanStats.todayCount == 3)
        assert(utcStats.todayCount == 8)
        assert(koreanStats.currentStreak == 2)
        assert(utcStats.currentStreak == 1)

        // Test Theme Presets
        assert(Theme.allPresets.count == 7, "Expected 7 theme presets")
        let dark = Theme.find(id: "dark_green")
        assert(dark.levelHexes.count == 5, "Theme should have 5 hexes")

        print("✅ Domain Tests Passed Successfully!")
    }
}
