import Foundation

public protocol ContributionRepositoryProtocol: Sendable {
    /// Fetches contribution calendar data for a given GitHub username.
    /// - Parameter username: GitHub username (e.g., "ksuchoi216")
    /// - Returns: Domain ContributionCalendar containing days, weeks, and totals
    func fetchContributions(username: String, calendar: Calendar) async throws -> ContributionCalendar
}

public extension ContributionRepositoryProtocol {
    func fetchContributions(username: String) async throws -> ContributionCalendar {
        try await fetchContributions(username: username, calendar: AppConfig.default.contributionCalendar)
    }
}
