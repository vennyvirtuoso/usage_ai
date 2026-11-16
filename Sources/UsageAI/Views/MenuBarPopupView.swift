import SwiftUI

public struct MenuBarPopupView: View {
    @ObservedObject var tracker = UsageTracker.shared
    @ObservedObject var settings = AppSettings.shared

    public var onOpenSettings: () -> Void
    public var onToggleWidget: () -> Void
    public var onQuit: () -> Void

    public init(
        onOpenSettings: @escaping () -> Void,
        onToggleWidget: @escaping () -> Void,
        onQuit: @escaping () -> Void
    ) {
        self.onOpenSettings = onOpenSettings
        self.onToggleWidget = onToggleWidget
        self.onQuit = onQuit
    }

    public var body: some View {
        VStack(spacing: 0) {
            // Header Bar
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(
                            LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing)
                        )

                    VStack(alignment: .leading, spacing: 1) {
                        Text("Usage AI")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Text(tracker.scanStatusMessage)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Desktop Widget button
                Button(action: onToggleWidget) {
                    Label(
                        settings.isDesktopWidgetVisible ? "Hide Widget" : "Desktop Widget",
                        systemImage: settings.isDesktopWidgetVisible ? "macwindow.badge.plus" : "macwindow"
                    )
                    .font(.system(size: 11, weight: .medium))
                }
                .buttonStyle(.borderedProminent)
                .tint(settings.isDesktopWidgetVisible ? .purple : .blue)
                .controlSize(.small)

                // Refresh Button
                Button(action: {
                    tracker.refreshNow()
                }) {
                    Image(systemName: tracker.isScanning ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.clockwise")
                        .font(.system(size: 13))
                        .rotationEffect(.degrees(tracker.isScanning ? 360 : 0))
                        .animation(tracker.isScanning ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: tracker.isScanning)
                }
                .buttonStyle(.borderless)
                .help("Refresh token usage now")

                // Settings Button
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                }
                .buttonStyle(.borderless)
                .help("Preferences & API Keys")
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 12)

            Divider()

            ScrollView {
                VStack(spacing: 12) {
                    // Summary Top Banner: Today's Combined Usage
                    HStack(spacing: 12) {
                        // Circular Budget Ring
                        let budgetProgress = Double(tracker.totalTokensToday) / Double(settings.dailyTokenBudget)
                        CircularRingGauge(
                            progress: budgetProgress,
                            strokeWidth: 7,
                            gradientColors: budgetProgress > 0.9 ? [.orange, .red] : [.blue, .purple],
                            title: "DAILY BUDGET",
                            valueText: "\(Int(min(budgetProgress, 1.0) * 100))%"
                        )
                        .frame(width: 68, height: 68)

                        VStack(alignment: .leading, spacing: 4) {
                            Text("TODAY'S COMBINED TOKENS")
                                .font(.system(size: 10, weight: .semibold))
                                .foregroundColor(.secondary)

                            HStack(alignment: .firstTextBaseline, spacing: 6) {
                                Text(tracker.formatTokens(tracker.totalTokensToday))
                                    .font(.system(size: 24, weight: .black, design: .rounded))

                                Text("(\(tracker.formatFullNumber(tracker.totalTokensToday)) tokens)")
                                    .font(.system(size: 10))
                                    .foregroundColor(.secondary)
                            }

                            HStack(spacing: 8) {
                                Text("Cost: $\(String(format: "%.3f", tracker.totalCostToday))")
                                    .font(.system(size: 11, weight: .semibold, design: .rounded))
                                    .foregroundColor(.primary)

                                Text("•")
                                    .foregroundColor(.secondary)

                                Text("All-time: \(tracker.formatTokens(tracker.totalTokensAllTime))")
                                    .font(.system(size: 11))
                                    .foregroundColor(.secondary)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color(nsColor: .windowBackgroundColor))
                    )

                    // Provider Ratio Bar
                    VStack(alignment: .leading, spacing: 4) {
                        Text("USAGE DISTRIBUTION (TODAY)")
                            .font(.system(size: 9, weight: .bold))
                            .foregroundColor(.secondary)
                        RatioBarView(
                            geminiTokens: tracker.geminiSummary.todayTokens,
                            claudeTokens: tracker.claudeSummary.todayTokens
                        )
                    }
                    .padding(.horizontal, 4)

                    // Provider Cards
                    ProviderCardView(summary: tracker.geminiSummary)
                    ProviderCardView(summary: tracker.claudeSummary)
                }
                .padding(16)
            }
            .frame(maxHeight: 520)

            Divider()

            // Footer
            HStack {
                Text(tracker.allRecords.isEmpty ? "No local sessions detected yet" : "Tracking \(tracker.allRecords.count) AI events")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Spacer()

                Button("Quit Usage AI", action: onQuit)
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        }
        .frame(width: 400)
    }
}
