import Foundation

public final class GetContributionsUseCase: Sendable {
    private let contributionRepository: ContributionRepositoryProtocol
    private let configRepository: ConfigRepositoryProtocol
    private let streakEngine: StreakCalculationEngine

    public init(
        contributionRepository: ContributionRepositoryProtocol,
        configRepository: ConfigRepositoryProtocol,
        streakEngine: StreakCalculationEngine = StreakCalculationEngine()
    ) {
        self.contributionRepository = contributionRepository
        self.configRepository = configRepository
        self.streakEngine = streakEngine
    }

    public func execute(username: String? = nil, forceRefresh: Bool = false) async throws -> ContributionOverviewDTO {
        let config = configRepository.loadConfig()
        let targetUser = (username ?? config.username).trimmingCharacters(in: .whitespacesAndNewlines)
        let theme = Theme.find(id: config.themeId)

        guard !targetUser.isEmpty else {
            return .empty
        }

        // 1. Try fresh network fetch
        do {
            let calendar = try await contributionRepository.fetchContributions(username: targetUser)
            let stats = streakEngine.calculateStats(from: calendar.days)

            // Cache successful result
            try? configRepository.saveCache(calendar)

            return ContributionOverviewDTO(
                username: targetUser,
                calendar: calendar,
                stats: stats,
                theme: theme,
                isCached: false,
                lastFetched: Date()
            )
        } catch {
            // 2. Fallback to cached data if network fails
            if let cached = configRepository.loadCache(), cached.username.lowercased() == targetUser.lowercased() {
                let stats = streakEngine.calculateStats(from: cached.days)
                return ContributionOverviewDTO(
                    username: targetUser,
                    calendar: cached,
                    stats: stats,
                    theme: theme,
                    isCached: true,
                    lastFetched: cached.updatedAt
                )
            }
            throw error
        }
    }
}
