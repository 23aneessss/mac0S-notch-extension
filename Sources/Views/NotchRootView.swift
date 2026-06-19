import SwiftUI

/// Root content of the notch panel.
///
/// The black `NotchShape` morphs between the collapsed pill and the expanded
/// panel — growing the bottom radius and flaring the top "ears" so it reads as
/// an extension of the hardware notch. Collapsed and expanded content occupy
/// different vertical regions (collapsed in the top strip, expanded below it),
/// so cross-fading their opacity never overlaps text.
struct NotchRootView: View {
    @Bindable var model: NotchModel
    let engine: PomodoroEngine
    let focus: FocusController

    private var geo: NotchGeometry { model.geometry }
    private var isOpen: Bool { model.isOpen }

    /// While idle the pill collapses to just the notch so it never covers the
    /// menu bar; during a session it widens to show time + sessions.
    private var isActive: Bool { engine.runState != .idle }
    private var collapsedWidth: CGFloat { isActive ? geo.closedWidth : geo.notchWidth }

    private var shapeWidth: CGFloat { isOpen ? geo.openWidth : collapsedWidth }
    private var shapeHeight: CGFloat { isOpen ? geo.openHeight : geo.notchHeight }
    private var bottomRadius: CGFloat { isOpen ? geo.openCornerRadius : geo.closedBottomRadius }
    // Square top while idle (matches the bare notch); flared otherwise.
    private var earRadius: CGFloat { (isOpen || isActive) ? geo.earRadius : 0 }

    var body: some View {
        ZStack(alignment: .top) {
            NotchShape(topRadius: earRadius, bottomRadius: bottomRadius)
                .fill(Color(red: 0, green: 0, blue: 0)) // pure #000000, like the physical notch
                .overlay {
                    NotchShape(topRadius: earRadius, bottomRadius: bottomRadius)
                        .stroke(Color.white.opacity(isOpen ? 0.08 : 0), lineWidth: 0.75)
                }
                .frame(width: shapeWidth, height: shapeHeight)
                .shadow(color: .black.opacity(isOpen ? 0.55 : 0), radius: 24, y: 14)

            // Collapsed content — top strip, only while a session is active.
            ClosedNotchView(engine: engine, geometry: geo)
                .frame(width: geo.closedWidth, height: geo.notchHeight)
                .opacity((isOpen || !isActive) ? 0 : 1)
                .allowsHitTesting(false)

            // Expanded content — below the notch strip.
            OpenNotchView(engine: engine, focus: focus, geometry: geo)
                .frame(width: geo.openWidth, height: geo.openHeight)
                .opacity(isOpen ? 1 : 0)
                .allowsHitTesting(isOpen)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
        .animation(.spring(response: 0.32, dampingFraction: 0.80), value: isOpen)
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: isActive)
        .animation(.easeOut(duration: 0.16), value: isOpen) // opacity cross-fade
    }
}
