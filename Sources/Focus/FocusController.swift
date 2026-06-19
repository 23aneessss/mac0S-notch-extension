import AppKit
import ApplicationServices
import Observation

/// Toggles macOS **Do Not Disturb** via the Control Center.
///
/// Apple exposes no public API to set Focus/DND, so FocusNotch automates the
/// Control Center toggle through the Accessibility (AX) system. This requires
/// the user to grant Accessibility permission once; the first attempt prompts
/// for it and opens the relevant Settings pane.
///
/// `isActive` tracks the state *we* set. The manual moon button always toggles;
/// automatic activation during focus sessions is gated by `focusEnabled`.
@MainActor
@Observable
final class FocusController {
    private let settings: PomodoroSettings
    private(set) var isActive = false

    init(settings: PomodoroSettings) {
        self.settings = settings
    }

    /// Whether macOS has granted us Accessibility control.
    var accessibilityGranted: Bool { AXIsProcessTrusted() }

    // MARK: Session-driven (auto)

    func activate() {
        guard settings.focusEnabled, !isActive else { return }
        setDoNotDisturb(true)
    }

    func deactivate() {
        guard isActive else { return }
        setDoNotDisturb(false)
    }

    // MARK: Manual (moon button) — always works

    func toggleManually() {
        setDoNotDisturb(!isActive)
    }

    // MARK: Implementation

    private func setDoNotDisturb(_ on: Bool) {
        guard on != isActive else { return }
        guard ensureAccessibilityPermission() else { return }
        if Self.runToggleScript() {
            isActive = on
        }
    }

    /// Returns true if Accessibility is granted. Otherwise prompts the user and
    /// opens the Accessibility settings pane, and returns false.
    @discardableResult
    func ensureAccessibilityPermission() -> Bool {
        if AXIsProcessTrusted() { return true }
        // Prompt (shows the system dialog) using the documented option key.
        let options = ["AXTrustedCheckOptionPrompt": true] as CFDictionary
        AXIsProcessTrustedWithOptions(options)
        openAccessibilitySettings()
        return false
    }

    func openAccessibilitySettings() {
        if let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?Privacy_Accessibility") {
            NSWorkspace.shared.open(url)
        }
    }

    /// Opens Control Center and presses the Do Not Disturb / Focus control,
    /// trying several strategies because the layout varies across macOS
    /// versions. Returns true only if something was actually pressed.
    private static func runToggleScript() -> Bool {
        let source = """
        on pressMatch(win, attr, val)
            tell application "System Events"
                repeat with e in (entire contents of win)
                    try
                        if attr is "desc" then
                            if (description of e) is val then
                                perform action "AXPress" of e
                                return true
                            end if
                        else if attr is "name" then
                            if (name of e) is val then
                                perform action "AXPress" of e
                                return true
                            end if
                        end if
                    end try
                end repeat
            end tell
            return false
        end pressMatch

        tell application "System Events"
            tell process "ControlCenter"
                set frontmost to true
                -- Open Control Center.
                try
                    perform action "AXPress" of (first menu bar item of menu bar 1 whose description is "Control Center")
                on error
                    try
                        perform action "AXPress" of (last menu bar item of menu bar 1)
                    end try
                end try
                delay 0.7

                set done to false
                -- 1) A control already labelled "Do Not Disturb".
                if not done then set done to my pressMatch(window 1, "desc", "Do Not Disturb")
                if not done then set done to my pressMatch(window 1, "name", "Do Not Disturb")
                -- 2) The Focus tile (toggles the active focus / expands the list).
                if not done then set done to my pressMatch(window 1, "desc", "Focus")
                if not done then set done to my pressMatch(window 1, "name", "Focus")

                delay 0.5
                -- 3) If a submenu expanded, now choose Do Not Disturb.
                if done then
                    try
                        my pressMatch(window 1, "desc", "Do Not Disturb")
                    end try
                end if

                delay 0.15
                try
                    key code 53
                end try
                return done
            end tell
        end tell
        """
        guard let script = NSAppleScript(source: source) else { return false }
        var error: NSDictionary?
        let result = script.executeAndReturnError(&error)
        if let error {
            NSLog("FocusNotch: Do Not Disturb toggle failed: \(error)")
            return false
        }
        // The script returns whether it pressed anything.
        return result.booleanValue
    }
}
