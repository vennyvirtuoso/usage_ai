import Foundation
import Security

public struct ClaudeCloudUsage: Codable {
    public var fiveHourUtilization: Double = 0.0 // percentage 0-100 used
    public var fiveHourRemaining: Double {
        if let reset = fiveHourResetDate, reset <= Date() {
            return 100.0
        }
        return max(0.0, 100.0 - fiveHourUtilization)
    }
    public var fiveHourResetDate: Date? = nil

    public var sevenDayUtilization: Double = 0.0 // percentage 0-100 used
    public var sevenDayRemaining: Double {
        if let reset = sevenDayResetDate, reset <= Date() {
            return 100.0
        }
        return max(0.0, 100.0 - sevenDayUtilization)
    }
    public var sevenDayResetDate: Date? = nil

    public var claudeCodeBreakdownPercent: Double = 100.0
    public var subscriptionType: String = "Pro"
    public var emailAddress: String = ""
    public var lastFetched: Date? = nil

    public var fiveHourResetCountdown: String {
        if AppSettings.shared.claudeManualOverrideEnabled {
            return AppSettings.shared.claudeSessionResetTime
        }
        guard let reset = fiveHourResetDate else { return "Ready" }
        if reset <= Date() { return "Ready" }
        return ClaudeCloudUsage.formatCountdown(until: reset)
    }

    public var sevenDayResetCountdown: String {
        guard let reset = sevenDayResetDate else { return "weekly" }
        if reset <= Date() { return "Ready" }
        return ClaudeCloudUsage.formatCountdown(until: reset)
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

    public struct ClaudeKeychainCredentials {
        public var accessToken: String
        public var refreshToken: String
        public var expiresAt: Double
        public var rawJSON: [String: Any]
    }

    public func readKeychainCredentials() -> ClaudeKeychainCredentials? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = ["find-generic-password", "-s", "Claude Code-credentials", "-w"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = Pipe()

        guard (try? process.run()) != nil else { return nil }
        process.waitUntilExit()
        guard process.terminationStatus == 0 else { return nil }

        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        guard let raw = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
              let rawData = raw.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: rawData) as? [String: Any],
              let claudeAi = json["claudeAiOauth"] as? [String: Any],
              let token = claudeAi["accessToken"] as? String, !token.isEmpty else {
            return nil
        }

        let refreshToken = claudeAi["refreshToken"] as? String ?? ""
        let expiresAt = claudeAi["expiresAt"] as? Double ?? 0.0

        return ClaudeKeychainCredentials(
            accessToken: token,
            refreshToken: refreshToken,
            expiresAt: expiresAt,
            rawJSON: json
        )
    }

    public func getAccessToken() -> String? {
        readKeychainCredentials()?.accessToken
    }

    public func saveCredentialsToKeychain(json: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let jsonStr = String(data: data, encoding: .utf8) else { return }

        let username = NSUserName()
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/security")
        process.arguments = [
            "add-generic-password",
            "-U",
            "-s", "Claude Code-credentials",
            "-a", username,
            "-w", jsonStr
        ]
        try? process.run()
        process.waitUntilExit()
    }

    public func refreshOAuthToken(refreshToken: String, existingJSON: [String: Any]) async -> String? {
        guard !refreshToken.isEmpty,
              let url = URL(string: "https://platform.claude.com/v1/oauth/token") else { return nil }

        let payload: [String: Any] = [
            "grant_type": "refresh_token",
            "refresh_token": refreshToken,
            "client_id": "9d1c250a-e61b-44d9-88ed-5944d1962f5e"
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: payload) else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("claude-code", forHTTPHeaderField: "User-Agent")
        request.httpBody = httpBody
        request.timeoutInterval = 15

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpRes = response as? HTTPURLResponse, httpRes.statusCode == 200,
                  let resJSON = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let newAccessToken = resJSON["access_token"] as? String else {
                return nil
            }

            let newRefreshToken = resJSON["refresh_token"] as? String ?? refreshToken
            let expiresIn = resJSON["expires_in"] as? Double ?? 28800.0
            let newExpiresAt = (Date().timeIntervalSince1970 + expiresIn) * 1000.0

            var updatedJSON = existingJSON
            var oauthDict = (updatedJSON["claudeAiOauth"] as? [String: Any]) ?? [:]
            oauthDict["accessToken"] = newAccessToken
            oauthDict["refreshToken"] = newRefreshToken
            oauthDict["expiresAt"] = newExpiresAt
            updatedJSON["claudeAiOauth"] = oauthDict

            self.saveCredentialsToKeychain(json: updatedJSON)
            return newAccessToken
        } catch {
            return nil
        }
    }

    private var rateLimitedUntil: Date? = nil

    public func fetchLiveUsage() async -> ClaudeCloudUsage? {
        // If web session / manual override is enabled in Preferences:
        if AppSettings.shared.claudeManualOverrideEnabled {
            var usage = ClaudeCloudUsage()
            usage.fiveHourUtilization = AppSettings.shared.claudeCurrentUsedPercent
            usage.lastFetched = Date()
            return usage
        }

        // If currently rate limited by Anthropic API (HTTP 429), avoid spamming and use cache
        if let until = rateLimitedUntil, until > Date() {
            return readFromLocalCache()
        }

        // 1. Custom token in Preferences (if set)
        let customToken = AppSettings.shared.claudeCustomToken.trimmingCharacters(in: .whitespacesAndNewlines)
        if !customToken.isEmpty {
            if let usage = await fetchFromAnthropicAPI(token: customToken) {
                return usage
            }
        }

        // 2. Keychain token with proactive auto-refresh
        if let creds = readKeychainCredentials() {
            var token = creds.accessToken
            let nowMs = Date().timeIntervalSince1970 * 1000.0

            // If token has expired or is expiring in under 5 minutes, refresh proactively!
            if creds.expiresAt > 0 && nowMs > (creds.expiresAt - 300_000.0) && !creds.refreshToken.isEmpty {
                if let refreshed = await refreshOAuthToken(refreshToken: creds.refreshToken, existingJSON: creds.rawJSON) {
                    token = refreshed
                }
            }

            if let usage = await fetchFromAnthropicAPI(token: token) {
                return usage
            }

            // If API returned failure (e.g. 401 Unauthorized), attempt refresh & retry
            if !creds.refreshToken.isEmpty {
                if let refreshed = await refreshOAuthToken(refreshToken: creds.refreshToken, existingJSON: creds.rawJSON) {
                    if let usage = await fetchFromAnthropicAPI(token: refreshed) {
                        return usage
                    }
                }
            }
        }

        // 3. Fallback to ~/.claude.json cachedUsageUtilization
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
            guard let httpRes = response as? HTTPURLResponse else { return nil }

            if httpRes.statusCode == 429 {
                let retryStr = httpRes.value(forHTTPHeaderField: "Retry-After") ?? "1200"
                let retrySec = Double(retryStr) ?? 1200.0
                self.rateLimitedUntil = Date().addingTimeInterval(retrySec)
                return nil
            }

            guard httpRes.statusCode == 200 else {
                return nil
            }
            self.rateLimitedUntil = nil
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
            var resetsInPast = false
            if let resetsAtStr = fiveHour["resets_at"] as? String,
               let rDate = parseDate(resetsAtStr) {
                if rDate <= Date() {
                    // Reset date is in the past! Quota has fully replenished.
                    resetsInPast = true
                    usage.fiveHourUtilization = 0.0
                    usage.fiveHourResetDate = nil
                } else {
                    usage.fiveHourResetDate = rDate
                }
            }

            if !resetsInPast {
                if let u = fiveHour["utilization"] as? Double {
                    usage.fiveHourUtilization = u
                } else if let uInt = fiveHour["utilization"] as? Int {
                    usage.fiveHourUtilization = Double(uInt)
                }
            }
        }

        if let sevenDay = dict["seven_day"] as? [String: Any] {
            var resetsInPast = false
            if let resetsAtStr = sevenDay["resets_at"] as? String,
               let rDate = parseDate(resetsAtStr) {
                if rDate <= Date() {
                    resetsInPast = true
                    usage.sevenDayUtilization = 0.0
                    usage.sevenDayResetDate = nil
                } else {
                    usage.sevenDayResetDate = rDate
                }
            }

            if !resetsInPast {
                if let u = sevenDay["utilization"] as? Double {
                    usage.sevenDayUtilization = u
                } else if let uInt = sevenDay["utilization"] as? Int {
                    usage.sevenDayUtilization = Double(uInt)
                }
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
