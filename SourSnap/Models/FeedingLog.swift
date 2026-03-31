import Foundation
import SwiftData

@Model
final class FeedingLog {
    var date: Date
    var flourAmount: Double
    var waterAmount: Double
    var notes: String
    var starterProfile: StarterProfile?

    init(date: Date = .now, flourAmount: Double = 0, waterAmount: Double = 0, notes: String = "") {
        self.date = date
        self.flourAmount = flourAmount
        self.waterAmount = waterAmount
        self.notes = notes
    }
}
