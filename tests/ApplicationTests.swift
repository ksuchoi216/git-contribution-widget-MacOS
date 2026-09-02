import Foundation

// Mock Repositories for Application Layer Testing
final class MockContributionRepository: ContributionRepositoryProtocol, @unchecked Sendable {
    var shouldFail: Bool = false
    var mockCalendar: ContributionCalendar?

    func fetchContributions(username: String) async throws -> ContributionCalendar {
        if shouldFail {
            throw NetworkError.serverError("Simulated network failure")
        }
        return mockCalendar ?? ContributionCalendar(
            username: username,
            days: [
                ContributionDay(dateString: "2026-09-01", date: Date(), count: 5, level: .level3, weekday: 3)
            ],
            weeks: [],
            monthHeaders: [],
            totalContributions: 5,
            updatedAt: Date()
        )
    }
}

final class MockConfigRepository: ConfigRepositoryProtocol, @unchecked Sendable {
    var config: AppConfig = .default
    var cache: ContributionCalendar?

    func loadConfig() -> AppConfig {
        return config
    }

    func saveConfig(_ config: AppConfig) throws {
        self.config = config
    }

    func loadCache() -> ContributionCalendar? {
        return cache
    }

    func saveCache(_ calendar: ContributionCalendar) throws {
        self.cache = calendar
    }
}

@main
struct ApplicationTestRunner {
    static func main() async {
        print("--- Running Application Layer Tests ---")

        let mockContribRepo = MockContributionRepository()
        let mockConfigRepo = MockConfigRepository()
        mockConfigRepo.config.username = "ksuchoi216"

        let getUseCase = GetContributionsUseCase(
            contributionRepository: mockContribRepo,
            configRepository: mockConfigRepo
        )

        // 1. Test Fetch Success
        do {
            let result = try await getUseCase.execute(username: "ksuchoi216")
            assert(result.username == "ksuchoi216", "Username should match")
            assert(result.stats.totalContributions == 5, "Total contributions should match mock")
            assert(result.isCached == false, "Fresh fetch should not be marked as cached")
            assert(mockConfigRepo.cache != nil, "Successful fetch should populate cache")
        } catch {
            fatalError("Fetch should have succeeded: \(error)")
        }

        // 2. Test Offline Cache Fallback
        mockContribRepo.shouldFail = true
        do {
            let result = try await getUseCase.execute(username: "ksuchoi216")
            assert(result.isCached == true, "Fallback result should be marked as cached")
            assert(result.stats.totalContributions == 5, "Cached total should match")
        } catch {
            fatalError("Fallback to cache should have succeeded: \(error)")
        }

        // 3. Test UpdateConfigUseCase
        let updateUseCase = UpdateConfigUseCase(configRepository: mockConfigRepo)
        do {
            _ = try updateUseCase.execute { cfg in
                cfg.themeId = "dracula"
                cfg.refreshIntervalMinutes = 15
            }
            assert(mockConfigRepo.config.themeId == "dracula", "Theme should be updated")
            assert(mockConfigRepo.config.refreshIntervalMinutes == 15, "Refresh interval should be updated")
        } catch {
            fatalError("Update config should have succeeded: \(error)")
        }

        // 4. Test ToggleDesktopWidgetUseCase
        let toggleUseCase = ToggleDesktopWidgetUseCase(updateConfigUseCase: updateUseCase)
        do {
            let status1 = try toggleUseCase.execute(enabled: true)
            assert(status1 == true, "Desktop widget should be enabled")
            let status2 = try toggleUseCase.execute()
            assert(status2 == false, "Desktop widget should toggle to false")
        } catch {
            fatalError("Toggle widget should have succeeded: \(error)")
        }

        print("✅ Application Layer Tests Passed Successfully!")
    }
}
