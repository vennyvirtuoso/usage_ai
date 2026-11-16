import SwiftUI

public struct DesktopWidgetView: View {
    @ObservedObject var tracker = UsageTracker.shared
    @ObservedObject var settings = AppSettings.shared

    public var onClose: () -> Void

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        ZStack {
            if settings.isDesktopWidgetCompact {
                compactWidgetView
            } else {
                expandedWidgetView
            }
        }
        .padding(14)
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: 20)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.3), Color.white.opacity(0.05)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 20))
            .shadow(color: Color.black.opacity(0.25), radius: 16, x: 0, y: 8)
        )
        .opacity(settings.widgetOpacity)
    }

    // MARK: - Compact Widget
    private var compactWidgetView: some View {
        VStack(spacing: 10) {
            // Widget Title & Controls
            HStack(spacing: 4) {
                Image(systemName: "sparkles")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.cyan)

                Text("Usage AI")
                    .font(.system(size: 11, weight: .bold, design: .rounded))

                Spacer()

                Button(action: {
                    settings.isDesktopWidgetCompact.toggle()
                }) {
                    Image(systemName: "arrow.up.left.and.arrow.down.right")
                        .font(.system(size: 9))
                }
                .buttonStyle(.plain)
                .help("Expand Widget")

                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Widget")
            }

            // Dual Gauges
            HStack(spacing: 12) {
                // Gemini Gauge
                CircularRingGauge(
                    progress: min(Double(tracker.geminiSummary.todayTokens) / 500_000.0, 1.0),
                    strokeWidth: 5,
                    gradientColors: [.blue, .cyan],
                    title: "GEMINI",
                    valueText: tracker.formatTokens(tracker.geminiSummary.todayTokens)
                )
                .frame(width: 58, height: 58)

                // Claude Gauge
                CircularRingGauge(
                    progress: min(Double(tracker.claudeSummary.todayTokens) / 500_000.0, 1.0),
                    strokeWidth: 5,
                    gradientColors: [.orange, .red],
                    title: "CLAUDE",
                    valueText: tracker.formatTokens(tracker.claudeSummary.todayTokens)
                )
                .frame(width: 58, height: 58)
            }

            // Total Today Banner
            HStack {
                Text("Today:")
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(.secondary)
                Text(tracker.formatTokens(tracker.totalTokensToday))
                    .font(.system(size: 11, weight: .heavy, design: .rounded))
                Spacer()
                Text(String(format: "$%.2f", tracker.totalCostToday))
                    .font(.system(size: 10, weight: .bold, design: .rounded))
                    .foregroundColor(.green)
            }
            .padding(.horizontal, 6)
            .padding(.vertical, 3)
            .background(Color.primary.opacity(0.06))
            .cornerRadius(6)
        }
        .frame(width: 160)
    }

    // MARK: - Expanded Widget
    private var expandedWidgetView: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            HStack {
                HStack(spacing: 6) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.system(size: 16))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )
                    Text("Usage AI")
                        .font(.system(size: 14, weight: .bold, design: .rounded))
                }

                Spacer()

                // Compact Toggle
                Button(action: {
                    settings.isDesktopWidgetCompact.toggle()
                }) {
                    Image(systemName: "arrow.down.right.and.arrow.up.left")
                        .font(.system(size: 11))
                }
                .buttonStyle(.plain)
                .help("Compact Mode")

                // Pin Toggle
                Button(action: {
                    settings.isDesktopWidgetPinned.toggle()
                }) {
                    Image(systemName: settings.isDesktopWidgetPinned ? "pin.fill" : "pin")
                        .font(.system(size: 11))
                        .foregroundColor(settings.isDesktopWidgetPinned ? .accentColor : .secondary)
                }
                .buttonStyle(.plain)
                .help(settings.isDesktopWidgetPinned ? "Unpin from desktop" : "Pin to desktop background")

                // Close Button
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 13))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
                .help("Close Widget")
            }

            // Stats Hero
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("TODAY'S TOKENS")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(tracker.formatTokens(tracker.totalTokensToday))
                        .font(.system(size: 26, weight: .black, design: .rounded))
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text("EST. COST")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.secondary)
                    Text(String(format: "$%.3f", tracker.totalCostToday))
                        .font(.system(size: 18, weight: .heavy, design: .rounded))
                        .foregroundColor(.green)
                }
            }

            // Distribution bar
            RatioBarView(
                geminiTokens: tracker.geminiSummary.todayTokens,
                claudeTokens: tracker.claudeSummary.todayTokens
            )

            // Two Mini Columns
            HStack(spacing: 8) {
                // Gemini mini card
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("✨ Gemini")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                        Spacer()
                        Text(String(format: "$%.2f", tracker.geminiSummary.estimatedTodayCost))
                            .font(.system(size: 10, weight: .semibold))
                    }
                    Text(tracker.formatTokens(tracker.geminiSummary.todayTokens))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))

                    // Context window & Quota
                    Text("Ctx: \(tracker.formatTokens(tracker.geminiSummary.quota.contextTokensCurrentSession)) (\(String(format: "%.1f%%", tracker.geminiSummary.quota.contextPercent * 100)))")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Quota: \(Int(tracker.geminiSummary.quota.quotaRemainingPercent * 100))% left")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(8)
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)

                // Claude mini card
                VStack(alignment: .leading, spacing: 4) {
                    HStack {
                        Text("🤖 Claude")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                        Spacer()
                        Text(String(format: "$%.2f", tracker.claudeSummary.estimatedTodayCost))
                            .font(.system(size: 10, weight: .semibold))
                    }
                    Text(tracker.formatTokens(tracker.claudeSummary.todayTokens))
                        .font(.system(size: 16, weight: .heavy, design: .rounded))

                    // Context window & Quota
                    Text("Ctx: \(tracker.formatTokens(tracker.claudeSummary.quota.contextTokensCurrentSession)) (\(String(format: "%.1f%%", tracker.claudeSummary.quota.contextPercent * 100)))")
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                    Text("Quota: \(Int(tracker.claudeSummary.quota.quotaRemainingPercent * 100))% left")
                        .font(.system(size: 8, weight: .semibold))
                        .foregroundColor(.green)
                }
                .padding(8)
                .background(Color.orange.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .frame(width: 260)
    }
}

// NSVisualEffectView wrapper for SwiftUI
public struct VisualEffectView: NSViewRepresentable {
    public let material: NSVisualEffectView.Material
    public let blendingMode: NSVisualEffectView.BlendingMode

    public init(material: NSVisualEffectView.Material, blendingMode: NSVisualEffectView.BlendingMode) {
        self.material = material
        self.blendingMode = blendingMode
    }

    public func makeNSView(context: Context) -> NSVisualEffectView {
        let visualEffectView = NSVisualEffectView()
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
        visualEffectView.state = .active
        return visualEffectView
    }

    public func updateNSView(_ visualEffectView: NSVisualEffectView, context: Context) {
        visualEffectView.material = material
        visualEffectView.blendingMode = blendingMode
    }
}
