import Foundation

public struct APIValidationResult {
    public let isValid: Bool
    public let message: String
}

public class APIService {
    public static let shared = APIService()

    private init() {}

    public func validateGeminiKey(_ apiKey: String) async -> APIValidationResult {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return APIValidationResult(isValid: false, message: "API key is empty")
        }

        guard let url = URL(string: "https://generativelanguage.googleapis.com/v1beta/models?key=\(apiKey)") else {
            return APIValidationResult(isValid: false, message: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse {
                if httpRes.statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let models = json["models"] as? [[String: Any]] {
                        return APIValidationResult(isValid: true, message: "Connected! Found \(models.count) Gemini models.")
                    }
                    return APIValidationResult(isValid: true, message: "Connected successfully.")
                } else {
                    return APIValidationResult(isValid: false, message: "Error HTTP \(httpRes.statusCode)")
                }
            }
        } catch {
            return APIValidationResult(isValid: false, message: error.localizedDescription)
        }
        return APIValidationResult(isValid: false, message: "Validation failed")
    }

    public func validateClaudeKey(_ apiKey: String) async -> APIValidationResult {
        guard !apiKey.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return APIValidationResult(isValid: false, message: "API key is empty")
        }

        guard let url = URL(string: "https://api.anthropic.com/v1/models") else {
            return APIValidationResult(isValid: false, message: "Invalid URL")
        }

        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.timeoutInterval = 10

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            if let httpRes = response as? HTTPURLResponse {
                if httpRes.statusCode == 200 {
                    if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
                       let dataArr = json["data"] as? [[String: Any]] {
                        return APIValidationResult(isValid: true, message: "Connected! Found \(dataArr.count) Claude models.")
                    }
                    return APIValidationResult(isValid: true, message: "Connected to Anthropic API.")
                } else {
                    return APIValidationResult(isValid: false, message: "Error HTTP \(httpRes.statusCode)")
                }
            }
        } catch {
            return APIValidationResult(isValid: false, message: error.localizedDescription)
        }
        return APIValidationResult(isValid: false, message: "Validation failed")
    }
}
