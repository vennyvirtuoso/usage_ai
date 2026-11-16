import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var tracker = UsageTracker.shared

    public init() {}

    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            accountsTab
                .tabItem {
                    Label("Accounts", systemImage: "person.2")
                }

            widgetTab
                .tabItem {
                    Label("Desktop Widget", systemImage: "macwindow")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding(18)
        .frame(minWidth: 580, idealWidth: 620, minHeight: 450, idealHeight: 480)
    }

    // MARK: - General Tab
    private var generalTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Refresh frequency
                VStack(alignment: .leading, spacing: 8) {
                    Text("Auto-Refresh Interval")
                        .font(.headline)

                    Picker("Sync Every:", selection: $settings.refreshIntervalSeconds) {
                        Text("10 minutes").tag(600.0)
                        Text("20 minutes (Recommended)").tag(1200.0)
                        Text("30 minutes").tag(1800.0)
                        Text("1 hour").tag(3600.0)
                    }
                    .pickerStyle(.menu)
                    .frame(width: 280)

                    Text("Automatically checks official cloud quotas for Claude and Gemini across all your servers.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)

                // Menu bar title format
                VStack(alignment: .leading, spacing: 8) {
                    Text("Menu Bar Display Format")
                        .font(.headline)

                    Picker("Display:", selection: $settings.menuBarDisplayMode) {
                        ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.radioGroup)

                    Text("Displays your live remaining quota in the macOS menu bar at all times.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)

                // Manual refresh
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Manual Quota Sync")
                            .font(.headline)
                        Text("Status: \(tracker.syncStatusMessage)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button("↻ Refresh Now") {
                        tracker.refreshNow()
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.regular)
                }
                .padding()
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Accounts Tab
    private var accountsTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                // Gemini Accounts
                VStack(alignment: .leading, spacing: 12) {
                    Text("Gemini Antigravity Accounts")
                        .font(.headline)

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Primary Account (Auto-Synced with CLI):")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("alexasolosix@gmail.com", text: $settings.geminiAccount1Email)
                            .textFieldStyle(.roundedBorder)
                        Text("Uses ~/.gemini/bin/agy /quota to query your real-time cloud weekly and 5-hour limits.")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 4) {
                        Text("Secondary Account:")
                            .font(.subheadline)
                            .fontWeight(.medium)
                        TextField("parasgandre@gmail.com", text: $settings.geminiAccount2Email)
                            .textFieldStyle(.roundedBorder)

                        Text("Optional Gemini API Key for secondary account:")
                            .font(.caption)
                            .padding(.top, 4)
                        SecureField("AIzaSy... (optional)", text: $settings.geminiAccount2ApiKey)
                            .textFieldStyle(.roundedBorder)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)

                // Claude Account
                VStack(alignment: .leading, spacing: 8) {
                    Text("Anthropic Claude Account")
                        .font(.headline)

                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.seal.fill")
                            .foregroundColor(.green)
                            .font(.system(size: 16))
                        VStack(alignment: .leading, spacing: 1) {
                            Text("Account: vijendra9753@gmail.com (Claude Pro)")
                                .font(.subheadline)
                                .bold()
                            Text("Connected via macOS Keychain (Claude Code-credentials)")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }

                    Text("Automatically queries https://api.anthropic.com/api/oauth/usage to fetch live 5-hour session and weekly quotas.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    // MARK: - Desktop Widget Tab
    private var widgetTab: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Desktop Widget Configuration")
                        .font(.headline)

                    Toggle("Enable Desktop Floating Widget", isOn: $settings.isDesktopWidgetVisible)
                        .font(.subheadline)

                    Toggle("Pin to Desktop Wallpaper Layer (Stays behind windows)", isOn: $settings.isDesktopWidgetPinned)
                        .font(.subheadline)

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Widget Size:")
                            .font(.subheadline)
                            .fontWeight(.medium)

                        Picker("", selection: $settings.widgetSizeStyle) {
                            ForEach(WidgetSizeStyle.allCases, id: \.self) { size in
                                Text(size.rawValue).tag(size)
                            }
                        }
                        .pickerStyle(.radioGroup)
                    }

                    Divider()

                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Widget Opacity:")
                                .font(.subheadline)
                            Spacer()
                            Text("\(Int(settings.widgetOpacity * 100))%")
                                .font(.subheadline)
                                .bold()
                        }
                        Slider(value: $settings.widgetOpacity, in: 0.5...1.0, step: 0.05)
                    }
                }
                .padding()
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(nsColor: .controlBackgroundColor))
                .cornerRadius(10)
            }
            .padding(.horizontal, 10)
            .padding(.vertical, 8)
        }
    }

    // MARK: - About Tab
    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Usage AI")
                .font(.system(size: 20, weight: .bold, design: .rounded))

            Text("Version 1.2.0")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Real-time cloud-synced quota monitor for Claude and Gemini Antigravity across all local and remote servers.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 40)

            Spacer()
        }
        .padding(.top, 30)
    }
}
