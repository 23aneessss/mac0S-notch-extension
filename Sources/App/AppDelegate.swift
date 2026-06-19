import AppKit

/// Application lifecycle owner. Builds the shared environment and brings up the
/// notch panel, status bar item, and notification permissions on launch.
@MainActor
final class AppDelegate: NSObject, NSApplicationDelegate {
    let environment = AppEnvironment()

    private var notchController: NotchController?
    private var statusItemController: StatusItemController?

    func applicationDidFinishLaunching(_ notification: Notification) {
        // Agent apps still benefit from being the accessory activation policy.
        NSApp.setActivationPolicy(.accessory)

        NotificationManager.shared.requestAuthorization()

        let notch = NotchController(environment: environment)
        notch.start()
        self.notchController = notch

        let statusItem = StatusItemController(environment: environment)
        self.statusItemController = statusItem

        // Apply the persisted launch-at-login preference.
        LaunchAtLogin.isEnabled = environment.settings.launchAtLogin
    }

    func applicationWillTerminate(_ notification: Notification) {
        // Make sure we never leave the user's Focus mode stuck on.
        environment.focus.deactivate()
    }

    func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
        true
    }
}
