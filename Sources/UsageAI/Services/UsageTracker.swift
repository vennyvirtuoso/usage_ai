import Foundation
import Combine
import SwiftUI

@MainActor
public class UsageTracker: ObservableObject {
    public static let shared = UsageTracker()

    @Published public var geminiSummary = ProviderUsageSummary(provider: .geminiAntigravity)
    @Published public var claudeSummary = ProviderUsageSummary(provider: .claude)

    @Published public var allRecords: [TokenRecord] = []
    @Published public var isScanning: Bool = false
    @Published public var lastRefreshedDate: Date? = nil
    @Published public var scanStatusMessage: String = "Ready"

    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    public var totalTokensToday: Int {
        geminiSummary.todayTokens + claudeSummary.todayTokens
    }

    public var totalTokensAllTime: Int {
        geminiSummary.totalTokens + claudeSummary.totalTokens
    }

    public var totalCostToday: Double {
        geminiSummary.estimatedTodayCost + claudeSummary.estimatedTodayCost
    }

    public var totalCostAllTime: Double {
        geminiSummary.estimatedTotalCost + claudeSummary.estimatedTotalCost
    }

    public var totalRequestsToday: Int {
        geminiSummary.quota.dailyRequestsUsed + claudeSummary.quota.dailyRequestsUsed
    }

    public var menuBarDisplayString: String {
        let settings = AppSettings.shared
        switch settings.menuBarDisplayMode {
        case .bothTokens:
            let gStr = formatTokens(geminiSummary.todayTokens)
            let cStr = formatTokens(claudeSummary.todayTokens)
            return "✨ \(gStr) | 🤖 \(cStr)"
        case .totalTokens:
            let totStr = formatTokens(totalTokensToday)
            return "⚡ \(totStr)"
        case .withCost:
            let totStr = formatTokens(totalTokensToday)
            let costStr = String(format: "$%.2f", totalCostToday)
            return "⚡ \(totStr) · \(costStr)"
        case .compactIcon:
            return ""
        }
    }

    private init() {
        startTimer()
        setupObservers()
        refreshNow()
    }

    private func setupObservers() {
        AppSettings.shared.$refreshIntervalSeconds
            .dropFirst()
            .sink { [weak self] _ in
                self?.startTimer()
            }
            .store(in: &cancellables)
    }

    public func startTimer() {
        refreshTimer?.invalidate()
        let interval = AppSettings.shared.refreshIntervalSeconds
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNow()
            }
        }
    }

    public func refreshNow() {
        guard !isScanning else { return }
        isScanning = true
        scanStatusMessage = "Scanning transcripts..."

        let settings = AppSettings.shared
        let customGemini = settings.customAntigravityPath
        let customClaude = settings.customClaudePath

        Task.detached(priority: .userInitiated) {
            let antigravityRecords = AntigravityScanner.shared.scanLogs(customPath: customGemini)
            let claudeRecords = ClaudeScanner.shared.scanLogs(customPath: customClaude)
            let combined = antigravityRecords + claudeRecords

            await MainActor.run {
                self.processRecords(antigravityRecords: antigravityRecords, claudeRecords: claudeRecords, all: combined)
                self.isScanning = false
                self.lastRefreshedDate = Date()
                self.scanStatusMessage = "Updated at \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))"
            }
        }
    }

    private func processRecords(antigravityRecords: [TokenRecord], claudeRecords: [TokenRecord], all: [TokenRecord]) {
        self.allRecords = all.sorted(by: { $0.timestamp > $1.timestamp })

        var gemini = ProviderUsageSummary(provider: .geminiAntigravity)
        var claude = ProviderUsageSummary(provider: .claude)

        let calendar = Calendar.current
        let today = Date()

        // Process Gemini records
        var geminiTodayCount = 0
        for rec in antigravityRecords {
            gemini.totalTokens += rec.totalTokens
            gemini.inputTokens += rec.inputTokens
            gemini.outputTokens += rec.outputTokens
            gemini.cacheReadTokens += rec.cacheReadTokens
            gemini.cacheWriteTokens += rec.cacheWriteTokens

            let cost = PricingCalculator.shared.calculateCost(for: rec)
            gemini.estimatedTotalCost += cost

            if calendar.isDate(rec.timestamp, inSameDayAs: today) {
                gemini.todayTokens += rec.totalTokens
                gemini.todayInputTokens += rec.inputTokens
                gemini.todayOutputTokens += rec.outputTokens
                gemini.todayCachedTokens += rec.cacheReadTokens
                gemini.estimatedTodayCost += cost
                geminiTodayCount += 1
            }

            gemini.modelCounts[rec.model, default: 0] += rec.totalTokens

            if gemini.lastActivityDate == nil || (rec.timestamp > gemini.lastActivityDate!) {
                gemini.lastActivityDate = rec.timestamp
            }
        }

        // Gemini CLI /quota & context window calculations
        if let latestGemini = antigravityRecords.sorted(by: { $0.timestamp > $1.timestamp }).first {
            gemini.latestModel = latestGemini.model
            gemini.quota.contextTokensCurrentSession = latestGemini.contextTokens
            gemini.quota.contextWindowLimit = ModelSpecs.contextWindow(for: latestGemini.model, provider: .geminiAntigravity)
        }
        gemini.quota.dailyRequestsUsed = geminiTodayCount
        gemini.quota.dailyTokensUsed = gemini.todayTokens

        // Process Claude records
        var claudeTodayCount = 0
        for rec in claudeRecords {
            claude.totalTokens += rec.totalTokens
            claude.inputTokens += rec.inputTokens
            claude.outputTokens += rec.outputTokens
            claude.cacheReadTokens += rec.cacheReadTokens
            claude.cacheWriteTokens += rec.cacheWriteTokens

            let cost = PricingCalculator.shared.calculateCost(for: rec)
            claude.estimatedTotalCost += cost

            if calendar.isDate(rec.timestamp, inSameDayAs: today) {
                claude.todayTokens += rec.totalTokens
                claude.todayInputTokens += rec.inputTokens
                claude.todayOutputTokens += rec.outputTokens
                claude.todayCachedTokens += rec.cacheReadTokens
                claude.estimatedTodayCost += cost
                claudeTodayCount += 1
            }

            claude.modelCounts[rec.model, default: 0] += rec.totalTokens

            if claude.lastActivityDate == nil || (rec.timestamp > claude.lastActivityDate!) {
                claude.lastActivityDate = rec.timestamp
            }
        }

        // Claude CLI /quota & context window calculations
        if let latestClaude = claudeRecords.sorted(by: { $0.timestamp > $1.timestamp }).first {
            claude.latestModel = latestClaude.model
            claude.quota.contextTokensCurrentSession = latestClaude.contextTokens
            claude.quota.contextWindowLimit = ModelSpecs.contextWindow(for: latestClaude.model, provider: .claude)
        }
        claude.quota.dailyRequestsUsed = claudeTodayCount
        claude.quota.dailyTokensUsed = claude.todayTokens

        self.geminiSummary = gemini
        self.claudeSummary = claude
    }

    public func formatTokens(_ count: Int) -> String {
        if count >= 1_000_000 {
            return String(format: "%.1fM", Double(count) / 1_000_000.0)
        } else if count >= 1_000 {
            return String(format: "%.1fk", Double(count) / 1_000.0)
        } else {
            return "\(count)"
        }
    }

    public func formatFullNumber(_ count: Int) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        return formatter.string(from: NSNumber(value: count)) ?? "\(count)"
    }
}
