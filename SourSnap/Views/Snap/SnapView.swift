import SwiftUI
import SwiftData

struct SnapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [StarterProfile]
    @Query private var allEntries: [JournalEntry]
    @Query private var userProfiles: [UserProfile]
    @Binding var selectedTab: AppTab

    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var showPaywall = false
    @State private var isAnalyzing = false
    @State private var didSave = false

    private var isProUser: Bool {
        userProfiles.first?.isPro ?? false
    }

    private var hasReachedFreeLimit: Bool {
        !isProUser && allEntries.count >= 3
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color.appBackground.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 24) {
                        if capturedImage == nil {
                            promptSection
                        } else if isAnalyzing {
                            analyzingSection
                        } else if didSave {
                            savedSection
                        } else {
                            previewSection
                        }
                    }
                    .padding(16)
                    .padding(.bottom, 100)
                }
            }
            .navigationTitle("Snap")
            .navigationBarTitleDisplayMode(.large)
            .sheet(isPresented: $showCamera) {
                CameraView(capturedImage: $capturedImage)
                    .ignoresSafeArea()
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerView(selectedImage: $capturedImage)
            }
            .sheet(isPresented: $showPaywall) {
                PaywallView()
            }
        }
    }

    // MARK: - Sections

    private var promptSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            KikoMascot(pose: .snap, size: 180)

            Text("Time for a snap!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            Text("Take a photo of your starter and Kiko will analyze it for you")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            VStack(spacing: 12) {
                Button {
                    HapticManager.medium()
                    showCamera = true
                } label: {
                    Label("Take Photo", systemImage: "camera.fill")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appPrimary, in: Capsule())
                }

                Button {
                    HapticManager.light()
                    showPhotoPicker = true
                } label: {
                    Label("Choose from Library", systemImage: "photo.fill")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(Color.appPrimary.opacity(0.12), in: Capsule())
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var previewSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)

            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 300)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.appTextPrimary.opacity(0.1), radius: 12, y: 6)
            }

            Text("Looking good!")
                .font(.system(size: 20, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            Text("Ready to save this snap to your journal?")
                .font(.system(size: 16, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)

            VStack(spacing: 12) {
                Button {
                    HapticManager.medium()
                    if hasReachedFreeLimit {
                        showPaywall = true
                    } else {
                        analyzeAndSave()
                    }
                } label: {
                    Label("Analyze", systemImage: "sparkles")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appPrimary, in: Capsule())
                }

                Button {
                    HapticManager.light()
                    resetSnap()
                } label: {
                    Text("Retake")
                        .font(.system(size: 16, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }
            }
            .padding(.horizontal, 24)
        }
    }

    private var analyzingSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 20)

            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 250)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.appTextPrimary.opacity(0.1), radius: 12, y: 6)
            }

            KikoMascot(pose: .thinking, size: 100)

            Text("Kiko is analyzing...")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            VStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appSurface)
                        .frame(height: 44)
                        .shimmer()
                }
            }
            .padding(.horizontal, 20)
        }
    }

    private var savedSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            KikoMascot(pose: .celebrating, size: 160)

            HStack(spacing: 8) {
                Image(systemName: "checkmark.circle.fill")
                Text("Saved to Journal!")
            }
            .font(.system(size: 20, weight: .bold, design: .rounded))
            .foregroundStyle(Color.appSuccess)

            Button {
                HapticManager.light()
                resetSnap()
            } label: {
                Text("Take Another")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
            }
        }
    }

    // MARK: - Actions

    private func analyzeAndSave() {
        guard let image = capturedImage else { return }
        isAnalyzing = true

        Task {
            // Save photo to disk via PhotoStorageManager
            let starterID = profiles.first?.id ?? UUID()
            let paths = PhotoStorageManager.shared.savePhoto(image: image, starterID: starterID)

            // Call OpenAI Vision API for starter analysis
            var analysis: OpenAIService.AnalysisResult?
            do {
                analysis = try await OpenAIService.shared.analyzeStarterPhoto(image)
            } catch {
                // If analysis fails, we still save the entry without AI data
                print("Vision analysis failed: \(error.localizedDescription)")
            }

            await MainActor.run {
                let entry = JournalEntry(
                    photoPath: paths?.photoPath,
                    thumbnailPath: paths?.thumbPath,
                    healthScore: analysis.map { Double($0.healthScore) * 10 },
                    aiAnalysis: analysis?.aiAnalysis,
                    colorAssessment: analysis?.colorAssessment ?? "",
                    activityLevel: analysis?.activityLevel ?? "",
                    textureAssessment: analysis?.textureAssessment ?? "",
                    recommendations: analysis?.recommendations,
                    bubbleActivity: analysis?.bubbleActivity ?? 0,
                    riseLevel: analysis?.riseLevel ?? 0,
                    overallHealth: analysis?.overallHealth ?? "",
                    guidance: analysis?.guidance ?? "",
                    encouragement: analysis?.encouragement ?? ""
                )
                entry.starterProfile = profiles.first
                modelContext.insert(entry)

                isAnalyzing = false
                didSave = true
                HapticManager.success()

                if let profile = profiles.first {
                    WidgetDataManager.update(
                        starterName: profile.name,
                        daysOld: profile.daysSinceBorn,
                        currentStreak: 0,
                        lastHealthScore: entry.healthScore,
                        lastSnapDate: entry.date
                    )
                }

                // Navigate back to Journal tab after a brief moment
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selectedTab = .journal
                    }
                    // Reset for next use
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        resetSnap()
                    }
                }
            }
        }
    }

    private func resetSnap() {
        capturedImage = nil
        isAnalyzing = false
        didSave = false
    }
}
