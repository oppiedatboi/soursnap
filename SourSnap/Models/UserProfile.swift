import Foundation
import SwiftData

@Model
final class UserProfile {
    var id: UUID = UUID()
    var displayName: String
    var feedingReminderEnabled: Bool
    var feedingReminderTime: Date
    var temperatureUnit: String
    var hasCompletedOnboarding: Bool
    var subscriptionStatus: String
    var appleUserIdentifier: String?
    var email: String?
    var createdAt: Date

    var isPro: Bool {
        subscriptionStatus == "paid"
    }

    init(
        displayName: String = "",
        feedingReminderEnabled: Bool = false,
        feedingReminderTime: Date = Calendar.current.date(from: DateComponents(hour: 8, minute: 0)) ?? .now,
        temperatureUnit: String = "fahrenheit",
        hasCompletedOnboarding: Bool = false,
        subscriptionStatus: String = "free",
        appleUserIdentifier: String? = nil,
        email: String? = nil
    ) {
        self.id = UUID()
        self.displayName = displayName
        self.feedingReminderEnabled = feedingReminderEnabled
        self.feedingReminderTime = feedingReminderTime
        self.temperatureUnit = temperatureUnit
        self.hasCompletedOnboarding = hasCompletedOnboarding
        self.subscriptionStatus = subscriptionStatus
        self.appleUserIdentifier = appleUserIdentifier
        self.email = email
        self.createdAt = .now
    }
}
