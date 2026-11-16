import Foundation
import Combine

public enum MenuBarDisplayMode: String, CaseIterable, Codable {
    case fiveHourQuota = "5-Hour Quotas (✨ 97% | 🤖 93%)"
    case weeklyQuota = "Weekly Quotas (✨ 79% | 🤖 83%)"
    case compactIcon = "Minimal Icon Only"
}

public enum WidgetSizeStyle: String, CaseIterable, Codable {
    case medium = "Medium Widget (Standard)"
    case small = "Small Widget (Compact)"
}

public enum WidgetTheme: String, CaseIterable, Codable {
    case obsidian = "Deep Obsidian (Best on All Wallpapers)"
    case frosted = "Adaptive Frosted Glass"
    case titanium = "Titanium Dark"
}

public class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    // Refresh interval: default 20 minutes (1200 seconds)
    @Published public var refreshIntervalSeconds: Double {
        didSet { defaults.set(refreshIntervalSeconds, forKey: "refreshIntervalSeconds") }
    }

    @Published public var menuBarDisplayMode: MenuBarDisplayMode {
        didSet { defaults.set(menuBarDisplayMode.rawValue, forKey: "menuBarDisplayMode") }
    }

    @Published public var widgetSizeStyle: WidgetSizeStyle {
        didSet { defaults.set(widgetSizeStyle.rawValue, forKey: "widgetSizeStyle") }
    }

    @Published public var widgetTheme: WidgetTheme {
        didSet { defaults.set(widgetTheme.rawValue, forKey: "widgetTheme") }
    }

    // Gemini Accounts
    @Published public var geminiAccount1Email: String {
        didSet { defaults.set(geminiAccount1Email, forKey: "geminiAccount1Email") }
    }

    @Published public var geminiAccount2Email: String {
        didSet { defaults.set(geminiAccount2Email, forKey: "geminiAccount2Email") }
    }

    @Published public var geminiAccount2ApiKey: String {
        didSet { defaults.set(geminiAccount2ApiKey, forKey: "geminiAccount2ApiKey") }
    }

    @Published public var selectedGeminiAccountTab: String {
        didSet { defaults.set(selectedGeminiAccountTab, forKey: "selectedGeminiAccountTab") }
    }

    // Desktop Widget
    @Published public var isDesktopWidgetVisible: Bool {
        didSet { defaults.set(isDesktopWidgetVisible, forKey: "isDesktopWidgetVisible") }
    }

    @Published public var isDesktopWidgetPinned: Bool {
        didSet { defaults.set(isDesktopWidgetPinned, forKey: "isDesktopWidgetPinned") }
    }

    @Published public var widgetOpacity: Double {
        didSet { defaults.set(widgetOpacity, forKey: "widgetOpacity") }
    }

    private init() {
        let savedInterval = defaults.double(forKey: "refreshIntervalSeconds")
        self.refreshIntervalSeconds = savedInterval >= 300.0 ? savedInterval : 1200.0

        if let rawMode = defaults.string(forKey: "menuBarDisplayMode"),
           let mode = MenuBarDisplayMode(rawValue: rawMode) {
            self.menuBarDisplayMode = mode
        } else {
            self.menuBarDisplayMode = .fiveHourQuota
        }

        if let rawSize = defaults.string(forKey: "widgetSizeStyle"),
           let size = WidgetSizeStyle(rawValue: rawSize) {
            self.widgetSizeStyle = size
        } else {
            self.widgetSizeStyle = .medium
        }

        if let rawTheme = defaults.string(forKey: "widgetTheme"),
           let theme = WidgetTheme(rawValue: rawTheme) {
            self.widgetTheme = theme
        } else {
            self.widgetTheme = .obsidian
        }

        self.geminiAccount1Email = defaults.string(forKey: "geminiAccount1Email") ?? "alexasolosix@gmail.com"
        self.geminiAccount2Email = defaults.string(forKey: "geminiAccount2Email") ?? "parasgandre@gmail.com"
        self.geminiAccount2ApiKey = defaults.string(forKey: "geminiAccount2ApiKey") ?? ""
        self.selectedGeminiAccountTab = defaults.string(forKey: "selectedGeminiAccountTab") ?? "alexasolosix@gmail.com"

        self.isDesktopWidgetVisible = defaults.bool(forKey: "isDesktopWidgetVisible")
        self.isDesktopWidgetPinned = defaults.bool(forKey: "isDesktopWidgetPinned")

        let savedOpacity = defaults.double(forKey: "widgetOpacity")
        self.widgetOpacity = savedOpacity > 0 ? savedOpacity : 0.98
    }
}
