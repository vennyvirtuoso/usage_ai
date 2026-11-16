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

    public var cacheHitRatio: Double {
        let totalPrompt = inputTokens + cacheReadTokens
        guard totalPrompt > 0 else { return 0.0 }
        return Double(cacheReadTokens) / Double(totalPrompt)
    }

    public init(provider: AIProvider) {
        self.provider = provider
    }
}
