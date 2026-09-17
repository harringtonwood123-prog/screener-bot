import SwiftUI

/// Placeholder for a banner ad.
///
/// Renders an inert, clearly-labelled box — there is no ad SDK wired in, so the
/// app ships with no tracking, no IDFA prompt and no network calls from here.
/// Drop a real banner view in place of the body when you're ready; the layout
/// reserves the standard 320x50 slot so nothing shifts when you do.
/// See MONETIZATION.md.
struct AdSlotView: View {
    var body: some View {
        VStack(spacing: 6) {
            Text("Ad")
                .font(.system(size: 9, weight: .semibold))
                .padding(.horizontal, 5)
                .padding(.vertical, 2)
                .background(Theme.hairline)
                .clipShape(RoundedRectangle(cornerRadius: 3))
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("Ad slot")
                .font(.footnote)
                .foregroundStyle(Theme.inkSoft)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(Theme.surfaceRaised)
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
}
