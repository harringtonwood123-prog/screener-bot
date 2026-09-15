import Foundation
import UIKit
import Vision
import CoreImage

/// What we could work out about a photo of a garment.
struct ScanResult {
    var suggestedKind: GarmentKind?
    var primaryHex: String
    var secondaryHex: String?
    /// The garment cut out from its background, when that worked.
    var cutout: UIImage?
}

/// Reads a photo and guesses what the item is and what colour it is.
///
/// Everything here is on-device and best-effort: if Vision can't decide, the user
/// just picks from a list. Nothing blocks on a correct guess.
enum GarmentScanner {

    static func scan(_ image: UIImage) async -> ScanResult {
        let cutout = await isolateSubject(in: image)
        let target = cutout ?? image
        let palette = dominantColors(in: target, maxCount: 2)

        return ScanResult(
            suggestedKind: await classify(image),
            primaryHex: palette.first ?? "#8E8E93",
            secondaryHex: palette.count > 1 ? palette[1] : nil,
            cutout: cutout
        )
    }

    // MARK: - Subject isolation

    /// Cuts the garment out of its background so the colour sample isn't polluted
    /// by the carpet or the wardrobe door behind it.
    private static func isolateSubject(in image: UIImage) async -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNGenerateForegroundInstanceMaskRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])

        do {
            try handler.perform([request])
            guard let observation = request.results?.first else { return nil }
            let buffer = try observation.generateMaskedImage(
                ofInstances: observation.allInstances,
                from: handler,
                croppedToInstancesExtent: true
            )
            let ciImage = CIImage(cvPixelBuffer: buffer)
            let context = CIContext()
            guard let output = context.createCGImage(ciImage, from: ciImage.extent) else { return nil }
            return UIImage(cgImage: output)
        } catch {
            return nil
        }
    }

    // MARK: - Classification

    private static func classify(_ image: UIImage) async -> GarmentKind? {
        guard let cgImage = image.cgImage else { return nil }

        let request = VNClassifyImageRequest()
        let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
        guard (try? handler.perform([request])) != nil,
              let observations = request.results else { return nil }

        // Only trust reasonably confident labels; a wrong guess is worse than none.
        for observation in observations.prefix(25) where observation.confidence > 0.12 {
            if let kind = kind(forVisionLabel: observation.identifier) { return kind }
        }
        return nil
    }

    /// Maps Vision's generic label vocabulary onto the wardrobe's garment kinds.
    private static func kind(forVisionLabel label: String) -> GarmentKind? {
        let l = label.lowercased()
        let table: [(String, GarmentKind)] = [
            ("t_shirt", .tShirt), ("t-shirt", .tShirt), ("tee_shirt", .tShirt),
            ("jersey", .tShirt), ("polo", .poloShirt),
            ("dress_shirt", .dressShirt), ("oxford", .oxfordShirt),
            ("flannel", .flannelShirt), ("plaid", .flannelShirt),
            ("cardigan", .sweater), ("sweater", .sweater), ("jumper", .sweater),
            ("hoodie", .hoodie), ("hooded", .hoodie), ("sweatshirt", .sweatshirt),
            ("tank", .tankTop),
            ("jean", .jeans), ("denim", .jeans),
            ("chino", .chinos), ("trouser", .dressTrousers), ("slacks", .dressTrousers),
            ("cargo", .cargoPants), ("legging", .leggings), ("jogger", .joggers),
            ("sweatpant", .joggers), ("short", .shorts),
            ("blazer", .blazer), ("suit", .blazer), ("jacket", .bomberJacket),
            ("raincoat", .rainJacket), ("anorak", .rainJacket),
            ("windbreaker", .windbreaker), ("parka", .pufferJacket),
            ("fleece", .fleece), ("overcoat", .overcoat), ("trench", .overcoat),
            ("coat", .overcoat),
            ("running_shoe", .runningShoes), ("sneaker", .sneakers),
            ("loafer", .loafers), ("oxford_shoe", .dressShoes),
            ("boot", .boots), ("sandal", .sandals), ("shoe", .sneakers),
            ("cap", .cap), ("beanie", .beanie), ("scarf", .scarf),
            ("belt", .belt), ("watch", .watch), ("sunglass", .sunglasses)
        ]
        // Longest match first so "running_shoe" beats "shoe".
        for (needle, kind) in table.sorted(by: { $0.0.count > $1.0.count }) where l.contains(needle) {
            return kind
        }
        return nil
    }

    // MARK: - Colour extraction

    /// Finds the garment's dominant colours by quantising the image into coarse
    /// HSB buckets and taking the most populated ones.
    static func dominantColors(in image: UIImage, maxCount: Int = 2) -> [String] {
        guard let pixels = downsampledPixels(image, side: 64) else { return [] }

        var buckets: [Int: (count: Int, h: Double, s: Double, b: Double)] = [:]

        var index = 0
        while index + 3 < pixels.count {
            let r = Double(pixels[index]) / 255
            let g = Double(pixels[index + 1]) / 255
            let b = Double(pixels[index + 2]) / 255
            let alpha = Double(pixels[index + 3]) / 255
            index += 4

            // Skip anything transparent — that's the removed background.
            if alpha < 0.5 { continue }

            let color = HSBColor(red: r, green: g, blue: b)

            // Skip the near-white and near-black extremes that are usually
            // shadow or blown-out highlight rather than the garment itself.
            if color.brightness > 0.96 && color.saturation < 0.06 { continue }
            if color.brightness < 0.04 { continue }

            // Coarse buckets: 24 hue steps, 4 saturation steps, 5 brightness steps.
            let hueBucket = color.saturation < 0.12 ? 0 : Int(color.hue / 15) + 1
            let satBucket = Int(color.saturation * 3.99)
            let briBucket = Int(color.brightness * 4.99)
            let key = (hueBucket * 100) + (satBucket * 10) + briBucket

            var entry = buckets[key] ?? (0, 0, 0, 0)
            entry.count += 1
            entry.h += color.hue
            entry.s += color.saturation
            entry.b += color.brightness
            buckets[key] = entry
        }

        let ranked = buckets.values
            .filter { $0.count > 0 }
            .sorted { $0.count > $1.count }
            .prefix(maxCount)

        return ranked.map { entry in
            let n = Double(entry.count)
            return HSBColor(hue: entry.h / n, saturation: entry.s / n, brightness: entry.b / n).hex
        }
    }

    /// Redraws the image small, in a known RGBA layout, and hands back the raw bytes.
    private static func downsampledPixels(_ image: UIImage, side: Int) -> [UInt8]? {
        guard let cgImage = image.cgImage else { return nil }

        let bytesPerPixel = 4
        let bytesPerRow = side * bytesPerPixel
        var data = [UInt8](repeating: 0, count: side * side * bytesPerPixel)

        let drew = data.withUnsafeMutableBytes { raw -> Bool in
            guard let base = raw.baseAddress,
                  let context = CGContext(
                    data: base,
                    width: side,
                    height: side,
                    bitsPerComponent: 8,
                    bytesPerRow: bytesPerRow,
                    space: CGColorSpaceCreateDeviceRGB(),
                    bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
                  ) else { return false }
            context.draw(cgImage, in: CGRect(x: 0, y: 0, width: side, height: side))
            return true
        }

        return drew ? data : nil
    }
}
