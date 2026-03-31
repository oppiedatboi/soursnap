import SwiftUI
import SwiftData

struct SnapView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var profiles: [StarterProfile]

    @State private var capturedImage: UIImage?
    @State private var showCamera = false
    @State private var showPhotoPicker = false
    @State private var isAnalyzing = false
    @State private var analysisResult: OpenAIService.AnalysisResult?
    @State private var errorMessage: String?
    @State private var saved = false

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
                        } else if let result = analysisResult {
                            resultSection(result)
                        } else if let error = errorMessage {
                            errorSection(error)
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
                    .onChange(of: capturedImage) { _, newValue in
                        if newValue != nil { analyzePhoto() }
                    }
            }
            .sheet(isPresented: $showPhotoPicker) {
                PhotoPickerView(selectedImage: $capturedImage)
                    .onChange(of: capturedImage) { _, newValue in
                        if newValue != nil { analyzePhoto() }
                    }
            }
        }
    }

    // MARK: - Sections

    private var promptSection: some View {
        VStack(spacing: 24) {
            Spacer().frame(height: 40)

            BubMascot(pose: .snap, size: 180)

            Text("Time for a snap!")
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            Text("Take a photo of your starter and Bub will analyze it for you")
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

            BubMascot(pose: .thinking, size: 100)

            Text("Bub is analyzing...")
                .font(.system(size: 18, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            // Shimmer loading cards
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

    private func resultSection(_ result: OpenAIService.AnalysisResult) -> some View {
        VStack(spacing: 20) {
            if let image = capturedImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(maxHeight: 220)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .shadow(color: Color.appTextPrimary.opacity(0.1), radius: 12, y: 6)
            }

            AnalysisCardView(analysis: result)

            if !saved {
                Button {
                    HapticManager.success()
                    saveToJournal(result)
                } label: {
                    Label("Save to Journal", systemImage: "square.and.arrow.down.fill")
                        .font(.system(size: 17, weight: .bold, design: .rounded))
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 16)
                        .background(Color.appSuccess, in: Capsule())
                }
                .padding(.horizontal, 24)
            } else {
                HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                    Text("Saved to Journal!")
                }
                .font(.system(size: 17, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appSuccess)
            }

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

    private func errorSection(_ error: String) -> some View {
        VStack(spacing: 20) {
            BubMascot(pose: .sad, size: 140)

            Text("Oops!")
                .font(.system(size: 22, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            Text(error)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)

            Button {
                HapticManager.medium()
                analyzePhoto()
            } label: {
                Label("Try Again", systemImage: "arrow.clockwise")
                    .font(.system(size: 16, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .padding(.horizontal, 32)
                    .padding(.vertical, 14)
                    .background(Color.appPrimary, in: Capsule())
            }

            Button {
                HapticManager.light()
                resetSnap()
            } label: {
                Text("Take a New Photo")
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }
        }
    }

    // MARK: - Actions

    private func analyzePhoto() {
        guard let image = capturedImage else { return }
        isAnalyzing = true
        analysisResult = nil
        errorMessage = nil

        Task {
            do {
                let result = try await OpenAIService.shared.analyzeStarterPhoto(image)
                await MainActor.run {
                    analysisResult = result
                    isAnalyzing = false
                    HapticManager.success()
                }
            } catch {
                await MainActor.run {
                    errorMessage = error.localizedDescription
                    isAnalyzing = false
                    HapticManager.error()
                }
            }
        }
    }

    private func saveToJournal(_ result: OpenAIService.AnalysisResult) {
        let entry = JournalEntry(
            photo: capturedImage?.jpegData(compressionQuality: 0.8),
            bubbleActivity: result.bubbleActivity,
            riseLevel: result.riseLevel,
            colorAssessment: result.colorAssessment,
            overallHealth: result.overallHealth,
            guidance: result.guidance,
            encouragement: result.encouragement
        )
        entry.starterProfile = profiles.first
        modelContext.insert(entry)
        saved = true
    }

    private func resetSnap() {
        capturedImage = nil
        analysisResult = nil
        errorMessage = nil
        saved = false
        isAnalyzing = false
    }
}
