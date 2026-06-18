import AppKit
import SwiftUI

/// Owns the notch panel and drives its expand/collapse behaviour from mouse
/// position.
///
/// Hover is tracked with two monitors because the panel toggles
/// `ignoresMouseEvents`:
/// - While collapsed the panel is click-through, so mouse-moved events go to
///   the app behind us and are caught by the *global* monitor.
/// - While expanded the panel receives events, so they are caught by the
///   *local* monitor.
///
/// Opening waits a short "intent" delay so brushing past the notch doesn't pop
/// it open; closing waits a longer delay and re-checks the cursor, so crossing
/// a gap between controls never snaps it shut.
@MainActor
final class NotchController {
    private let environment: AppEnvironment
    private let model: NotchModel

    private var window: NotchWindow?
    private var globalMonitor: Any?
    private var localMonitor: Any?

    private var pendingOpen: DispatchWorkItem?
    private var pendingClose: DispatchWorkItem?

    private let openDelay: TimeInterval = 0.05
    private let closeDelay: TimeInterval = 0.22

    init(environment: AppEnvironment) {
        self.environment = environment
        let screen = Self.targetScreen(settings: environment.settings)
            ?? NSScreen.main
            ?? NSScreen.screens[0]
        self.model = NotchModel(geometry: NotchGeometry.compute(for: screen))
    }

    // MARK: Lifecycle

    func start() {
        rebuildWindow()
        installMonitors()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(screenParametersChanged),
            name: NSApplication.didChangeScreenParametersNotification,
            object: nil
        )
    }

    deinit {
        if let globalMonitor { NSEvent.removeMonitor(globalMonitor) }
        if let localMonitor { NSEvent.removeMonitor(localMonitor) }
    }

    // MARK: Window

    private func rebuildWindow() {
        guard let screen = Self.targetScreen(settings: environment.settings) else {
            window?.orderOut(nil)
            window = nil
            return
        }

        let geometry = NotchGeometry.compute(for: screen)
        model.geometry = geometry

        if let window {
            window.setFrame(geometry.windowFrame, display: true)
            return
        }

        let window = NotchWindow(contentRect: geometry.windowFrame)
        let root = NotchRootView(model: model, engine: environment.engine, focus: environment.focus)
        let hosting = NSHostingView(rootView: root)
        hosting.frame = CGRect(origin: .zero, size: geometry.windowFrame.size)
        hosting.autoresizingMask = [.width, .height]
        window.contentView = hosting
        window.setFrame(geometry.windowFrame, display: true)
        window.orderFrontRegardless()
        self.window = window
    }

    @objc private func screenParametersChanged() {
        // Defer slightly; screen geometry can be momentarily inconsistent.
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { [weak self] in
            self?.rebuildWindow()
        }
    }

    // MARK: Hover monitors

    private func installMonitors() {
        globalMonitor = NSEvent.addGlobalMonitorForEvents(matching: [.mouseMoved]) { [weak self] _ in
            MainActor.assumeIsolated { self?.evaluateHover() }
        }
        localMonitor = NSEvent.addLocalMonitorForEvents(matching: [.mouseMoved]) { [weak self] event in
            MainActor.assumeIsolated { self?.evaluateHover() }
            return event
        }
    }

    /// The collapsed hover region depends on session state: the full pill while
    /// a session is active (info is showing), or just the notch while idle.
    private var collapsedHoverRect: CGRect {
        environment.engine.runState == .idle
            ? model.geometry.notchHoverRect
            : model.geometry.closedHoverRect
    }

    private func evaluateHover() {
        let mouse = NSEvent.mouseLocation
        let region = model.isOpen ? model.geometry.openHoverRect : collapsedHoverRect
        if region.contains(mouse) {
            requestOpen()
        } else {
            requestClose()
        }
    }

    private func requestOpen() {
        pendingClose?.cancel()
        pendingClose = nil
        guard !model.isOpen, pendingOpen == nil else { return }

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingOpen = nil
            // Only commit if the cursor is still over the collapsed region.
            if self.collapsedHoverRect.contains(NSEvent.mouseLocation) {
                self.setOpen(true)
            }
        }
        pendingOpen = work
        DispatchQueue.main.asyncAfter(deadline: .now() + openDelay, execute: work)
    }

    private func requestClose() {
        pendingOpen?.cancel()
        pendingOpen = nil
        guard model.isOpen, pendingClose == nil else { return }

        let work = DispatchWorkItem { [weak self] in
            guard let self else { return }
            self.pendingClose = nil
            // Re-check: the cursor may have returned to the panel.
            if !self.model.geometry.openHoverRect.contains(NSEvent.mouseLocation) {
                self.setOpen(false)
            }
        }
        pendingClose = work
        DispatchQueue.main.asyncAfter(deadline: .now() + closeDelay, execute: work)
    }

    private func setOpen(_ open: Bool) {
        guard model.isOpen != open else { return }
        model.isOpen = open
        window?.ignoresMouseEvents = !open
    }

    // MARK: Screen selection

    private static func targetScreen(settings: PomodoroSettings) -> NSScreen? {
        if let notched = NSScreen.notched {
            return notched
        }
        // No physical notch. Optionally show a simulated island on the main
        // display so non-notch Macs can still use the app.
        return settings.showOnNonNotchDisplays ? NSScreen.main : nil
    }
}
