import AppKit

/// All the sizes the notch UI needs, computed once per screen layout.
///
/// Centering rule: the physical notch is centered on the display, so the empty
/// "gap" in our collapsed pill must also be centered. We therefore use *equal*
/// side widths on both sides of the gap — that keeps the gap aligned with the
/// real notch regardless of how wide the left/right content is.
///
/// Occlusion rule: in the expanded state the physical camera notch still bites
/// into the top-center of our panel. All expanded content is laid out *below*
/// the notch strip (`notchHeight`) so the hardware can never hide it.
struct NotchGeometry: Equatable {
    // View-space
    var notchWidth: CGFloat
    var notchHeight: CGFloat
    var sideWidth: CGFloat          // equal width of each label area beside the notch
    var openWidth: CGFloat
    var openHeight: CGFloat
    var openContentHeight: CGFloat  // openHeight - notchHeight
    var closedBottomRadius: CGFloat
    var openCornerRadius: CGFloat
    var earRadius: CGFloat          // concave top-corner flare when expanded

    // Window / screen-space (global coordinates, bottom-left origin)
    var windowFrame: CGRect
    var hMargin: CGFloat            // horizontal padding inside the window (for ears + shadow)
    var closedHoverRect: CGRect     // hover region while a session is active (full pill)
    var notchHoverRect: CGRect      // hover region while idle (notch only)
    var openHoverRect: CGRect

    /// Total collapsed width: notch gap plus both equal side areas.
    var closedWidth: CGFloat { notchWidth + sideWidth * 2 }

    static func compute(for screen: NSScreen) -> NotchGeometry {
        let notchHeight = (screen.notchHeight ?? 32).rounded()
        let notchWidth = (screen.notchWidth ?? 200).rounded()

        let sideWidth: CGFloat = 82
        let closedWidth = notchWidth + sideWidth * 2

        // Ring-free layout: phase badge + hero time + slim progress bar + controls.
        let openContentHeight: CGFloat = 190
        let openHeight = notchHeight + openContentHeight
        let openWidth = max(closedWidth + 44, 392)

        let closedBottomRadius: CGFloat = 12
        let openCornerRadius: CGFloat = 30
        let earRadius: CGFloat = 12

        // Window padding so the ears and drop shadow have room to render.
        let hMargin: CGFloat = 30
        let bottomMargin: CGFloat = 24

        let frame = screen.frame
        let centerX = (frame.midX).rounded()
        let topY = frame.maxY

        let windowWidth = openWidth + hMargin * 2
        let windowHeight = openHeight + bottomMargin

        let windowFrame = CGRect(
            x: (centerX - windowWidth / 2).rounded(),
            y: (topY - windowHeight).rounded(),
            width: windowWidth,
            height: windowHeight
        )

        // Collapsed hover region: the pill, with a little vertical slop so the
        // cursor reliably enters from the menu bar.
        let closedHoverWidth = closedWidth + 6
        let closedHoverHeight = notchHeight + 3
        let closedHoverRect = CGRect(
            x: centerX - closedHoverWidth / 2,
            y: topY - closedHoverHeight,
            width: closedHoverWidth,
            height: closedHoverHeight
        )

        // Idle hover region: just the notch, so we don't pop open from menu-bar
        // activity beside it.
        let notchHoverWidth = notchWidth + 6
        let notchHoverRect = CGRect(
            x: centerX - notchHoverWidth / 2,
            y: topY - closedHoverHeight,
            width: notchHoverWidth,
            height: closedHoverHeight
        )

        // Expanded hover region: the whole panel, with a small margin so moving
        // the cursor between controls never slips outside and snaps it shut.
        let openHoverRect = CGRect(
            x: centerX - openWidth / 2 - 8,
            y: topY - openHeight - 6,
            width: openWidth + 16,
            height: openHeight + 6
        )

        return NotchGeometry(
            notchWidth: notchWidth,
            notchHeight: notchHeight,
            sideWidth: sideWidth,
            openWidth: openWidth,
            openHeight: openHeight,
            openContentHeight: openContentHeight,
            closedBottomRadius: closedBottomRadius,
            openCornerRadius: openCornerRadius,
            earRadius: earRadius,
            windowFrame: windowFrame,
            hMargin: hMargin,
            closedHoverRect: closedHoverRect,
            notchHoverRect: notchHoverRect,
            openHoverRect: openHoverRect
        )
    }
}
