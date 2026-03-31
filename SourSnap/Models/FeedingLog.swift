import Foundation
import SwiftData

@Model
final class FeedingLog {
    var id: UUID = UUID()
    var date: Date
    var flourAmount: Double
    var waterAmount: Double
    var flourType: String?
    var discardAmount: Double?
    var notes: String
    var starterProfile: StarterProfile?

    init(
        date: Date = .now,
        flourAmount: Double = 0,
        waterAmount: Double = 0,
        flourType: String? = nil,
        discardAmount: Double? = nil,
        notes: String = ""
    ) {
        self.id = UUID()
        self.date = date
        self.flourAmount = flourAmount
        self.waterAmount = waterAmount
        self.flourType = flourType
        self.discardAmount = discardAmount
        self.notes = notes
    }
}
