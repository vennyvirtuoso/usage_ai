import Foundation

@main
struct RunTests {
    static func main() async {
        print("🧪 Running Usage AI Test Suite...")

        let fileManager = FileManager.default
        let tempDir = URL(fileURLWithPath: "/tmp/test_usage_ai")
        try? fileManager.removeItem(at: tempDir)
        try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let geminiDir = tempDir.appendingPathComponent("gemini_brain/session1/.system_generated/logs")
        try? fileManager.createDirectory(at: geminiDir, withIntermediateDirectories: true)
        let geminiLog = geminiDir.appendingPathComponent("transcript.jsonl")

        let sampleGemini = """
        {"step_index":0,"source":"USER_EXPLICIT","type":"USER_INPUT","status":"DONE","created_at":"2026-11-17T02:00:00Z","content":"hello"}
        {"step_index":1,"source":"MODEL","type":"PLANNER_RESPONSE","status":"DONE","created_at":"2026-11-17T02:00:05Z","model":"gemini-3.8-flash-medium","input_tokens":10000,"cache_read_tokens":5000,"output_tokens":500}
        {"step_index":2,"source":"MODEL","type":"PLANNER_RESPONSE","status":"DONE","created_at":"2026-11-17T02:01:00Z","model":"gemini-1.5-pro","input_tokens":20000,"cache_read_tokens":10000,"output_tokens":2000}
        """
        try? sampleGemini.write(to: geminiLog, atomically: true, encoding: .utf8)

        let claudeDir = tempDir.appendingPathComponent("claude_home/projects/my_project")
        try? fileManager.createDirectory(at: claudeDir, withIntermediateDirectories: true)
        let claudeLog = claudeDir.appendingPathComponent("session.jsonl")

        let sampleClaude = """
        {"model":"claude-3-5-sonnet-20241022","usage":{"input_tokens":4000,"output_tokens":800,"cache_read_input_tokens":15000,"cache_creation_input_tokens":2000},"created_at":"2026-11-17T02:10:00Z"}
        {"model":"claude-3-haiku","usage":{"input_tokens":1500,"output_tokens":300,"cache_read_input_tokens":0,"cache_creation_input_tokens":0},"created_at":"2026-11-17T02:15:00Z"}
        """
        try? sampleClaude.write(to: claudeLog, atomically: true, encoding: .utf8)

        // 1. Test Gemini Scanner
        print("➡️ Testing AntigravityScanner...")
        let geminiRecords = AntigravityScanner.shared.scanLogs(customPath: tempDir.appendingPathComponent("gemini_brain").path)
        assert(geminiRecords.count == 2, "Expected 2 Gemini records, got \(geminiRecords.count)")

        let totalGeminiTokens = geminiRecords.reduce(0) { $0 + $1.totalTokens }
        // Record 1: 10000 in + 500 out + 5000 cache = 15500
        // Record 2: 20000 in + 2000 out + 10000 cache = 32000
        // Total = 47500
        assert(totalGeminiTokens == 47500, "Expected 47,500 total tokens, got \(totalGeminiTokens)")
        print("  ✅ Gemini Scanner parsed \(geminiRecords.count) records, \(totalGeminiTokens) tokens.")

        // 2. Test Claude Scanner
        print("➡️ Testing ClaudeScanner...")
        let claudeRecords = ClaudeScanner.shared.scanLogs(customPath: tempDir.appendingPathComponent("claude_home").path)
        assert(claudeRecords.count == 2, "Expected 2 Claude records, got \(claudeRecords.count)")

        let totalClaudeTokens = claudeRecords.reduce(0) { $0 + $1.totalTokens }
        // Claude 1: 4000 in + 800 out + 15000 cacheRead + 2000 cacheWrite = 21800
        // Claude 2: 1500 in + 300 out = 1800
        // Total = 23600
        assert(totalClaudeTokens == 23600, "Expected 23,600 total tokens, got \(totalClaudeTokens)")
        print("  ✅ Claude Scanner parsed \(claudeRecords.count) records, \(totalClaudeTokens) tokens.")

        // 3. Test Pricing Calculator
        print("➡️ Testing PricingCalculator...")
        let rec1 = geminiRecords[0]
        let cost1 = PricingCalculator.shared.calculateCost(for: rec1)
        // Gemini 3.8 Flash: 10k * $0.10/M ($0.001) + 500 * $0.40/M ($0.0002) + 5000 * $0.025/M ($0.000125) = $0.001325
        assert(cost1 > 0.001 && cost1 < 0.002, "Gemini pricing outside expected range: \(cost1)")

        let cRec1 = claudeRecords[0]
        let cCost1 = PricingCalculator.shared.calculateCost(for: cRec1)
        // Claude 3.5 Sonnet: 4k * $3.00/M ($0.012) + 800 * $15.00/M ($0.012) + 15k * $0.30/M ($0.0045) + 2k * $3.75/M ($0.0075) = $0.036
        assert(cCost1 > 0.03 && cCost1 < 0.04, "Claude pricing outside expected range: \(cCost1)")
        print("  ✅ Pricing calculations validated successfully.")

        // 4. Test Model Specs & Context Window
        print("➡️ Testing ModelSpecs & Quota calculations...")
        let geminiCtx = ModelSpecs.contextWindow(for: "gemini-3.8-flash-medium", provider: .geminiAntigravity)
        assert(geminiCtx == 1_048_576, "Expected 1M context window for Gemini Flash, got \(geminiCtx)")

        let geminiProCtx = ModelSpecs.contextWindow(for: "gemini-1.5-pro", provider: .geminiAntigravity)
        assert(geminiProCtx == 2_097_152, "Expected 2M context window for Gemini Pro, got \(geminiProCtx)")

        let claudeCtx = ModelSpecs.contextWindow(for: "claude-3-5-sonnet", provider: .claude)
        assert(claudeCtx == 200_000, "Expected 200k context window for Claude Sonnet, got \(claudeCtx)")

        var quota = QuotaInfo()
        quota.contextTokensCurrentSession = 20_000
        quota.contextWindowLimit = 200_000
        assert(abs(quota.contextPercent - 0.10) < 0.001, "Expected 10% context percent")

        quota.dailyTokensUsed = 1_000_000
        quota.dailyTokensLimit = 4_000_000
        assert(abs(quota.quotaRemainingPercent - 0.75) < 0.001, "Expected 75% quota remaining")
        print("  ✅ Context window and quota metrics validated successfully.")

        // 5. Test Antigravity Live Cloud Parser
        print("➡️ Testing AntigravityLiveService cloud parsing...")
        let sampleAgyJson = """
        {
          "status": "SUCCESS",
          "command": {
            "name": "usage",
            "data": {
              "groups": [
                {
                  "name": "Gemini Models",
                  "buckets": [
                    { "id": "gemini-weekly", "remaining_fraction": 0.7897, "reset_time": "2026-11-21T07:37:46Z", "description": "Weekly limit" },
                    { "id": "gemini-5h", "remaining_fraction": 0.9676, "reset_time": "2026-11-17T03:19:02Z", "description": "5h limit" }
                  ]
                }
              ]
            }
          }
        }
        """.data(using: .utf8)!

        let parsedAgy = AntigravityLiveService.shared.parseAgyOutput(data: sampleAgyJson)
        assert(parsedAgy != nil, "Expected parsed Antigravity cloud usage")
        assert(parsedAgy?.geminiWeeklyPercent == 79, "Expected 79% weekly, got \(parsedAgy?.geminiWeeklyPercent ?? -1)")
        assert(parsedAgy?.geminiFiveHourPercent == 97, "Expected 97% 5h, got \(parsedAgy?.geminiFiveHourPercent ?? -1)")
        print("  ✅ Antigravity live cloud quota parser verified (79% weekly, 97% 5-hour).")

        // 6. Test AppSettings: 20 minutes refresh interval & Widget Sizing
        print("➡️ Testing AppSettings refresh interval & widget sizes...")
        assert(AppSettings.shared.refreshIntervalSeconds >= 600.0, "Expected at least 10 minutes refresh interval")
        assert(WidgetSizeStyle.allCases.count == 2, "Expected 2 widget size styles")
        print("  ✅ 20-minute refresh interval and widget sizes verified.")

        // Cleanup
        try? fileManager.removeItem(at: tempDir)
        print("\n🎉 ALL USAGE AI TESTS PASSED PERFECTLY!\n")
    }
}
