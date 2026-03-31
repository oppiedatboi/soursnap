import Foundation
import SwiftData

@Model
final class JournalEntry {
    var date: Date
    @Attribute(.externalStorage) var photo: Data?
    var aiAnalysis: String
    var bubbleActivity: Int
    var riseLevel: Int
    var colorAssessment: String
    var overallHealth: String
    var guidance: String
    var encouragement: String
    var notes: String
    var starterProfile: StarterProfile?

    init(
        date: Date = .now,
        photo: Data? = nil,
        aiAnalysis: String = "",
        bubbleActivity: Int = 0,
        riseLevel: Int = 0,
        colorAssessment: String = "",
        overallHealth: String = "",
        guidance: String = "",
        encouragement: String = "",
        notes: String = ""
    ) {
        self.date = date
        self.photo = photo
        self.aiAnalysis = aiAnalysis
        self.bubbleActivity = bubbleActivity
        self.riseLevel = riseLevel
        self.colorAssessment = colorAssessment
        self.overallHealth = overallHealth
        self.guidance = guidance
        self.encouragement = encouragement
        self.notes = notes
    }
}
