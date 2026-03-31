import Foundation
import SwiftData

@Model
final class ChatMessage {
    var role: String
    var content: String
    var timestamp: Date
    var starterProfile: StarterProfile?

    init(role: String, content: String, timestamp: Date = .now) {
        self.role = role
        self.content = content
        self.timestamp = timestamp
    }

    var isUser: Bool { role == "user" }
    var isAssistant: Bool { role == "assistant" }
}
