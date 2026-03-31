import SwiftUI

extension Color {
    static let appBackground = Color(hex: "FFF8F0")
    static let appSurface = Color(hex: "FFF1E6")
    static let appPrimary = Color(hex: "D4813B")
    static let appSecondary = Color(hex: "8B6914")
    static let appSuccess = Color(hex: "6B8E4E")
    static let appWarning = Color(hex: "E8A838")
    static let appAlert = Color(hex: "C75B3A")
    static let appTextPrimary = Color(hex: "3D2B1F")
    static let appTextSecondary = Color(hex: "7A6555")
    static let appBorder = Color(hex: "E8DDD0")

    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6:
            (a, r, g, b) = (255, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        case 8:
            (a, r, g, b) = ((int >> 24) & 0xFF, (int >> 16) & 0xFF, (int >> 8) & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
