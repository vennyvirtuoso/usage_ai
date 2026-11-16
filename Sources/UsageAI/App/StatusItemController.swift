import AppKit
import SwiftUI
import Combine

@MainActor
public class StatusItemController: NSObject {
    public static let shared = StatusItemController()

    private var statusItem: NSStatusItem?
    private var popover: NSPopover?
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
    }

    public func setup() {
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        self.statusItem = item

        if let button = item.button {
            button.action = #selector(statusItemClicked(_:))
            button.target = self
            button.sendAction(on: [.leftMouseUp, .rightMouseUp])
        }

        setupPopover()
        setupObservers()
        updateDisplay()
    }

    private func setupPopover() {
        let pop = NSPopover()
        pop.behavior = .transient
        pop.animates = true

        let contentView = MenuBarPopupView(
            onOpenSettings: {
                AppDelegate.shared?.openSettings()
            },
            onToggleWidget: {
                DesktopWidgetController.shared.toggleWidget()
            },
            onQuit: {
                NSApplication.shared.terminate(nil)
            }
        )

        pop.contentViewController = NSHostingController(rootView: contentView)
        self.popover = pop
    }

    private func setupObservers() {
        UsageTracker.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDisplay()
            }
            .store(in: &cancellables)

        AppSettings.shared.$menuBarDisplayMode
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                self?.updateDisplay()
            }
            .store(in: &cancellables)
    }

    public func updateDisplay() {
        guard let button = statusItem?.button else { return }

        let tracker = UsageTracker.shared
        let settings = AppSettings.shared

        let icon = NSImage(systemSymbolName: "chart.line.uptrend.xyaxis.circle.fill", accessibilityDescription: "Usage AI")
        icon?.isTemplate = true
        button.image = icon
        button.imagePosition = .imageLeading

        switch settings.menuBarDisplayMode {
        case .bothTokens:
            let gStr = tracker.formatTokens(tracker.geminiSummary.todayTokens)
            let cStr = tracker.formatTokens(tracker.claudeSummary.todayTokens)
            button.title = " ✨ \(gStr)  🤖 \(cStr)"
        case .totalTokens:
            let totStr = tracker.formatTokens(tracker.totalTokensToday)
            button.title = " ⚡ \(totStr)"
        case .withCost:
            let totStr = tracker.formatTokens(tracker.totalTokensToday)
            let costStr = String(format: "$%.2f", tracker.totalCostToday)
            button.title = " ⚡ \(totStr) · \(costStr)"
        case .compactIcon:
            button.title = ""
        }
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            // Right-click opens context menu directly
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Usage AI", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Refresh Now", action: #selector(refreshAction), keyEquivalent: "r"))
            menu.addItem(NSMenuItem(title: "Toggle Desktop Widget", action: #selector(toggleWidgetAction), keyEquivalent: "w"))
            menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(settingsAction), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit Usage AI", action: #selector(quitAction), keyEquivalent: "q"))

            for item in menu.items {
                item.target = self
            }
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
            // Left click toggles rich popover
            togglePopover(sender)
        }
    }

    public func togglePopover(_ sender: AnyObject?) {
        guard let pop = popover, let button = statusItem?.button else { return }

        if pop.isShown {
            pop.performClose(sender)
        } else {
            pop.show(relativeTo: button.bounds, of: button, preferredEdge: .minY)
            pop.contentViewController?.view.window?.makeKey()
        }
    }

    @objc private func refreshAction() {
        UsageTracker.shared.refreshNow()
    }

    @objc private func toggleWidgetAction() {
        DesktopWidgetController.shared.toggleWidget()
    }

    @objc private func settingsAction() {
        AppDelegate.shared?.openSettings()
    }

    @objc private func quitAction() {
        NSApplication.shared.terminate(nil)
    }
}
