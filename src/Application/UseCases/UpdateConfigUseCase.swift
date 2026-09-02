import Foundation

public final class UpdateConfigUseCase: Sendable {
    private let configRepository: ConfigRepositoryProtocol
    private let launchAgentManager: LaunchAgentManager

    public init(
        configRepository: ConfigRepositoryProtocol,
        launchAgentManager: LaunchAgentManager = .shared
    ) {
        self.configRepository = configRepository
        self.launchAgentManager = launchAgentManager
    }

    public func execute(_ updateBlock: (inout AppConfig) -> Void) throws -> AppConfig {
        var config = configRepository.loadConfig()
        let previousStartAtLogin = config.isStartAtLoginEnabled

        updateBlock(&config)

        try configRepository.saveConfig(config)

        if config.isStartAtLoginEnabled != previousStartAtLogin {
            launchAgentManager.setLaunchAtLogin(enabled: config.isStartAtLoginEnabled)
        }

        return config
    }

    public func getConfig() -> AppConfig {
        configRepository.loadConfig()
    }
}
