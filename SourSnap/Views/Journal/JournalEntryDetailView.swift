import SwiftUI

struct JournalEntryDetailView: View {
    let entry: JournalEntry
    @Environment(\.dismiss) private var dismiss
    @State private var appeared = false
    @State private var fullImage: UIImage?
    @State private var showingShareSheet = false
    @State private var shareImage: UIImage?

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Photo — prefer photoPath, fall back to legacy Data
                    if let image = fullImage {
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(maxHeight: 300)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(color: Color.appTextPrimary.opacity(0.1), radius: 12, y: 6)
                            .scaleEffect(appeared ? 1 : 0.9)
                            .opacity(appeared ? 1 : 0)
                    }

                    // Date header
                    Text(entry.date.formatted(.dateTime.weekday(.wide).month(.wide).day().year()))
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)

                    // Health score
                    if let score = entry.healthScore {
                        HStack(spacing: 8) {
                            Image(systemName: "heart.fill")
                                .font(.system(size: 18))
                                .foregroundStyle(healthColor(score))
                            Text("Health: \(Int(score))%")
                                .font(.system(size: 22, weight: .bold, design: .rounded))
                                .foregroundStyle(Color.appTextPrimary)
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                    }

                    // Ratings (legacy)
                    if entry.bubbleActivity > 0 || entry.riseLevel > 0 {
                        HStack(spacing: 16) {
                            ratingCard(title: "Bubbles", value: entry.bubbleActivity, icon: "circle.circle.fill")
                            ratingCard(title: "Rise", value: entry.riseLevel, icon: "arrow.up.circle.fill")
                        }
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                    }

                    // AI Analysis
                    if let analysis = entry.aiAnalysis, !analysis.isEmpty {
                        infoCard(title: "AI Analysis", content: analysis, icon: "sparkles")
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                    }

                    // Color Assessment
                    if !entry.colorAssessment.isEmpty {
                        infoCard(title: "Color", content: entry.colorAssessment, icon: "paintpalette.fill")
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                    }

                    // Overall Health
                    if !entry.overallHealth.isEmpty {
                        infoCard(title: "Health", content: entry.overallHealth, icon: "heart.fill")
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                    }

                    // Guidance
                    if !entry.guidance.isEmpty {
                        infoCard(title: "Guidance", content: entry.guidance, icon: "lightbulb.fill")
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                    }

                    // Encouragement
                    if !entry.encouragement.isEmpty {
                        HStack(spacing: 12) {
                            KikoMascot(pose: .celebrating, size: 48)
                            Text(entry.encouragement)
                                .font(.system(size: 15, weight: .medium, design: .rounded))
                                .foregroundStyle(Color.appPrimary)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color.appPrimary.opacity(0.1), in: RoundedRectangle(cornerRadius: 16))
                        .opacity(appeared ? 1 : 0)
                        .offset(y: appeared ? 0 : 20)
                    }

                    // User Notes
                    if !entry.userNotes.isEmpty {
                        infoCard(title: "Notes", content: entry.userNotes, icon: "note.text")
                            .opacity(appeared ? 1 : 0)
                            .offset(y: appeared ? 0 : 20)
                    }
                }
                .padding(16)
                .padding(.bottom, 40)
            }
            .background(Color.appBackground)
            .navigationTitle("Entry Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        HapticManager.medium()
                        generateAndShare()
                    } label: {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundStyle(Color.appPrimary)
                    }
                }
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
            .sheet(isPresented: $showingShareSheet) {
                if let shareImage {
                    let deepLink = "Check out my starter on Kiko Dough! https://kiboapp.com/s/\(entry.id.uuidString)"
                    ShareSheet(items: [shareImage, deepLink])
                }
            }
            .onAppear {
                withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                    appeared = true
                }
            }
            .task {
                loadFullImage()
            }
        }
    }

    private func generateAndShare() {
        let starterName = entry.starterProfile?.name ?? "My Starter"
        let daysOld = entry.starterProfile?.daysSinceBorn ?? 0
        let kikoImage = UIImage(named: MascotPose.celebrating.rawValue)

        shareImage = ShareCardRenderer.render(
            starterPhoto: fullImage,
            starterName: starterName,
            daysOld: daysOld,
            healthScore: entry.healthScore,
            kikoMascotImage: kikoImage
        )
        showingShareSheet = true
    }

    private func loadFullImage() {
        // Prefer photoPath from PhotoStorageManager
        if let photoPath = entry.photoPath,
           let img = PhotoStorageManager.shared.loadImage(path: photoPath) {
            fullImage = img
            return
        }
        // Fall back to legacy photo Data blob
        if let photoData = entry.photo, let img = UIImage(data: photoData) {
            fullImage = img
        }
    }

    private func healthColor(_ score: Double) -> Color {
        if score >= 70 { return .appSuccess }
        if score >= 40 { return .appWarning }
        return .appAlert
    }

    private func ratingCard(title: String, value: Int, icon: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 24))
                .foregroundStyle(Color.appPrimary)

            Text("\(value)/5")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            Text(title)
                .font(.system(size: 13, weight: .medium, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }

    private func infoCard(title: String, content: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)
                Text(title)
                    .font(.system(size: 14, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }

            Text(content)
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.appBorder, lineWidth: 1))
    }
}
