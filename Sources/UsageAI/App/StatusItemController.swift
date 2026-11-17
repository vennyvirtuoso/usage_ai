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
        // Variable length or standard square icon length
        let item = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)
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
                DispatchQueue.main.async {
                    self?.updateDisplay()
                }
            }
            .store(in: &cancellables)

        AppSettings.shared.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateDisplay()
                }
            }
            .store(in: &cancellables)
    }

    public func updateDisplay() {
        guard let item = statusItem, let button = item.button else { return }

        // Single custom Usage AI icon (Zero emoji clutter, zero duplicate symbols!)
        button.image = CustomMenuBarIcon.createIcon()

        let displayText = UsageTracker.shared.menuBarDisplayString
        if displayText.isEmpty {
            item.length = NSStatusItem.squareLength
            button.imagePosition = .imageOnly
            button.title = ""
        } else {
            item.length = NSStatusItem.variableLength
            button.imagePosition = .imageLeading
            button.title = " " + displayText
        }

        button.toolTip = "Ghee-Khatam — Gemini: \(UsageTracker.shared.geminiFiveHourPercent)% · Claude: \(UsageTracker.shared.claudeFiveHourPercent)%"
    }

    @objc private func statusItemClicked(_ sender: NSStatusBarButton) {
        guard let event = NSApp.currentEvent else { return }

        if event.type == .rightMouseUp {
            let menu = NSMenu()
            menu.addItem(NSMenuItem(title: "Ghee-Khatam", action: nil, keyEquivalent: ""))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Refresh Cloud Quotas Now", action: #selector(refreshAction), keyEquivalent: "r"))
            menu.addItem(NSMenuItem(title: "Toggle Desktop Widget", action: #selector(toggleWidgetAction), keyEquivalent: "w"))
            menu.addItem(NSMenuItem(title: "Preferences...", action: #selector(settingsAction), keyEquivalent: ","))
            menu.addItem(NSMenuItem.separator())
            menu.addItem(NSMenuItem(title: "Quit Ghee-Khatam", action: #selector(quitAction), keyEquivalent: "q"))

            for item in menu.items {
                item.target = self
            }
            statusItem?.menu = menu
            statusItem?.button?.performClick(nil)
            statusItem?.menu = nil
        } else {
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
