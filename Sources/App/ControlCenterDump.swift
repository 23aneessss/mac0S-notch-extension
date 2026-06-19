#if DEBUG
import AppKit

/// Development helper: dumps the Control Center UI tree (menu bar items + every
/// window's elements) so the Do Not Disturb automation can be matched exactly
/// to this machine's macOS version.
///
/// Must run from the GUI app (which holds Accessibility permission), not from a
/// terminal-launched process. Trigger it from the status-bar "Debug" menu item;
/// it writes to ~/Desktop/fn_cc_dump.txt.
@MainActor
enum ControlCenterDump {
    private static let script = """
    set output to ""
    tell application "System Events"
        tell process "ControlCenter"
            set frontmost to true
            set output to output & "== MENU BAR ITEMS ==" & linefeed
            try
                repeat with mbi in (menu bar items of menu bar 1)
                    try
                        set output to output & "  desc=" & (description of mbi) & " | name=" & (name of mbi) & linefeed
                    end try
                end repeat
            end try
            try
                perform action "AXPress" of (first menu bar item of menu bar 1 whose description is "Control Center")
            on error
                try
                    perform action "AXPress" of (last menu bar item of menu bar 1)
                end try
            end try
            delay 0.9
            set output to output & "== WINDOWS ==" & linefeed
            try
                repeat with w in windows
                    set output to output & "WINDOW: " & (name of w) & linefeed
                    try
                        repeat with e in (entire contents of w)
                            try
                                set output to output & "  " & (class of e as text) & " | desc=" & (description of e) & " | name=" & (name of e) & linefeed
                            end try
                        end repeat
                    end try
                end repeat
            on error errMsg
                set output to output & "ERR: " & errMsg
            end try
            try
                key code 53
            end try
        end tell
    end tell
    return output
    """

    /// Runs the dump and returns the text (used by the env-var path).
    static func runIfRequested() -> Bool {
        guard ProcessInfo.processInfo.environment["FN_DUMP_CC"] != nil else { return false }
        print("===== CONTROL CENTER DUMP BEGIN =====")
        print(run())
        print("===== CONTROL CENTER DUMP END =====")
        return true
    }

    /// Runs the dump and writes it to ~/Desktop/fn_cc_dump.txt. Returns the path.
    @discardableResult
    static func dumpToFile() -> String {
        let path = (NSHomeDirectory() as NSString).appendingPathComponent("Desktop/fn_cc_dump.txt")
        try? run().write(toFile: path, atomically: true, encoding: .utf8)
        return path
    }

    private static func run() -> String {
        let s = NSAppleScript(source: script)
        var error: NSDictionary?
        let result = s?.executeAndReturnError(&error)
        if let error { return "DUMP ERROR: \(error)" }
        return result?.stringValue ?? "<nil>"
    }
}
#endif
