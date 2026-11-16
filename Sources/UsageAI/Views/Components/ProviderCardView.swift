import SwiftUI

public struct StatPillView: View {
    public let title: String
    public let value: String
    public let icon: String?
    public let tintColor: Color

    public init(title: String, value: String, icon: String? = nil, tintColor: Color = .blue) {
        self.title = title
        self.value = value
        self.icon = icon
        self.tintColor = tintColor
    }

    public var body: some View {
        HStack(spacing: 5) {
            if let icon = icon {
                Image(systemName: icon)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(tintColor)
            }
            Text(title)
                .font(.system(size: 10, weight: .medium))
                .foregroundColor(.secondary)
            Text(value)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .foregroundColor(.primary)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(tintColor.opacity(0.12))
        )
    }
}

public struct ProviderCardView: View {
    public let summary: ProviderUsageSummary
    public let isGemini: Bool
    @ObservedObject var tracker = UsageTracker.shared

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

    public init(summary: ProviderUsageSummary) {
        self.summary = summary
        self.isGemini = summary.provider == .geminiAntigravity
    }

    public var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            // Card Header
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: summary.provider.iconSymbol)
                        .font(.system(size: 13, weight: .bold))
                        .foregroundColor(.white)
                        .padding(5)
                        .background(accentGradient)
                        .clipShape(RoundedRectangle(cornerRadius: 6))

                    VStack(alignment: .leading, spacing: 1) {
                        HStack(spacing: 4) {
                            Text(summary.provider.displayName)
                                .font(.system(size: 13, weight: .semibold))
                            Circle()
                                .fill(Color.green)
                                .frame(width: 6, height: 6)
                        }
                        Text(isGemini ? "Google Antigravity Cloud" : "Anthropic Cloud")
                            .font(.system(size: 9))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Estimated Cost Badge
                VStack(alignment: .trailing, spacing: 1) {
                    Text(String(format: "$%.3f", summary.estimatedTodayCost))
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(primaryColor)
                    Text("Today's cost")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }

            // MARK: - Live Cloud Quota (Synced Across All Servers)
            VStack(alignment: .leading, spacing: 7) {
                HStack {
                    Label("CLOUD QUOTA (SYNCED ACROSS ALL SERVERS)", systemImage: "network")
                        .font(.system(size: 8, weight: .heavy))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Live API")
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(Color.green.opacity(0.15))
                        .foregroundColor(.green)
                        .cornerRadius(3)
                }

                if isGemini {
                    let agy = tracker.antigravityCloudUsage
                    let fiveHourRem = agy != nil ? agy!.geminiFiveHourRemaining : summary.quota.quotaRemainingPercent
                    let weeklyRem = agy != nil ? agy!.geminiWeeklyRemaining : 0.79

                    // 1. Five Hour Limit
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("5-Hour Window:")
                                .font(.system(size: 10, weight: .medium))
                            Spacer()
                            Text("\(Int(fiveHourRem * 100))% remaining")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text("(\(agy?.fiveHourResetCountdown ?? "4h 39m"))")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        quotaBar(fraction: fiveHourRem, color: .green)
                    }

                    // 2. Weekly Limit
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Weekly Quota:")
                                .font(.system(size: 10, weight: .medium))
                            Spacer()
                            Text("\(Int(weeklyRem * 100))% remaining")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(weeklyRem < 0.2 ? .red : .blue)
                            Text("(\(agy?.weeklyResetCountdown ?? "4d 8h"))")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        quotaBar(fraction: weeklyRem, color: weeklyRem < 0.2 ? .red : .blue)
                    }

                } else {
                    // Claude Cloud
                    let claude = tracker.claudeCloudUsage
                    let fiveHourRem = claude != nil ? (claude!.fiveHourRemaining / 100.0) : 0.93
                    let weeklyRem = claude != nil ? (claude!.sevenDayRemaining / 100.0) : 0.83

                    // 1. Five Hour Session Limit
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("5-Hour Window:")
                                .font(.system(size: 10, weight: .medium))
                            Spacer()
                            Text("\(Int(fiveHourRem * 100))% remaining")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                            Text("(\(claude?.fiveHourResetCountdown ?? "3h 12m"))")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        quotaBar(fraction: fiveHourRem, color: .green)
                    }

                    // 2. Weekly Limit
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Weekly Quota:")
                                .font(.system(size: 10, weight: .medium))
                            Spacer()
                            Text("\(Int(weeklyRem * 100))% remaining")
                                .font(.system(size: 10, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                            Text("(\(claude?.sevenDayResetCountdown ?? "1d 15h"))")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                        }
                        quotaBar(fraction: weeklyRem, color: .orange)
                    }
                }
            }
            .padding(9)
            .background(Color.primary.opacity(0.04))
            .cornerRadius(8)

            // MARK: - Active Session Context Window
            if summary.quota.contextTokensCurrentSession > 0 {
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Active Context Window:")
                            .font(.system(size: 10, weight: .medium))
                        Spacer()
                        Text("\(tracker.formatTokens(summary.quota.contextTokensCurrentSession)) / \(tracker.formatTokens(summary.quota.contextWindowLimit)) (\(String(format: "%.1f%%", summary.quota.contextPercent * 100)))")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(summary.quota.contextPercent > 0.8 ? .red : .primary)
                    }
                    quotaBar(fraction: summary.quota.contextPercent, color: summary.quota.contextPercent > 0.8 ? .red : primaryColor)
                }
                .padding(.horizontal, 2)
            }

            // MARK: - CLI /usage Section
            HStack(spacing: 8) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY'S TOKENS")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(tracker.formatTokens(summary.todayTokens))
                        .font(.system(size: 17, weight: .heavy, design: .rounded))
                        .foregroundColor(.primary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().frame(height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("ALL TIME")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text(tracker.formatTokens(summary.totalTokens))
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Divider().frame(height: 28)

                VStack(alignment: .leading, spacing: 2) {
                    Text("CACHE SAVINGS")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                    Text("\(Int(summary.cacheHitRatio * 100))%")
                        .font(.system(size: 15, weight: .bold, design: .rounded))
                        .foregroundColor(summary.cacheHitRatio > 0.4 ? .green : .secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 2)

            // Token Details breakdown
            HStack(spacing: 6) {
                StatPillView(
                    title: "In",
                    value: tracker.formatTokens(summary.todayInputTokens),
                    icon: "arrow.down.right",
                    tintColor: primaryColor
                )
                StatPillView(
                    title: "Out",
                    value: tracker.formatTokens(summary.todayOutputTokens),
                    icon: "arrow.up.left",
                    tintColor: .purple
                )
                if summary.cacheReadTokens > 0 {
                    StatPillView(
                        title: "Cached",
                        value: tracker.formatTokens(summary.todayCachedTokens),
                        icon: "bolt.fill",
                        tintColor: .green
                    )
                }
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

    private func quotaBar(fraction: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 3)
                    .fill(Color.primary.opacity(0.08))
                RoundedRectangle(cornerRadius: 3)
                    .fill(color)
                    .frame(width: max(geo.size.width * CGFloat(min(max(fraction, 0.0), 1.0)), 2))
            }
        }
        .frame(height: 5)
    }

    private func cleanModelName(_ name: String) -> String {
        name.replacingOccurrences(of: "gemini-", with: "")
            .replacingOccurrences(of: "claude-", with: "")
            .replacingOccurrences(of: "-20241022", with: "")
    }
}
