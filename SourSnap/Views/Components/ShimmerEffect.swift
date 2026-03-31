import SwiftUI

struct ShimmerEffect: ViewModifier {
    @State private var phase: CGFloat = 0

    func body(content: Content) -> some View {
        content
            .overlay(
                LinearGradient(
                    gradient: Gradient(colors: [
                        .clear,
                        Color.appPrimary.opacity(0.15),
                        .clear
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                )
                .offset(x: phase)
                .onAppear {
                    withAnimation(
                        .linear(duration: 1.5)
                        .repeatForever(autoreverses: false)
                    ) {
                        phase = 400
                    }
                }
            )
            .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

extension View {
    func shimmer() -> some View {
        modifier(ShimmerEffect())
    }
}
