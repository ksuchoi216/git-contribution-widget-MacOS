import Foundation

public protocol ConfigRepositoryProtocol: Sendable {
    /// Loads application configuration from storage.
    func loadConfig() -> AppConfig

    /// Saves application configuration to storage.
    func saveConfig(_ config: AppConfig) throws

    /// Loads cached contribution calendar data if available.
    func loadCache() -> ContributionCalendar?

    /// Saves contribution calendar to cache storage.
    func saveCache(_ calendar: ContributionCalendar) throws
}
