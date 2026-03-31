import Foundation
import SwiftData

@Model
final class StarterProfile {
    var name: String
    var birthday: Date
    var flourType: String
    var hydrationRatio: Double
    var notes: String

    @Relationship(deleteRule: .cascade, inverse: \JournalEntry.starterProfile)
    var journalEntries: [JournalEntry] = []

    @Relationship(deleteRule: .cascade, inverse: \ChatMessage.starterProfile)
    var chatMessages: [ChatMessage] = []

    @Relationship(deleteRule: .cascade, inverse: \FeedingLog.starterProfile)
    var feedingLogs: [FeedingLog] = []

    init(name: String, birthday: Date = .now, flourType: String = "All-Purpose", hydrationRatio: Double = 100, notes: String = "") {
        self.name = name
        self.birthday = birthday
        self.flourType = flourType
        self.hydrationRatio = hydrationRatio
        self.notes = notes
    }

    var daysSinceBorn: Int {
        Calendar.current.dateComponents([.day], from: birthday, to: .now).day ?? 0
    }
}
