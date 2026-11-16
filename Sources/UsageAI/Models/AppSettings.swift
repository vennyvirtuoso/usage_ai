import Foundation
import Combine

public enum MenuBarDisplayMode: String, CaseIterable, Codable {
    case cloudQuota = "Cloud Quotas (✨ 97% | 🤖 93%)"
    case bothTokens = "Both Tokens (✨ 12k | 🤖 45k)"
    case totalTokens = "Total Combined (⚡ 57k)"
    case withCost = "Total + Cost (⚡ 57k · $0.24)"
    case compactIcon = "Minimal Icon Only"
}

public class AppSettings: ObservableObject {
    public static let shared = AppSettings()

    private let defaults = UserDefaults.standard

    @Published public var refreshIntervalSeconds: Double {
        didSet { defaults.set(refreshIntervalSeconds, forKey: "refreshIntervalSeconds") }
    }

    @Published public var menuBarDisplayMode: MenuBarDisplayMode {
        didSet { defaults.set(menuBarDisplayMode.rawValue, forKey: "menuBarDisplayMode") }
    }

    @Published public var dailyTokenBudget: Int {
        didSet { defaults.set(dailyTokenBudget, forKey: "dailyTokenBudget") }
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

    @Published public var customAntigravityPath: String {
        didSet { defaults.set(customAntigravityPath, forKey: "customAntigravityPath") }
    }

    @Published public var customClaudePath: String {
        didSet { defaults.set(customClaudePath, forKey: "customClaudePath") }
    }

    @Published public var geminiApiKey: String {
        didSet { defaults.set(geminiApiKey, forKey: "geminiApiKey") }
    }

    @Published public var claudeApiKey: String {
        didSet { defaults.set(claudeApiKey, forKey: "claudeApiKey") }
    }

    @Published public var isDesktopWidgetVisible: Bool {
        didSet { defaults.set(isDesktopWidgetVisible, forKey: "isDesktopWidgetVisible") }
    }

    @Published public var isDesktopWidgetCompact: Bool {
        didSet { defaults.set(isDesktopWidgetCompact, forKey: "isDesktopWidgetCompact") }
    }

    @Published public var isDesktopWidgetPinned: Bool {
        didSet { defaults.set(isDesktopWidgetPinned, forKey: "isDesktopWidgetPinned") }
    }

    @Published public var widgetOpacity: Double {
        didSet { defaults.set(widgetOpacity, forKey: "widgetOpacity") }
    }

    private init() {
        let savedInterval = defaults.double(forKey: "refreshIntervalSeconds")
        self.refreshIntervalSeconds = savedInterval > 0 ? savedInterval : 15.0

        if let rawMode = defaults.string(forKey: "menuBarDisplayMode"),
           let mode = MenuBarDisplayMode(rawValue: rawMode) {
            self.menuBarDisplayMode = mode
        } else {
            self.menuBarDisplayMode = .cloudQuota
        }

        let savedBudget = defaults.integer(forKey: "dailyTokenBudget")
        self.dailyTokenBudget = savedBudget > 0 ? savedBudget : 1_000_000

        self.geminiAccount1Email = defaults.string(forKey: "geminiAccount1Email") ?? "alexasolosix@gmail.com"
        self.geminiAccount2Email = defaults.string(forKey: "geminiAccount2Email") ?? "parasgandre@gmail.com"
        self.geminiAccount2ApiKey = defaults.string(forKey: "geminiAccount2ApiKey") ?? ""
        self.selectedGeminiAccountTab = defaults.string(forKey: "selectedGeminiAccountTab") ?? "alexasolosix@gmail.com"

        self.customAntigravityPath = defaults.string(forKey: "customAntigravityPath") ?? ""
        self.customClaudePath = defaults.string(forKey: "customClaudePath") ?? ""
        self.geminiApiKey = defaults.string(forKey: "geminiApiKey") ?? ""
        self.claudeApiKey = defaults.string(forKey: "claudeApiKey") ?? ""

        self.isDesktopWidgetVisible = defaults.bool(forKey: "isDesktopWidgetVisible")
        self.isDesktopWidgetCompact = defaults.bool(forKey: "isDesktopWidgetCompact")
        self.isDesktopWidgetPinned = defaults.bool(forKey: "isDesktopWidgetPinned")

        let savedOpacity = defaults.double(forKey: "widgetOpacity")
        self.widgetOpacity = savedOpacity > 0 ? savedOpacity : 0.95
    }
}
