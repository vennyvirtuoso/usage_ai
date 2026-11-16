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

    public static var storageURL: URL {
        let appSupport = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = appSupport.appendingPathComponent("UsageAI", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir.appendingPathComponent("quota_snapshot.json")
    }

    public static func load() -> SharedQuotaSnapshot? {
        guard let data = try? Data(contentsOf: storageURL) else { return nil }
        return try? JSONDecoder().decode(SharedQuotaSnapshot.self, from: data)
    }

    public func save() {
        guard let data = try? JSONEncoder().encode(self) else { return }
        try? data.write(to: Self.storageURL, options: .atomic)
    }
}
