#if DEBUG
import SwiftUI
import AppKit

/// Offscreen renderer used during development to verify the notch layout
/// without the live panel. Triggered by launching with `FN_RENDER_PREVIEW=1`;
/// writes PNGs to `FN_RENDER_DIR` (or the temp dir) and exits.
///
/// Each image overlays a red center line and a green outline of the physical
/// notch so collapsed-gap centering and content occlusion can be checked.
@MainActor
enum PreviewRenderer {
    static func renderIfRequested() -> Bool {
        guard ProcessInfo.processInfo.environment["FN_RENDER_PREVIEW"] != nil else { return false }
        let dir = ProcessInfo.processInfo.environment["FN_RENDER_DIR"] ?? NSTemporaryDirectory()

        guard let screen = NSScreen.main else { return true }
        let geo = NotchGeometry.compute(for: screen)

        render(name: "preview_closed_running", geo: geo, open: false,
               phase: .work, remaining: 24 * 60 + 18, runState: .running, cycle: 1, dir: dir)
        render(name: "preview_open_running", geo: geo, open: true,
               phase: .work, remaining: 24 * 60 + 18, runState: .running, cycle: 1, dir: dir)
        render(name: "preview_open_break", geo: geo, open: true,
               phase: .shortBreak, remaining: 5 * 60, runState: .running, cycle: 2, dir: dir)
        render(name: "preview_closed_idle", geo: geo, open: false,
               phase: .work, remaining: 25 * 60, runState: .idle, cycle: 0, dir: dir)
        return true
    }

    private static func render(
        name: String, geo: NotchGeometry, open: Bool,
        phase: PomodoroPhase, remaining: TimeInterval,
        runState: PomodoroEngine.RunState, cycle: Int, dir: String
    ) {
        let settings = PomodoroSettings()
        let focus = FocusController(settings: settings)
        let engine = PomodoroEngine(settings: settings, focus: focus)
        engine.previewState(phase: phase, remaining: remaining, runState: runState, cyclePosition: cycle)

        let model = NotchModel(geometry: geo)
        model.isOpen = open

        // Render at the true window size so the ears, rounded corners, shadow,
        // and centering are all visible exactly as they appear on screen.
        let w = geo.windowFrame.width
        let h = geo.windowFrame.height

        let content = ZStack(alignment: .top) {
            Color(white: 0.22) // simulated desktop behind the panel
            NotchRootView(model: model, engine: engine, focus: focus)
                .frame(width: w, height: h)
            // Physical notch outline (centered at top).
            Rectangle()
                .stroke(Color.green.opacity(0.7), lineWidth: 1)
                .frame(width: geo.notchWidth, height: geo.notchHeight)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            // Screen/notch center line.
            Rectangle()
                .fill(Color.red.opacity(0.7))
                .frame(width: 1)
        }
        .frame(width: w, height: h)

        let renderer = ImageRenderer(content: content)
        renderer.scale = 2
        guard let cg = renderer.cgImage else { return }
        let rep = NSBitmapImageRep(cgImage: cg)
        guard let data = rep.representation(using: .png, properties: [:]) else { return }
        let url = URL(fileURLWithPath: dir).appendingPathComponent("\(name).png")
        try? data.write(to: url)
        NSLog("FocusNotch preview written: \(url.path)")
    }
}
#endif
