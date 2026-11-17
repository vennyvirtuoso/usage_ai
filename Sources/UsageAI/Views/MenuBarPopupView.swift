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
                        Text("Ghee-Khatam")
                            .font(.system(size: 15, weight: .bold, design: .rounded))
                        Text(tracker.syncStatusMessage)
                            .font(.system(size: 10))
                            .foregroundColor(.secondary)
                    }
                }

                Spacer()

                // Refresh Button
                Button(action: {
                    tracker.refreshNow()
                }) {
                    Image(systemName: tracker.isSyncing ? "arrow.triangle.2.circlepath.circle.fill" : "arrow.clockwise")
                        .font(.system(size: 13))
                        .rotationEffect(.degrees(tracker.isSyncing ? 360 : 0))
                        .animation(tracker.isSyncing ? .linear(duration: 1).repeatForever(autoreverses: false) : .default, value: tracker.isSyncing)
                }
                .buttonStyle(.borderless)
                .help("Refresh Cloud Quotas Now")

                // Settings Button
                Button(action: onOpenSettings) {
                    Image(systemName: "gearshape")
                        .font(.system(size: 13))
                }
                .buttonStyle(.borderless)
                .help("Preferences")
            }
            .padding(.horizontal, 16)
            .padding(.top, 14)
            .padding(.bottom, 10)

            Divider()

            ScrollView {
                VStack(spacing: 12) {
                    // MARK: - Desktop Widget Promotion Card
                    HStack(spacing: 12) {
                        Image(systemName: settings.isDesktopWidgetVisible ? "macwindow.on.rectangle" : "macwindow.badge.plus")
                            .font(.system(size: 22))
                            .foregroundColor(settings.isDesktopWidgetVisible ? .green : .blue)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(settings.isDesktopWidgetVisible ? "Desktop Widget Active" : "Add to Desktop as Widget")
                                .font(.system(size: 12, weight: .bold, design: .rounded))
                            Text(settings.isDesktopWidgetVisible ? "Pinned on your Mac desktop" : "Glance at real-time quotas on your desktop")
                                .font(.system(size: 10))
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Button(action: onToggleWidget) {
                            Text(settings.isDesktopWidgetVisible ? "Hide Widget" : "+ Add Widget")
                                .font(.system(size: 11, weight: .semibold))
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(settings.isDesktopWidgetVisible ? .secondary : .blue)
                        .controlSize(.small)
                    }
                    .padding(10)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(Color(nsColor: .windowBackgroundColor))
                    )

                    // Widget Size Picker (if visible)
                    if settings.isDesktopWidgetVisible {
                        HStack {
                            Text("Widget Size:")
                                .font(.system(size: 10, weight: .medium))
                                .foregroundColor(.secondary)
                            Picker("", selection: $settings.widgetSizeStyle) {
                                Text("Medium").tag(WidgetSizeStyle.medium)
                                Text("Small").tag(WidgetSizeStyle.small)
                            }
                            .pickerStyle(.segmented)
                            .controlSize(.small)
                            .frame(width: 140)
                            Spacer()
                        }
                        .padding(.horizontal, 4)
                    }

                    // MARK: - Quota Cards
                    ProviderCardView(isGemini: true)
                    ProviderCardView(isGemini: false)
                }
                .padding(14)
            }
            .frame(maxHeight: 480)

            Divider()

            // Footer
            HStack {
                Text("Refreshes automatically every 20 minutes")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)

                Spacer()

                Button("Quit Ghee-Khatam", action: onQuit)
                    .font(.system(size: 11))
                    .buttonStyle(.plain)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            .background(Color(nsColor: .windowBackgroundColor).opacity(0.5))
        }
        .frame(width: 390)
    }
}
