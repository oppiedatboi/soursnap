import SwiftUI
import SwiftData

struct ProfileView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [StarterProfile]
    @Query private var entries: [JournalEntry]
    @Query private var feedingLogs: [FeedingLog]

    @Query private var userProfiles: [UserProfile]

    @State private var showingCreateProfile = false
    @State private var showingFeedingSheet = false
    @State private var showingEditProfile = false
    @State private var showingRename = false
    @State private var showingArchiveConfirm = false
    @State private var showingJourney = false
    @State private var showingSignOutConfirm = false
    @State private var appeared = false
    @State private var showCelebration = false
    @State private var confettiPieces: [ConfettiPiece] = []

    private var profile: StarterProfile? { profiles.first(where: { $0.isActive }) }
    private var userProfile: UserProfile? { userProfiles.first }

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
            .sheet(isPresented: $showingEditProfile) {
                if let profile {
                    EditProfileSheet(profile: profile)
                }
            }
            .sheet(isPresented: $showingJourney) {
                if let profile {
                    ProgressView(profile: profile)
                }
            }
            .alert("Rename Starter", isPresented: $showingRename) {
                if let profile {
                    RenameAlert(profile: profile)
                }
            }
            .alert("Sign Out?", isPresented: $showingSignOutConfirm) {
                Button("Sign Out", role: .destructive) {
                    AuthManager.shared.signOut()
                    HapticManager.medium()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You'll need to sign in again to access your account.")
            }
            .alert("Archive Starter?", isPresented: $showingArchiveConfirm) {
                Button("Archive", role: .destructive) {
                    if let profile {
                        profile.isActive = false
                        HapticManager.medium()
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This will hide your starter from the profile. You can create a new one after archiving.")
            }
        }
    }

    private var createProfilePrompt: some View {
        VStack(spacing: 24) {
            KikoMascot(pose: .hero, size: 180)

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

                // Feeding history
                feedingHistorySection
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // Settings
                settingsSection
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 20)

                // Account section
                accountSection
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
            updateWidgetData(profile)
        }
    }

    private func mascotHeader(_ profile: StarterProfile) -> some View {
        VStack(spacing: 12) {
            if currentStreak > 7 {
                KikoMascot(pose: .celebrating, size: 120)
            } else if entries.count > 5 {
                KikoMascot(pose: .bubbly, size: 120)
            } else {
                KikoMascot(pose: .hero, size: 120)
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
            statCard(value: "\(feedingStreak)", label: "Feed Streak", icon: "flame.fill")
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

            Button {
                HapticManager.light()
                showingJourney = true
            } label: {
                Label("View Journey", systemImage: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.appSurface, in: Capsule())
                    .overlay(Capsule().stroke(Color.appPrimary, lineWidth: 1.5))
            }

            // Management row
            HStack(spacing: 12) {
                Button {
                    HapticManager.light()
                    showingRename = true
                } label: {
                    Label("Rename", systemImage: "pencil")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1))
                }

                Button {
                    HapticManager.light()
                    showingEditProfile = true
                } label: {
                    Label("Edit Details", systemImage: "slider.horizontal.3")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1))
                }

                Button {
                    HapticManager.light()
                    showingArchiveConfirm = true
                } label: {
                    Label("Archive", systemImage: "archivebox")
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appAlert)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.appBorder, lineWidth: 1))
                }
            }
        }
    }

    // MARK: - Feeding History

    private var recentFeedings: [FeedingLog] {
        feedingLogs
            .filter { $0.starterProfile?.id == profile?.id }
            .sorted { $0.date > $1.date }
            .prefix(7)
            .map { $0 }
    }

    private var feedingStreak: Int {
        let calendar = Calendar.current
        let profileLogs = feedingLogs.filter { $0.starterProfile?.id == profile?.id }
        let sortedDates = profileLogs.map { calendar.startOfDay(for: $0.date) }
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

    private var feedingHistorySection: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text("Recent Feedings")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()

                if feedingStreak > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: "flame.fill")
                            .font(.system(size: 12))
                            .foregroundStyle(Color.appAlert)
                        Text("\(feedingStreak) day streak")
                            .font(.system(size: 12, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appAlert)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.appAlert.opacity(0.12), in: Capsule())
                }
            }

            if recentFeedings.isEmpty {
                HStack {
                    Spacer()
                    VStack(spacing: 8) {
                        Image(systemName: "drop")
                            .font(.system(size: 24))
                            .foregroundStyle(Color.appTextSecondary)
                        Text("No feedings logged yet")
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                    .padding(.vertical, 16)
                    Spacer()
                }
            } else {
                ForEach(recentFeedings) { log in
                    feedingRow(log)
                }
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }

    private func feedingRow(_ log: FeedingLog) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(log.date.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()))
                    .font(.system(size: 13, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appTextPrimary)

                Spacer()

                Text(log.date.formatted(.dateTime.hour().minute()))
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }

            HStack(spacing: 16) {
                Label("\(Int(log.flourAmount))g flour", systemImage: "leaf")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)

                Label("\(Int(log.waterAmount))g water", systemImage: "drop")
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }

            if !log.notes.isEmpty {
                Text(log.notes)
                    .font(.system(size: 12, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
            }

            Divider()
        }
    }

    // MARK: - Widget Data

    private func updateWidgetData(_ profile: StarterProfile) {
        let lastEntry = entries
            .filter { $0.starterProfile?.id == profile.id }
            .sorted { $0.date > $1.date }
            .first

        WidgetDataManager.update(
            starterName: profile.name,
            daysOld: profile.daysSinceBorn,
            currentStreak: feedingStreak,
            lastHealthScore: lastEntry?.healthScore,
            lastSnapDate: lastEntry?.date
        )
    }

    // MARK: - Settings

    private var settingsSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Settings")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            if let userProfile {
                Toggle(isOn: Binding(
                    get: { userProfile.feedingReminderEnabled },
                    set: { newValue in
                        userProfile.feedingReminderEnabled = newValue
                        if newValue {
                            Task {
                                let granted = await NotificationManager.shared.requestPermission()
                                if granted, let starterName = profile?.name {
                                    NotificationManager.shared.scheduleFeedingReminder(
                                        at: userProfile.feedingReminderTime,
                                        starterName: starterName
                                    )
                                } else {
                                    userProfile.feedingReminderEnabled = false
                                }
                            }
                        } else {
                            NotificationManager.shared.cancelFeedingReminder()
                        }
                    }
                )) {
                    HStack(spacing: 10) {
                        Image(systemName: "bell.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appPrimary)
                        Text("Feeding Reminders")
                            .font(.system(size: 15, weight: .medium, design: .rounded))
                            .foregroundStyle(Color.appTextPrimary)
                    }
                }
                .tint(Color.appPrimary)

                if userProfile.feedingReminderEnabled {
                    DatePicker(
                        "Reminder Time",
                        selection: Binding(
                            get: { userProfile.feedingReminderTime },
                            set: { newTime in
                                userProfile.feedingReminderTime = newTime
                                if let starterName = profile?.name {
                                    NotificationManager.shared.scheduleFeedingReminder(
                                        at: newTime,
                                        starterName: starterName
                                    )
                                }
                            }
                        ),
                        displayedComponents: .hourAndMinute
                    )
                    .font(.system(size: 15, design: .rounded))
                    .tint(Color.appPrimary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }

    // MARK: - Account Section

    private var accountSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Account")
                .font(.system(size: 16, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            if AuthManager.shared.isSignedIn {
                if let email = AuthManager.shared.userEmail {
                    HStack(spacing: 10) {
                        Image(systemName: "envelope.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(Color.appPrimary)
                        Text(email)
                            .font(.system(size: 14, design: .rounded))
                            .foregroundStyle(Color.appTextSecondary)
                    }
                }

                Button {
                    HapticManager.light()
                    showingSignOutConfirm = true
                } label: {
                    HStack {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Sign Out")
                            .font(.system(size: 14, weight: .semibold, design: .rounded))
                    }
                    .foregroundStyle(Color.appAlert)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(Color.appAlert.opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
                }
            } else {
                HStack(spacing: 10) {
                    Image(systemName: "person.crop.circle.badge.questionmark")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.appTextSecondary)
                    Text("Free tier — Sign in for full access")
                        .font(.system(size: 14, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
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

            // Celebrating Kiko
            VStack(spacing: 16) {
                KikoMascot(pose: .celebrating, size: 200)
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
                        KikoMascot(pose: .hero, size: 100)

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
                        KikoMascot(pose: .jar, size: 100)

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
                            WidgetDataManager.update(
                                starterName: profile.name,
                                daysOld: profile.daysSinceBorn,
                                currentStreak: 0,
                                lastHealthScore: nil,
                                lastSnapDate: nil
                            )
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

// MARK: - Rename Alert Content

struct RenameAlert: View {
    let profile: StarterProfile
    @State private var newName = ""

    var body: some View {
        TextField("New name", text: $newName)
            .onAppear { newName = profile.name }
        Button("Save") {
            if !newName.trimmingCharacters(in: .whitespaces).isEmpty {
                profile.name = newName.trimmingCharacters(in: .whitespaces)
                HapticManager.success()
            }
        }
        Button("Cancel", role: .cancel) {}
    }
}

// MARK: - Edit Profile Sheet

struct EditProfileSheet: View {
    let profile: StarterProfile
    @Environment(\.dismiss) private var dismiss

    @State private var flourType: String = ""
    @State private var hydration: Double = 100
    @State private var notes: String = ""

    private let flourTypes = ["All-Purpose", "Bread Flour", "Whole Wheat", "Rye", "Spelt", "Einkorn", "Mix"]

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        KikoMascot(pose: .jar, size: 80)

                        Text("Edit \(profile.name)")
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Color.appTextPrimary)

                        VStack(spacing: 16) {
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

                            formField(title: "Notes") {
                                TextField("Any notes about your starter...", text: $notes, axis: .vertical)
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
                            profile.flourType = flourType
                            profile.hydrationRatio = hydration
                            profile.notes = notes
                            dismiss()
                        } label: {
                            Text("Save Changes")
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
            .navigationTitle("Edit Starter")
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
            .onAppear {
                flourType = profile.flourType
                hydration = profile.hydrationRatio
                notes = profile.notes
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
