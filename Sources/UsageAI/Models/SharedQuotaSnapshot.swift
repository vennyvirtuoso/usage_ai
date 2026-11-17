import Foundation

public struct SharedQuotaSnapshot: Codable {
    public let geminiFiveHourPercent: Int
    public let geminiWeeklyPercent: Int
    public let geminiFiveHourCountdown: String
    public let geminiWeeklyCountdown: String
    public let claudeFiveHourPercent: Int
    public let claudeWeeklyPercent: Int
    public let claudeFiveHourCountdown: String
    public let claudeWeeklyCountdown: String
    public let updatedAt: Date

    public init(
        geminiFiveHourPercent: Int,
        geminiWeeklyPercent: Int,
        geminiFiveHourCountdown: String,
        geminiWeeklyCountdown: String,
        claudeFiveHourPercent: Int,
        claudeWeeklyPercent: Int,
        claudeFiveHourCountdown: String,
        claudeWeeklyCountdown: String,
        updatedAt: Date = Date()
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
    }

    public static func load() -> SharedQuotaSnapshot? {
        guard let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            return nil
        }
        let url = appSupport.appendingPathComponent("UsageAI/quota_snapshot.json")
        guard let data = try? Data(contentsOf: url) else { return nil }
        return try? JSONDecoder().decode(SharedQuotaSnapshot.self, from: data)
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
        let widgetDir = home.appendingPathComponent("Library/Containers/com.usageai.mac.widget/Data/Library/Application Support/UsageAI", isDirectory: true)
        try? FileManager.default.createDirectory(at: widgetDir, withIntermediateDirectories: true)
        let widgetFileURL = widgetDir.appendingPathComponent("quota_snapshot.json")
        try? data.write(to: widgetFileURL, options: .atomic)
    }
}
