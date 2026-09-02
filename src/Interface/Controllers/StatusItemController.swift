import AppKit
import Combine

@MainActor
public final class StatusItemController: NSObject {
    private let statusItem: NSStatusItem
    private let appState: AppState
    private let popoverController: PopoverController
    private var cancellables = Set<AnyCancellable>()

    public init(appState: AppState, popoverController: PopoverController) {
        self.appState = appState
        self.popoverController = popoverController
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        setupStatusButton()
        bindState()
    }

    private func setupStatusButton() {
        guard let button = statusItem.button else { return }
        button.target = self
        button.action = #selector(statusItemClicked(_:))
        button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        updateButtonTitle()
    }

    private func bindState() {
        // Observe overview, config, and loading state changes
        Publishers.CombineLatest3(appState.$overview, appState.$config, appState.$isLoading)
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                self?.updateButtonTitle()
            }
            .store(in: &cancellables)
    }

    private func updateButtonTitle() {
        guard let button = statusItem.button else { return }

        let stats = appState.overview.stats
        let config = appState.config

        var parts: [String] = []

        if config.showMenuBarCurrentStreak {
            if stats.currentStreak > 0 {
                parts.append("🔥 \(stats.currentStreak)")
            } else {
                parts.append("🌱 0")
            }
        }

        if config.showMenuBarLongestStreak {
            parts.append("🏆 \(stats.longestStreak)")
        }

        if config.showMenuBarToday {
            parts.append("⚡ \(stats.todayCount)")
        }

        let title = parts.joined(separator: "  ")

        // Set status item image
        if let image = NSImage(systemSymbolName: "circle.grid.cross.fill", accessibilityDescription: "GitHub Contributions") {
            let config = NSImage.SymbolConfiguration(pointSize: 13, weight: .regular)
            button.image = image.withSymbolConfiguration(config)
            button.imagePosition = title.isEmpty ? .imageOnly : .imageLeading
        }

        button.title = title
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        let event = NSApp.currentEvent
        if event?.type == .rightMouseUp {
            // Right-click menu
            showContextMenu(sender)
        } else {
            // Left-click toggle popover
            popoverController.togglePopover(sender: sender)
        }
    }

    private func showContextMenu(_ sender: NSStatusBarButton) {
        let menu = NSMenu()

        let refreshItem = NSMenuItem(title: "Refresh Now", action: #selector(refreshClicked), keyEquivalent: "r")
        refreshItem.target = self
        menu.addItem(refreshItem)

        let widgetToggleTitle = appState.config.isDesktopWidgetEnabled ? "Hide Desktop Widget" : "Show Desktop Widget"
        let widgetItem = NSMenuItem(title: widgetToggleTitle, action: #selector(toggleWidgetClicked), keyEquivalent: "w")
        widgetItem.target = self
        menu.addItem(widgetItem)

        menu.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quitClicked), keyEquivalent: "q")
        quitItem.target = self
        menu.addItem(quitItem)

        statusItem.menu = menu
        statusItem.button?.performClick(nil)
        statusItem.menu = nil
    }

    @objc private func refreshClicked() {
        Task {
            await appState.fetchContributions(force: true)
        }
    }

    @objc private func toggleWidgetClicked() {
        appState.toggleDesktopWidget()
    }

    @objc private func quitClicked() {
        NSApplication.shared.terminate(nil)
    }
}
