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
    global dumpText
    set dumpText to ""

    on walk(el, depth)
        global dumpText
        if depth > 7 then return
        set pad to ""
        repeat depth times
            set pad to pad & "  "
        end repeat
        tell application "System Events"
            set kids to {}
            try
                set kids to UI elements of el
            end try
            repeat with k in kids
                set kClass to "?"
                set kDesc to ""
                set kName to ""
                set kRole to ""
                set kId to ""
                set kHelp to ""
                try
                    set kClass to (class of k as text)
                end try
                try
                    set kDesc to (description of k)
                end try
                try
                    set kName to (name of k)
                end try
                try
                    set kRole to (role description of k)
                end try
                try
                    set kId to (value of attribute "AXIdentifier" of k)
                end try
                try
                    set kHelp to (help of k)
                end try
                set dumpText to dumpText & pad & kClass & " | role=" & kRole & " | id=" & kId & " | help=" & kHelp & " | desc=" & kDesc & " | name=" & kName & linefeed
                my walk(k, depth + 1)
            end repeat
        end tell
    end walk

    tell application "System Events"
        tell process "ControlCenter"
            set frontmost to true
            set dumpText to dumpText & "== MENU BAR ITEMS ==" & linefeed
            try
                repeat with mbi in (menu bar items of menu bar 1)
                    try
                        set dumpText to dumpText & "  desc=" & (description of mbi) & " | name=" & (name of mbi) & linefeed
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
            delay 1.5
            set dumpText to dumpText & "== WINDOWS (" & (count of windows) & ") ==" & linefeed
            repeat with w in windows
                set dumpText to dumpText & "WINDOW name=" & (name of w) & linefeed
                my walk(w, 1)
            end repeat
            try
                key code 53
            end try
        end tell
    end tell
    return dumpText
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
