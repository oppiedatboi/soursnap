import SwiftUI

enum MascotPose: String, CaseIterable {
    case hero = "kiko-hero"
    case jar = "kiko-jar"
    case snap = "kiko-snap"
    case celebrating = "kiko-celebrating"
    case sleeping = "kiko-sleeping"
    case sad = "kiko-sad"
    case bubbly = "kiko-bubbly"
    case thinking = "kiko-thinking"
}

struct KikoMascot: View {
    let pose: MascotPose
    var size: CGFloat = 160

    @State private var isBreathing = false

    var body: some View {
        Image(pose.rawValue)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: size, height: size)
            .scaleEffect(isBreathing ? 1.02 : 1.0)
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
