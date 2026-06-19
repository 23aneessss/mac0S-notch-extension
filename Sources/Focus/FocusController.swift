import AppKit
import Observation

/// Toggles macOS **Do Not Disturb** by running a Shortcuts shortcut.
///
/// Apple exposes no public API for Focus, so the reliable bridge is a Shortcut
/// that accepts `on` / `off` via standard input. This is compatible with the
/// free `macos-focus-mode` shortcut (the default). The name is configurable in
/// Settings. No Accessibility or Automation permissions are required.
@MainActor
@Observable
final class FocusController {
    private let settings: PomodoroSettings
    private(set) var isActive = false

    init(settings: PomodoroSettings) {
        self.settings = settings
    }

    /// Whether the configured shortcut is currently installed.
    var isAvailable: Bool { Self.shortcutExists(settings.dndShortcutName) }

    // MARK: Session-driven (auto)

    func activate() {
        guard settings.focusEnabled, !isActive else { return }
        setDoNotDisturb(true)
    }

    func deactivate() {
        guard isActive else { return }
        setDoNotDisturb(false)
    }

    // MARK: Manual (moon button)

    func toggleManually() {
        setDoNotDisturb(!isActive)
    }

    // MARK: Implementation

    private func setDoNotDisturb(_ on: Bool) {
        let name = settings.dndShortcutName
        guard !name.isEmpty else { return }
        isActive = on // optimistic — the UI reflects the change immediately
        Self.runShortcut(name: name, input: on ? "on" : "off") { [weak self] success in
            if !success { self?.isActive = !on } // revert if the shortcut failed
        }
    }

    // MARK: Shortcuts CLI

    /// Runs `shortcuts run <name>`, piping `input` ("on"/"off") to stdin.
    nonisolated static func runShortcut(
        name: String,
        input: String,
        completion: (@MainActor (Bool) -> Void)? = nil
    ) {
        DispatchQueue.global(qos: .userInitiated).async {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
            process.arguments = ["run", name]
            let stdin = Pipe()
            process.standardInput = stdin
            process.standardOutput = FileHandle.nullDevice
            process.standardError = FileHandle.nullDevice

            var ok = false
            do {
                try process.run()
                stdin.fileHandleForWriting.write(Data(input.utf8))
                try? stdin.fileHandleForWriting.close()
                process.waitUntilExit()
                ok = process.terminationStatus == 0
            } catch {
                NSLog("FocusNotch: failed to run shortcut \"\(name)\": \(error.localizedDescription)")
            }

            if let completion {
                Task { @MainActor in completion(ok) }
            }
        }
    }

    /// Whether a shortcut with the given name appears in `shortcuts list`.
    nonisolated static func shortcutExists(_ name: String) -> Bool {
        guard !name.isEmpty else { return false }
        let process = Process()
        process.executableURL = URL(fileURLWithPath: "/usr/bin/shortcuts")
        process.arguments = ["list"]
        let pipe = Pipe()
        process.standardOutput = pipe
        process.standardError = FileHandle.nullDevice
        do {
            try process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            return String(decoding: data, as: UTF8.self)
                .split(separator: "\n")
                .map { $0.trimmingCharacters(in: .whitespaces) }
                .contains(name)
        } catch {
            return false
        }
    }
}
