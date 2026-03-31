import Foundation
import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()

    private let center = UNUserNotificationCenter.current()
    private let feedingReminderID = "daily-feeding-reminder"

    private let encouragingMessages = [
        "Your starter is hungry and waiting! A well-fed starter is a happy starter.",
        "Rise and shine — your starter needs some love today!",
        "Don't forget your bubbly friend! Consistent feeding = amazing bread.",
        "Your sourdough journey continues! Time for today's feeding.",
        "A little flour, a little water, a lot of magic. Let's go!",
        "Your starter has been patiently waiting. Feed time!",
        "Great bakers feed consistently. You've got this!",
        "Bubbles are brewing! Keep the momentum going with today's feed.",
    ]

    private init() {}

    func requestPermission() async -> Bool {
        do {
            return try await center.requestAuthorization(options: [.alert, .sound, .badge])
        } catch {
            return false
        }
    }

    func scheduleFeedingReminder(at time: Date, starterName: String) {
        center.removePendingNotificationRequests(withIdentifiers: [feedingReminderID])

        let content = UNMutableNotificationContent()
        content.title = "Time to feed \(starterName)! 🍞"
        content.body = encouragingMessages.randomElement() ?? encouragingMessages[0]
        content.sound = .default

        let components = Calendar.current.dateComponents([.hour, .minute], from: time)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: true)

        let request = UNNotificationRequest(
            identifier: feedingReminderID,
            content: content,
            trigger: trigger
        )

        center.add(request)
    }

    func cancelFeedingReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [feedingReminderID])
    }
}
