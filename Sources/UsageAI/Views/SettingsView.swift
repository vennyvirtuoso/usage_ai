import SwiftUI
import AppKit

public struct SettingsView: View {
    @ObservedObject var settings = AppSettings.shared
    @ObservedObject var tracker = UsageTracker.shared

    @State private var geminiKeyInput: String = ""
    @State private var claudeKeyInput: String = ""
    @State private var geminiValidationStatus: String? = nil
    @State private var claudeValidationStatus: String? = nil
    @State private var isValidatingGemini: Bool = false
    @State private var isValidatingClaude: Bool = false

    public init() {}

    public var body: some View {
        TabView {
            generalTab
                .tabItem {
                    Label("General", systemImage: "gearshape")
                }

            sourcesTab
                .tabItem {
                    Label("Local Logs", systemImage: "folder")
                }

            apiTab
                .tabItem {
                    Label("API Keys", systemImage: "key.fill")
                }

            aboutTab
                .tabItem {
                    Label("About", systemImage: "info.circle")
                }
        }
        .padding(20)
        .frame(width: 480, height: 380)
        .onAppear {
            geminiKeyInput = settings.geminiApiKey
            claudeKeyInput = settings.claudeApiKey
        }
    }

    // MARK: - General Tab
    private var generalTab: some View {
        Form {
            Section("Menu Bar Display") {
                Picker("Format:", selection: $settings.menuBarDisplayMode) {
                    ForEach(MenuBarDisplayMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.menu)

                Picker("Refresh Every:", selection: $settings.refreshIntervalSeconds) {
                    Text("5 seconds (Fastest)").tag(5.0)
                    Text("15 seconds (Recommended)").tag(15.0)
                    Text("30 seconds").tag(30.0)
                    Text("1 minute").tag(60.0)
                }
            }

            Section("Daily Budget & Alert") {
                HStack {
                    Text("Daily Token Budget:")
                    Spacer()
                    TextField("Budget", value: $settings.dailyTokenBudget, formatter: NumberFormatter())
                        .frame(width: 120)
                        .multilineTextAlignment(.trailing)
                }
                Text("Used for circular progress ring gauge calculations.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Section("Desktop Floating Widget") {
                Toggle("Show Desktop Widget", isOn: $settings.isDesktopWidgetVisible)
                Toggle("Compact Widget Size", isOn: $settings.isDesktopWidgetCompact)
                Toggle("Pin Behind Windows (Desktop Wallpaper Mode)", isOn: $settings.isDesktopWidgetPinned)

                HStack {
                    Text("Widget Opacity:")
                    Slider(value: $settings.widgetOpacity, in: 0.4...1.0, step: 0.05)
                    Text("\(Int(settings.widgetOpacity * 100))%")
                        .frame(width: 40)
                }
            }
        }
    }

    // MARK: - Local Sources Tab
    private var sourcesTab: some View {
        Form {
            Section("Gemini / Antigravity Transcripts") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Default: ~/.gemini/antigravity/brain/")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        TextField("Custom path (optional)", text: $settings.customAntigravityPath)
                        Button("Browse...") {
                            chooseDirectory { path in
                                settings.customAntigravityPath = path
                                tracker.refreshNow()
                            }
                        }
                    }
                }
            }

            Section("Claude Code Transcripts") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Default: ~/.claude/ (projects, sessions, logs)")
                        .font(.caption)
                        .foregroundColor(.secondary)

                    HStack {
                        TextField("Custom path (optional)", text: $settings.customClaudePath)
                        Button("Browse...") {
                            chooseDirectory { path in
                                settings.customClaudePath = path
                                tracker.refreshNow()
                            }
                        }
                    }
                }
            }

            Section("Status") {
                HStack {
                    Text("Discovered Records:")
                    Spacer()
                    Text("\(tracker.allRecords.count) AI events")
                        .bold()
                }

                Button("Rescan All Local Logs Now") {
                    AntigravityScanner.shared.clearCache()
                    ClaudeScanner.shared.clearCache()
                    tracker.refreshNow()
                }
            }
        }
    }

    // MARK: - API Keys Tab
    private var apiTab: some View {
        Form {
            Section("Optional API Keys (For Live Cloud Monitoring)") {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Google Gemini API Key:")
                    HStack {
                        SecureField("AIzaSy...", text: $geminiKeyInput)
                        Button("Save") {
                            settings.geminiApiKey = geminiKeyInput
                        }
                        Button("Test") {
                            testGeminiKey()
                        }
                        .disabled(isValidatingGemini || geminiKeyInput.isEmpty)
                    }

                    if let status = geminiValidationStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("Connected") ? .green : .red)
                    }
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text("Anthropic Claude API Key:")
                    HStack {
                        SecureField("sk-ant-...", text: $claudeKeyInput)
                        Button("Save") {
                            settings.claudeApiKey = claudeKeyInput
                        }
                        Button("Test") {
                            testClaudeKey()
                        }
                        .disabled(isValidatingClaude || claudeKeyInput.isEmpty)
                    }

                    if let status = claudeValidationStatus {
                        Text(status)
                            .font(.caption)
                            .foregroundColor(status.contains("Connected") ? .green : .red)
                    }
                }
            }
        }
    }

    // MARK: - About Tab
    private var aboutTab: some View {
        VStack(spacing: 12) {
            Image(systemName: "chart.line.uptrend.xyaxis.circle.fill")
                .font(.system(size: 48))
                .foregroundStyle(LinearGradient(colors: [.blue, .purple], startPoint: .topLeading, endPoint: .bottomTrailing))

            Text("Usage AI")
                .font(.system(size: 18, weight: .bold, design: .rounded))

            Text("Version 1.0.0 (Native macOS)")
                .font(.caption)
                .foregroundColor(.secondary)

            Text("Real-time token usage, caching efficiency, and cost tracker for Claude and Gemini Antigravity.")
                .font(.subheadline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding(.horizontal, 30)

            Spacer()
        }
        .padding(.top, 24)
    }

    private func chooseDirectory(completion: @escaping (String) -> Void) {
        let panel = NSOpenPanel()
        panel.canChooseFiles = false
        panel.canChooseDirectories = true
        panel.allowsMultipleSelection = false
        panel.prompt = "Select Log Folder"

        if panel.runModal() == .OK, let url = panel.url {
            completion(url.path)
        }
    }

    private func testGeminiKey() {
        isValidatingGemini = true
        geminiValidationStatus = "Testing connection..."
        Task {
            let res = await APIService.shared.validateGeminiKey(geminiKeyInput)
            await MainActor.run {
                isValidatingGemini = false
                geminiValidationStatus = res.message
                if res.isValid {
                    settings.geminiApiKey = geminiKeyInput
                }
            }
        }
    }

    private func testClaudeKey() {
        isValidatingClaude = true
        claudeValidationStatus = "Testing connection..."
        Task {
            let res = await APIService.shared.validateClaudeKey(claudeKeyInput)
            await MainActor.run {
                isValidatingClaude = false
                claudeValidationStatus = res.message
                if res.isValid {
                    settings.claudeApiKey = claudeKeyInput
                }
            }
        }
    }
}
