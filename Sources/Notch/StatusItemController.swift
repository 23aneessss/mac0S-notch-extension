import AppKit

/// A menu bar item that mirrors the timer and offers the same controls as the
/// notch — useful on external displays, for discoverability, and as the place
/// to open Settings and quit.
@MainActor
final class StatusItemController: NSObject, NSMenuDelegate {
    private let environment: AppEnvironment
    private let statusItem: NSStatusItem
    private var settingsController: SettingsWindowController?

    init(environment: AppEnvironment) {
        self.environment = environment
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        super.init()

        if let button = statusItem.button {
            button.image = NSImage(systemSymbolName: "timer", accessibilityDescription: "FocusNotch")
            button.imagePosition = .imageLeading
            button.font = .monospacedDigitSystemFont(ofSize: 12, weight: .medium)
        }

        statusItem.menu = makeMenu()

        // Keep the title in sync with the engine.
        environment.engine.onChange = { [weak self] in self?.refreshTitle() }
        refreshTitle()
    }

    private func refreshTitle() {
        guard let button = statusItem.button else { return }
        let engine = environment.engine
        switch engine.runState {
        case .running, .paused:
            button.title = " " + TimeFormatting.compactClock(engine.remaining)
        case .idle:
            button.title = ""
        }
    }

    private func makeMenu() -> NSMenu {
        let menu = NSMenu()
        menu.delegate = self
        return menu
    }

    // Rebuild the menu lazily so labels reflect current state.
    func menuNeedsUpdate(_ menu: NSMenu) {
        menu.removeAllItems()
        let engine = environment.engine

        let status = NSMenuItem(title: statusLine(), action: nil, keyEquivalent: "")
        status.isEnabled = false
        menu.addItem(status)
        menu.addItem(.separator())

        let toggleTitle = engine.isRunning ? "Pause" : (engine.runState == .paused ? "Resume" : "Start")
        menu.addItem(item(toggleTitle, #selector(toggle), key: "s"))
        menu.addItem(item("Skip", #selector(skip), key: "k"))
        menu.addItem(item("Reset Phase", #selector(resetPhase), key: "r"))
        menu.addItem(item("Reset All", #selector(resetAll), key: ""))

        menu.addItem(.separator())
        menu.addItem(item("Settings…", #selector(openSettings), key: ","))
        menu.addItem(item("About FocusNotch", #selector(showAbout), key: ""))
        menu.addItem(.separator())
        menu.addItem(item("Quit FocusNotch", #selector(quit), key: "q"))
    }

    private func statusLine() -> String {
        let engine = environment.engine
        let phase = engine.phase.title
        switch engine.runState {
        case .idle: return "\(phase) — ready"
        case .paused: return "\(phase) — paused \(TimeFormatting.clock(engine.remaining))"
        case .running: return "\(phase) — \(TimeFormatting.clock(engine.remaining))"
        }
    }

    private func item(_ title: String, _ action: Selector, key: String) -> NSMenuItem {
        let item = NSMenuItem(title: title, action: action, keyEquivalent: key)
        item.target = self
        return item
    }

    // MARK: Actions

    @objc private func toggle() { environment.engine.toggle() }
    @objc private func skip() { environment.engine.skip() }
    @objc private func resetPhase() { environment.engine.resetCurrentPhase() }
    @objc private func resetAll() { environment.engine.resetAll() }
    @objc private func quit() { NSApp.terminate(nil) }

    @objc private func openSettings() {
        if settingsController == nil {
            settingsController = SettingsWindowController(environment: environment)
        }
        settingsController?.show()
    }

    @objc private func showAbout() {
        NSApp.activate(ignoringOtherApps: true)
        NSApp.orderFrontStandardAboutPanel(options: [
            .applicationName: "FocusNotch",
            .init(rawValue: "Copyright"): "Make your notch useful.",
        ])
    }
}
