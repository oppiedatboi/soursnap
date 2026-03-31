import SwiftUI

struct AnalysisCardView: View {
    let analysis: OpenAIService.AnalysisResult
    @State private var appeared = false

    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack {
                BubMascot(pose: .bubbly, size: 48)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Bub's Analysis")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(Color.appTextPrimary)
                    Text("Here's what I see!")
                        .font(.system(size: 13, design: .rounded))
                        .foregroundStyle(Color.appTextSecondary)
                }
                Spacer()
            }

            // Ratings row
            HStack(spacing: 12) {
                ratingPill(label: "Bubbles", value: analysis.bubbleActivity, icon: "circle.circle.fill")
                ratingPill(label: "Rise", value: analysis.riseLevel, icon: "arrow.up.circle.fill")
            }
            .opacity(appeared ? 1 : 0)
            .offset(y: appeared ? 0 : 15)

            // Color assessment
            if !analysis.colorAssessment.isEmpty {
                detailRow(icon: "paintpalette.fill", title: "Color", text: analysis.colorAssessment)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
            }

            // Overall health
            if !analysis.overallHealth.isEmpty {
                detailRow(icon: "heart.fill", title: "Health", text: analysis.overallHealth)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
            }

            // Guidance
            if !analysis.guidance.isEmpty {
                detailRow(icon: "lightbulb.fill", title: "Next Steps", text: analysis.guidance)
                    .opacity(appeared ? 1 : 0)
                    .offset(y: appeared ? 0 : 15)
            }

            // Encouragement
            if !analysis.encouragement.isEmpty {
                Text(analysis.encouragement)
                    .font(.system(size: 15, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appPrimary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 4)
                    .opacity(appeared ? 1 : 0)
            }
        }
        .padding(20)
        .background(Color.appSurface, in: RoundedRectangle(cornerRadius: 20))
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.appBorder, lineWidth: 1))
        .onAppear {
            withAnimation(.spring(response: 0.5, dampingFraction: 0.8)) {
                appeared = true
            }
        }
    }

    private func ratingPill(label: String, value: Int, icon: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
                Text("\(value)/5")
                    .font(.system(size: 20, weight: .bold, design: .rounded))
            }
        }
        .foregroundStyle(ratingColor(value))
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(ratingColor(value).opacity(0.1), in: RoundedRectangle(cornerRadius: 12))
    }

    private func detailRow(icon: String, title: String, text: String) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(Color.appPrimary)
                Text(title)
                    .font(.system(size: 13, weight: .bold, design: .rounded))
                    .foregroundStyle(Color.appTextSecondary)
            }
            Text(text)
                .font(.system(size: 14, design: .rounded))
                .foregroundStyle(Color.appTextPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func ratingColor(_ value: Int) -> Color {
        if value >= 4 { return .appSuccess }
        if value >= 2 { return .appWarning }
        return .appAlert
    }
}
