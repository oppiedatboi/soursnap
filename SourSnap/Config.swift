import Foundation

enum Config {
    // Set your OpenAI API key in Secrets.swift (gitignored) or replace this placeholder
    static let openAIAPIKey = Secrets.openAIAPIKey
    static let openAIBaseURL = "https://api.openai.com/v1"
}
