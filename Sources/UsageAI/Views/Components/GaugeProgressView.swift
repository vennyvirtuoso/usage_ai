import SwiftUI

public struct CircularRingGauge: View {
    public let progress: Double
    public let strokeWidth: CGFloat
    public let gradientColors: [Color]
    public let title: String
    public let valueText: String

    public init(
        progress: Double,
        strokeWidth: CGFloat = 8,
        gradientColors: [Color] = [.blue, .cyan],
        title: String = "",
        valueText: String = ""
    ) {
        self.progress = min(max(progress, 0.0), 1.0)
        self.strokeWidth = strokeWidth
        self.gradientColors = gradientColors
        self.title = title
        self.valueText = valueText
    }

    public var body: some View {
        ZStack {
            // Background track
            Circle()
                .stroke(Color.primary.opacity(0.1), lineWidth: strokeWidth)

            // Progress arc
            Circle()
                .trim(from: 0, to: CGFloat(progress))
                .stroke(
                    AngularGradient(
                        gradient: Gradient(colors: gradientColors),
                        center: .center,
                        startAngle: .degrees(-90),
                        endAngle: .degrees(270)
                    ),
                    style: StrokeStyle(lineWidth: strokeWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(-90))
                .animation(.easeInOut(duration: 0.5), value: progress)

            // Inner label
            VStack(spacing: 2) {
                if !title.isEmpty {
                    Text(title)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Text(valueText)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
            }
        }
    }
}

public struct RatioBarView: View {
    public let geminiTokens: Int
    public let claudeTokens: Int

    private var geminiRatio: Double {
        let total = geminiTokens + claudeTokens
        guard total > 0 else { return 0.5 }
        return Double(geminiTokens) / Double(total)
    }

    public init(geminiTokens: Int, claudeTokens: Int) {
        self.geminiTokens = geminiTokens
        self.claudeTokens = claudeTokens
    }

    public var body: some View {
        VStack(spacing: 6) {
            GeometryReader { geo in
                HStack(spacing: 2) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(colors: [Color.blue, Color.cyan], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(geo.size.width * CGFloat(geminiRatio) - 1, 4))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(LinearGradient(colors: [Color.orange, Color.red], startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(geo.size.width * CGFloat(1.0 - geminiRatio) - 1, 4))
                }
            }
            .frame(height: 6)

            HStack {
                HStack(spacing: 4) {
                    Circle().fill(Color.blue).frame(width: 6, height: 6)
                    Text("Gemini: \(Int(geminiRatio * 100))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
                Spacer()
                HStack(spacing: 4) {
                    Circle().fill(Color.orange).frame(width: 6, height: 6)
                    Text("Claude: \(Int((1.0 - geminiRatio) * 100))%")
                        .font(.system(size: 10, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
    }
}
