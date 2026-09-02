import Foundation

@main
struct InfrastructureTestRunner {
    static func main() async {
        print("--- Running Infrastructure Layer Live Scraper Test ---")

        let repo = GitHubContributionRepository()
        let username = "ksuchoi216"

        do {
            print("Fetching contributions for '\(username)'...")
            let calendar = try await repo.fetchContributions(username: username)

            print("Username: \(calendar.username)")
            print("Total parsed days: \(calendar.days.count)")
            print("Total weeks: \(calendar.weeks.count)")
            print("Total contributions: \(calendar.totalContributions)")
            print("Month headers count: \(calendar.monthHeaders.count)")

            assert(calendar.days.count >= 300, "Should have ~365 days of data, got \(calendar.days.count)")
            assert(calendar.totalContributions > 0, "Total contributions should be > 0, got \(calendar.totalContributions)")

            // Test FileConfigRepository
            let fileConfigRepo = FileConfigRepository()
            var config = fileConfigRepo.loadConfig()
            config.username = username
            try fileConfigRepo.saveConfig(config)
            try fileConfigRepo.saveCache(calendar)

            let loadedCache = fileConfigRepo.loadCache()
            assert(loadedCache != nil, "Cache should be successfully saved and loaded")
            assert(loadedCache?.username == username, "Cached username should match")

            print("✅ Infrastructure Tests Passed Successfully!")
        } catch {
            print("❌ Infrastructure test error: \(error)")
            exit(1)
        }
    }
}
