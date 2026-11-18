import Foundation

public struct SharedQuotaSnapshot: Codable {
    public var geminiFiveHourPercent: Int
    public var geminiWeeklyPercent: Int
    public var geminiFiveHourCountdown: String
    public var geminiWeeklyCountdown: String
    public var claudeFiveHourPercent: Int
    public var claudeWeeklyPercent: Int
    public var claudeFiveHourCountdown: String
    public var claudeWeeklyCountdown: String
    public var updatedAt: Date

    // Multi-account Gemini support
    public var selectedGeminiAccount: String
    public var account1Name: String
    public var account1FiveHour: Int
    public var account1Weekly: Int
    public var account1FiveHourCountdown: String
    public var account1WeeklyCountdown: String

    public var account2Name: String
    public var account2FiveHour: Int
    public var account2Weekly: Int
    public var account2FiveHourCountdown: String
    public var account2WeeklyCountdown: String

    public var account3Name: String
    public var account3FiveHour: Int
    public var account3Weekly: Int
    public var account3FiveHourCountdown: String
    public var account3WeeklyCountdown: String

    public var hasClaude: Bool
    public var hasGemini: Bool

    public init(
        geminiFiveHourPercent: Int,
        geminiWeeklyPercent: Int,
        geminiFiveHourCountdown: String,
        geminiWeeklyCountdown: String,
        claudeFiveHourPercent: Int,
        claudeWeeklyPercent: Int,
        claudeFiveHourCountdown: String,
        claudeWeeklyCountdown: String,
        updatedAt: Date = Date(),
        selectedGeminiAccount: String = "Account 1",
        account1Name: String = "Account 1",
        account1FiveHour: Int = 97,
        account1Weekly: Int = 79,
        account1FiveHourCountdown: String = "4h 39m",
        account1WeeklyCountdown: String = "4d 8h",
        account2Name: String = "Account 2",
        account2FiveHour: Int = 100,
        account2Weekly: Int = 100,
        account2FiveHourCountdown: String = "Ready",
        account2WeeklyCountdown: String = "7d limit",
        account3Name: String = "Account 3",
        account3FiveHour: Int = 100,
        account3Weekly: Int = 100,
        account3FiveHourCountdown: String = "Ready",
        account3WeeklyCountdown: String = "7d limit",
        hasClaude: Bool = true,
        hasGemini: Bool = true
    ) {
        self.geminiFiveHourPercent = geminiFiveHourPercent
        self.geminiWeeklyPercent = geminiWeeklyPercent
        self.geminiFiveHourCountdown = geminiFiveHourCountdown
        self.geminiWeeklyCountdown = geminiWeeklyCountdown
        self.claudeFiveHourPercent = claudeFiveHourPercent
        self.claudeWeeklyPercent = claudeWeeklyPercent
        self.claudeFiveHourCountdown = claudeFiveHourCountdown
        self.claudeWeeklyCountdown = claudeWeeklyCountdown
        self.updatedAt = updatedAt
        self.hasClaude = hasClaude
        self.hasGemini = hasGemini

        self.selectedGeminiAccount = selectedGeminiAccount
        self.account1Name = account1Name
        self.account1FiveHour = account1FiveHour
        self.account1Weekly = account1Weekly
        self.account1FiveHourCountdown = account1FiveHourCountdown
        self.account1WeeklyCountdown = account1WeeklyCountdown

        self.account2Name = account2Name
        self.account2FiveHour = account2FiveHour
        self.account2Weekly = account2Weekly
        self.account2FiveHourCountdown = account2FiveHourCountdown
        self.account2WeeklyCountdown = account2WeeklyCountdown

        self.account3Name = account3Name
        self.account3FiveHour = account3FiveHour
        self.account3Weekly = account3Weekly
        self.account3FiveHourCountdown = account3FiveHourCountdown
        self.account3WeeklyCountdown = account3WeeklyCountdown
    }

    enum CodingKeys: String, CodingKey {
        case geminiFiveHourPercent, geminiWeeklyPercent, geminiFiveHourCountdown, geminiWeeklyCountdown
        case claudeFiveHourPercent, claudeWeeklyPercent, claudeFiveHourCountdown, claudeWeeklyCountdown
        case updatedAt
        case selectedGeminiAccount
        case account1Name, account1FiveHour, account1Weekly, account1FiveHourCountdown, account1WeeklyCountdown
        case account2Name, account2FiveHour, account2Weekly, account2FiveHourCountdown, account2WeeklyCountdown
        case account3Name, account3FiveHour, account3Weekly, account3FiveHourCountdown, account3WeeklyCountdown
        case hasClaude, hasGemini
    }

    public init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        geminiFiveHourPercent = try c.decodeIfPresent(Int.self, forKey: .geminiFiveHourPercent) ?? 97
        geminiWeeklyPercent = try c.decodeIfPresent(Int.self, forKey: .geminiWeeklyPercent) ?? 79
        geminiFiveHourCountdown = try c.decodeIfPresent(String.self, forKey: .geminiFiveHourCountdown) ?? "4h 39m"
        geminiWeeklyCountdown = try c.decodeIfPresent(String.self, forKey: .geminiWeeklyCountdown) ?? "4d 8h"
        claudeFiveHourPercent = try c.decodeIfPresent(Int.self, forKey: .claudeFiveHourPercent) ?? 100
        claudeWeeklyPercent = try c.decodeIfPresent(Int.self, forKey: .claudeWeeklyPercent) ?? 83
        claudeFiveHourCountdown = try c.decodeIfPresent(String.self, forKey: .claudeFiveHourCountdown) ?? "Ready"
        claudeWeeklyCountdown = try c.decodeIfPresent(String.self, forKey: .claudeWeeklyCountdown) ?? "1d 15h"
        updatedAt = try c.decodeIfPresent(Date.self, forKey: .updatedAt) ?? Date()

        hasClaude = try c.decodeIfPresent(Bool.self, forKey: .hasClaude) ?? true
        hasGemini = try c.decodeIfPresent(Bool.self, forKey: .hasGemini) ?? true

        selectedGeminiAccount = try c.decodeIfPresent(String.self, forKey: .selectedGeminiAccount) ?? "Account 1"
        account1Name = try c.decodeIfPresent(String.self, forKey: .account1Name) ?? "Account 1"
        account1FiveHour = try c.decodeIfPresent(Int.self, forKey: .account1FiveHour) ?? geminiFiveHourPercent
        account1Weekly = try c.decodeIfPresent(Int.self, forKey: .account1Weekly) ?? geminiWeeklyPercent
        account1FiveHourCountdown = try c.decodeIfPresent(String.self, forKey: .account1FiveHourCountdown) ?? geminiFiveHourCountdown
        account1WeeklyCountdown = try c.decodeIfPresent(String.self, forKey: .account1WeeklyCountdown) ?? geminiWeeklyCountdown

        account2Name = try c.decodeIfPresent(String.self, forKey: .account2Name) ?? "Account 2"
        account2FiveHour = try c.decodeIfPresent(Int.self, forKey: .account2FiveHour) ?? 100
        account2Weekly = try c.decodeIfPresent(Int.self, forKey: .account2Weekly) ?? 100
        account2FiveHourCountdown = try c.decodeIfPresent(String.self, forKey: .account2FiveHourCountdown) ?? "Ready"
        account2WeeklyCountdown = try c.decodeIfPresent(String.self, forKey: .account2WeeklyCountdown) ?? "7d limit"

        account3Name = try c.decodeIfPresent(String.self, forKey: .account3Name) ?? "Account 3"
        account3FiveHour = try c.decodeIfPresent(Int.self, forKey: .account3FiveHour) ?? 100
        account3Weekly = try c.decodeIfPresent(Int.self, forKey: .account3Weekly) ?? 100
        account3FiveHourCountdown = try c.decodeIfPresent(String.self, forKey: .account3FiveHourCountdown) ?? "Ready"
        account3WeeklyCountdown = try c.decodeIfPresent(String.self, forKey: .account3WeeklyCountdown) ?? "7d limit"
    }

    public static func load() -> SharedQuotaSnapshot? {
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let url = appSupport.appendingPathComponent("UsageAI/quota_snapshot.json")
            if let data = try? Data(contentsOf: url),
               let decoded = try? JSONDecoder().decode(SharedQuotaSnapshot.self, from: data) {
                return decoded
            }
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        for containerId in ["com.gheekhatam.mac.widget", "com.usageai.mac.widget"] {
            let widgetFileURL = home.appendingPathComponent("Library/Containers/\(containerId)/Data/Library/Application Support/UsageAI/quota_snapshot.json")
            if let data = try? Data(contentsOf: widgetFileURL),
               let decoded = try? JSONDecoder().decode(SharedQuotaSnapshot.self, from: data) {
                return decoded
            }
        }
        return nil
    }

    public func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }

        // 1. Write to main app support directory
        if let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first {
            let dir = appSupport.appendingPathComponent("UsageAI", isDirectory: true)
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            let fileURL = dir.appendingPathComponent("quota_snapshot.json")
            try? data.write(to: fileURL, options: .atomic)
        }

        // 2. Also write directly to widget container directory so the sandboxed widget has it ready
        let home = FileManager.default.homeDirectoryForCurrentUser
        for containerId in ["com.gheekhatam.mac.widget", "com.usageai.mac.widget"] {
            let widgetDir = home.appendingPathComponent("Library/Containers/\(containerId)/Data/Library/Application Support/UsageAI", isDirectory: true)
            try? FileManager.default.createDirectory(at: widgetDir, withIntermediateDirectories: true)
            let widgetFileURL = widgetDir.appendingPathComponent("quota_snapshot.json")
            try? data.write(to: widgetFileURL, options: .atomic)
        }
    }

    public static func toggleAccount(to target: String) {
        if var snapshot = SharedQuotaSnapshot.load() {
            snapshot.selectedGeminiAccount = target
            if target == snapshot.account3Name {
                snapshot.geminiFiveHourPercent = snapshot.account3FiveHour
                snapshot.geminiWeeklyPercent = snapshot.account3Weekly
                snapshot.geminiFiveHourCountdown = snapshot.account3FiveHourCountdown
                snapshot.geminiWeeklyCountdown = snapshot.account3WeeklyCountdown
            } else if target == snapshot.account2Name || target.contains("paras") {
                snapshot.geminiFiveHourPercent = snapshot.account2FiveHour
                snapshot.geminiWeeklyPercent = snapshot.account2Weekly
                snapshot.geminiFiveHourCountdown = snapshot.account2FiveHourCountdown
                snapshot.geminiWeeklyCountdown = snapshot.account2WeeklyCountdown
            } else {
                snapshot.geminiFiveHourPercent = snapshot.account1FiveHour
                snapshot.geminiWeeklyPercent = snapshot.account1Weekly
                snapshot.geminiFiveHourCountdown = snapshot.account1FiveHourCountdown
                snapshot.geminiWeeklyCountdown = snapshot.account1WeeklyCountdown
            }
            snapshot.save()
        }
    }
}
