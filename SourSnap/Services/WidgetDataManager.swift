import Foundation
import WidgetKit

enum WidgetDataManager {
    static let suiteName = "group.com.brainrotlabs.kibo"

    private static var defaults: UserDefaults? {
        UserDefaults(suiteName: suiteName)
    }

    // MARK: - Keys

    private enum Key {
        static let starterName = "widget_starter_name"
        static let daysOld = "widget_days_old"
        static let currentStreak = "widget_current_streak"
        static let lastHealthScore = "widget_last_health_score"
        static let lastSnapDate = "widget_last_snap_date"
    }

    // MARK: - Write (from main app)

    static func update(
        starterName: String,
        daysOld: Int,
        currentStreak: Int,
        lastHealthScore: Double?,
        lastSnapDate: Date?
    ) {
        guard let defaults else { return }
        defaults.set(starterName, forKey: Key.starterName)
        defaults.set(daysOld, forKey: Key.daysOld)
        defaults.set(currentStreak, forKey: Key.currentStreak)
        if let score = lastHealthScore {
            defaults.set(score, forKey: Key.lastHealthScore)
        }
        if let date = lastSnapDate {
            defaults.set(date.timeIntervalSince1970, forKey: Key.lastSnapDate)
        }
        WidgetCenter.shared.reloadAllTimelines()
    }

    // MARK: - Read (from widget)

    static var starterName: String {
        defaults?.string(forKey: Key.starterName) ?? "My Starter"
    }

    static var daysOld: Int {
        defaults?.integer(forKey: Key.daysOld) ?? 0
    }

    static var currentStreak: Int {
        defaults?.integer(forKey: Key.currentStreak) ?? 0
    }

    static var lastHealthScore: Double? {
        let val = defaults?.double(forKey: Key.lastHealthScore) ?? 0
        return val > 0 ? val : nil
    }

    static var lastSnapDate: Date? {
        let ts = defaults?.double(forKey: Key.lastSnapDate) ?? 0
        return ts > 0 ? Date(timeIntervalSince1970: ts) : nil
    }
}
