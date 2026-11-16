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
                        Text(summary.provider.displayName)
                            .font(.system(size: 13, weight: .semibold))
                        Text(summary.latestModel.isEmpty ? "Active Model" : cleanModelName(summary.latestModel))
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

            // MARK: - CLI /quota Section
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Label("CLI /quota & Context", systemImage: "gauge.with.needle")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Resets in \(summary.quota.timeUntilResetString)")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }

                // 1. Active Context Window Gauge (Latest Turn / Session)
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Context Window:")
                            .font(.system(size: 10, weight: .medium))
                        Spacer()
                        Text("\(tracker.formatTokens(summary.quota.contextTokensCurrentSession)) / \(tracker.formatTokens(summary.quota.contextWindowLimit)) (\(String(format: "%.1f%%", summary.quota.contextPercent * 100)))")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(summary.quota.contextPercent > 0.8 ? .red : .primary)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.primary.opacity(0.08))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(
                                    summary.quota.contextPercent > 0.8 ? Color.red : primaryColor
                                )
                                .frame(width: max(geo.size.width * CGFloat(min(summary.quota.contextPercent, 1.0)), 2))
                        }
                    }
                    .frame(height: 5)
                }

                // 2. Daily Token Quota Gauge
                VStack(alignment: .leading, spacing: 3) {
                    HStack {
                        Text("Daily Quota Remaining:")
                            .font(.system(size: 10, weight: .medium))
                        Spacer()
                        Text("\(String(format: "%.1f%%", summary.quota.quotaRemainingPercent * 100)) remaining")
                            .font(.system(size: 10, weight: .semibold, design: .rounded))
                            .foregroundColor(.green)
                    }

                    GeometryReader { geo in
                        ZStack(alignment: .leading) {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(Color.primary.opacity(0.08))
                            RoundedRectangle(cornerRadius: 3)
                                .fill(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                                .frame(width: max(geo.size.width * CGFloat(min(summary.quota.quotaRemainingPercent, 1.0)), 2))
                        }
                    }
                    .frame(height: 5)
                }

                // Requests & Limits Pill Row
                HStack(spacing: 8) {
                    HStack(spacing: 3) {
                        Image(systemName: "arrow.triangle.swap")
                            .font(.system(size: 8))
                            .foregroundColor(.secondary)
                        Text("Requests: \(summary.quota.dailyRequestsUsed) / \(summary.quota.dailyRequestsLimit)")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Text(summary.quota.tierName)
                        .font(.system(size: 8, weight: .bold))
                        .padding(.horizontal, 5)
                        .padding(.vertical, 1)
                        .background(primaryColor.opacity(0.12))
                        .foregroundColor(primaryColor)
                        .cornerRadius(3)
                }
            }
            .padding(8)
            .background(Color.primary.opacity(0.03))
            .cornerRadius(8)

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

            // Top Models Badge Row
            if !summary.modelCounts.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 4) {
                        ForEach(summary.modelCounts.sorted(by: { $0.value > $1.value }).prefix(3), id: \.key) { model, count in
                            Text("\(cleanModelName(model)): \(tracker.formatTokens(count))")
                                .font(.system(size: 9, weight: .medium))
                                .padding(.horizontal, 6)
                                .padding(.vertical, 2)
                                .background(Color.primary.opacity(0.06))
                                .cornerRadius(4)
                        }
                    }
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

    private func cleanModelName(_ name: String) -> String {
        name.replacingOccurrences(of: "gemini-", with: "")
            .replacingOccurrences(of: "claude-", with: "")
            .replacingOccurrences(of: "-20241022", with: "")
    }
}
