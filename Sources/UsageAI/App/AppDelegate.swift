import AppKit
import SwiftUI

@MainActor
public class AppDelegate: NSObject, NSApplicationDelegate {
    public static private(set) var shared: AppDelegate?

    private var settingsWindow: NSWindow?

    public func applicationDidFinishLaunching(_ notification: Notification) {
        AppDelegate.shared = self

        // Run as an accessory app (menu bar extra, no dock icon unless settings is open)
        NSApp.setActivationPolicy(.accessory)

        // Initialize status bar item and menu bar popover
        StatusItemController.shared.setup()

        // Initialize desktop widget if enabled
        if AppSettings.shared.isDesktopWidgetVisible {
            DesktopWidgetController.shared.showWidget()
        }
    }

    public func openSettings() {
        if settingsWindow == nil {
            let window = NSWindow(
                contentRect: NSRect(x: 0, y: 0, width: 480, height: 400),
                styleMask: [.titled, .closable, .miniaturizable],
                backing: .buffered,
                defer: false
            )
            window.title = "Usage AI Preferences"
            window.contentView = NSHostingView(rootView: SettingsView())
            window.center()
            window.isReleasedWhenClosed = false
            self.settingsWindow = window
        }

        NSApp.activate(ignoringOtherApps: true)
        settingsWindow?.makeKeyAndOrderFront(nil)
    }

    public func applicationWillTerminate(_ notification: Notification) {
        // Cleanup if needed
    }
}
