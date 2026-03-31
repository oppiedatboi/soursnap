import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [StarterProfile]
    @Query private var entries: [JournalEntry]
    @Query private var feedingLogs: [FeedingLog]

    @State private var showingCreateProfile = false
    @State private var showingFeedingSheet = false
    @State private var appeared = false
    @State private var showCelebration = false
    @State private var confettiPieces: [ConfettiPiece] = []

    private var profile: StarterProfile? { profiles.first }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                if let profile {
                    profileContent(profile)
                } else {
                    createProfilePrompt
                }

                // Celebration overlay
                if showCelebration {
                    celebrationOverlay
                }
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showingCreateProfile, onDismiss: {
                if profile != nil {
                    triggerCelebration()
                }
            }) {
                CreateProfileSheet()
            }
            .sheet(isPresented: $showingFeedingSheet) {
                if let profile {
                    FeedingSheet(profile: profile)
                }
            }
        }
    }

    private var createProfilePrompt: some View {
        VStack(spacing: 24) {
            BubMascot(pose: .hero, size: 180)

            Text("Let's name your starter!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            Text("Every great starter deserves a great name")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)

            Button {
                HapticManager.medium()
                showingCreateProfile = true
            } label: {
                Label("Create Profile", systemImage: "plus.circle.fill")
                    .font(.system(size: 17, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color.appPrimary, in: Capsule())
            }
        }
    }

    private func profileContent(_ profile: StarterProfile) -> some View {
        ScrollView {
            VStack(spacing: 20) {
                // Mascot header
                mascotHeader(profile)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // Stats grid
                statsGrid(profile)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // Profile details card
                profileCard(profile)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // Actions
                actionsSection
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)
            }
            .padding(16)
            .padding(.bottom, 100)
        }
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func mascotHeader(_ profile: StarterProfile) -> some View {
        VStack(spacing: 12) {
            if currentStreak > 7 {
                BubMascot(pose: .celebrating, size: 120)
            } else if entries.count > 5 {
                BubMascot(pose: .bubbly, size: 120)
            } else {
                BubMascot(pose: .hero, size: 120)
            }

            Text(profile.name)
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            Text("Born \(profile.birthday.formatted(.dateTime.month(.wide).day().year()))")
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    private func statsGrid(_ profile: StarterProfile) -> some View {
        HStack(spacing: 12) {
            statCard(value: "\(profile.daysSinceBorn)", label: "Days Old", icon: "calendar")
            statCard(value: "\(entries.count)", label: "Total Snaps", icon: "camera.fill")
            statCard(value: "\(currentStreak)", label: "Day Streak", icon: "flame.fill")
        }
    }

    private func statCard(value: String, label: String, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Color.appPrimary)

            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            Text(label)
                .font(.system(size: 11, weight: .medium, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }

    private func profileCard(_ profile: StarterProfile) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Starter Details")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            detailRow(label: "Flour Type", value: profile.flourType)
            detailRow(label: "Hydration", value: "\(Int(profile.hydrationRatio))%")

            if !profile.notes.isEmpty {
                detailRow(label: "Notes", value: profile.notes)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }

    private func detailRow(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
            Text(value)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
        }
    }

    private var actionsSection: some View {
        VStack(spacing: 12) {
            Button {
                HapticManager.medium()
                showingFeedingSheet = true
            } label: {
                Label("Log Feeding", systemImage: "drop.fill")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appPrimary, in: Capsule())
            }
        }
    }

    // MARK: - Celebration

    private var celebrationOverlay: some View {
        ZStack {
            // Confetti particles
            ForEach(confettiPieces) { piece in
                Circle()
                    .fill(piece.color)
                    .frame(width: piece.size, height: piece.size)
                    .offset(x: piece.x, y: piece.y)
                    .opacity(piece.opacity)
                    .rotationEffect(.degrees(piece.rotation))
            }

            // Celebrating Bub
            VStack(spacing: 16) {
                BubMascot(pose: .celebrating, size: 200)
                    .scaleEffect(showCelebration ? 1.0 : 0.5)

                Text("Welcome to the family! 🎉")
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)
                    .opacity(showCelebration ? 1 : 0)
            }
        }
        .allowsHitTesting(false)
    }

    private func triggerCelebration() {
        HapticManager.success()
        confettiPieces = (0..<40).map { _ in
            ConfettiPiece(
                x: CGFloat.random(in: -180...180),
                y: CGFloat.random(in: -400...(-50)),
                size: CGFloat.random(in: 6...12),
                color: [Color.appPrimary, Color.appSuccess, Color.appWarning, Color.appSecondary, Color.appAlert].randomElement()!,
                rotation: Double.random(in: 0...360),
                opacity: 1.0
            )
        }

        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) {
            showCelebration = true
        }

        // Animate confetti falling
        withAnimation(.easeIn(duration: 2.0)) {
            confettiPieces = confettiPieces.map { piece in
                var p = piece
                p.y = CGFloat.random(in: 200...500)
                p.rotation += Double.random(in: 180...720)
                p.opacity = 0
                return p
            }
        }

        // Dismiss celebration
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
            withAnimation(.easeOut(duration: 0.5)) {
                showCelebration = false
            }
        }
    }

    private var currentStreak: Int {
        let calendar = Calendar.current
        let sortedDates = entries.map { calendar.startOfDay(for: $0.date) }
        let uniqueDates = Set(sortedDates).sorted(by: >)

        guard let first = uniqueDates.first else { return 0 }

        var streak = 0
        var expectedDate = calendar.startOfDay(for: .now)

        // Allow today or yesterday as start
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

// MARK: - Create Profile Sheet

struct CreateProfileSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var name = ""
    @State private var flourType = "All-Purpose"
    @State private var hydration = 100.0
    @State private var birthday = Date.now

    private let flourTypes = ["All-Purpose", "Bread Flour", "Whole Wheat", "Rye", "Spelt", "Einkorn", "Mix"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        BubMascot(pose: .hero, size: 100)

                        VStack(spacing: 16) {
                            formField(title: "Starter Name") {
                                TextField("e.g., Bubbles, Clint Yeastwood...", text: $name)
                                    .font(.system(size: 16, design: .rounded))
                                    .padding(14)
                                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1))
                            }

                            formField(title: "Birthday") {
                                DatePicker("", selection: $birthday, displayedComponents: .date)
                                    .datePickerStyle(.compact)
                                    .labelsHidden()
                                    .tint(Color.appPrimary)
                            }

                            formField(title: "Flour Type") {
                                Picker("Flour", selection: $flourType) {
                                    ForEach(flourTypes, id: \.self) { Text($0) }
                                }
                                .pickerStyle(.segmented)
                            }

                            formField(title: "Hydration: \(Int(hydration))%") {
                                Slider(value: $hydration, in: 50...200, step: 5)
                                    .tint(Color.appPrimary)
                            }
                        }
                        .padding(.horizontal, 16)

                        Button {
                            HapticManager.success()
                            let profile = StarterProfile(
                                name: name.isEmpty ? "My Starter" : name,
                                birthday: birthday,
                                flourType: flourType,
                                hydrationRatio: hydration
                            )
                            modelContext.insert(profile)
                            dismiss()
                        } label: {
                            Text("Create Starter")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appPrimary, in: Capsule())
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("New Starter")
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

    private func formField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
            content()
        }
    }
}

// MARK: - Feeding Sheet

struct FeedingSheet: View {
    let profile: StarterProfile
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var flourAmount = ""
    @State private var waterAmount = ""
    @State private var notes = ""

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        BubMascot(pose: .jar, size: 100)

                        Text("Log a feeding for \(profile.name)")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appTextPrimary)

                        VStack(spacing: 16) {
                            formField(title: "Flour (grams)") {
                                TextField("e.g., 50", text: $flourAmount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 16, design: .rounded))
                                    .padding(14)
                                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1))
                            }

                            formField(title: "Water (grams)") {
                                TextField("e.g., 50", text: $waterAmount)
                                    .keyboardType(.decimalPad)
                                    .font(.system(size: 16, design: .rounded))
                                    .padding(14)
                                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1))
                            }

                            formField(title: "Notes (optional)") {
                                TextField("Any observations...", text: $notes, axis: .vertical)
                                    .lineLimit(3...6)
                                    .font(.system(size: 16, design: .rounded))
                                    .padding(14)
                                    .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
                                    .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1))
                            }
                        }
                        .padding(.horizontal, 16)

                        Button {
                            HapticManager.success()
                            let log = FeedingLog(
                                flourAmount: Double(flourAmount) ?? 0,
                                waterAmount: Double(waterAmount) ?? 0,
                                notes: notes
                            )
                            log.starterProfile = profile
                            modelContext.insert(log)
                            dismiss()
                        } label: {
                            Label("Log Feeding", systemImage: "checkmark.circle.fill")
                                .font(.system(size: 17, weight: .bold, design: .rounded))
                                .foregroundStyle(.white)
                                .frame(maxWidth: .infinity)
                                .padding(.vertical, 16)
                                .background(Color.appPrimary, in: Capsule())
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.top, 20)
                    .padding(.bottom, 40)
                }
            }
            .navigationTitle("Log Feeding")
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

    private func formField<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
            content()
        }
    }
}

// MARK: - Confetti Model

struct ConfettiPiece: Identifiable {
    let id = UUID()
    var x: CGFloat
    var y: CGFloat
    var size: CGFloat
    var color: Color
    var rotation: Double
    var opacity: Double
}
