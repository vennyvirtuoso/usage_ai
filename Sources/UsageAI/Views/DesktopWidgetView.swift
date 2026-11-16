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
        .padding(12)
        .background(widgetBackground)
        .opacity(settings.widgetOpacity)
        .padding(6) // Margin inside transparent window for smooth rounded shadow
    }

    // MARK: - Premium Composite Glass Background
    // Engineered specifically to guarantee 100% crisp legibility on ANY desktop wallpaper
    // with NO square borders or artifacts
    private var widgetBackground: some View {
        ZStack {
            // Layer 1: System HUD Backdrop Blur
            VisualEffectView(material: .hudWindow, blendingMode: .behindWindow)

            // Layer 2: High-contrast obsidian tint (cuts through blinding white or dark wallpapers)
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    settings.widgetTheme == .frosted
                        ? Color(nsColor: .windowBackgroundColor).opacity(0.88)
                        : Color(red: 0.08, green: 0.09, blue: 0.12).opacity(0.92)
                )

            // Layer 3: Subtle inner vignette gradient
            RoundedRectangle(cornerRadius: 22)
                .fill(
                    LinearGradient(
                        colors: [Color.white.opacity(0.08), Color.black.opacity(0.18)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

            // Layer 4: Ultra-crisp precision border with metallic rim highlight
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
        // Smooth rounded shadow (replaces rectangular window shadow)
        .shadow(color: Color.black.opacity(0.38), radius: 12, x: 0, y: 6)
    }

    // MARK: - Medium Widget (Classic Apple HIG Size: 344x148)
    private var mediumWidgetLayout: some View {
        VStack(spacing: 7) {
            // Top Bar
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(hex: "#10B981"))
                        .frame(width: 5, height: 5)

                    Text("AI QUOTA")
                        .font(.system(size: 9, weight: .black, design: .rounded))
                        .tracking(0.8)
                        .foregroundColor(.white.opacity(0.85))

                    Text("•")
                        .foregroundColor(.white.opacity(0.35))
                        .font(.system(size: 8))

                    Text("LIVE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.white.opacity(0.45))
                }

                Spacer()

                // Actions (Static buttons, zero CPU overhead)
                HStack(spacing: 6) {
                    // Manual sync
                    Button(action: {
                        tracker.refreshNow()
                    }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                    .help("Refresh Quotas Now")

                    // Pin toggle
                    Button(action: {
                        settings.isDesktopWidgetPinned.toggle()
                    }) {
                        Image(systemName: settings.isDesktopWidgetPinned ? "pin.fill" : "pin")
                            .font(.system(size: 9, weight: .semibold))
                            .foregroundColor(settings.isDesktopWidgetPinned ? Color(hex: "#38BDF8") : .white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                    .help(settings.isDesktopWidgetPinned ? "Unpin (Float above apps)" : "Pin to Desktop")

                    // Close
                    Button(action: onClose) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.55))
                    }
                    .buttonStyle(.plain)
                    .help("Close Widget")
                }
            }
            .padding(.horizontal, 2)

            // Split Columns: Gemini & Claude
            HStack(spacing: 10) {
                geminiCardView
                claudeCardView
            }
        }
        .frame(width: 334, height: 142)
    }

    // MARK: - Gemini Card
    private var geminiCardView: some View {
        let agy = tracker.antigravityCloudUsage
        let selectedEmail = settings.selectedGeminiAccountTab
        let accountData = agy?.accounts.first(where: { $0.email == selectedEmail })

        let fiveHourRem = accountData?.fiveHourRemaining ?? (agy?.geminiFiveHourRemaining ?? 0.97)
        let weeklyRem = accountData?.weeklyRemaining ?? (agy?.geminiWeeklyRemaining ?? 0.79)
        let fiveHourCountdown = accountData?.fiveHourResetCountdown ?? (agy?.fiveHourResetCountdown ?? "4h 39m")
        let weeklyCountdown = accountData?.weeklyResetCountdown ?? (agy?.weeklyResetCountdown ?? "4d 8h")

        return VStack(alignment: .leading, spacing: 5) {
            // Header & Account Switcher
            HStack(alignment: .center) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#38BDF8"))
                    Text("Gemini")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                // Account Mini Toggle
                accountSwitcherMenu
            }

            // 5-Hour Limit
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("5-Hour")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                    Text("\(Int(fiveHourRem * 100))%")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#34D399"))
                    Text("(\(fiveHourCountdown))")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.45))
                }
                customProgressBar(fraction: fiveHourRem, gradient: [Color(hex: "#059669"), Color(hex: "#34D399")])
            }

            // Weekly Limit
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Weekly")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                    Text("\(Int(weeklyRem * 100))%")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(weeklyRem < 0.25 ? Color(hex: "#F87171") : Color(hex: "#38BDF8"))
                    Text("(\(weeklyCountdown))")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.45))
                }
                customProgressBar(fraction: weeklyRem, gradient: weeklyRem < 0.25 ? [Color(hex: "#DC2626"), Color(hex: "#F87171")] : [Color(hex: "#2563EB"), Color(hex: "#38BDF8")])
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#38BDF8").opacity(0.20), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
    }

    // Gemini Account switcher on widget
    private var accountSwitcherMenu: some View {
        HStack(spacing: 3) {
            miniAccountButton(email: settings.geminiAccount1Email, shortName: "alexa")
            miniAccountButton(email: settings.geminiAccount2Email, shortName: "paras")
        }
        .padding(2)
        .background(Color.black.opacity(0.35))
        .cornerRadius(6)
    }

    private func miniAccountButton(email: String, shortName: String) -> some View {
        let isSelected = settings.selectedGeminiAccountTab == email
        return Button(action: {
            settings.selectedGeminiAccountTab = email
        }) {
            Text(shortName)
                .font(.system(size: 8, weight: isSelected ? .black : .medium))
                .foregroundColor(isSelected ? .white : .white.opacity(0.5))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(isSelected ? Color(hex: "#0284C7") : Color.clear)
                .cornerRadius(4)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Claude Card
    private var claudeCardView: some View {
        let claude = tracker.claudeCloudUsage
        let fiveHourRem = claude != nil ? (claude!.fiveHourRemaining / 100.0) : 0.93
        let weeklyRem = claude != nil ? (claude!.sevenDayRemaining / 100.0) : 0.83
        let fiveHourCountdown = claude?.fiveHourResetCountdown ?? "3h 12m"
        let weeklyCountdown = claude?.sevenDayResetCountdown ?? "1d 15h"

        return VStack(alignment: .leading, spacing: 5) {
            // Header
            HStack {
                HStack(spacing: 4) {
                    Image(systemName: "brain.head.profile")
                        .font(.system(size: 10, weight: .bold))
                        .foregroundColor(Color(hex: "#FB923C"))
                    Text("Claude")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                }

                Spacer()

                Text("PRO")
                    .font(.system(size: 8, weight: .black))
                    .foregroundColor(Color(hex: "#FB923C"))
                    .padding(.horizontal, 5)
                    .padding(.vertical, 2)
                    .background(Color(hex: "#FB923C").opacity(0.18))
                    .cornerRadius(4)
            }

            // 5-Hour Limit
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("5-Hour")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                    Text("\(Int(fiveHourRem * 100))%")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#34D399"))
                    Text("(\(fiveHourCountdown))")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.45))
                }
                customProgressBar(fraction: fiveHourRem, gradient: [Color(hex: "#059669"), Color(hex: "#34D399")])
            }

            // Weekly Limit
            VStack(alignment: .leading, spacing: 2) {
                HStack {
                    Text("Weekly")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.white.opacity(0.75))
                    Spacer()
                    Text("\(Int(weeklyRem * 100))%")
                        .font(.system(size: 12, weight: .black, design: .rounded))
                        .foregroundColor(Color(hex: "#FB923C"))
                    Text("(\(weeklyCountdown))")
                        .font(.system(size: 8))
                        .foregroundColor(.white.opacity(0.45))
                }
                customProgressBar(fraction: weeklyRem, gradient: [Color(hex: "#EA580C"), Color(hex: "#FB923C")])
            }
        }
        .padding(8)
        .background(
            RoundedRectangle(cornerRadius: 14)
                .fill(Color.white.opacity(0.06))
                .overlay(
                    RoundedRectangle(cornerRadius: 14)
                        .stroke(Color(hex: "#FB923C").opacity(0.20), lineWidth: 1)
                )
        )
        .frame(maxWidth: .infinity)
    }

    // MARK: - Small Widget (Compact 150x130)
    private var smallWidgetLayout: some View {
        VStack(spacing: 8) {
            HStack {
                Circle()
                    .fill(Color(hex: "#10B981"))
                    .frame(width: 5, height: 5)
                Text("AI QUOTA")
                    .font(.system(size: 10, weight: .black, design: .rounded))
                    .tracking(0.5)
                    .foregroundColor(.white)
                Spacer()
                Button(action: onClose) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 11))
                        .foregroundColor(.white.opacity(0.5))
                }
                .buttonStyle(.plain)
            }

            HStack(spacing: 12) {
                // Gemini Gauge
                VStack(spacing: 3) {
                    CircularRingGauge(
                        progress: Double(tracker.geminiFiveHourPercent) / 100.0,
                        strokeWidth: 5,
                        gradientColors: [Color(hex: "#2563EB"), Color(hex: "#38BDF8")],
                        title: "GEMINI",
                        valueText: "\(tracker.geminiFiveHourPercent)%"
                    )
                    .frame(width: 50, height: 50)
                    Text("Wk: \(tracker.geminiWeeklyPercent)%")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.75))
                }

                // Claude Gauge
                VStack(spacing: 3) {
                    CircularRingGauge(
                        progress: Double(tracker.claudeFiveHourPercent) / 100.0,
                        strokeWidth: 5,
                        gradientColors: [Color(hex: "#EA580C"), Color(hex: "#FB923C")],
                        title: "CLAUDE",
                        valueText: "\(tracker.claudeFiveHourPercent)%"
                    )
                    .frame(width: 50, height: 50)
                    Text("Wk: \(tracker.claudeWeeklyPercent)%")
                        .font(.system(size: 9, weight: .bold))
                        .foregroundColor(.white.opacity(0.75))
                }
            }

            Text("Syncs every 20m")
                .font(.system(size: 8, weight: .medium))
                .foregroundColor(.white.opacity(0.45))
        }
        .frame(width: 148, height: 128)
    }

    // High-contrast progress bar that remains razor-sharp over any wallpaper
    private func customProgressBar(fraction: Double, gradient: [Color]) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                // Dark recessed track with 1px shadow
                Capsule()
                    .fill(Color.black.opacity(0.60))
                    .overlay(
                        Capsule()
                            .stroke(Color.white.opacity(0.12), lineWidth: 0.5)
                    )

                // Illuminated progress fill
                Capsule()
                    .fill(
                        LinearGradient(
                            colors: gradient,
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .frame(width: max(geo.size.width * CGFloat(min(max(fraction, 0.0), 1.0)), 4))
            }
        }
        .frame(height: 6)
    }
}

// Color hex helper
extension Color {
    init(hex: String) {
        let scanner = Scanner(string: hex.replacingOccurrences(of: "#", with: ""))
        var rgbValue: UInt64 = 0
        scanner.scanHexInt64(&rgbValue)
        let r = Double((rgbValue & 0xFF0000) >> 16) / 255.0
        let g = Double((rgbValue & 0x00FF00) >> 8) / 255.0
        let b = Double(rgbValue & 0x0000FF) / 255.0
        self.init(red: r, green: g, blue: b)
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
