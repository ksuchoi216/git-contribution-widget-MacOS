import AppKit
import SwiftUI

@MainActor
public final class PopoverController: NSObject, NSPopoverDelegate {
    private let popover: NSPopover
    private let appState: AppState
    private var eventMonitor: Any?

    public init(appState: AppState) {
        self.appState = appState
        self.popover = NSPopover()
        super.init()

        setupPopover()
    }

    private func setupPopover() {
        popover.contentSize = NSSize(width: 740, height: 260)
        popover.behavior = .transient
        popover.animates = true
        popover.delegate = self

        let contentView = PopoverView(appState: appState)
        popover.contentViewController = NSHostingController(rootView: contentView)
    }

    public func togglePopover(sender: NSStatusBarButton) {
        if popover.isShown {
            closePopover()
        } else {
            showPopover(sender: sender)
        }
    }

    public func showPopover(sender: NSStatusBarButton) {
        popover.show(relativeTo: sender.bounds, of: sender, preferredEdge: .minY)
        popover.contentViewController?.view.window?.makeKey()
        startMonitoringClicks()
    }

    public func closePopover() {
        popover.performClose(nil)
        stopMonitoringClicks()
    }

    private func startMonitoringClicks() {
        stopMonitoringClicks()
        eventMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { [weak self] _ in
            self?.closePopover()
        }
    }

    private func stopMonitoringClicks() {
        if let monitor = eventMonitor {
            NSEvent.removeMonitor(monitor)
            eventMonitor = nil
        }
    }

    public func popoverDidClose(_ notification: Notification) {
        stopMonitoringClicks()
    }
}
