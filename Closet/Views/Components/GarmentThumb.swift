import SwiftUI
import UIKit

/// A garment's photo, or a colour swatch with its icon when there's no photo.
struct GarmentThumb: View {
    let garment: Garment
    var size: CGFloat = 74

    @State private var image: UIImage?

    var body: some View {
        ZStack {
            if let image {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                garment.color.swiftUIColor
                Image(systemName: garment.slot.symbol)
                    .font(.system(size: size * 0.32))
                    .foregroundStyle(garment.color.contrastingForeground.opacity(0.65))
            }
        }
        .frame(width: size, height: size)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.08), lineWidth: 1)
        )
        .task(id: garment.imageFilename) {
            guard let filename = garment.imageFilename else {
                image = nil
                return
            }
            image = await Task.detached(priority: .utility) {
                ImageStore.load(filename)
            }.value
        }
    }
}
