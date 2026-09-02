import Foundation

public protocol ContributionRepositoryProtocol: Sendable {
    /// Fetches contribution calendar data for a given GitHub username.
    /// - Parameter username: GitHub username (e.g., "ksuchoi216")
    /// - Returns: Domain ContributionCalendar containing days, weeks, and totals
    func fetchContributions(username: String) async throws -> ContributionCalendar
}
