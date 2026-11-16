import SwiftUI

public struct DesktopWidgetView: View {
    @ObservedObject var tracker = UsageTracker.shared
    @ObservedObject var settings = AppSettings.shared

    public var onClose: () -> Void

    public init(onClose: @escaping () -> Void) {
        self.onClose = onClose
    }

    public var body: some View {
        Group {
            if settings.widgetSizeStyle == .small {
                smallWidgetLayout
            } else {
                mediumWidgetLayout
            }
        }
        .padding(14)
        .background(
            ZStack {
                VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)
                RoundedRectangle(cornerRadius: 22)
                    .stroke(
                        LinearGradient(
                            colors: [Color.white.opacity(0.35), Color.white.opacity(0.08)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: 22))
            .shadow(color: Color.black.opacity(0.28), radius: 18, x: 0, y: 8)
        )
        .opacity(settings.widgetOpacity)
    }

    // MARK: - Medium Widget (Standard Apple Widget Size: 340x160)
    private var mediumWidgetLayout: some View {
        VStack(spacing: 10) {
            // Widget Header
            HStack {
                HStack(spacing: 5) {
                    Image(systemName: "gauge.with.needle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.blue)
                    Text("AI Quota")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                    Circle()
                        .fill(Color.green)
                        .frame(width: 5, height: 5)
                }

                Spacer()

                // Pin Button
                Button(action: {
                    settings.isDesktopWidgetPinned.toggle()
                }) {
                    Image(systemName: settings.isDesktopWidgetPinned ? "pin.fill" : "pin")
                        .font(.system(size: 10))
                        .foregroundColor(settings.isDesktopWidgetPinned ? .blue : .secondary)
                }
                .buttonStyle(.plain)
                .help(settings.isDesktopWidgetPinned ? "Unpin (Float above windows)" : "Pin to Desktop")

                // Close Button
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary.opacity(0.8))
                }
                .buttonStyle(.plain)
                .help("Remove Widget from Desktop")
            }

            // Columns: Gemini Account & Claude Account
            HStack(spacing: 12) {
                // Gemini Column
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("✨ Gemini")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                        Spacer()
                        Text(cleanEmail(settings.selectedGeminiAccountTab))
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // 5h Limit
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("5-Hour")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(tracker.geminiFiveHourPercent)%")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        quotaBar(fraction: Double(tracker.geminiFiveHourPercent) / 100.0, color: .green)
                    }

                    // Weekly Limit
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Weekly")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(tracker.geminiWeeklyPercent)%")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(tracker.geminiWeeklyPercent < 25 ? .red : .blue)
                        }
                        quotaBar(fraction: Double(tracker.geminiWeeklyPercent) / 100.0, color: tracker.geminiWeeklyPercent < 25 ? .red : .blue)
                    }

                    Text("Resets in \(tracker.antigravityCloudUsage?.fiveHourResetCountdown ?? "4h 39m")")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(10)
                .frame(maxWidth: .infinity)

                // Claude Column
                VStack(alignment: .leading, spacing: 6) {
                    HStack {
                        Text("🤖 Claude")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                        Spacer()
                        Text("Pro")
                            .font(.system(size: 8, weight: .medium))
                            .foregroundColor(.secondary)
                    }

                    // 5h Limit
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("5-Hour")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(tracker.claudeFiveHourPercent)%")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        quotaBar(fraction: Double(tracker.claudeFiveHourPercent) / 100.0, color: .green)
                    }

                    // Weekly Limit
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Weekly")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(tracker.claudeWeeklyPercent)%")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                        }
                        quotaBar(fraction: Double(tracker.claudeWeeklyPercent) / 100.0, color: .orange)
                    }

                    Text("Resets in \(tracker.claudeCloudUsage?.fiveHourResetCountdown ?? "3h 12m")")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(10)
                .frame(maxWidth: .infinity)
            }
        }
        .frame(width: 320, height: 140)
    }

    // MARK: - Small Widget (Compact 160x160)
    private var smallWidgetLayout: some View {
        VStack(spacing: 8) {
            HStack {
                Text("AI Quotas")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                // Gemini Ring
                VStack(spacing: 3) {
                    CircularRingGauge(
                        progress: Double(tracker.geminiFiveHourPercent) / 100.0,
                        strokeWidth: 5,
                        gradientColors: [.blue, .cyan],
                        title: "GEMINI",
                        valueText: "\(tracker.geminiFiveHourPercent)%"
                    )
                    .frame(width: 52, height: 52)
                    Text("Wk: \(tracker.geminiWeeklyPercent)%")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                }

                // Claude Ring
                VStack(spacing: 3) {
                    CircularRingGauge(
                        progress: Double(tracker.claudeFiveHourPercent) / 100.0,
                        strokeWidth: 5,
                        gradientColors: [.orange, .red],
                        title: "CLAUDE",
                        valueText: "\(tracker.claudeFiveHourPercent)%"
                    )
                    .frame(width: 52, height: 52)
                    Text("Wk: \(tracker.claudeWeeklyPercent)%")
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(.secondary)
                }
            }

            Text("Next refresh in 20m")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
        .frame(width: 150, height: 130)
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
        .frame(height: 5)
    }

    private func cleanEmail(_ email: String) -> String {
        email.components(separatedBy: "@").first ?? email
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
