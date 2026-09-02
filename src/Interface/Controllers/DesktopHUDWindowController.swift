import AppKit
import SwiftUI
import Combine

@MainActor
public final class DesktopHUDWindowController: NSObject {
    private var window: NSWindow?
    private let appState: AppState
    private var cancellables = Set<AnyCancellable>()

    public init(appState: AppState) {
        self.appState = appState
        super.init()

        bindWidgetState()
    }

    private func bindWidgetState() {
        appState.$config
            .map(\.isDesktopWidgetEnabled)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isEnabled in
                if isEnabled {
                    self?.showWindow()
                } else {
                    self?.hideWindow()
                }
            }
            .store(in: &cancellables)
    }

    public func showWindow() {
        if window == nil {
            let hudView = DesktopHUDView(appState: appState)
            let hostingController = NSHostingController(rootView: hudView)

            let win = NSWindow(
                contentRect: NSRect(x: 100, y: 100, width: 760, height: 200),
                styleMask: [.borderless, .fullSizeContentView],
                backing: .buffered,
                defer: false
            )

            win.isMovableByWindowBackground = true
            win.level = .floating
            win.collectionBehavior = [.canJoinAllSpaces, .stationary]
            win.backgroundColor = .clear
            win.isOpaque = false
            win.hasShadow = false
            win.contentViewController = hostingController

            // Center or position on screen
            if let screen = NSScreen.main {
                let screenRect = screen.visibleFrame
                let x = screenRect.maxX - 780
                let y = screenRect.minY + 40
                win.setFrameOrigin(NSPoint(x: x, y: y))
            }

            self.window = win
        }

        window?.orderFront(nil)
    }

    public func hideWindow() {
        window?.orderOut(nil)
        window = nil
    }
}
