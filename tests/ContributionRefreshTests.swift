import Foundation

private final class ContributionURLProtocol: URLProtocol {
    static var utcOffsetHours = 9
    static var fallback = false
    static var enrichmentFails = false
    static var includesToday = false

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let url = request.url!
        let isRangeRequest = URLComponents(url: url, resolvingAgainstBaseURL: false)?
            .queryItems?.contains { $0.name == "to" } == true
        let today = Self.dateString(offset: 0)
        let yesterday = Self.dateString(offset: -1)
        let tomorrow = Self.dateString(offset: 1)
        var status = 200
        let body: String
        if url.host == "github-contributions-api.jogruber.de" {
            body = """
            {"contributions":[{"date":"\(yesterday)","count":8,"level":1}]}
            """
        } else if isRangeRequest {
            status = Self.enrichmentFails ? 503 : 200
            // GitHub can return the entire year, including overlapping and future days.
            body = Self.cell(date: yesterday, count: 8)
                + Self.cell(date: today, count: 3)
                + Self.cell(date: tomorrow, count: 0)
        } else {
            status = Self.fallback ? 503 : 200
            body = Self.cell(date: yesterday, count: 8)
                + (Self.includesToday ? Self.cell(date: today, count: 3) : "")
        }
        let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: nil)!
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    static func dateString(offset: Int) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withFullDate]
        formatter.timeZone = TimeZone(secondsFromGMT: utcOffsetHours * 3600)
        return formatter.string(from: Calendar.current.date(byAdding: .day, value: offset, to: Date())!)
    }

    static func cell(date: String, count: Int) -> String {
        """
        <td data-date="\(date)" id="day-\(date)" data-level="1" class="ContributionCalendar-day"></td>
        <tool-tip for="day-\(date)">\(count) contributions on September 19th.</tool-tip>
        """
    }
}

@main
struct ContributionRefreshTestRunner {
    static func main() async throws {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [ContributionURLProtocol.self]
        let repository = GitHubContributionRepository(httpClient: HTTPClient(session: URLSession(configuration: configuration)))

        for fallback in [false, true] {
            ContributionURLProtocol.fallback = fallback
            let calendar = try await repository.fetchContributions(username: "test-user")
            let stats = StreakCalculationEngine().calculateStats(from: calendar.days)
            guard stats.todayCount == 3 else {
                print("FAIL: local today must contain 3 contributions, got \(stats.todayCount)")
                exit(1)
            }
            assert(calendar.days.count == 2, "Do not duplicate overlapping days or include future days")
            assert(calendar.totalContributions == 11)
            assert(stats.currentStreak == 2)
            assert(calendar.weeks.flatMap { $0 } == calendar.days)
            print("PASS: missing local day recovered (JSON fallback: \(fallback))")
        }

        ContributionURLProtocol.fallback = false
        for offset in [-12, 0, 9, 14] {
            ContributionURLProtocol.utcOffsetHours = offset
            let referenceCalendar = AppConfig(utcOffsetHours: offset).contributionCalendar
            let result = try await repository.fetchContributions(username: "test-user", calendar: referenceCalendar)
            let stats = StreakCalculationEngine().calculateStats(from: result.days, calendar: referenceCalendar)
            assert(stats.todayCount == 3, "Supplemental fetch must use the selected UTC offset")
        }
        ContributionURLProtocol.utcOffsetHours = 9
        ContributionURLProtocol.enrichmentFails = true
        let stale = try await repository.fetchContributions(username: "test-user")
        assert(stale.days.count == 1, "Keep available data when the supplemental request fails")
        assert(stale.totalContributions == 8)

        ContributionURLProtocol.includesToday = true
        let fresh = try await repository.fetchContributions(username: "test-user")
        assert(fresh.days.count == 2)
        assert(StreakCalculationEngine().calculateStats(from: fresh.days).todayCount == 3)
        print("PASS: supplemental failure and already-current data")
    }
}
