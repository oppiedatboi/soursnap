import SwiftUI

enum MascotPose: String, CaseIterable {
    case hero = "bub-hero"
    case jar = "bub-jar"
    case snap = "bub-snap"
    case celebrating = "bub-celebrating"
    case sleeping = "bub-sleeping"
    case sad = "bub-sad"
    case bubbly = "bub-bubbly"
    case thinking = "bub-thinking"
}

struct BubMascot: View {
    let pose: MascotPose
    var size: CGFloat = 160

    @State private var isBreathing = false

    var body: some View {
        Image(pose.rawValue)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .offset(y: isBreathing ? -2 : 2)
            .animation(
                .easeInOut(duration: 2)
                .repeatForever(autoreverses: true),
                value: isBreathing
            )
            .onAppear {
                isBreathing = true
            }
    }
}
