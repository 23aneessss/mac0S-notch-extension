import AppKit
import SwiftUI

/// Hosts the first-launch `OnboardingView` in a centered window.
@MainActor
final class OnboardingWindowController {
    private let environment: AppEnvironment
    private var window: NSWindow?

    init(environment: AppEnvironment) {
        self.environment = environment
    }

    func show() {
        let view = OnboardingView(
            settings: environment.settings,
            dndAvailable: environment.focus.isAvailable,
            onFinish: { [weak self] in self?.close() }
        )
        let hosting = NSHostingController(rootView: view)
        let window = NSWindow(contentViewController: hosting)
        window.styleMask = [.titled, .closable, .fullSizeContentView]
        window.titleVisibility = .hidden
        window.titlebarAppearsTransparent = true
        window.isReleasedWhenClosed = false
        window.title = "Welcome to FocusNotch"
        window.center()
        self.window = window

        NSApp.activate(ignoringOtherApps: true)
        window.makeKeyAndOrderFront(nil)
    }

    private func close() {
        window?.close()
        window = nil
    }
}
