import AppKit
import SwiftUI

@MainActor
public final class AppDelegate: NSObject, NSApplicationDelegate {
    private var appState: AppState!
    private var popoverController: PopoverController!
    private var statusItemController: StatusItemController!
    private var desktopHUDController: DesktopHUDWindowController!

    public func applicationDidFinishLaunching(_ notification: Notification) {
        // MARK: - Composition Root (Clean Architecture Dependency Injection)

        // 1. Infrastructure Layer
        let httpClient = HTTPClient.shared
        let contributionRepository = GitHubContributionRepository(httpClient: httpClient)
        let configRepository = FileConfigRepository()
        let launchAgentManager = LaunchAgentManager.shared

        // 2. Application Layer (Use Cases)
        let streakEngine = StreakCalculationEngine()
        let getContributionsUseCase = GetContributionsUseCase(
            contributionRepository: contributionRepository,
            configRepository: configRepository,
            streakEngine: streakEngine
        )
        let updateConfigUseCase = UpdateConfigUseCase(
            configRepository: configRepository,
            launchAgentManager: launchAgentManager
        )
        let toggleDesktopWidgetUseCase = ToggleDesktopWidgetUseCase(
            updateConfigUseCase: updateConfigUseCase
        )

        // 3. Interface Layer (State Coordinator)
        let state = AppState(
            getContributionsUseCase: getContributionsUseCase,
            updateConfigUseCase: updateConfigUseCase,
            toggleDesktopWidgetUseCase: toggleDesktopWidgetUseCase
        )
        self.appState = state

        // Handle initial CLI arguments if passed to app executable
        handleCommandLineArguments()

        // 4. Interface Layer (Controllers)
        let popover = PopoverController(appState: state)
        self.popoverController = popover
        self.statusItemController = StatusItemController(appState: state, popoverController: popover)
        self.desktopHUDController = DesktopHUDWindowController(appState: state)

        // 5. Initial Data Load
        state.initialLoad()
    }

    private func handleCommandLineArguments() {
        let args = CommandLine.arguments
        for i in 0..<args.count {
            if (args[i] == "--id" || args[i] == "-id") && i + 1 < args.count {
                let username = args[i + 1]
                appState.updateUsername(username)
            }
        }
    }

    public func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        return true
    }
}
