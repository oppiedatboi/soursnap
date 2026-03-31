import SwiftUI
import UIKit

/// Renders a shareable card image for a journal entry.
/// Uses UIGraphicsImageRenderer to produce a single UIImage
/// suitable for UIActivityViewController.
struct ShareCardRenderer {
    // MARK: - Theme colours (matching AppColors hex values)
    private static let background  = UIColor(red: 1.0, green: 0.973, blue: 0.941, alpha: 1)   // FFF8F0
    private static let surface     = UIColor(red: 1.0, green: 0.945, blue: 0.902, alpha: 1)   // FFF1E6
    private static let primary     = UIColor(red: 0.831, green: 0.506, blue: 0.231, alpha: 1) // D4813B
    private static let textPrimary = UIColor(red: 0.239, green: 0.169, blue: 0.122, alpha: 1) // 3D2B1F
    private static let textSecondary = UIColor(red: 0.478, green: 0.396, blue: 0.333, alpha: 1) // 7A6555
    private static let success     = UIColor(red: 0.420, green: 0.557, blue: 0.306, alpha: 1) // 6B8E4E
    private static let warning     = UIColor(red: 0.910, green: 0.659, blue: 0.220, alpha: 1) // E8A838
    private static let alert       = UIColor(red: 0.780, green: 0.357, blue: 0.227, alpha: 1) // C75B3A

    // MARK: - Card Dimensions
    private static let cardWidth: CGFloat = 390
    private static let photoHeight: CGFloat = 340
    private static let padding: CGFloat = 24
    private static let cornerRadius: CGFloat = 24

    /// Generates the share card image.
    static func render(
        starterPhoto: UIImage?,
        starterName: String,
        daysOld: Int,
        healthScore: Double?,
        bubMascotImage: UIImage?
    ) -> UIImage {
        // Calculate total card height based on content
        let headerHeight: CGFloat = starterPhoto != nil ? photoHeight : 80
        let infoHeight: CGFloat = 120
        let brandingHeight: CGFloat = 56
        let totalHeight = padding + headerHeight + 16 + infoHeight + 16 + brandingHeight + padding

        let renderer = UIGraphicsImageRenderer(size: CGSize(width: cardWidth, height: totalHeight))

        return renderer.image { ctx in
            let rect = CGRect(x: 0, y: 0, width: cardWidth, height: totalHeight)
            let gc = ctx.cgContext

            // ── Card background with rounded corners ──
            let cardPath = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)
            background.setFill()
            cardPath.fill()

            // ── Starter photo ──
            var yOffset = padding

            if let photo = starterPhoto {
                let photoRect = CGRect(
                    x: padding,
                    y: yOffset,
                    width: cardWidth - padding * 2,
                    height: photoHeight
                )
                let photoPath = UIBezierPath(
                    roundedRect: photoRect,
                    cornerRadius: 16
                )
                gc.saveGState()
                photoPath.addClip()
                // Aspect-fill the photo into the rect
                let photoSize = photo.size
                let scale = max(photoRect.width / photoSize.width, photoRect.height / photoSize.height)
                let drawWidth = photoSize.width * scale
                let drawHeight = photoSize.height * scale
                let drawX = photoRect.midX - drawWidth / 2
                let drawY = photoRect.midY - drawHeight / 2
                photo.draw(in: CGRect(x: drawX, y: drawY, width: drawWidth, height: drawHeight))
                gc.restoreGState()

                yOffset += photoHeight + 16
            } else {
                yOffset += 80 + 16
            }

            // ── Info section background ──
            let infoRect = CGRect(
                x: padding,
                y: yOffset,
                width: cardWidth - padding * 2,
                height: infoHeight
            )
            let infoPath = UIBezierPath(roundedRect: infoRect, cornerRadius: 16)
            surface.setFill()
            infoPath.fill()

            // ── Starter name ──
            let nameFont = UIFont.systemFont(ofSize: 24, weight: .bold).rounded()
            let nameAttrs: [NSAttributedString.Key: Any] = [
                .font: nameFont,
                .foregroundColor: textPrimary
            ]
            let nameStr = starterName as NSString
            let nameSize = nameStr.size(withAttributes: nameAttrs)
            nameStr.draw(
                at: CGPoint(x: infoRect.minX + 16, y: infoRect.minY + 14),
                withAttributes: nameAttrs
            )

            // ── Days old ──
            let daysFont = UIFont.systemFont(ofSize: 15, weight: .medium).rounded()
            let daysAttrs: [NSAttributedString.Key: Any] = [
                .font: daysFont,
                .foregroundColor: textSecondary
            ]
            let daysStr = "\(daysOld) days old" as NSString
            daysStr.draw(
                at: CGPoint(x: infoRect.minX + 16, y: infoRect.minY + 14 + nameSize.height + 4),
                withAttributes: daysAttrs
            )

            // ── Health score badge ──
            if let score = healthScore {
                let badgeWidth: CGFloat = 80
                let badgeHeight: CGFloat = 32
                let badgeX = infoRect.maxX - 16 - badgeWidth
                let badgeY = infoRect.minY + 16
                let badgeRect = CGRect(x: badgeX, y: badgeY, width: badgeWidth, height: badgeHeight)
                let badgePath = UIBezierPath(roundedRect: badgeRect, cornerRadius: badgeHeight / 2)
                healthColor(score).setFill()
                badgePath.fill()

                let scoreFont = UIFont.systemFont(ofSize: 14, weight: .bold).rounded()
                let scoreAttrs: [NSAttributedString.Key: Any] = [
                    .font: scoreFont,
                    .foregroundColor: UIColor.white
                ]
                let scoreStr = "\(Int(score))% " as NSString
                let scoreSize = scoreStr.size(withAttributes: scoreAttrs)
                scoreStr.draw(
                    at: CGPoint(
                        x: badgeRect.midX - scoreSize.width / 2,
                        y: badgeRect.midY - scoreSize.height / 2
                    ),
                    withAttributes: scoreAttrs
                )
            }

            // ── Bub mascot in corner ──
            if let bub = bubMascotImage {
                let bubSize: CGFloat = 56
                let bubRect = CGRect(
                    x: infoRect.maxX - 16 - bubSize,
                    y: infoRect.maxY - 12 - bubSize,
                    width: bubSize,
                    height: bubSize
                )
                bub.draw(in: bubRect)
            }

            yOffset += infoHeight + 16

            // ── Branding footer ──
            let brandFont = UIFont.systemFont(ofSize: 13, weight: .semibold).rounded()
            let brandAttrs: [NSAttributedString.Key: Any] = [
                .font: brandFont,
                .foregroundColor: textSecondary
            ]
            let brandStr = "Tracked with Kibo" as NSString
            let brandSize = brandStr.size(withAttributes: brandAttrs)
            brandStr.draw(
                at: CGPoint(
                    x: rect.midX - brandSize.width / 2,
                    y: yOffset + (brandingHeight - brandSize.height) / 2
                ),
                withAttributes: brandAttrs
            )

            // ── Primary accent line at bottom ──
            let lineRect = CGRect(
                x: rect.midX - 40,
                y: totalHeight - 6,
                width: 80,
                height: 3
            )
            let linePath = UIBezierPath(roundedRect: lineRect, cornerRadius: 1.5)
            primary.setFill()
            linePath.fill()
        }
    }

    private static func healthColor(_ score: Double) -> UIColor {
        if score >= 70 { return success }
        if score >= 40 { return warning }
        return alert
    }
}

// MARK: - UIFont rounded helper

private extension UIFont {
    func rounded() -> UIFont {
        guard let descriptor = fontDescriptor.withDesign(.rounded) else { return self }
        return UIFont(descriptor: descriptor, size: pointSize)
    }
}

// MARK: - Share helper

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}
