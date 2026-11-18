import Foundation
import Combine

public enum MenuBarDisplayMode: String, CaseIterable, Codable {
    case iconOnly = "Single Custom Icon Only (Recommended)"
    case fiveHourQuota = "Custom Icon + 5-Hour Quotas (97% · 93%)"
    case weeklyQuota = "Custom Icon + Weekly Quotas (79% · 83%)"
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

    @Published public var geminiAccount3Email: String {
        didSet { defaults.set(geminiAccount3Email, forKey: "geminiAccount3Email") }
    }

    @Published public var geminiAccount3ApiKey: String {
        didSet { defaults.set(geminiAccount3ApiKey, forKey: "geminiAccount3ApiKey") }
    }

    @Published public var selectedGeminiAccountTab: String {
        didSet { defaults.set(selectedGeminiAccountTab, forKey: "selectedGeminiAccountTab") }
    }

    public var account1ShortName: String {
        let email = geminiAccount1Email
        if email.contains("@") {
            return email.components(separatedBy: "@").first ?? "Account 1"
        }
        return email.isEmpty ? "Account 1" : email
    }

    public var account2ShortName: String {
        let email = geminiAccount2Email
        if email.contains("@") {
            return email.components(separatedBy: "@").first ?? "Account 2"
        }
        return email.isEmpty ? "Account 2" : email
    }

    public var account3ShortName: String {
        let email = geminiAccount3Email
        if email.contains("@") {
            return email.components(separatedBy: "@").first ?? "Account 3"
        }
        return email.isEmpty ? "Account 3" : email
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

    // Claude Custom / Web Session Override
    @Published public var claudeManualOverrideEnabled: Bool {
        didSet { defaults.set(claudeManualOverrideEnabled, forKey: "claudeManualOverrideEnabled") }
    }

    @Published public var claudeCurrentUsedPercent: Double {
        didSet { defaults.set(claudeCurrentUsedPercent, forKey: "claudeCurrentUsedPercent") }
    }

    @Published public var claudeSessionResetTime: String {
        didSet { defaults.set(claudeSessionResetTime, forKey: "claudeSessionResetTime") }
    }

    @Published public var claudeCustomToken: String {
        didSet { defaults.set(claudeCustomToken, forKey: "claudeCustomToken") }
    }

    private init() {
        let savedInterval = defaults.double(forKey: "refreshIntervalSeconds")
        self.refreshIntervalSeconds = savedInterval >= 300.0 ? savedInterval : 1200.0

        if let rawMode = defaults.string(forKey: "menuBarDisplayMode"),
           let mode = MenuBarDisplayMode(rawValue: rawMode) {
            self.menuBarDisplayMode = mode
        } else {
            self.menuBarDisplayMode = .iconOnly
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

        self.geminiAccount1Email = defaults.string(forKey: "geminiAccount1Email") ?? "user1@gmail.com"
        self.geminiAccount2Email = defaults.string(forKey: "geminiAccount2Email") ?? "user2@gmail.com"
        self.geminiAccount2ApiKey = defaults.string(forKey: "geminiAccount2ApiKey") ?? ""
        self.geminiAccount3Email = defaults.string(forKey: "geminiAccount3Email") ?? "user3@gmail.com"
        self.geminiAccount3ApiKey = defaults.string(forKey: "geminiAccount3ApiKey") ?? ""
        self.selectedGeminiAccountTab = defaults.string(forKey: "selectedGeminiAccountTab") ?? "user1@gmail.com"

        self.isDesktopWidgetVisible = defaults.bool(forKey: "isDesktopWidgetVisible")
        self.isDesktopWidgetPinned = defaults.bool(forKey: "isDesktopWidgetPinned")

        let savedOpacity = defaults.double(forKey: "widgetOpacity")
        self.widgetOpacity = savedOpacity > 0 ? savedOpacity : 0.98

        self.claudeManualOverrideEnabled = defaults.bool(forKey: "claudeManualOverrideEnabled")
        let savedUsed = defaults.double(forKey: "claudeCurrentUsedPercent")
        self.claudeCurrentUsedPercent = savedUsed > 0 ? savedUsed : 8.0
        self.claudeSessionResetTime = defaults.string(forKey: "claudeSessionResetTime") ?? "7:10 AM"
        self.claudeCustomToken = defaults.string(forKey: "claudeCustomToken") ?? ""
    }
}
