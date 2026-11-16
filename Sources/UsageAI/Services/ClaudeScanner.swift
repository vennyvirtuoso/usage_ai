import Foundation

public class ClaudeScanner {
    public static let shared = ClaudeScanner()

    private var fileCache: [String: (modDate: Date, size: UInt64, records: [TokenRecord])] = [:]
    private let isoDateFormatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter
    }()
    private let isoDateFormatterNoFrac: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime]
        return formatter
    }()

    public init() {}

    public func discoverClaudeDirectories(customPath: String? = nil) -> [URL] {
        var directories: [URL] = []
        let fileManager = FileManager.default

        if let custom = customPath, !custom.isEmpty {
            let customURL = URL(fileURLWithPath: (custom as NSString).expandingTildeInPath)
            if fileManager.fileExists(atPath: customURL.path) {
                directories.append(customURL)
            }
        }

        let home = fileManager.homeDirectoryForCurrentUser
        let defaultClaude = home.appendingPathComponent(".claude")
        if fileManager.fileExists(atPath: defaultClaude.path) {
            directories.append(defaultClaude)
        }

        return directories
    }

    public func scanLogs(customPath: String? = nil) -> [TokenRecord] {
        let directories = discoverClaudeDirectories(customPath: customPath)
        var allRecords: [TokenRecord] = []
        let fileManager = FileManager.default

        for baseDir in directories {
            guard let enumerator = fileManager.enumerator(
                at: baseDir,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey],
                options: [.skipsPackageDescendants]
            ) else {
                continue
            }

            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                let name = fileURL.lastPathComponent.lowercased()

                if ext == "jsonl" || ext == "json" {
                    // Check if file is related to sessions, projects, history, or transcripts
                    if name.contains("session") || name.contains("transcript") || name.contains("history") ||
                       name.contains("project") || fileURL.path.contains("/projects/") || fileURL.path.contains("/sessions/") {
                        let records = parseFile(fileURL: fileURL)
                        allRecords.append(contentsOf: records)
                    }
                }
            }
        }

        return allRecords
    }

    private func parseFile(fileURL: URL) -> [TokenRecord] {
        let filePath = fileURL.path
        let fileManager = FileManager.default

        guard let attrs = try? fileManager.attributesOfItem(atPath: filePath),
              let modDate = attrs[.modificationDate] as? Date,
              let fileSize = attrs[.size] as? UInt64 else {
            return []
        }

        if let cached = fileCache[filePath], cached.modDate == modDate, cached.size == fileSize {
            return cached.records
        }

        guard let data = try? Data(contentsOf: fileURL) else {
            return []
        }

        var parsedRecords: [TokenRecord] = []

        if fileURL.pathExtension.lowercased() == "jsonl" {
            parsedRecords = parseJSONL(data: data, fileURL: fileURL, modDate: modDate)
        } else {
            parsedRecords = parseJSON(data: data, fileURL: fileURL, modDate: modDate)
        }

        fileCache[filePath] = (modDate, fileSize, parsedRecords)
        return parsedRecords
    }

    private func parseJSONL(data: Data, fileURL: URL, modDate: Date) -> [TokenRecord] {
        guard let contentString = String(data: data, encoding: .utf8) else { return [] }
        var records: [TokenRecord] = []

        let lines = contentString.components(separatedBy: .newlines)
        for (idx, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || !trimmed.starts(with: "{") { continue }

            guard let lineData = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }

            if let record = extractRecord(from: json, idPrefix: "\(fileURL.lastPathComponent):\(idx)", modDate: modDate, fileURL: fileURL) {
                records.append(record)
            }
        }
        return records
    }

    private func parseJSON(data: Data, fileURL: URL, modDate: Date) -> [TokenRecord] {
        guard let obj = try? JSONSerialization.jsonObject(with: data) else { return [] }
        var records: [TokenRecord] = []

        if let array = obj as? [[String: Any]] {
            for (idx, item) in array.enumerated() {
                if let record = extractRecord(from: item, idPrefix: "\(fileURL.lastPathComponent):\(idx)", modDate: modDate, fileURL: fileURL) {
                    records.append(record)
                }
            }
        } else if let dict = obj as? [String: Any] {
            if let record = extractRecord(from: dict, idPrefix: "\(fileURL.lastPathComponent):0", modDate: modDate, fileURL: fileURL) {
                records.append(record)
            }
            // Check for nested messages/turns array
            if let messages = dict["messages"] as? [[String: Any]] {
                for (idx, msg) in messages.enumerated() {
                    if let record = extractRecord(from: msg, idPrefix: "\(fileURL.lastPathComponent):msg\(idx)", modDate: modDate, fileURL: fileURL) {
                        records.append(record)
                    }
                }
            }
        }
        return records
    }

    private func extractRecord(from json: [String: Any], idPrefix: String, modDate: Date, fileURL: URL) -> TokenRecord? {
        var inputTokens: Int = 0
        var outputTokens: Int = 0
        var cacheReadTokens: Int = 0
        var cacheWriteTokens: Int = 0
        var modelName: String = "claude-3-5-sonnet"
        var timestamp: Date = modDate

        if let m = json["model"] as? String, !m.isEmpty {
            modelName = m
        }

        if let dateStr = json["timestamp"] as? String ?? json["created_at"] as? String {
            if let parsedDate = isoDateFormatter.date(from: dateStr) ?? isoDateFormatterNoFrac.date(from: dateStr) {
                timestamp = parsedDate
            }
        } else if let timeNum = json["timestamp"] as? Double {
            timestamp = Date(timeIntervalSince1970: timeNum > 1_000_000_000_000 ? timeNum / 1000.0 : timeNum)
        }

        if let usage = json["usage"] as? [String: Any] {
            inputTokens = usage["input_tokens"] as? Int ?? 0
            outputTokens = usage["output_tokens"] as? Int ?? 0
            cacheReadTokens = usage["cache_read_input_tokens"] as? Int ?? usage["cache_read_tokens"] as? Int ?? 0
            cacheWriteTokens = usage["cache_creation_input_tokens"] as? Int ?? usage["cache_write_tokens"] as? Int ?? 0
        } else {
            inputTokens = json["input_tokens"] as? Int ?? 0
            outputTokens = json["output_tokens"] as? Int ?? 0
            cacheReadTokens = json["cache_read_tokens"] as? Int ?? 0
            cacheWriteTokens = json["cache_write_tokens"] as? Int ?? 0
        }

        guard inputTokens > 0 || outputTokens > 0 || cacheReadTokens > 0 else {
            return nil
        }

        return TokenRecord(
            id: idPrefix,
            provider: .claude,
            model: modelName,
            inputTokens: inputTokens,
            outputTokens: outputTokens,
            cacheReadTokens: cacheReadTokens,
            cacheWriteTokens: cacheWriteTokens,
            timestamp: timestamp,
            sourceFile: fileURL.lastPathComponent
        )
    }

    public func clearCache() {
        fileCache.removeAll()
    }
}
