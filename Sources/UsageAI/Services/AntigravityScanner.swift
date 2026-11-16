import Foundation

public class AntigravityScanner {
    public static let shared = AntigravityScanner()

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

    public func discoverBrainDirectories(customPath: String? = nil) -> [URL] {
        var directories: [URL] = []
        let fileManager = FileManager.default

        if let custom = customPath, !custom.isEmpty {
            let customURL = URL(fileURLWithPath: (custom as NSString).expandingTildeInPath)
            if fileManager.fileExists(atPath: customURL.path) {
                directories.append(customURL)
            }
        }

        let home = fileManager.homeDirectoryForCurrentUser
        let defaultBrain = home.appendingPathComponent(".gemini/antigravity/brain")
        if fileManager.fileExists(atPath: defaultBrain.path) {
            directories.append(defaultBrain)
        }

        let altGemini = home.appendingPathComponent(".gemini")
        if fileManager.fileExists(atPath: altGemini.path) && !directories.contains(where: { $0.path == altGemini.path }) {
            directories.append(altGemini)
        }

        return directories
    }

    public func scanLogs(customPath: String? = nil) -> [TokenRecord] {
        let directories = discoverBrainDirectories(customPath: customPath)
        var allRecords: [TokenRecord] = []
        let fileManager = FileManager.default

        for baseDir in directories {
            guard let enumerator = fileManager.enumerator(
                at: baseDir,
                includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey],
                options: [.skipsHiddenFiles]
            ) else {
                continue
            }

            for case let fileURL as URL in enumerator {
                let name = fileURL.lastPathComponent
                if name.hasSuffix(".jsonl") && (name.contains("transcript") || name.contains("session") || name.contains("log")) {
                    let records = parseFile(fileURL: fileURL)
                    allRecords.append(contentsOf: records)
                }
            }

            // Also check hidden .system_generated/logs
            let systemGeneratedDir = baseDir.appendingPathComponent(".system_generated/logs")
            if fileManager.fileExists(atPath: systemGeneratedDir.path) {
                if let subEnum = fileManager.enumerator(
                    at: systemGeneratedDir,
                    includingPropertiesForKeys: [.contentModificationDateKey, .fileSizeKey, .isRegularFileKey]
                ) {
                    for case let fileURL as URL in subEnum {
                        let name = fileURL.lastPathComponent
                        if name.hasSuffix(".jsonl") {
                            let records = parseFile(fileURL: fileURL)
                            allRecords.append(contentsOf: records)
                        }
                    }
                }
            }
            
            // Check subfolders inside brain/ (e.g. brain/<conv-id>/.system_generated/logs)
            if let convDirs = try? fileManager.contentsOfDirectory(at: baseDir, includingPropertiesForKeys: nil) {
                for convDir in convDirs {
                    let convLogs = convDir.appendingPathComponent(".system_generated/logs")
                    if fileManager.fileExists(atPath: convLogs.path) {
                        if let files = try? fileManager.contentsOfDirectory(at: convLogs, includingPropertiesForKeys: nil) {
                            for f in files where f.pathExtension == "jsonl" {
                                let records = parseFile(fileURL: f)
                                allRecords.append(contentsOf: records)
                            }
                        }
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
        guard let contentString = String(data: data, encoding: .utf8) else {
            return []
        }

        let lines = contentString.components(separatedBy: .newlines)
        for (idx, line) in lines.enumerated() {
            let trimmed = line.trimmingCharacters(in: .whitespacesAndNewlines)
            if trimmed.isEmpty || !trimmed.starts(with: "{") { continue }

            guard let lineData = trimmed.data(using: .utf8),
                  let json = try? JSONSerialization.jsonObject(with: lineData) as? [String: Any] else {
                continue
            }

            var inputTokens: Int = 0
            var outputTokens: Int = 0
            var cacheReadTokens: Int = 0
            var cacheWriteTokens: Int = 0
            var modelName: String = "gemini-unknown"
            var timestamp: Date = modDate

            // Direct tokens on JSON
            if let inTok = json["input_tokens"] as? Int {
                inputTokens = inTok
            } else if let promptTok = json["prompt_tokens"] as? Int {
                inputTokens = promptTok
            }

            if let outTok = json["output_tokens"] as? Int {
                outputTokens = outTok
            } else if let candTok = json["candidates_tokens"] as? Int {
                outputTokens = candTok
            } else if let compTok = json["completion_tokens"] as? Int {
                outputTokens = compTok
            }

            if let cRead = json["cache_read_tokens"] as? Int {
                cacheReadTokens = cRead
            } else if let cRead2 = json["cached_tokens"] as? Int {
                cacheReadTokens = cRead2
            }

            if let cWrite = json["cache_write_tokens"] as? Int {
                cacheWriteTokens = cWrite
            }

            // Nested usage dictionary (Gemini/OpenAI format)
            if let usage = json["usage"] as? [String: Any] {
                if let inTok = usage["input_tokens"] as? Int ?? usage["prompt_tokens"] as? Int {
                    inputTokens = inTok
                }
                if let outTok = usage["output_tokens"] as? Int ?? usage["candidates_tokens"] as? Int ?? usage["completion_tokens"] as? Int {
                    outputTokens = outTok
                }
                if let cRead = usage["cache_read_tokens"] as? Int ?? usage["cached_tokens"] as? Int {
                    cacheReadTokens = cRead
                }
                if let cWrite = usage["cache_write_tokens"] as? Int {
                    cacheWriteTokens = cWrite
                }
            }

            if let m = json["model"] as? String, !m.isEmpty {
                modelName = m
            }

            if let dateStr = json["created_at"] as? String ?? json["timestamp"] as? String {
                if let parsedDate = isoDateFormatter.date(from: dateStr) ?? isoDateFormatterNoFrac.date(from: dateStr) {
                    timestamp = parsedDate
                }
            }

            // If we found any valid token count
            if inputTokens > 0 || outputTokens > 0 || cacheReadTokens > 0 {
                let rec = TokenRecord(
                    id: "\(filePath):\(idx)",
                    provider: .geminiAntigravity,
                    model: modelName,
                    inputTokens: inputTokens,
                    outputTokens: outputTokens,
                    cacheReadTokens: cacheReadTokens,
                    cacheWriteTokens: cacheWriteTokens,
                    timestamp: timestamp,
                    sourceFile: fileURL.lastPathComponent
                )
                parsedRecords.append(rec)
            }
        }

        fileCache[filePath] = (modDate, fileSize, parsedRecords)
        return parsedRecords
    }

    public func clearCache() {
        fileCache.removeAll()
    }
}
