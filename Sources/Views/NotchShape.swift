import SwiftUI

/// The signature notch silhouette: a panel flush with the top of the screen
/// with **concave "ears"** at the top corners (so the black flares out and
/// blends into the menu bar, exactly like the physical notch / Dynamic Island)
/// and large convex rounded corners at the bottom.
///
/// The ears extend `topRadius` *beyond* the rect on each side, so the owning
/// view should leave a little horizontal margin around the shape.
struct NotchShape: Shape {
    var topRadius: CGFloat      // concave ear radius (0 = square top, matches a bare notch)
    var bottomRadius: CGFloat   // convex bottom corner radius

    var animatableData: AnimatablePair<CGFloat, CGFloat> {
        get { AnimatablePair(topRadius, bottomRadius) }
        set {
            topRadius = newValue.first
            bottomRadius = newValue.second
        }
    }

    func path(in rect: CGRect) -> Path {
        let er = max(0, min(topRadius, rect.width / 2))
        let br = max(0, min(bottomRadius, min(rect.width, rect.height) / 2))

        var p = Path()
        // Top-left ear: flare out from the body into the menu bar.
        p.move(to: CGPoint(x: rect.minX - er, y: rect.minY))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX, y: rect.minY + er),
            control: CGPoint(x: rect.minX, y: rect.minY)
        )
        // Left side down to the bottom-left corner.
        p.addLine(to: CGPoint(x: rect.minX, y: rect.maxY - br))
        p.addQuadCurve(
            to: CGPoint(x: rect.minX + br, y: rect.maxY),
            control: CGPoint(x: rect.minX, y: rect.maxY)
        )
        // Bottom edge.
        p.addLine(to: CGPoint(x: rect.maxX - br, y: rect.maxY))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX, y: rect.maxY - br),
            control: CGPoint(x: rect.maxX, y: rect.maxY)
        )
        // Right side up to the top-right ear.
        p.addLine(to: CGPoint(x: rect.maxX, y: rect.minY + er))
        p.addQuadCurve(
            to: CGPoint(x: rect.maxX + er, y: rect.minY),
            control: CGPoint(x: rect.maxX, y: rect.minY)
        )
        // Top edge (spans the full flared width) closes the path.
        p.closeSubpath()
        return p
    }
}
