import Foundation
import Security

public struct ClaudeCloudUsage: Codable {
    public var fiveHourUtilization: Double = 0.0 // percentage 0-100 used
    public var fiveHourRemaining: Double { max(0.0, 100.0 - fiveHourUtilization) }
    public var fiveHourResetDate: Date? = nil

    public var sevenDayUtilization: Double = 0.0 // percentage 0-100 used
    public var sevenDayRemaining: Double { max(0.0, 100.0 - sevenDayUtilization) }
    public var sevenDayResetDate: Date? = nil

    public var claudeCodeBreakdownPercent: Double = 100.0
    public var subscriptionType: String = "Pro"
    public var emailAddress: String = ""
    public var lastFetched: Date? = nil

    public var fiveHourResetCountdown: String {
        guard let reset = fiveHourResetDate else { return "rolling" }
        return ClaudeCloudUsage.formatCountdown(until: reset)
    }

    public var sevenDayResetCountdown: String {
        guard let reset = sevenDayResetDate else { return "weekly" }
        return ClaudeCloudUsage.formatCountdown(until: reset)
    }

    private static func formatCountdown(until date: Date) -> String {
        let diff = date.timeIntervalSince(Date())
        if diff <= 0 { return "now" }
        let days = Int(diff) / 86400
        let hours = (Int(diff) % 86400) / 3600
        let minutes = (Int(diff) % 3600) / 60
        if days > 0 {
            return "\(days)d \(hours)h"
        } else if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }
}

public final class ClaudeLiveService: @unchecked Sendable {
    public static let shared = ClaudeLiveService()

    private let isoDateFormatter: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return f
    }()
    private let isoDateFormatterNoFrac: ISO8601DateFormatter = {
        let f = ISO8601DateFormatter()
        f.formatOptions = [.withInternetDateTime]
        return f
    }()

    public init() {}

    public func getAccessToken() -> String? {
        // 1. Try Keychain
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        if (try? process.run()) != nil {
            process.waitUntilExit()
            if process.terminationStatus == 0 {
                let data = pipe.fileHandleForReading.readDataToEndOfFile()
                if let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                   let rawData = raw.data(using: .utf8),
                   let json = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
                   let claudeAi = json["claudeAiOauth"] as? [String: Any],
                   let token = claudeAi["accessToken"] as? String, !token.isEmpty {
                    return token
                }
            }
        }

        return nil
    }

    public func fetchLiveUsage() async -> ClaudeCloudUsage? {
        // First try live API if token exists
        if let token = getAccessToken() {
            if let usage = await fetchFromAnthropicAPI(token: token) {
                return usage
            }
        }

        // Fallback to ~/.claude.json cachedUsageUtilization
        return readFromLocalCache()
    }

    private func fetchFromAnthropicAPI(token: String) async -> ClaudeCloudUsage? {
        guard let url = URL(string: "https://api.anthropic.com/api/oauth/usage") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("oauth-2025-04-20", forHTTPHeaderField: "anthropic-beta")
        request.setValue("claude-code", forHTTPHeaderField: "User-Agent")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200 else {
                return nil
            }
            return parseUsageJSON(data: data)
        } catch {
            return nil
        }
    }

    public func readFromLocalCache() -> ClaudeCloudUsage? {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let claudeJson = home.appendingPathComponent(".claude.json")
        guard let data = try? Data(contentsOf: claudeJson),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let cachedUsage = json["cachedUsageUtilization"] as? [String: Any] else {
            return nil
        }

        guard let usageData = try? JSONSerialization.data(withJSONObject: cachedUsage) else {
            return nil
        }

        return parseUsageJSON(data: usageData)
    }

    private func parseUsageJSON(data: Data) -> ClaudeCloudUsage? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return nil }
        let dict = (root["utilization"] as? [String: Any]) ?? root

        var usage = ClaudeCloudUsage()
        usage.lastFetched = Date()

        if let fiveHour = dict["five_hour"] as? [String: Any] {
            if let u = fiveHour["utilization"] as? Double {
                usage.fiveHourUtilization = u
            } else if let uInt = fiveHour["utilization"] as? Int {
                usage.fiveHourUtilization = Double(uInt)
            }
            if let resetsAtStr = fiveHour["resets_at"] as? String {
                usage.fiveHourResetDate = parseDate(resetsAtStr)
            }
        }

        if let sevenDay = dict["seven_day"] as? [String: Any] {
            if let u = sevenDay["utilization"] as? Double {
                usage.sevenDayUtilization = u
            } else if let uInt = sevenDay["utilization"] as? Int {
                usage.sevenDayUtilization = Double(uInt)
            }
            if let resetsAtStr = sevenDay["resets_at"] as? String {
                usage.sevenDayResetDate = parseDate(resetsAtStr)
            }
        }

        if let breakdown = dict["seven_day_breakdown"] as? [String: Any],
           let rows = breakdown["rows"] as? [[String: Any]] {
            for r in rows {
                if let key = r["key"] as? String, key == "claude_code", let p = r["percent"] as? Double {
                    usage.claudeCodeBreakdownPercent = p
                }
            }
        }

        return usage
    }

    private func parseDate(_ str: String) -> Date? {
        isoDateFormatter.date(from: str) ?? isoDateFormatterNoFrac.date(from: str)
    }
}
