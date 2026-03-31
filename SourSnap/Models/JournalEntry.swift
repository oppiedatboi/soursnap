import Foundation
import SwiftData

@Model
final class JournalEntry {
    var id: UUID = UUID()
    var date: Date
    @Attribute(.externalStorage) var photo: Data?
    var photoPath: String?
    var thumbnailPath: String?
    var healthScore: Double?
    var aiAnalysis: String?
    var userNotes: String
    var temperature: Double?
    var colorAssessment: String
    var activityLevel: String
    var textureAssessment: String
    var recommendations: [String]?

    // Legacy fields retained for existing UI compatibility
    var bubbleActivity: Int
    var riseLevel: Int
    var overallHealth: String
    var guidance: String
    var encouragement: String

    var starterProfile: StarterProfile?

    init(
        date: Date = .now,
        photo: Data? = nil,
        photoPath: String? = nil,
        thumbnailPath: String? = nil,
        healthScore: Double? = nil,
        aiAnalysis: String? = nil,
        userNotes: String = "",
        temperature: Double? = nil,
        colorAssessment: String = "",
        activityLevel: String = "",
        textureAssessment: String = "",
        recommendations: [String]? = nil,
        bubbleActivity: Int = 0,
        riseLevel: Int = 0,
        overallHealth: String = "",
        guidance: String = "",
        encouragement: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.photo = photo
        self.photoPath = photoPath
        self.thumbnailPath = thumbnailPath
        self.healthScore = healthScore
        self.aiAnalysis = aiAnalysis
        self.userNotes = userNotes
        self.temperature = temperature
        self.colorAssessment = colorAssessment
        self.activityLevel = activityLevel
        self.textureAssessment = textureAssessment
        self.recommendations = recommendations
        self.bubbleActivity = bubbleActivity
        self.riseLevel = riseLevel
        self.overallHealth = overallHealth
        self.guidance = guidance
        self.encouragement = encouragement
    }
}
