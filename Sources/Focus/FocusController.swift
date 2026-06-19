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
        if Self.runDNDToggle() {
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

    /// Drives the Control Center "Focus" toggle (AXIdentifier
    /// Toggles macOS Do Not Disturb: opens Control Center, presses the Focus
    /// tile (AXIdentifier `controlcenter-focus-modes`) to expand its submenu,
    /// then presses the labelled "Do Not Disturb" row. Returns true on success.
    ///
    /// `entire contents` doesn't enumerate this window on macOS Tahoe, so we
    /// traverse `UI elements` recursively.
    private static func runDNDToggle() -> Bool {
        let source = """
        on findById(el, theId)
            tell application "System Events"
                set kids to {}
                try
                    set kids to UI elements of el
                end try
                repeat with k in kids
                    try
                        if (value of attribute "AXIdentifier" of k) is theId then return k
                    end try
                    set sub to my findById(k, theId)
                    if sub is not missing value then return sub
                end repeat
            end tell
            return missing value
        end findById

        on findByLabel(el, theLabel)
            tell application "System Events"
                set kids to {}
                try
                    set kids to UI elements of el
                end try
                repeat with k in kids
                    try
                        if (name of k) is theLabel then return k
                    end try
                    try
                        if (description of k) is theLabel then return k
                    end try
                    set sub to my findByLabel(k, theLabel)
                    if sub is not missing value then return sub
                end repeat
            end tell
            return missing value
        end findByLabel

        tell application "System Events"
            tell process "ControlCenter"
                set frontmost to true
                try
                    perform action "AXPress" of (first menu bar item of menu bar 1 whose description is "Control Center")
                on error
                    return "noopen"
                end try
                delay 0.5

                set focusTile to my findById(window 1, "controlcenter-focus-modes")
                if focusTile is missing value then
                    try
                        key code 53
                    end try
                    return "notile"
                end if
                perform action "AXPress" of focusTile
                delay 0.6

                set dnd to missing value
                repeat with w in windows
                    set dnd to my findByLabel(w, "Do Not Disturb")
                    if dnd is not missing value then exit repeat
                end repeat
                if dnd is missing value then
                    try
                        key code 53
                    end try
                    try
                        key code 53
                    end try
                    return "nodnd"
                end if

                perform action "AXPress" of dnd
                delay 0.2
                try
                    key code 53
                end try
                try
                    key code 53
                end try
                return "ok"
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
        let value = result.stringValue ?? ""
        if value != "ok" {
            NSLog("FocusNotch: Do Not Disturb toggle did not complete (\(value)).")
            return false
        }
        return true
    }
}
