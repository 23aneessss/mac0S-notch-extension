#if DEBUG
import AppKit

/// Development helper: launch with `FN_DUMP_CC=1` to open Control Center and
/// print the role/description/name of every UI element, so the Do Not Disturb
/// automation can be matched exactly to this machine's macOS version. Requires
/// Accessibility + Automation permission (same as the real toggle).
@MainActor
enum ControlCenterDump {
    static func runIfRequested() -> Bool {
        guard ProcessInfo.processInfo.environment["FN_DUMP_CC"] != nil else { return false }

        let source = """
        set output to ""
        tell application "System Events"
            tell process "ControlCenter"
                set frontmost to true
                try
                    perform action "AXPress" of (first menu bar item of menu bar 1 whose description is "Control Center")
                on error
                    try
                        perform action "AXPress" of (last menu bar item of menu bar 1)
                    end try
                end try
                delay 0.8
                try
                    repeat with e in (entire contents of window 1)
                        try
                            set output to output & (class of e as text) & " | desc=" & (description of e) & " | name=" & (name of e) & linefeed
                        end try
                    end repeat
                on error errMsg
                    set output to output & "ERROR: " & errMsg
                end try
                try
                    key code 53
                end try
            end tell
        end tell
        return output
        """

        let script = NSAppleScript(source: source)
        var error: NSDictionary?
        let result = script?.executeAndReturnError(&error)
        if let error {
            print("FN_DUMP_CC error: \(error)")
        }
        print("===== CONTROL CENTER DUMP BEGIN =====")
        print(result?.stringValue ?? "<nil>")
        print("===== CONTROL CENTER DUMP END =====")
        return true
    }
}
#endif
