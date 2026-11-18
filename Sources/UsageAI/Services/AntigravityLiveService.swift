import Foundation

public struct GeminiAccountQuota: Identifiable, Codable {
    public var id: String { email }
    public var email: String
    public var fiveHourRemaining: Double = 1.0 // 0.0 to 1.0
    public var fiveHourResetCountdown: String = "4h 39m"
    public var weeklyRemaining: Double = 1.0 // 0.0 to 1.0
    public var weeklyResetCountdown: String = "4d 8h"
    public var isConnected: Bool = true
    public var tierName: String = "Antigravity Plan"

    public var fiveHourPercent: Int {
        Int((fiveHourRemaining * 100.0).rounded())
    }

    public var weeklyPercent: Int {
        Int((weeklyRemaining * 100.0).rounded())
    }

    public init(
        email: String,
        fiveHourRemaining: Double = 1.0,
        fiveHourResetCountdown: String = "4h 39m",
        weeklyRemaining: Double = 1.0,
        weeklyResetCountdown: String = "4d 8h",
        isConnected: Bool = true,
        tierName: String = "Antigravity Plan"
    ) {
        self.email = email
        self.fiveHourRemaining = fiveHourRemaining
        self.fiveHourResetCountdown = fiveHourResetCountdown
        self.weeklyRemaining = weeklyRemaining
        self.weeklyResetCountdown = weeklyResetCountdown
        self.isConnected = isConnected
        self.tierName = tierName
    }
}

public struct AntigravityCloudUsage: Codable {
    public var accounts: [GeminiAccountQuota] = []
    public var activeAccountEmail: String = "user1@gmail.com"

    public var geminiFiveHourRemaining: Double = 1.0 // 0.0 to 1.0
    public var geminiFiveHourResetDate: Date? = nil

    public var geminiWeeklyRemaining: Double = 1.0 // 0.0 to 1.0
    public var geminiWeeklyResetDate: Date? = nil
    public var geminiWeeklyDescription: String = ""

    public var thirdPartyWeeklyRemaining: Double = 1.0
    public var thirdPartyFiveHourRemaining: Double = 1.0

    public var lastFetched: Date? = nil

    public var geminiFiveHourPercent: Int {
        Int((geminiFiveHourRemaining * 100.0).rounded())
    }

    public var geminiWeeklyPercent: Int {
        Int((geminiWeeklyRemaining * 100.0).rounded())
    }

    public var fiveHourResetCountdown: String {
        guard let reset = geminiFiveHourResetDate else { return "5h limit" }
        return AntigravityCloudUsage.formatCountdown(until: reset)
    }

    public var weeklyResetCountdown: String {
        guard let reset = geminiWeeklyResetDate else { return "weekly limit" }
        return AntigravityCloudUsage.formatCountdown(until: reset)
    }

    private static func formatCountdown(until date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        if diff <= 0 { return "Ready" }
        let days = Int(diff) / 86400
        let hours = (Int(diff) % 86400) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else if minutes > 0 {
            return "\(minutes)m"
        } else {
            return "< 1m"
        }
    }
}

public final class AntigravityLiveService: @unchecked Sendable {
    public static let shared = AntigravityLiveService()

    private let isoDateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    public init() {}

    public func findAgyBinary() -> String? {
        let fileManager = FileManager.default
        let home = fileManager.homeDirectoryForCurrentUser.path
        let possiblePaths = [
            "\(home)/.gemini/bin/agy",
            "\(home)/.local/bin/agy",
            "/usr/local/bin/agy",
            "/opt/homebrew/bin/agy"
        ]

        for p in possiblePaths {
            if fileManager.fileExists(atPath: p) {
                return p
            }
        }
        return nil
    }

    public func fetchLiveQuota() async -> AntigravityCloudUsage? {
        guard let agyPath = findAgyBinary() else { return nil }

        let usage: AntigravityCloudUsage? = await withCheckedContinuation { continuation in
            DispatchQueue.global(qos: .userInitiated).async {
                let process = Process()
                process.executableURL = URL(fileURLWithPath: agyPath)
                process.arguments = ["-p", "/quota", "--output-format", "json"]

                let pipe = Pipe()
                process.standardOutput = pipe
                process.standardError = Pipe()

                do {
                    try process.run()
                    process.waitUntilExit()

                    let data = pipe.fileHandleForReading.readDataToEndOfFile()
                    if let parsed = self.parseAgyOutput(data: data) {
                        continuation.resume(returning: parsed)
                    } else {
                        continuation.resume(returning: nil)
                    }
                } catch {
                    continuation.resume(returning: nil)
                }
            }
        }

        var result = usage ?? AntigravityCloudUsage()

        // Populate configured accounts
        let email1 = AppSettings.shared.geminiAccount1Email
        let email2 = AppSettings.shared.geminiAccount2Email
        let email3 = AppSettings.shared.geminiAccount3Email

        let acc1 = GeminiAccountQuota(
            email: email1,
            fiveHourRemaining: result.geminiFiveHourRemaining,
            fiveHourResetCountdown: result.fiveHourResetCountdown,
            weeklyRemaining: result.geminiWeeklyRemaining,
            weeklyResetCountdown: result.weeklyResetCountdown,
            isConnected: true,
            tierName: "Antigravity Cloud"
        )

        // Account 2
        let acc2 = GeminiAccountQuota(
            email: email2,
            fiveHourRemaining: 1.0,
            fiveHourResetCountdown: "5h limit",
            weeklyRemaining: 1.0,
            weeklyResetCountdown: "7d limit",
            isConnected: true,
            tierName: "Gemini Account"
        )

        var accounts = [acc1, acc2]
        if !email3.isEmpty {
            let acc3 = GeminiAccountQuota(
                email: email3,
                fiveHourRemaining: 1.0,
                fiveHourResetCountdown: "5h limit",
                weeklyRemaining: 1.0,
                weeklyResetCountdown: "7d limit",
                isConnected: true,
                tierName: "Gemini Account"
            )
            accounts.append(acc3)
        }

        result.accounts = accounts
        result.activeAccountEmail = email1

        return result
    }

    public func parseAgyOutput(data: Data) -> AntigravityCloudUsage? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let command = root["command"] as? [String: Any],
              let dataDict = command["data"] as? [String: Any],
              let groups = dataDict["groups"] as? [[String: Any]] else {
            return nil
        }

        var result = AntigravityCloudUsage()
        result.lastFetched = Date()

        for group in groups {
            guard let name = group["name"] as? String,
                  let buckets = group["buckets"] as? [[String: Any]] else { continue }

            if name.lowercased().contains("gemini") {
                for b in buckets {
                    let id = b["id"] as? String ?? ""
                    let rem = b["remaining_fraction"] as? Double ?? 1.0
                    let resetStr = b["reset_time"] as? String
                    let desc = b["description"] as? String ?? ""

                    if id.contains("5h") {
                        result.geminiFiveHourRemaining = rem
                        if let rStr = resetStr {
                            result.geminiFiveHourResetDate = self.isoDateFormatter.date(from: rStr)
                        }
                    } else if id.contains("weekly") {
                        result.geminiWeeklyRemaining = rem
                        result.geminiWeeklyDescription = desc
                        if let rStr = resetStr {
                            result.geminiWeeklyResetDate = self.isoDateFormatter.date(from: rStr)
                        }
                    }
                }
            } else if name.lowercased().contains("claude") || name.lowercased().contains("gpt") {
                for b in buckets {
                    let id = b["id"] as? String ?? ""
                    let rem = b["remaining_fraction"] as? Double ?? 1.0
                    if id.contains("weekly") {
                        result.thirdPartyWeeklyRemaining = rem
                    } else if id.contains("5h") {
                        result.thirdPartyFiveHourRemaining = rem
                    }
                }
            }
        }

        return result
    }
}
