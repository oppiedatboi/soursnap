import Foundation
import UIKit

final class OpenAIService: Sendable {
    static let shared = OpenAIService()
    private init() {}

    private let baseURL = Config.openAIBaseURL
    private let model = "gpt-4o-mini"

    private let visionSystemPrompt = """
    You are Bub, a friendly sourdough starter mentor. Analyze this sourdough starter photo. \
    Provide: 1) Visual assessment (color, texture, bubbles, rise level), 2) Health score 1-10, \
    3) What looks good, 4) Any concerns, 5) One clear next-step recommendation. \
    Keep it conversational and encouraging. \
    Respond in JSON format: {"healthScore": int, "aiAnalysis": string (your full conversational analysis), \
    "colorAssessment": string, "activityLevel": string (describe bubble activity and rise), \
    "textureAssessment": string, "recommendations": [string], \
    "bubbleActivity": int (1-5), "riseLevel": int (1-5), \
    "overallHealth": string, "guidance": string (next step recommendation), \
    "encouragement": string (a short encouraging note)}
    """

    private let chatSystemPrompt = """
    You are Bub, a friendly sourdough starter mentor. Warm, encouraging, knowledgeable about sourdough. \
    Short conversational messages (2-4 sentences). Use emoji sparingly. Never say as an AI. \
    If asked about mold, say to discard if unsure.
    """

    struct AnalysisResult: Codable {
        let healthScore: Int
        let aiAnalysis: String
        let colorAssessment: String
        let activityLevel: String
        let textureAssessment: String
        let recommendations: [String]
        let bubbleActivity: Int
        let riseLevel: Int
        let overallHealth: String
        let guidance: String
        let encouragement: String
    }

    // MARK: - Vision Analysis

    func analyzeStarterPhoto(_ image: UIImage) async throws -> AnalysisResult {
        guard let imageData = image.jpegData(compressionQuality: 0.7) else {
            throw OpenAIError.imageConversionFailed
        }
        let base64 = imageData.base64EncodedString()

        let messages: [[String: Any]] = [
            ["role": "system", "content": visionSystemPrompt],
            ["role": "user", "content": [
                ["type": "text", "text": "Please analyze my sourdough starter from this photo."],
                ["type": "image_url", "image_url": ["url": "data:image/jpeg;base64,\(base64)", "detail": "low"]]
            ] as [[String: Any]]]
        ]

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.7
        ]

        let data = try await makeRequest(body: body)
        let responseText = try extractContent(from: data)

        // Parse JSON from response (handle markdown code blocks)
        let jsonString = responseText
            .replacingOccurrences(of: "```json", with: "")
            .replacingOccurrences(of: "```", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let jsonData = jsonString.data(using: .utf8) else {
            throw OpenAIError.invalidResponse
        }

        let decoder = JSONDecoder()
        return try decoder.decode(AnalysisResult.self, from: jsonData)
    }

    // MARK: - Chat

    func sendChatMessage(_ userMessage: String, history: [(role: String, content: String)]) async throws -> String {
        var messages: [[String: Any]] = [
            ["role": "system", "content": chatSystemPrompt]
        ]

        for msg in history {
            messages.append(["role": msg.role, "content": msg.content])
        }

        messages.append(["role": "user", "content": userMessage])

        let body: [String: Any] = [
            "model": model,
            "messages": messages,
            "max_tokens": 500,
            "temperature": 0.8
        ]

        let data = try await makeRequest(body: body)
        return try extractContent(from: data)
    }

    // MARK: - Networking

    private func makeRequest(body: [String: Any]) async throws -> Data {
        guard let url = URL(string: "\(baseURL)/chat/completions") else {
            throw OpenAIError.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(Config.openAIAPIKey)", forHTTPHeaderField: "Authorization")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)
        request.timeoutInterval = 60

        let (data, response) = try await URLSession.shared.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw OpenAIError.invalidResponse
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            let errorBody = String(data: data, encoding: .utf8) ?? "Unknown error"
            throw OpenAIError.apiError(statusCode: httpResponse.statusCode, message: errorBody)
        }

        return data
    }

    private func extractContent(from data: Data) throws -> String {
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any],
              let content = message["content"] as? String else {
            throw OpenAIError.invalidResponse
        }
        return content
    }
}

enum OpenAIError: LocalizedError {
    case invalidURL
    case imageConversionFailed
    case invalidResponse
    case apiError(statusCode: Int, message: String)

    var errorDescription: String? {
        switch self {
        case .invalidURL: return "Invalid API URL"
        case .imageConversionFailed: return "Couldn't process the photo. Try taking another one!"
        case .invalidResponse: return "Got an unexpected response. Give it another try!"
        case .apiError(let code, let msg):
            if code == 401 { return "API key issue — check your configuration." }
            if code == 429 { return "Too many requests — wait a moment and try again." }
            return "Something went wrong (error \(code)). Try again in a moment."
        }
    }
}
