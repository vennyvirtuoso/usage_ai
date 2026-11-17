import WidgetKit
import SwiftUI
import AppKit

public struct QuotaTimelineEntry: TimelineEntry {
    public let date: Date
    public let geminiFiveHour: Int
    public let geminiWeekly: Int
    public let geminiFiveHourCountdown: String
    public let geminiWeeklyCountdown: String
    public let claudeFiveHour: Int
    public let claudeWeekly: Int
    public let claudeFiveHourCountdown: String
    public let claudeWeeklyCountdown: String
}

public struct QuotaProvider: TimelineProvider {
    public init() {}

    public func placeholder(in context: Context) -> QuotaTimelineEntry {
        QuotaTimelineEntry(
            date: Date(),
            geminiFiveHour: 97,
            geminiWeekly: 79,
            geminiFiveHourCountdown: "4h 39m",
            geminiWeeklyCountdown: "4d 8h",
            claudeFiveHour: 93,
            claudeWeekly: 83,
            claudeFiveHourCountdown: "3h 12m",
            claudeWeeklyCountdown: "1d 15h"
        )
    }

    public func getSnapshot(in context: Context, completion: @escaping (QuotaTimelineEntry) -> Void) {
        if context.isPreview {
            completion(placeholder(in: context))
        } else {
            completion(fetchCurrentEntry())
        }
    }

    public func getTimeline(in context: Context, completion: @escaping (Timeline<QuotaTimelineEntry>) -> Void) {
        let entry = fetchCurrentEntry()
        // Refresh timeline every 20 minutes
        let nextUpdate = Date().addingTimeInterval(1200)
        let timeline = Timeline(entries: [entry], policy: .after(nextUpdate))
        completion(timeline)
    }

    private func fetchCurrentEntry() -> QuotaTimelineEntry {
        if let snapshot = SharedQuotaSnapshot.load() {
            return QuotaTimelineEntry(
                date: snapshot.updatedAt,
                geminiFiveHour: snapshot.geminiFiveHourPercent,
                geminiWeekly: snapshot.geminiWeeklyPercent,
                geminiFiveHourCountdown: snapshot.geminiFiveHourCountdown,
                geminiWeeklyCountdown: snapshot.geminiWeeklyCountdown,
                claudeFiveHour: snapshot.claudeFiveHourPercent,
                claudeWeekly: snapshot.claudeWeeklyPercent,
                claudeFiveHourCountdown: snapshot.claudeFiveHourCountdown,
                claudeWeeklyCountdown: snapshot.claudeWeeklyCountdown
            )
        }

        var g5h = 97
        var gWk = 79
        var g5hCount = "4h 39m"
        var gWkCount = "4d 8h"

        var c5h = 93
        var cWk = 83
        var c5hCount = "3h 12m"
        var cWkCount = "1d 15h"

        // Try reading Claude cache from ~/.claude.json
        let home = FileManager.default.homeDirectoryForCurrentUser
        let claudeJson = home.appendingPathComponent(".claude.json")
        if let data = try? Data(contentsOf: claudeJson),
           let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let cachedUsage = json["cachedUsageUtilization"] as? [String: Any],
           let util = (cachedUsage["utilization"] as? [String: Any]) ?? cachedUsage as? [String: Any] {

            if let fiveHour = util["five_hour"] as? [String: Any] {
                var resetsInPast = false
                if let resetsAtStr = fiveHour["resets_at"] as? String {
                    let iso = ISO8601DateFormatter()
                    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let r = iso.date(from: resetsAtStr) ?? ISO8601DateFormatter().date(from: resetsAtStr), r <= Date() {
                        resetsInPast = true
                        c5h = 100
                        c5hCount = "Ready"
                    }
                }
                if !resetsInPast, let u = fiveHour["utilization"] as? Double {
                    c5h = max(0, min(100, Int((100.0 - u).rounded())))
                }
            }
            if let sevenDay = util["seven_day"] as? [String: Any] {
                var resetsInPast = false
                if let resetsAtStr = sevenDay["resets_at"] as? String {
                    let iso = ISO8601DateFormatter()
                    iso.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
                    if let r = iso.date(from: resetsAtStr) ?? ISO8601DateFormatter().date(from: resetsAtStr), r <= Date() {
                        resetsInPast = true
                        cWk = 100
                        cWkCount = "Ready"
                    }
                }
                if !resetsInPast, let u = sevenDay["utilization"] as? Double {
                    cWk = max(0, min(100, Int((100.0 - u).rounded())))
                }
            }
        }

        return QuotaTimelineEntry(
            date: Date(),
            geminiFiveHour: g5h,
            geminiWeekly: gWk,
            geminiFiveHourCountdown: g5hCount,
            geminiWeeklyCountdown: gWkCount,
            claudeFiveHour: c5h,
            claudeWeekly: cWk,
            claudeFiveHourCountdown: c5hCount,
            claudeWeeklyCountdown: cWkCount
        )
    }
}

public struct UsageAIWidgetEntryView: View {
    public var entry: QuotaProvider.Entry
    @Environment(\.widgetFamily) var family

    public var body: some View {
        Group {
            if family == .systemSmall {
                smallView
            } else {
                mediumView
            }
        }
        .containerBackground(for: .widget) {
            Color.clear
        }
    }

    // MARK: - Medium Notification Center Widget
    private var mediumView: some View {
        VStack(spacing: 8) {
            // Header
            HStack {
                HStack(spacing: 5) {
                    Circle()
                        .fill(Color(red: 0.06, green: 0.72, blue: 0.51))
                        .frame(width: 6, height: 6)
                    Text("AI Quotas")
                        .font(.system(size: 11, weight: .bold, design: .rounded))
                }
                Spacer()
                Text("Every 20m")
                    .font(.system(size: 8))
                    .foregroundColor(.secondary)
            }

            // Cards row
            HStack(spacing: 10) {
                // Gemini Card
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("✨ Gemini")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.blue)
                        Spacer()
                    }

                    // 5h
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("5-Hour")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(entry.geminiFiveHour)%")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        quotaBar(fraction: Double(entry.geminiFiveHour) / 100.0, color: .green)
                    }

                    // Weekly
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Weekly")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(entry.geminiWeekly)%")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.blue)
                        }
                        quotaBar(fraction: Double(entry.geminiWeekly) / 100.0, color: .blue)
                    }

                    Text("5h: \(entry.geminiFiveHourCountdown) left")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.blue.opacity(0.08))
                .cornerRadius(10)
                .frame(maxWidth: .infinity)

                // Claude Card
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("🤖 Claude")
                            .font(.system(size: 11, weight: .bold))
                            .foregroundColor(.orange)
                        Spacer()
                        Text("Pro")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.orange)
                    }

                    // 5h
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("5-Hour")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(entry.claudeFiveHour)%")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.green)
                        }
                        quotaBar(fraction: Double(entry.claudeFiveHour) / 100.0, color: .green)
                    }

                    // Weekly
                    VStack(alignment: .leading, spacing: 2) {
                        HStack {
                            Text("Weekly")
                                .font(.system(size: 9))
                                .foregroundColor(.secondary)
                            Spacer()
                            Text("\(entry.claudeWeekly)%")
                                .font(.system(size: 11, weight: .bold, design: .rounded))
                                .foregroundColor(.orange)
                        }
                        quotaBar(fraction: Double(entry.claudeWeekly) / 100.0, color: .orange)
                    }

                    Text("5h: \(entry.claudeFiveHourCountdown) left")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
                .padding(8)
                .background(Color.orange.opacity(0.08))
                .cornerRadius(10)
                .frame(maxWidth: .infinity)
            }
        }
    }

    // MARK: - Small Notification Center Widget
    private var smallView: some View {
        VStack(spacing: 8) {
            HStack {
                Text("AI Quotas")
                    .font(.system(size: 11, weight: .bold, design: .rounded))
                Spacer()
                Circle()
                    .fill(Color.green)
                    .frame(width: 5, height: 5)
            }

            HStack(spacing: 12) {
                VStack(spacing: 3) {
                    Text("GEMINI")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.blue)
                    Text("\(entry.geminiFiveHour)%")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    Text("Wk: \(entry.geminiWeekly)%")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }

                Divider().frame(height: 40)

                VStack(spacing: 3) {
                    Text("CLAUDE")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.orange)
                    Text("\(entry.claudeFiveHour)%")
                        .font(.system(size: 18, weight: .black, design: .rounded))
                    Text("Wk: \(entry.claudeWeekly)%")
                        .font(.system(size: 8))
                        .foregroundColor(.secondary)
                }
            }

            Text("Syncs every 20m")
                .font(.system(size: 8))
                .foregroundColor(.secondary)
        }
    }

    private func quotaBar(fraction: Double, color: Color) -> some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Color.primary.opacity(0.12))
                Capsule()
                    .fill(color)
                    .frame(width: max(geo.size.width * CGFloat(min(max(fraction, 0.0), 1.0)), 2))
            }
        }
        .frame(height: 5)
    }
}

@main
public struct UsageAIWidgetBundle: WidgetBundle {
    public init() {}

    public var body: some Widget {
        UsageAIWidget()
    }
}

public struct UsageAIWidget: Widget {
    public let kind: String = "UsageAIWidget"

    public init() {}

    public var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: QuotaProvider()) { entry in
            UsageAIWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Usage AI")
        .description("Track real-time Claude & Gemini Antigravity cloud quotas.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}
