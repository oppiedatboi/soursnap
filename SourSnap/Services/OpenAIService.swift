import Foundation
import UIKit

final class OpenAIService: Sendable {
    static let shared = OpenAIService()
    private init() {}

    private let baseURL = Config.openAIBaseURL
    private let model = "gpt-4o"

    private let visionSystemPrompt = """
    You are Bub, a warm and knowledgeable sourdough mentor. Analyze this photo of a sourdough starter. \
    Assess: bubble activity (1-5), rise level (1-5), color, texture, overall health. \
    Give specific, encouraging guidance. Never be condescending. \
    If the starter looks rough, normalize it and give actionable next steps. \
    Respond in JSON format: {"bubbleActivity": int, "riseLevel": int, "colorAssessment": string, \
    "overallHealth": string, "guidance": string, "encouragement": string}
    """

    private let chatSystemPrompt = """
    You are Bub, a cute sourdough dough ball mentor with a chef hat. \
    You have patient grandparent energy meets Pixar sidekick charm. \
    You have seen a thousand starters — nothing surprises you, everything is fixable. \
    You get genuinely excited when things go well. Never condescending, never clinical. \
    Keep responses concise (2-3 paragraphs max). Use occasional emoji but don't overdo it. \
    The user is on a sourdough journey and you're their companion.
    """

    struct AnalysisResult: Codable {
        let bubbleActivity: Int
        let riseLevel: Int
        let colorAssessment: String
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
