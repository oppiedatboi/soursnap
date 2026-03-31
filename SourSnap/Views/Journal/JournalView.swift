import SwiftUI
import SwiftData

struct JournalView: View {
    @Query(sort: \JournalEntry.date, order: .reverse) private var entries: [JournalEntry]
    @State private var selectedEntry: JournalEntry?
    @State private var appearedCards: Set<Int> = []

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    emptyState
                } else {
                    journalList
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(Color.appBackground.ignoresSafeArea())
            .navigationTitle("Journal")
            .navigationBarTitleDisplayMode(.large)
            .toolbarColorScheme(.light, for: .navigationBar)
        }
        .sheet(item: $selectedEntry) { entry in
            JournalEntryDetailView(entry: entry)
        }
    }

    private var emptyState: some View {
        VStack(spacing: 20) {
            BubMascot(pose: .sleeping, size: 180)

            Text("Your journey starts with a snap!")
                .font(.system(size: 20, weight: .semibold, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)

            Text("Take your first photo in the Snap tab")
                .font(.system(size: 15, design: .rounded))
                .foregroundStyle(Color.appTextSecondary)
        }
    }

    private var journalList: some View {
        ScrollView {
            LazyVStack(spacing: 16) {
                ForEach(Array(entries.enumerated()), id: \.element.persistentModelID) { index, entry in
                    JournalCardView(entry: entry)
                        .opacity(appearedCards.contains(index) ? 1 : 0)
                        .offset(y: appearedCards.contains(index) ? 0 : 20)
                        .animation(
                            .spring(response: 0.4, dampingFraction: 0.8)
                            .delay(Double(index) * 0.05),
                            value: appearedCards.contains(index)
                        )
                        .onAppear {
                            appearedCards.insert(index)
                        }
                        .onTapGesture {
                            HapticManager.light()
                            selectedEntry = entry
                        }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .padding(.bottom, 100)
        }
    }
}

struct JournalCardView: View {
    let entry: JournalEntry
    @State private var thumbnail: UIImage?
    @State private var dragOffset: CGSize = .zero

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                // Photo thumbnail — prefer photoPath, fall back to legacy photo Data
                if let thumb = thumbnail {
                    Image(uiImage: thumb)
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(width: 72, height: 72)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.appSurface)
                        .frame(width: 72, height: 72)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.system(size: 24))
                                .foregroundStyle(Color.appBorder)
                        )
                }

                VStack(alignment: .leading, spacing: 6) {
                    Text(entry.date.formatted(.dateTime.month(.wide).day().year()))
                        .font(.system(size: 14, weight: .semibold, design: .rounded))
                        .foregroundStyle(Color.appTextPrimary)

                    // Health score badge
                    if let score = entry.healthScore {
                        healthScoreBadge(score)
                    } else if entry.bubbleActivity > 0 || entry.riseLevel > 0 {
                        HStack(spacing: 12) {
                            ratingBadge(label: "Bubbles", value: entry.bubbleActivity, icon: "circle.circle")
                            ratingBadge(label: "Rise", value: entry.riseLevel, icon: "arrow.up.circle")
                        }
                    }
                }

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.appBorder)
            }

            // Snippet: prefer aiAnalysis, then overallHealth, then userNotes
            if let snippet = entrySnippet {
                Text(snippet)
                    .font(.system(size: 14, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
                    .lineLimit(2)
            }
        }
        .padding(16)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.appBorder, lineWidth: 1)
        )
        .rotation3DEffect(
            .degrees(Double(dragOffset.width) / 20),
            axis: (x: 0, y: 1, z: 0)
        )
        .rotation3DEffect(
            .degrees(Double(dragOffset.height) / 20),
            axis: (x: -1, y: 0, z: 0)
        )
        .gesture(
            DragGesture()
                .onChanged { value in
                    dragOffset = value.translation
                }
                .onEnded { _ in
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                        dragOffset = .zero
                    }
                }
        )
        .task {
            loadThumbnail()
        }
    }

    private var entrySnippet: String? {
        if let analysis = entry.aiAnalysis, !analysis.isEmpty { return analysis }
        if !entry.overallHealth.isEmpty { return entry.overallHealth }
        if !entry.userNotes.isEmpty { return entry.userNotes }
        return nil
    }

    private func loadThumbnail() {
        // Prefer thumbnailPath from PhotoStorageManager
        if let thumbPath = entry.thumbnailPath,
           let img = PhotoStorageManager.shared.loadImage(path: thumbPath) {
            thumbnail = img
            return
        }
        // Fall back to photoPath
        if let photoPath = entry.photoPath,
           let img = PhotoStorageManager.shared.loadImage(path: photoPath) {
            thumbnail = img
            return
        }
        // Fall back to legacy photo Data blob
        if let photoData = entry.photo, let img = UIImage(data: photoData) {
            thumbnail = img
        }
    }

    private func healthScoreBadge(_ score: Double) -> some View {
        HStack(spacing: 6) {
            Image(systemName: "heart.fill")
                .font(.system(size: 12, weight: .semibold))
            Text("\(Int(score))%")
                .font(.system(size: 14, weight: .bold, design: .rounded))
        }
        .foregroundStyle(healthColor(score))
        .padding(.horizontal, 10)
        .padding(.vertical, 4)
        .background(healthColor(score).opacity(0.12), in: Capsule())
    }

    private func ratingBadge(label: String, value: Int, icon: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 12, weight: .semibold))
            Text("\(value)/5")
                .font(.system(size: 13, weight: .bold, design: .rounded))
        }
        .foregroundStyle(value >= 4 ? Color.appSuccess : value >= 2 ? Color.appWarning : Color.appAlert)
    }

    private func healthColor(_ score: Double) -> Color {
        if score >= 70 { return .appSuccess }
        if score >= 40 { return .appWarning }
        return .appAlert
    }
}
