import UIKit

final class PhotoStorageManager: @unchecked Sendable {
    static let shared = PhotoStorageManager()

    private let fileManager = FileManager.default
    private let jpegQuality: CGFloat = 0.8
    private let thumbnailSize: CGFloat = 200

    private var documentsDirectory: URL {
        fileManager.urls(for: .documentDirectory, in: .userDomainMask).first!
    }

    private init() {}

    // MARK: - Save

    /// Saves a photo and its thumbnail to Documents/{starterID}/{YYYY-MM}/{uuid}.jpg
    /// Returns relative paths from Documents directory for both full and thumbnail images.
    func savePhoto(image: UIImage, starterID: UUID) -> (photoPath: String, thumbPath: String)? {
        let photoID = UUID()
        let dateFolder = Self.dateFolder()

        let relativeDir = "\(starterID.uuidString)/\(dateFolder)"
        let thumbRelativeDir = "\(starterID.uuidString)/thumbs"

        let fullDir = documentsDirectory.appendingPathComponent(relativeDir)
        let thumbDir = documentsDirectory.appendingPathComponent(thumbRelativeDir)

        do {
            try fileManager.createDirectory(at: fullDir, withIntermediateDirectories: true)
            try fileManager.createDirectory(at: thumbDir, withIntermediateDirectories: true)
        } catch {
            return nil
        }

        let photoRelativePath = "\(relativeDir)/\(photoID.uuidString).jpg"
        let thumbRelativePath = "\(thumbRelativeDir)/\(photoID.uuidString)_thumb.jpg"

        let photoURL = documentsDirectory.appendingPathComponent(photoRelativePath)
        let thumbURL = documentsDirectory.appendingPathComponent(thumbRelativePath)

        guard let photoData = image.jpegData(compressionQuality: jpegQuality) else { return nil }

        let thumbnail = generateThumbnail(from: image, targetSize: thumbnailSize)
        guard let thumbData = thumbnail.jpegData(compressionQuality: jpegQuality) else { return nil }

        do {
            try photoData.write(to: photoURL)
            try thumbData.write(to: thumbURL)
        } catch {
            return nil
        }

        return (photoPath: photoRelativePath, thumbPath: thumbRelativePath)
    }

    // MARK: - Delete

    func deletePhoto(path: String) {
        let url = documentsDirectory.appendingPathComponent(path)
        try? fileManager.removeItem(at: url)
    }

    // MARK: - Load

    func loadImage(path: String) -> UIImage? {
        let url = documentsDirectory.appendingPathComponent(path)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    // MARK: - Helpers

    private func generateThumbnail(from image: UIImage, targetSize: CGFloat) -> UIImage {
        let size = image.size
        let scale = targetSize / max(size.width, size.height)
        let newSize = CGSize(width: size.width * scale, height: size.height * scale)

        let renderer = UIGraphicsImageRenderer(size: newSize)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: newSize))
        }
    }

    private static func dateFolder() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM"
        return formatter.string(from: Date())
    }
}
