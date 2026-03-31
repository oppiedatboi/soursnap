import WidgetKit
import SwiftUI

// MARK: - Timeline Entry

struct KiboEntry: TimelineEntry {
    let date: Date
    let starterName: String
    let daysOld: Int
    let currentStreak: Int
    let lastHealthScore: Double?
    let lastSnapDate: Date?
}

// MARK: - Timeline Provider

struct KiboTimelineProvider: AppIntentTimelineProvider {
    typealias Entry = KiboEntry
    typealias Intent = KiboWidgetIntent

    func placeholder(in context: Context) -> KiboEntry {
        KiboEntry(
            date: .now,
            starterName: "Bubbles",
            daysOld: 42,
            currentStreak: 7,
            lastHealthScore: 8.5,
            lastSnapDate: .now
        )
    }

    func snapshot(for configuration: KiboWidgetIntent, in context: Context) async -> KiboEntry {
        readEntry()
    }

    func timeline(for configuration: KiboWidgetIntent, in context: Context) async -> Timeline<KiboEntry> {
        let entry = readEntry()
        // Refresh once per hour
        let nextUpdate = Calendar.current.date(byAdding: .hour, value: 1, to: .now)!
        return Timeline(entries: [entry], policy: .after(nextUpdate))
    }

    private func readEntry() -> KiboEntry {
        let defaults = UserDefaults(suiteName: "group.com.brainrotlabs.kibo")
        let name = defaults?.string(forKey: "widget_starter_name") ?? "My Starter"
        let days = defaults?.integer(forKey: "widget_days_old") ?? 0
        let streak = defaults?.integer(forKey: "widget_current_streak") ?? 0
        let score = defaults?.double(forKey: "widget_last_health_score")
        let snapTs = defaults?.double(forKey: "widget_last_snap_date") ?? 0

        return KiboEntry(
            date: .now,
            starterName: name,
            daysOld: days,
            currentStreak: streak,
            lastHealthScore: (score ?? 0) > 0 ? score : nil,
            lastSnapDate: snapTs > 0 ? Date(timeIntervalSince1970: snapTs) : nil
        )
    }
}

// MARK: - App Intent (required for AppIntentTimelineProvider)

import AppIntents

struct KiboWidgetIntent: WidgetConfigurationIntent {
    static let title: LocalizedStringResource = "Kibo Widget"
    static let description: IntentDescription = "Shows your sourdough starter status"
}

// MARK: - Small Widget View

struct KiboWidgetSmallView: View {
    let entry: KiboEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "birthday.cake")
                    .font(.system(size: 20))
                    .foregroundStyle(Color(hex: "D4813B"))

                Text(entry.starterName)
                    .font(.system(size: 15, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "3D2B1F"))
                    .lineLimit(1)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 4) {
                Label("\(entry.daysOld) days old", systemImage: "calendar")
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(Color(hex: "7A6555"))

                Label(
                    "\(entry.currentStreak) day streak",
                    systemImage: "flame.fill"
                )
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(entry.currentStreak > 0 ? Color(hex: "C75B3A") : Color(hex: "7A6555"))
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(14)
    }
}

// MARK: - Medium Widget View

struct KiboWidgetMediumView: View {
    let entry: KiboEntry

    var body: some View {
        HStack(spacing: 16) {
            // Left: icon + name
            VStack(alignment: .leading, spacing: 6) {
                Image(systemName: "birthday.cake")
                    .font(.system(size: 28))
                    .foregroundStyle(Color(hex: "D4813B"))

                Text(entry.starterName)
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(Color(hex: "3D2B1F"))
                    .lineLimit(1)

                Spacer()

                if let score = entry.lastHealthScore {
                    HStack(spacing: 4) {
                        Image(systemName: "heart.fill")
                            .font(.system(size: 11))
                            .foregroundStyle(Color(hex: "6B8E4E"))
                        Text(String(format: "%.1f", score))
                            .font(.system(size: 13, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color(hex: "3D2B1F"))
                    }
                }
            }

            Spacer()

            // Right: stats
            VStack(alignment: .trailing, spacing: 8) {
                statRow(icon: "calendar", value: "\(entry.daysOld)", label: "days old")
                statRow(icon: "flame.fill", value: "\(entry.currentStreak)", label: "streak")

                Spacer()

                if let snapDate = entry.lastSnapDate {
                    Text("Last snap: \(snapDate, style: .relative) ago")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color(hex: "7A6555"))
                        .lineLimit(1)
                } else {
                    Text("No snaps yet")
                        .font(.system(size: 11, design: .rounded))
                        .foregroundStyle(Color(hex: "7A6555"))
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(14)
    }

    private func statRow(icon: String, value: String, label: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 11))
                .foregroundStyle(Color(hex: "D4813B"))
            Text(value)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color(hex: "3D2B1F"))
            Text(label)
                .font(.system(size: 12, design: .rounded))
                .foregroundStyle(Color(hex: "7A6555"))
        }
    }
}

// MARK: - Widget Definition

struct KiboWidget: Widget {
    let kind = "KiboWidget"

    var body: some WidgetConfiguration {
        AppIntentConfiguration(
            kind: kind,
            intent: KiboWidgetIntent.self,
            provider: KiboTimelineProvider()
        ) { entry in
            Group {
                if #available(iOSApplicationExtension 17.0, *) {
                    KiboWidgetEntryView(entry: entry)
                        .containerBackground(Color(hex: "FFF8F0"), for: .widget)
                } else {
                    KiboWidgetEntryView(entry: entry)
                        .background(Color(hex: "FFF8F0"))
                }
            }
        }
        .configurationDisplayName("Kibo Starter")
        .description("See your sourdough starter's status at a glance.")
        .supportedFamilies([.systemSmall, .systemMedium])
    }
}

struct KiboWidgetEntryView: View {
    @Environment(\.widgetFamily) var family
    let entry: KiboEntry

    var body: some View {
        switch family {
        case .systemMedium:
            KiboWidgetMediumView(entry: entry)
        default:
            KiboWidgetSmallView(entry: entry)
        }
    }
}

// MARK: - Color Extension (self-contained for widget target)

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r = Double((int >> 16) & 0xFF) / 255
        let g = Double((int >> 8) & 0xFF) / 255
        let b = Double(int & 0xFF) / 255
        self.init(.sRGB, red: r, green: g, blue: b, opacity: 1)
    }
}
