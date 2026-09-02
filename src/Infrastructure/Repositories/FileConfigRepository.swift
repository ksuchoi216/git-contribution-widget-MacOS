import Foundation

public final class FileConfigRepository: ConfigRepositoryProtocol, @unchecked Sendable {
    private let appSupportURL: URL
    private let configFileURL: URL
    private let cacheFileURL: URL
    private let fileManager: FileManager

    public init(fileManager: FileManager = .default) {
        self.fileManager = fileManager

        let paths = fileManager.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let baseAppSupport = paths.first ?? URL(fileURLWithPath: NSHomeDirectory()).appendingPathComponent("Library/Application Support")
        self.appSupportURL = baseAppSupport.appendingPathComponent("GitContributionWidget", isDirectory: true)
        self.configFileURL = self.appSupportURL.appendingPathComponent("config.json")
        self.cacheFileURL = self.appSupportURL.appendingPathComponent("cache.json")

        createDirectoryIfNeeded()
    }

    private func createDirectoryIfNeeded() {
        if !fileManager.fileExists(atPath: appSupportURL.path) {
            try? fileManager.createDirectory(at: appSupportURL, withIntermediateDirectories: true, attributes: nil)
        }
    }

    public func loadConfig() -> AppConfig {
        createDirectoryIfNeeded()
        guard let data = try? Data(contentsOf: configFileURL),
              let config = try? JSONDecoder().decode(AppConfig.self, from: data) else {
            return .default
        }
        return config
    }

    public func saveConfig(_ config: AppConfig) throws {
        createDirectoryIfNeeded()
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(config)
        try data.write(to: configFileURL, options: [.atomic])
    }

    public func loadCache() -> ContributionCalendar? {
        createDirectoryIfNeeded()
        guard let data = try? Data(contentsOf: cacheFileURL) else {
            return nil
        }
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return try? decoder.decode(ContributionCalendar.self, from: data)
    }

    public func saveCache(_ calendar: ContributionCalendar) throws {
        createDirectoryIfNeeded()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let data = try encoder.encode(calendar)
        try data.write(to: cacheFileURL, options: [.atomic])
    }
}
