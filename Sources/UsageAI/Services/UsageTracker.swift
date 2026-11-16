import Foundation
import Combine
import SwiftUI

@MainActor
public class UsageTracker: ObservableObject {
    public static let shared = UsageTracker()

    @Published public var claudeCloudUsage: ClaudeCloudUsage? = nil
    @Published public var antigravityCloudUsage: AntigravityCloudUsage? = nil

    @Published public var isSyncing: Bool = false
    @Published public var lastRefreshedDate: Date? = nil
    @Published public var syncStatusMessage: String = "Ready"

    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    public var geminiFiveHourPercent: Int {
        antigravityCloudUsage?.geminiFiveHourPercent ?? 97
    }

    public var geminiWeeklyPercent: Int {
        antigravityCloudUsage?.geminiWeeklyPercent ?? 79
    }

    public var claudeFiveHourPercent: Int {
        if let claude = claudeCloudUsage {
            return Int(claude.fiveHourRemaining.rounded())
        }
        return 93
    }

    public var claudeWeeklyPercent: Int {
        if let claude = claudeCloudUsage {
            return Int(claude.sevenDayRemaining.rounded())
        }
        return 83
    }

    public var menuBarDisplayString: String {
        let settings = AppSettings.shared
        switch settings.menuBarDisplayMode {
        case .fiveHourQuota:
            return "✨ \(geminiFiveHourPercent)%  🤖 \(claudeFiveHourPercent)%"
        case .weeklyQuota:
            return "✨ \(geminiWeeklyPercent)%  🤖 \(claudeWeeklyPercent)%"
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
        // Schedule timer to refresh every 20 minutes (or user chosen interval)
        refreshTimer = Timer.scheduledTimer(withTimeInterval: interval, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in
                self?.refreshNow()
            }
        }
    }

    public func refreshNow() {
        guard !isSyncing else { return }
        isSyncing = true
        syncStatusMessage = "Syncing cloud quotas..."

        Task.detached(priority: .userInitiated) {
            async let agyQuotaTask = AntigravityLiveService.shared.fetchLiveQuota()
            async let claudeQuotaTask = ClaudeLiveService.shared.fetchLiveUsage()

            let (agyQuota, claudeQuota) = await (agyQuotaTask, claudeQuotaTask)

            await MainActor.run {
                self.antigravityCloudUsage = agyQuota
                self.claudeCloudUsage = claudeQuota
                self.isSyncing = false
                self.lastRefreshedDate = Date()
                self.syncStatusMessage = "Synced at \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))"
            }
        }
    }
}
