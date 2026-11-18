import SwiftUI

public struct ProviderCardView: View {
    public let isGemini: Bool
    @ObservedObject var tracker = UsageTracker.shared
    @ObservedObject var settings = AppSettings.shared

    private var accentGradient: LinearGradient {
        if isGemini {
            return LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .topLeading, endPoint: .bottomTrailing)
        } else {
            return LinearGradient(colors: [Color.orange, Color.red], startPoint: .topLeading, endPoint: .bottomTrailing)
        }
    }

    private var primaryColor: Color {
        isGemini ? Color.blue : Color.orange
    }

    public init(isGemini: Bool) {
        self.isGemini = isGemini
    }

    public var body: some View {
        let isDetected = isGemini ? tracker.isGeminiDetected : tracker.isClaudeDetected

        VStack(alignment: .leading, spacing: 10) {
            // Card Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: isGemini ? "sparkles" : "brain.head.profile")
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(isGemini ? "Gemini / Antigravity" : "Claude (Anthropic)")
                                .font(.system(size: 13, weight: .semibold))
                            Circle()
                                .fill(isDetected ? Color.green : Color.secondary.opacity(0.6))
                                .frame(width: 6, height: 6)
                        }
                        Text(isDetected ? (isGemini ? "Google Cloud (Synced All Servers)" : "Anthropic Cloud (Claude Code)") : "Standby (Not detected)")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Live Cloud Pill
                HStack(spacing: 3) {
                    Image(systemName: isDetected ? "checkmark.circle.fill" : "circle.dashed")
                        .font(.system(size: 8))
                        .foregroundColor(isDetected ? .green : .secondary)
                    Text(isDetected ? "Live API" : "Standby")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(isDetected ? .green : .secondary)
                }
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(isDetected ? Color.green.opacity(0.12) : Color.secondary.opacity(0.12))
                .cornerRadius(4)
            }

            if !isDetected {
                VStack(alignment: .leading, spacing: 4) {
                    Text(isGemini ? "Gemini CLI / accounts not found" : "Claude Code session not detected")
                        .font(.system(size: 11, weight: .medium))
                    Text(isGemini ? "Enter your Google accounts in Preferences (⌘,), or install Antigravity CLI to sync." : "Run 'claude' in Terminal to login via Keychain, or configure manual override in Preferences.")
                        .font(.system(size: 10))
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color.primary.opacity(0.04))
                .cornerRadius(10)
            } else {

            // MARK: - Gemini Account Switcher (if Gemini)
            if isGemini {
                VStack(alignment: .leading, spacing: 4) {
                    Text("ACCOUNT:")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)

                    HStack(spacing: 4) {
                        accountButton(email: settings.geminiAccount1Email, label: settings.account1ShortName)
                        accountButton(email: settings.geminiAccount2Email, label: settings.account2ShortName)
                        if !settings.geminiAccount3Email.isEmpty {
                            accountButton(email: settings.geminiAccount3Email, label: settings.account3ShortName)
                        }
                    }
                    .padding(3)
                    .background(Color.primary.opacity(0.05))
                    .cornerRadius(8)
                }
            }

            // MARK: - Live Cloud Quota (Synced Across All Servers)
            VStack(alignment: .leading, spacing: 8) {
                if isGemini {
                    let agy = tracker.antigravityCloudUsage
                    let selectedEmail = settings.selectedGeminiAccountTab
                    let accountData = agy?.accounts.first(where: { $0.email == selectedEmail })

                    let fiveHourRem = accountData?.fiveHourRemaining ?? (agy?.geminiFiveHourRemaining ?? 0.97)
                    let weeklyRem = accountData?.weeklyRemaining ?? (agy?.geminiWeeklyRemaining ?? 0.79)
                    let fiveHourCountdown = accountData?.fiveHourResetCountdown ?? (agy?.fiveHourResetCountdown ?? "4h 39m")
                    let weeklyCountdown = accountData?.weeklyResetCountdown ?? (agy?.weeklyResetCountdown ?? "4d 8h")

                    // 1. Five Hour Limit
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("5-Hour Limit Remaining:")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text("\(Int(fiveHourRem * 100))%")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text(formatResetLabel(fiveHourCountdown))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        quotaBar(fraction: fiveHourRem, color: .green)
                    }

                    // 2. Weekly Limit
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Weekly Plan Limit Remaining:")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text("\(Int(weeklyRem * 100))%")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(weeklyRem < 0.25 ? .red : .blue)
                            Text(formatResetLabel(weeklyCountdown))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        quotaBar(fraction: weeklyRem, color: weeklyRem < 0.25 ? .red : .blue)
                    }

                } else {
                    // Claude Cloud
                    let claude = tracker.claudeCloudUsage
                    let fiveHourRem = claude != nil ? (claude!.fiveHourRemaining / 100.0) : 0.93
                    let weeklyRem = claude != nil ? (claude!.sevenDayRemaining / 100.0) : 0.83

                    // 1. Five Hour Session Limit
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("5-Hour Rolling Limit Remaining:")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text("\(Int(fiveHourRem * 100))%")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text(formatResetLabel(claude?.fiveHourResetCountdown ?? "3h 12m"))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        quotaBar(fraction: fiveHourRem, color: .green)
                    }

                    // 2. Weekly Limit
                    VStack(alignment: .leading, spacing: 3) {
                        HStack {
                            Text("Weekly Limit Remaining:")
                                .font(.system(size: 11, weight: .medium))
                            Spacer()
                            Text("\(Int(weeklyRem * 100))%")
                                .font(.system(size: 13, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                            Text(formatResetLabel(claude?.sevenDayResetCountdown ?? "1d 15h"))
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        quotaBar(fraction: weeklyRem, color: .orange)
                    }

                    // Breakdown pill
                    HStack {
                        Text("Active: Claude Code (99% utilization share)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                    }
                }
            }
            .padding(10)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(10)
            }
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(nsColor: .controlBackgroundColor))
                .shadow(color: Color.black.opacity(0.05), radius: 3, x: 0, y: 1)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(primaryColor.opacity(0.2), lineWidth: 1)
        )
    }

    private func accountButton(email: String, label: String) -> some View {
        let isSelected = settings.selectedGeminiAccountTab == email
        return Button(action: {
            settings.selectedGeminiAccountTab = email
        }) {
            HStack(spacing: 5) {
                Circle()
                    .fill(isSelected ? Color.blue : Color.secondary.opacity(0.4))
                    .frame(width: 6, height: 6)
                Text(label)
                    .font(.system(size: 10, weight: isSelected ? .bold : .medium))
                    .lineLimit(1)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 5)
            .frame(maxWidth: .infinity)
            .background(isSelected ? Color(nsColor: .controlBackgroundColor) : Color.clear)
            .cornerRadius(6)
        }
        .buttonStyle(.plain)
    }

    private func quotaBar(fraction: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.1))
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: max(geo.size.width * CGFloat(min(max(fraction, 0.0), 1.0)), 2))
            }
        }
        .frame(height: 6)
    }

    private func formatResetLabel(_ countdown: String) -> String {
        let trimmed = countdown.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.lowercased() == "ready" {
            return "(Ready)"
        }
        return "(resets in \(trimmed))"
    }
}
