import Foundation

public enum AIProvider: String, CaseIterable, Codable, Identifiable {
    case geminiAntigravity = "gemini_antigravity"
    case claude = "claude"

    public var id: String { rawValue }

    public var displayName: String {
        switch self {
        case .geminiAntigravity:
            return "Gemini / Antigravity"
        case .claude:
            return "Claude (Anthropic)"
        }
    }

    public var shortName: String {
        switch self {
        case .geminiAntigravity:
            return "Gemini"
        case .claude:
            return "Claude"
        }
    }

    public var iconSymbol: String {
        switch self {
        case .geminiAntigravity:
            return "sparkles"
        case .claude:
            return "brain.head.profile"
        }
    }

    public var brandEmoji: String {
        switch self {
        case .geminiAntigravity:
            return "✨"
        case .claude:
            return "🤖"
        }
    }
}

public struct ModelSpecs {
    public static func contextWindow(for model: String, provider: AIProvider) -> Int {
        let lower = model.lowercased()
        if lower.contains("1.5-pro") || lower.contains("2.0-pro") {
            return 2_097_152 // 2 Million
        }
        if lower.contains("gemini") {
            return 1_048_576 // 1 Million
        }
        if lower.contains("claude") {
            return 200_000 // 200k
        }
        return provider == .claude ? 200_000 : 1_048_576
    }

    public static func defaultDailyQuota(for provider: AIProvider) -> (requests: Int, tokens: Int) {
        switch provider {
        case .geminiAntigravity:
            return (1500, 4_000_000)
        case .claude:
            return (1000, 2_500_000)
        }
    }
}

public struct TokenRecord: Identifiable, Codable {
    public let id: String
    public let provider: AIProvider
    public let model: String
    public let inputTokens: Int
    public let outputTokens: Int
    public let cacheReadTokens: Int
    public let cacheWriteTokens: Int
    public let timestamp: Date
    public let sourceFile: String

    public var totalTokens: Int {
        inputTokens + outputTokens + cacheReadTokens + cacheWriteTokens
    }

    public var contextTokens: Int {
        inputTokens + cacheReadTokens + outputTokens
    }

    public init(
        id: String = UUID().uuidString,
        provider: AIProvider,
        model: String,
        inputTokens: Int,
        outputTokens: Int,
        cacheReadTokens: Int = 0,
        cacheWriteTokens: Int = 0,
        timestamp: Date = Date(),
        sourceFile: String = ""
    ) {
        self.id = id
        self.provider = provider
        self.model = model
        self.inputTokens = inputTokens
        self.outputTokens = outputTokens
        self.cacheReadTokens = cacheReadTokens
        self.cacheWriteTokens = cacheWriteTokens
        self.timestamp = timestamp
        self.sourceFile = sourceFile
    }
}

public struct QuotaInfo: Codable {
    public var contextTokensCurrentSession: Int = 0
    public var contextWindowLimit: Int = 200_000
    public var dailyRequestsUsed: Int = 0
    public var dailyRequestsLimit: Int = 1500
    public var dailyTokensUsed: Int = 0
    public var dailyTokensLimit: Int = 4_000_000
    public var tierName: String = "Standard Tier"

    public var contextPercent: Double {
        guard contextWindowLimit > 0 else { return 0.0 }
        return Double(contextTokensCurrentSession) / Double(contextWindowLimit)
    }

    public var quotaRemainingPercent: Double {
        guard dailyTokensLimit > 0 else { return 1.0 }
        let used = Double(dailyTokensUsed) / Double(dailyTokensLimit)
        return max(0.0, 1.0 - used)
    }

    public var requestsRemaining: Int {
        max(0, dailyRequestsLimit - dailyRequestsUsed)
    }

    public var timeUntilResetString: String {
        let calendar = Calendar(identifier: .gregorian)
        var utcCalendar = calendar
        if let utc = TimeZone(secondsFromGMT: 0) {
            utcCalendar.timeZone = utc
        }
        let now = Date()
        guard let tomorrow = utcCalendar.date(byAdding: .day, value: 1, to: now),
              let midnight = utcCalendar.date(bySettingHour: 0, minute: 0, second: 0, of: tomorrow) else {
            return "midnight UTC"
        }

        let diff = midnight.timeIntervalSince(now)
        let hours = Int(diff) / 3600
        let minutes = (Int(diff) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }

    public init() {}
}

public struct ProviderUsageSummary: Identifiable {
    public var id: AIProvider { provider }
    public let provider: AIProvider
    public var totalTokens: Int = 0
    public var inputTokens: Int = 0
    public var outputTokens: Int = 0
    public var cacheReadTokens: Int = 0
    public var cacheWriteTokens: Int = 0
    public var todayTokens: Int = 0
    public var todayInputTokens: Int = 0
    public var todayOutputTokens: Int = 0
    public var todayCachedTokens: Int = 0
    public var estimatedTotalCost: Double = 0.0
    public var estimatedTodayCost: Double = 0.0
    public var modelCounts: [String: Int] = [:] // model -> total tokens
    public var lastActivityDate: Date?
    public var latestModel: String = ""
    public var quota: QuotaInfo = QuotaInfo()

    public var cacheHitRatio: Double {
        let totalPrompt = inputTokens + cacheReadTokens
        guard totalPrompt > 0 else { return 0.0 }
        return Double(cacheReadTokens) / Double(totalPrompt)
    }

    public init(provider: AIProvider) {
        self.provider = provider
        let defaults = ModelSpecs.defaultDailyQuota(for: provider)
        self.quota.dailyRequestsLimit = defaults.requests
        self.quota.dailyTokensLimit = defaults.tokens
        self.quota.contextWindowLimit = ModelSpecs.contextWindow(for: "", provider: provider)
    }
}
