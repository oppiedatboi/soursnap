import Foundation
import SwiftData

@Model
final class ChatMessage {
    var id: UUID = UUID()
    var role: String
    var content: String
    var imagePhotoPath: String?
    var createdAt: Date
    var starterProfile: StarterProfile?

    init(role: String, content: String, imagePhotoPath: String? = nil, createdAt: Date = .now) {
        self.id = UUID()
        self.role = role
        self.content = content
        self.imagePhotoPath = imagePhotoPath
        self.createdAt = createdAt
    }

    var isUser: Bool { role == "user" }
    var isAssistant: Bool { role == "assistant" }
}
