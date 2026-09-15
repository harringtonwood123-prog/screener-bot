import Foundation
import UIKit

/// Saves garment photos as JPEGs in Application Support, keeping only filenames
/// in the wardrobe JSON so the database stays small.
enum ImageStore {

    private static var directory: URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        let dir = base.appendingPathComponent("GarmentImages", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    /// Writes a downscaled JPEG and returns its filename.
    @discardableResult
    static func save(_ image: UIImage) -> String? {
        let resized = downscale(image, maxDimension: 900)
        guard let data = resized.jpegData(compressionQuality: 0.8) else { return nil }
        let filename = "\(UUID().uuidString).jpg"
        do {
            try data.write(to: directory.appendingPathComponent(filename), options: .atomic)
            return filename
        } catch {
            return nil
        }
    }

    static func load(_ filename: String?) -> UIImage? {
        guard let filename else { return nil }
        let url = directory.appendingPathComponent(filename)
        guard let data = try? Data(contentsOf: url) else { return nil }
        return UIImage(data: data)
    }

    static func delete(_ filename: String?) {
        guard let filename else { return }
        try? FileManager.default.removeItem(at: directory.appendingPathComponent(filename))
    }

    private static func downscale(_ image: UIImage, maxDimension: CGFloat) -> UIImage {
        let longest = max(image.size.width, image.size.height)
        guard longest > maxDimension else { return image }
        let scale = maxDimension / longest
        let size = CGSize(width: image.size.width * scale, height: image.size.height * scale)
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { _ in
            image.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
