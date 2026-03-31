import SwiftUI
import SwiftData

struct ProgressView: View {
    let profile: StarterProfile
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var entries: [JournalEntry]
    @Query private var feedingLogs: [FeedingLog]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        phaseTimeline
                        milestonesSection
                    }
                    .padding(16)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("\(profile.name)'s Journey")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        HapticManager.light()
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }
            }
        }
    }

    // MARK: - Journey Phases

    private var currentDay: Int { max(profile.daysSinceBorn, 0) }

    private var phases: [(name: String, range: ClosedRange<Int>, description: String, icon: String)] {
        [
            ("Getting Started", 1...3, "Your starter is waking up! Early bubbles may appear.", "sunrise"),
            ("Building Activity", 4...7, "Yeast and bacteria are establishing. Feed consistently.", "bolt"),
            ("Establishing Rhythm", 8...14, "Your starter is finding its rhythm. Watch for predictable rises.", "arrow.triangle.2.circlepath"),
            ("Maturing", 15...30, "Developing complex flavors. Nearly ready to bake!", "leaf"),
            ("Mature", 31...9999, "Your starter is mature and ready for anything!", "star.fill"),
        ]
    }

    private var currentPhaseIndex: Int {
        phases.firstIndex(where: { $0.range.contains(max(currentDay, 1)) }) ?? phases.count - 1
    }

    private var phaseTimeline: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text("Journey Phases")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
                .padding(.bottom, 16)

            ForEach(Array(phases.enumerated()), id: \.offset) { index, phase in
                let isCurrent = index == currentPhaseIndex
                let isPast = index < currentPhaseIndex

                HStack(alignment: .top, spacing: 14) {
                    // Timeline connector
                    VStack(spacing: 0) {
                        Circle()
                            .fill(isCurrent ? Color.appPrimary : isPast ? Color.appSuccess : Color.appBorder)
                            .frame(width: isCurrent ? 28 : 20, height: isCurrent ? 28 : 20)
                            .overlay {
                                if isCurrent {
                                    Image(systemName: phase.icon)
                                        .font(.system(size: 12, weight: .bold))
                                        .foregroundStyle(.white)
                                } else if isPast {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 10, weight: .bold))
                                        .foregroundStyle(.white)
                                }
                            }

                        if index < phases.count - 1 {
                            Rectangle()
                                .fill(isPast ? Color.appSuccess : Color.appBorder)
                                .frame(width: 2, height: 60)
                        }
                    }

                    // Phase content
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            Text(phase.name)
                                .font(.system(size: 15, weight: isCurrent ? .bold : .semibold, design: .rounded))
                                .foregroundStyle(isCurrent ? Color.appPrimary : isPast ? Color.appTextPrimary : Color.appTextSecondary)

                            if isCurrent {
                                Text("NOW")
                                    .font(.system(size: 10, weight: .black, design: .rounded))
                                    .foregroundStyle(.white)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 2)
                                    .background(Color.appPrimary, in: Capsule())
                            }
                        }

                        Text("Day \(phase.range.lowerBound)\(phase.range.upperBound < 9999 ? "-\(phase.range.upperBound)" : "+")")
                            .font(.system(size: 12, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.appTextSecondary)

                        if isCurrent {
                            Text(phase.description)
                                .font(.system(size: 13, design: .rounded))
                                .foregroundStyle(Color.appTextSecondary)
                                .padding(.top, 2)
                        }
                    }
                    .padding(.bottom, index < phases.count - 1 ? 12 : 0)
                }
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }

    // MARK: - Milestones

    private var milestonesSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Milestones")
                .font(.system(size: 18, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            let milestones = computeMilestones()

            if milestones.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "flag")
                            .font(.system(size: 28))
                            .foregroundStyle(Color.appTextSecondary)
                        Text("Start snapping and feeding to unlock milestones!")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(Color.appTextSecondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding(.vertical, 20)
                    Spacer()
                }
            } else {
                ForEach(milestones, id: \.title) { milestone in
                    HStack(spacing: 12) {
                        Image(systemName: milestone.icon)
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(milestone.color)
                            .frame(width: 36, height: 36)
                            .background(milestone.color.opacity(0.15), in: Circle())

                        VStack(alignment: .leading, spacing: 2) {
                            Text(milestone.title)
                                .font(.system(size: 14, weight: .semibold, design: .rounded))
                                .foregroundStyle(Color.appTextPrimary)
                            Text(milestone.subtitle)
                                .font(.system(size: 12, design: .rounded))
                                .foregroundStyle(Color.appTextSecondary)
                        }

                        Spacer()
                    }
                }
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }

    private struct Milestone {
        let title: String
        let subtitle: String
        let icon: String
        let color: Color
    }

    private func computeMilestones() -> [Milestone] {
        var milestones: [Milestone] = []

        let profileEntries = entries.filter { $0.starterProfile?.id == profile.id }
        let profileFeedings = feedingLogs.filter { $0.starterProfile?.id == profile.id }

        // First photo
        if let firstEntry = profileEntries.sorted(by: { $0.date < $1.date }).first {
            milestones.append(Milestone(
                title: "First Snap",
                subtitle: firstEntry.date.formatted(.dateTime.month(.abbreviated).day()),
                icon: "camera.fill",
                color: Color.appPrimary
            ))
        }

        // First feeding
        if let firstFeeding = profileFeedings.sorted(by: { $0.date < $1.date }).first {
            milestones.append(Milestone(
                title: "First Feeding",
                subtitle: firstFeeding.date.formatted(.dateTime.month(.abbreviated).day()),
                icon: "drop.fill",
                color: Color.appSuccess
            ))
        }

        // Total snaps milestones
        let snapCount = profileEntries.count
        if snapCount >= 10 {
            milestones.append(Milestone(
                title: "10 Snaps",
                subtitle: "\(snapCount) total photos taken",
                icon: "photo.stack",
                color: Color.appWarning
            ))
        }
        if snapCount >= 50 {
            milestones.append(Milestone(
                title: "50 Snaps!",
                subtitle: "Dedicated documenter",
                icon: "star.fill",
                color: Color.appWarning
            ))
        }

        // Feeding streak
        let streak = computeFeedingStreak(from: profileFeedings)
        if streak >= 7 {
            milestones.append(Milestone(
                title: "7-Day Feeding Streak",
                subtitle: "Best streak: \(streak) days",
                icon: "flame.fill",
                color: Color.appAlert
            ))
        }
        if streak >= 30 {
            milestones.append(Milestone(
                title: "30-Day Feeding Streak!",
                subtitle: "Sourdough master",
                icon: "flame.fill",
                color: Color.appAlert
            ))
        }

        // Age milestones
        if currentDay >= 7 {
            milestones.append(Milestone(
                title: "One Week Old",
                subtitle: "Day \(currentDay)",
                icon: "birthday.cake",
                color: Color.appSecondary
            ))
        }
        if currentDay >= 30 {
            milestones.append(Milestone(
                title: "One Month Old",
                subtitle: "Day \(currentDay)",
                icon: "birthday.cake",
                color: Color.appSecondary
            ))
        }

        return milestones
    }

    private func computeFeedingStreak(from logs: [FeedingLog]) -> Int {
        let calendar = Calendar.current
        let sortedDates = logs.map { calendar.startOfDay(for: $0.date) }
        let uniqueDates = Set(sortedDates).sorted(by: >)

        guard let first = uniqueDates.first else { return 0 }

        var streak = 0
        var expectedDate = calendar.startOfDay(for: .now)

        if first < expectedDate {
            expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
        }

        for date in uniqueDates {
            if date == expectedDate {
                streak += 1
                expectedDate = calendar.date(byAdding: .day, value: -1, to: expectedDate)!
            } else if date < expectedDate {
                break
            }
        }

        return streak
    }
}
