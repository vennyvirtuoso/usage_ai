import Foundation
import Combine
import SwiftUI
import WidgetKit

@MainActor
public class UsageTracker: ObservableObject {
    public static let shared = UsageTracker()

    @Published public var claudeCloudUsage: ClaudeCloudUsage? = nil
    @Published public var antigravityCloudUsage: AntigravityCloudUsage? = nil

    @Published public var isClaudeDetected: Bool = true
    @Published public var isGeminiDetected: Bool = true

    @Published public var isSyncing: Bool = false
    @Published public var lastRefreshedDate: Date? = nil
    @Published public var syncStatusMessage: String = "Ready"

    private var refreshTimer: Timer?
    private var cancellables = Set<AnyCancellable>()

    public var currentGeminiAccount: GeminiAccountQuota? {
        let email = AppSettings.shared.selectedGeminiAccountTab
        return antigravityCloudUsage?.accounts.first(where: { $0.email == email })
            ?? antigravityCloudUsage?.accounts.first
    }

    public var geminiFiveHourPercent: Int {
        if let acc = currentGeminiAccount {
            return acc.fiveHourPercent
        }
        return antigravityCloudUsage?.geminiFiveHourPercent ?? 97
    }

    public var geminiWeeklyPercent: Int {
        if let acc = currentGeminiAccount {
            return acc.weeklyPercent
        }
        return antigravityCloudUsage?.geminiWeeklyPercent ?? 79
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
        case .iconOnly:
            return ""
        case .fiveHourQuota:
            if isGeminiDetected && isClaudeDetected {
                return "\(geminiFiveHourPercent)% · \(claudeFiveHourPercent)%"
            } else if isClaudeDetected {
                return "\(claudeFiveHourPercent)%"
            } else if isGeminiDetected {
                return "\(geminiFiveHourPercent)%"
            } else {
                return "\(geminiFiveHourPercent)% · \(claudeFiveHourPercent)%"
            }
        case .weeklyQuota:
            if isGeminiDetected && isClaudeDetected {
                return "\(geminiWeeklyPercent)% · \(claudeWeeklyPercent)%"
            } else if isClaudeDetected {
                return "\(claudeWeeklyPercent)%"
            } else if isGeminiDetected {
                return "\(geminiWeeklyPercent)%"
            } else {
                return "\(geminiWeeklyPercent)% · \(claudeWeeklyPercent)%"
            }
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

        AppSettings.shared.$selectedGeminiAccountTab
            .dropFirst()
            .sink { [weak self] _ in
                Task { @MainActor [weak self] in
                    self?.updateSnapshot()
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
    }

    public func updateSnapshot() {
        let agyQuota = antigravityCloudUsage
        let claudeQuota = claudeCloudUsage
        let email1 = AppSettings.shared.geminiAccount1Email
        let email2 = AppSettings.shared.geminiAccount2Email
        let acc1 = agyQuota?.accounts.first(where: { $0.email == email1 })
        let acc2 = agyQuota?.accounts.first(where: { $0.email == email2 })

        let selected = AppSettings.shared.selectedGeminiAccountTab == email2 ? AppSettings.shared.account2ShortName : AppSettings.shared.account1ShortName

        let snapshot = SharedQuotaSnapshot(
            geminiFiveHourPercent: self.geminiFiveHourPercent,
            geminiWeeklyPercent: self.geminiWeeklyPercent,
            geminiFiveHourCountdown: currentGeminiAccount?.fiveHourResetCountdown ?? (agyQuota?.fiveHourResetCountdown ?? "4h 39m"),
            geminiWeeklyCountdown: currentGeminiAccount?.weeklyResetCountdown ?? (agyQuota?.weeklyResetCountdown ?? "4d 8h"),
            claudeFiveHourPercent: self.claudeFiveHourPercent,
            claudeWeeklyPercent: self.claudeWeeklyPercent,
            claudeFiveHourCountdown: claudeQuota?.fiveHourResetCountdown ?? "Ready",
            claudeWeeklyCountdown: claudeQuota?.sevenDayResetCountdown ?? "1d 15h",
            updatedAt: Date(),
            selectedGeminiAccount: selected,
            account1Name: AppSettings.shared.account1ShortName,
            account1FiveHour: acc1?.fiveHourPercent ?? 97,
            account1Weekly: acc1?.weeklyPercent ?? 79,
            account1FiveHourCountdown: acc1?.fiveHourResetCountdown ?? "4h 39m",
            account1WeeklyCountdown: acc1?.weeklyResetCountdown ?? "4d 8h",
            account2Name: AppSettings.shared.account2ShortName,
            account2FiveHour: acc2?.fiveHourPercent ?? 100,
            account2Weekly: acc2?.weeklyPercent ?? 100,
            account2FiveHourCountdown: acc2?.fiveHourResetCountdown ?? "Ready",
            account2WeeklyCountdown: acc2?.weeklyResetCountdown ?? "7d limit",
            hasClaude: self.isClaudeDetected,
            hasGemini: self.isGeminiDetected
        )
        snapshot.save()
        WidgetCenter.shared.reloadAllTimelines()
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

                let hasClaude = (claudeQuota != nil) || Self.checkClaudeAvailable()
                let hasGemini = (agyQuota != nil) || Self.checkGeminiAvailable()

                if hasClaude || hasGemini {
                    self.isClaudeDetected = hasClaude
                    self.isGeminiDetected = hasGemini
                } else {
                    self.isClaudeDetected = true
                    self.isGeminiDetected = true
                }

                self.isSyncing = false
                self.lastRefreshedDate = Date()
                self.syncStatusMessage = "Synced at \(DateFormatter.localizedString(from: Date(), dateStyle: .none, timeStyle: .medium))"

                self.updateSnapshot()
            }
        }
    }

    public static func checkClaudeAvailable() -> Bool {
        if ClaudeLiveService.shared.getAccessToken() != nil {
            return true
        }
        let home = FileManager.default.homeDirectoryForCurrentUser
        if FileManager.default.fileExists(atPath: home.appendingPathComponent(".claude.json").path) {
            return true
        }
        if AppSettings.shared.claudeManualOverrideEnabled {
            return true
        }
        return false
    }

    public static func checkGeminiAvailable() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        if FileManager.default.fileExists(atPath: home.appendingPathComponent(".gemini").path) {
            return true
        }
        if FileManager.default.fileExists(atPath: "/usr/local/bin/agy") ||
           FileManager.default.fileExists(atPath: "/opt/homebrew/bin/agy") ||
           FileManager.default.fileExists(atPath: home.appendingPathComponent(".gemini/bin/agy").path) {
            return true
        }
        let email1 = AppSettings.shared.geminiAccount1Email
        if !email1.isEmpty && email1 != "user1@gmail.com" {
            return true
        }
        return false
    }
}
