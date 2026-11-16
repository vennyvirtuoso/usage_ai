import Foundation

public struct PricingModel {
    public let inputPerMillion: Double
    public let outputPerMillion: Double
    public let cacheReadPerMillion: Double
    public let cacheWritePerMillion: Double

    public func calculateCost(input: Int, output: Int, cacheRead: Int = 0, cacheWrite: Int = 0) -> Double {
        let inputCost = (Double(input) / 1_000_000.0) * inputPerMillion
        let outputCost = (Double(output) / 1_000_000.0) * outputPerMillion
        let cacheReadCost = (Double(cacheRead) / 1_000_000.0) * cacheReadPerMillion
        let cacheWriteCost = (Double(cacheWrite) / 1_000_000.0) * cacheWritePerMillion
        return inputCost + outputCost + cacheReadCost + cacheWriteCost
    }
}

public class PricingCalculator {
    public static let shared = PricingCalculator()

    private let models: [String: PricingModel] = [
        // Claude Models
        "claude-3-5-sonnet": PricingModel(inputPerMillion: 3.00, outputPerMillion: 15.00, cacheReadPerMillion: 0.30, cacheWritePerMillion: 3.75),
        "claude-3-7-sonnet": PricingModel(inputPerMillion: 3.00, outputPerMillion: 15.00, cacheReadPerMillion: 0.30, cacheWritePerMillion: 3.75),
        "claude-3-opus": PricingModel(inputPerMillion: 15.00, outputPerMillion: 75.00, cacheReadPerMillion: 1.50, cacheWritePerMillion: 18.75),
        "claude-3-5-haiku": PricingModel(inputPerMillion: 0.80, outputPerMillion: 4.00, cacheReadPerMillion: 0.08, cacheWritePerMillion: 1.00),
        "claude-3-haiku": PricingModel(inputPerMillion: 0.25, outputPerMillion: 1.25, cacheReadPerMillion: 0.03, cacheWritePerMillion: 0.30),

        // Gemini Models
        "gemini-3.8-flash": PricingModel(inputPerMillion: 0.10, outputPerMillion: 0.40, cacheReadPerMillion: 0.025, cacheWritePerMillion: 0.10),
        "gemini-3.8-flash-medium": PricingModel(inputPerMillion: 0.10, outputPerMillion: 0.40, cacheReadPerMillion: 0.025, cacheWritePerMillion: 0.10),
        "gemini-2.0-flash": PricingModel(inputPerMillion: 0.10, outputPerMillion: 0.40, cacheReadPerMillion: 0.025, cacheWritePerMillion: 0.10),
        "gemini-1.5-pro": PricingModel(inputPerMillion: 1.25, outputPerMillion: 5.00, cacheReadPerMillion: 0.3125, cacheWritePerMillion: 1.25),
        "gemini-1.5-flash": PricingModel(inputPerMillion: 0.075, outputPerMillion: 0.30, cacheReadPerMillion: 0.01875, cacheWritePerMillion: 0.075),
        "gemini-pro": PricingModel(inputPerMillion: 0.50, outputPerMillion: 1.50, cacheReadPerMillion: 0.10, cacheWritePerMillion: 0.50)
    ]

    private let fallbackClaude = PricingModel(inputPerMillion: 3.00, outputPerMillion: 15.00, cacheReadPerMillion: 0.30, cacheWritePerMillion: 3.75)
    private let fallbackGemini = PricingModel(inputPerMillion: 0.15, outputPerMillion: 0.60, cacheReadPerMillion: 0.035, cacheWritePerMillion: 0.15)

    public func pricing(for modelName: String, provider: AIProvider) -> PricingModel {
        let lower = modelName.lowercased()
        for (pattern, model) in models {
            if lower.contains(pattern) {
                return model
            }
        }
        return provider == .claude ? fallbackClaude : fallbackGemini
    }

    public func calculateCost(for record: TokenRecord) -> Double {
        let priceModel = pricing(for: record.model, provider: record.provider)
        return priceModel.calculateCost(
            input: record.inputTokens,
            output: record.outputTokens,
            cacheRead: record.cacheReadTokens,
            cacheWrite: record.cacheWriteTokens
        )
    }
}
