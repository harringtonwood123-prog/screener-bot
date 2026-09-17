import SwiftUI

/// The app mark: three overlapping discs, which is what the app does — reading
/// how colours sit against each other. Drawn rather than bitmapped so it stays
/// crisp at any size and can drop the plate when it sits on a coloured header.
struct LogoMark: View {
    var size: CGFloat = 72
    /// Draws the gradient tile behind the discs. Off when already on brand colour.
    var showsPlate: Bool = true

    private var discRadius: CGFloat { size * 0.20 }

    var body: some View {
        ZStack {
            if showsPlate {
                RoundedRectangle(cornerRadius: size * 0.225, style: .continuous)
                    .fill(Theme.brandGradient)
            }

            ZStack {
                disc(Color(red: 0.97, green: 0.96, blue: 0.93), dx: 0, dy: -0.145)
                disc(Color(red: 0.94, green: 0.66, blue: 0.20), dx: -0.122, dy: 0.090)
                disc(Color(red: 0.18, green: 0.76, blue: 0.66), dx: 0.122, dy: 0.090)
            }
            .compositingGroup()
        }
        .frame(width: size, height: size)
        .accessibilityLabel("Closet")
    }

    private func disc(_ color: Color, dx: CGFloat, dy: CGFloat) -> some View {
        Circle()
            .fill(color)
            .opacity(0.88)
            .frame(width: discRadius * 2, height: discRadius * 2)
            .offset(x: size * dx, y: size * dy)
    }
}

/// Mark plus name, for the welcome screen and settings header.
struct LogoLockup: View {
    var size: CGFloat = 64
    var tint: Color = Theme.ink

    var body: some View {
        VStack(spacing: Theme.Space.snug) {
            LogoMark(size: size)
            Text("Closet")
                .font(Theme.display(size * 0.42))
                .foregroundStyle(tint)
        }
    }
}

#Preview {
    VStack(spacing: 32) {
        LogoLockup()
        HStack(spacing: 20) {
            LogoMark(size: 96)
            LogoMark(size: 48)
            LogoMark(size: 28)
        }
    }
    .padding(40)
    .background(Theme.canvas)
}
