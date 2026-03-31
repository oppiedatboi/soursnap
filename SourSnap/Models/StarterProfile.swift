import Foundation
import SwiftData

@Model
final class StarterProfile {
    var id: UUID = UUID()
    var name: String
    var birthday: Date
    var flourType: String
    var hydrationRatio: Double
    var notes: String
    var isActive: Bool = true
    var createdAt: Date = Date.now
    var avatarImagePath: String?

    @Relationship(deleteRule: .cascade, inverse: \JournalEntry.starterProfile)
    var journalEntries: [JournalEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.starterProfile)
    var chatMessages: [ChatMessage] = []

    @Relationship(deleteRule: .cascade, inverse: \FeedingLog.starterProfile)
    var feedingLogs: [FeedingLog] = []

    init(
        name: String,
        birthday: Date = .now,
        flourType: String = "All-Purpose",
        hydrationRatio: Double = 100,
        notes: String = "",
        isActive: Bool = true
    ) {
        self.id = UUID()
        self.name = name
        self.birthday = birthday
        self.flourType = flourType
        self.hydrationRatio = hydrationRatio
        self.notes = notes
        self.isActive = isActive
        self.createdAt = .now
    }

    var daysSinceBorn: Int {
        Calendar.current.dateComponents([.day], from: birthday, to: .now).day ?? 0
    }
}
