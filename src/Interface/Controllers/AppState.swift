import Foundation
import SwiftUI
import Combine

@MainActor
public final class AppState: ObservableObject {
    @Published public var overview: ContributionOverviewDTO = .empty
    @Published public var config: AppConfig = .default
    @Published public var isLoading: Bool = false
    @Published public var errorMessage: String? = nil
    @Published public var hoveredDay: ContributionDay? = nil
    @Published public var isSettingsOpen: Bool = false
    @Published public var popoverOpenTrigger: Int = 0

    public func notifyPopoverOpened() {
        popoverOpenTrigger += 1
    }

    public let getContributionsUseCase: GetContributionsUseCase
    public let updateConfigUseCase: UpdateConfigUseCase
    public let toggleDesktopWidgetUseCase: ToggleDesktopWidgetUseCase

    private var refreshTimer: AnyCancellable?

    public init(
        getContributionsUseCase: GetContributionsUseCase,
        updateConfigUseCase: UpdateConfigUseCase,
        toggleDesktopWidgetUseCase: ToggleDesktopWidgetUseCase
    ) {
        self.getContributionsUseCase = getContributionsUseCase
        self.updateConfigUseCase = updateConfigUseCase
        self.toggleDesktopWidgetUseCase = toggleDesktopWidgetUseCase
        self.config = updateConfigUseCase.getConfig()

        setupAutoRefresh()
    }

    public func initialLoad() {
        Task {
            await fetchContributions(force: false)
        }
    }

    public func fetchContributions(force: Bool = false) async {
        guard !config.username.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            self.errorMessage = "Please enter your GitHub ID in settings."
            return
        }

        isLoading = true
        errorMessage = nil

        do {
            let result = try await getContributionsUseCase.execute(
                username: config.username,
                forceRefresh: force
            )
            self.overview = result
            self.isLoading = false
        } catch {
            self.errorMessage = error.localizedDescription
            self.isLoading = false
        }
    }

    public func updateUsername(_ newName: String) {
        let trimmed = newName.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed != config.username else { return }

        do {
            self.config = try updateConfigUseCase.execute { cfg in
                cfg.username = trimmed
            }
            Task {
                await fetchContributions(force: true)
            }
        } catch {
            self.errorMessage = "Failed to save username: \(error.localizedDescription)"
        }
    }

    public func selectTheme(id: String) {
        do {
            self.config = try updateConfigUseCase.execute { cfg in
                cfg.themeId = id
            }
            let theme = Theme.find(id: id)
            self.overview = ContributionOverviewDTO(
                username: overview.username,
                calendar: overview.calendar,
                stats: overview.stats,
                theme: theme,
                isCached: overview.isCached,
                lastFetched: overview.lastFetched
            )
        } catch {
            self.errorMessage = "Failed to update theme: \(error.localizedDescription)"
        }
    }

    public func toggleDesktopWidget() {
        do {
            let newStatus = try toggleDesktopWidgetUseCase.execute()
            self.config.isDesktopWidgetEnabled = newStatus
        } catch {
            self.errorMessage = "Failed to toggle desktop widget: \(error.localizedDescription)"
        }
    }

    public func toggleStartAtLogin() {
        do {
            self.config = try updateConfigUseCase.execute { cfg in
                cfg.isStartAtLoginEnabled.toggle()
            }
        } catch {
            self.errorMessage = "Failed to update launch at login: \(error.localizedDescription)"
        }
    }

    public func toggleMenuBarCurrentStreak() {
        do {
            self.config = try updateConfigUseCase.execute { cfg in
                cfg.showMenuBarCurrentStreak.toggle()
            }
        } catch {
            self.errorMessage = "Failed to update menu bar config: \(error.localizedDescription)"
        }
    }

    public func toggleMenuBarLongestStreak() {
        do {
            self.config = try updateConfigUseCase.execute { cfg in
                cfg.showMenuBarLongestStreak.toggle()
            }
        } catch {
            self.errorMessage = "Failed to update menu bar config: \(error.localizedDescription)"
        }
    }

    public func toggleMenuBarToday() {
        do {
            self.config = try updateConfigUseCase.execute { cfg in
                cfg.showMenuBarToday.toggle()
            }
        } catch {
            self.errorMessage = "Failed to update menu bar config: \(error.localizedDescription)"
        }
    }

    public func toggleMenuBarEmojis() {
        do {
            self.config = try updateConfigUseCase.execute { cfg in
                cfg.showMenuBarEmojis.toggle()
            }
        } catch {
            self.errorMessage = "Failed to update menu bar config: \(error.localizedDescription)"
        }
    }

    public func updateRefreshIntervalMinutes(_ minutes: Int) {
        let validMinutes = max(5, minutes)
        do {
            self.config = try updateConfigUseCase.execute { cfg in
                cfg.refreshIntervalMinutes = validMinutes
            }
            setupAutoRefresh()
        } catch {
            self.errorMessage = "Failed to update refresh interval: \(error.localizedDescription)"
        }
    }

    private func setupAutoRefresh() {
        refreshTimer?.cancel()
        let interval = max(5, config.refreshIntervalMinutes) * 60
        refreshTimer = Timer.publish(every: Double(interval), on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                Task { [weak self] in
                    await self?.fetchContributions(force: true)
                }
            }
    }
}
