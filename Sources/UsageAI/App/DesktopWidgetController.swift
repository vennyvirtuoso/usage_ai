import AppKit
import SwiftUI
import Combine

@MainActor
public class DesktopWidgetController: NSObject, ObservableObject {
    public static let shared = DesktopWidgetController()

    private var panel: NSPanel?
    private var cancellables = Set<AnyCancellable>()

    private override init() {
        super.init()
        setupObservers()
    }

    private func setupObservers() {
        AppSettings.shared.$isDesktopWidgetVisible
            .receive(on: RunLoop.main)
            .sink { [weak self] visible in
                if visible {
                    self?.showWidget()
                } else {
                    self?.hideWidget()
                }
            }
            .store(in: &cancellables)

        AppSettings.shared.$isDesktopWidgetPinned
            .receive(on: RunLoop.main)
            .sink { [weak self] pinned in
                self?.updateWindowLevel(pinned: pinned)
            }
            .store(in: &cancellables)
    }

    public func toggleWidget() {
        AppSettings.shared.isDesktopWidgetVisible.toggle()
    }

    public func showWidget() {
        if panel == nil {
            createPanel()
        }
        panel?.orderFrontRegardless()
    }

    public func hideWidget() {
        panel?.orderOut(nil)
    }

    private func updateWindowLevel(pinned: Bool) {
        // If pinned, keep behind regular apps (like desktop wallpaper/widget level)
        // If unpinned, float above normal windows
        panel?.level = pinned ? .belowNormal : .floating
    }

    private func createPanel() {
        let newPanel = NSPanel(
            contentRect: NSRect(x: 100, y: 100, width: 280, height: 180),
            styleMask: [.borderless, .nonactivatingPanel, .resizable],
            backing: .buffered,
            defer: false
        )

        newPanel.isOpaque = false
        newPanel.backgroundColor = .clear
        newPanel.hasShadow = true
        newPanel.level = AppSettings.shared.isDesktopWidgetPinned ? .belowNormal : .floating
        newPanel.collectionBehavior = [.canJoinAllSpaces, .stationary, .ignoresCycle]
        newPanel.isMovableByWindowBackground = true

        let rootView = DesktopWidgetView(onClose: {
            AppSettings.shared.isDesktopWidgetVisible = false
        })

        let hostingView = NSHostingView(rootView: rootView)
        newPanel.contentView = hostingView

        // Position panel at top right of the main screen by default
        if let screen = NSScreen.main {
            let screenRect = screen.visibleFrame
            let x = screenRect.maxX - 300
            let y = screenRect.maxY - 220
            newPanel.setFrameOrigin(NSPoint(x: x, y: y))
        }

        self.panel = newPanel
    }
}

extension NSWindow.Level {
    static let belowNormal = NSWindow.Level(rawValue: Int(CGWindowLevelForKey(.desktopIconWindow)))
}
