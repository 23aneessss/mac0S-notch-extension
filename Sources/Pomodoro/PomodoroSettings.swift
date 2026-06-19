import Foundation
import Observation

/// User-facing, persisted preferences. Backed by `UserDefaults`; because the
/// type is `@Observable`, SwiftUI views refresh automatically when a value
/// changes and the new value is written through immediately.
@MainActor
@Observable
final class PomodoroSettings {
    private let defaults: UserDefaults

    // MARK: Durations (stored in minutes for the UI, exposed in seconds)

    var workMinutes: Int { didSet { defaults.set(workMinutes, forKey: Keys.workMinutes) } }
    var shortBreakMinutes: Int { didSet { defaults.set(shortBreakMinutes, forKey: Keys.shortBreakMinutes) } }
    var longBreakMinutes: Int { didSet { defaults.set(longBreakMinutes, forKey: Keys.longBreakMinutes) } }
    var sessionsBeforeLongBreak: Int { didSet { defaults.set(sessionsBeforeLongBreak, forKey: Keys.sessionsBeforeLongBreak) } }

    // MARK: Behaviour

    var autoStartBreaks: Bool { didSet { defaults.set(autoStartBreaks, forKey: Keys.autoStartBreaks) } }
    var autoStartWork: Bool { didSet { defaults.set(autoStartWork, forKey: Keys.autoStartWork) } }
    var playSound: Bool { didSet { defaults.set(playSound, forKey: Keys.playSound) } }
    var showNotifications: Bool { didSet { defaults.set(showNotifications, forKey: Keys.showNotifications) } }
    var showOnNonNotchDisplays: Bool { didSet { defaults.set(showOnNonNotchDisplays, forKey: Keys.showOnNonNotchDisplays) } }

    /// Whether the first-launch onboarding has been completed.
    var hasCompletedOnboarding: Bool { didSet { defaults.set(hasCompletedOnboarding, forKey: Keys.hasCompletedOnboarding) } }

    var launchAtLogin: Bool {
        didSet {
            defaults.set(launchAtLogin, forKey: Keys.launchAtLogin)
            LaunchAtLogin.isEnabled = launchAtLogin
        }
    }

    // MARK: Focus / Do Not Disturb

    /// Automatically enable macOS Do Not Disturb during focus sessions.
    var focusEnabled: Bool { didSet { defaults.set(focusEnabled, forKey: Keys.focusEnabled) } }
    /// Name of the Shortcut that toggles Do Not Disturb (accepts "on"/"off").
    var dndShortcutName: String { didSet { defaults.set(dndShortcutName, forKey: Keys.dndShortcutName) } }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        defaults.register(defaults: Self.registrationDefaults)

        workMinutes = defaults.integer(forKey: Keys.workMinutes)
        shortBreakMinutes = defaults.integer(forKey: Keys.shortBreakMinutes)
        longBreakMinutes = defaults.integer(forKey: Keys.longBreakMinutes)
        sessionsBeforeLongBreak = defaults.integer(forKey: Keys.sessionsBeforeLongBreak)

        autoStartBreaks = defaults.bool(forKey: Keys.autoStartBreaks)
        autoStartWork = defaults.bool(forKey: Keys.autoStartWork)
        playSound = defaults.bool(forKey: Keys.playSound)
        showNotifications = defaults.bool(forKey: Keys.showNotifications)
        showOnNonNotchDisplays = defaults.bool(forKey: Keys.showOnNonNotchDisplays)
        launchAtLogin = defaults.bool(forKey: Keys.launchAtLogin)

        focusEnabled = defaults.bool(forKey: Keys.focusEnabled)
        dndShortcutName = defaults.string(forKey: Keys.dndShortcutName) ?? "macos-focus-mode"
        hasCompletedOnboarding = defaults.bool(forKey: Keys.hasCompletedOnboarding)
    }

    /// Duration in seconds for a given phase.
    func duration(for phase: PomodoroPhase) -> TimeInterval {
        switch phase {
        case .work: return TimeInterval(max(1, workMinutes) * 60)
        case .shortBreak: return TimeInterval(max(1, shortBreakMinutes) * 60)
        case .longBreak: return TimeInterval(max(1, longBreakMinutes) * 60)
        }
    }

    func resetToDefaults() {
        workMinutes = 25
        shortBreakMinutes = 5
        longBreakMinutes = 15
        sessionsBeforeLongBreak = 4
        autoStartBreaks = true
        autoStartWork = false
        playSound = true
        showNotifications = true
        showOnNonNotchDisplays = true
    }

    private static let registrationDefaults: [String: Any] = [
        Keys.workMinutes: 25,
        Keys.shortBreakMinutes: 5,
        Keys.longBreakMinutes: 15,
        Keys.sessionsBeforeLongBreak: 4,
        Keys.autoStartBreaks: true,
        Keys.autoStartWork: false,
        Keys.playSound: true,
        Keys.showNotifications: true,
        Keys.showOnNonNotchDisplays: true,
        Keys.launchAtLogin: false,
        Keys.focusEnabled: false,
    ]

    private enum Keys {
        static let workMinutes = "workMinutes"
        static let shortBreakMinutes = "shortBreakMinutes"
        static let longBreakMinutes = "longBreakMinutes"
        static let sessionsBeforeLongBreak = "sessionsBeforeLongBreak"
        static let autoStartBreaks = "autoStartBreaks"
        static let autoStartWork = "autoStartWork"
        static let playSound = "playSound"
        static let showNotifications = "showNotifications"
        static let showOnNonNotchDisplays = "showOnNonNotchDisplays"
        static let launchAtLogin = "launchAtLogin"
        static let focusEnabled = "focusEnabled"
        static let dndShortcutName = "dndShortcutName"
        static let hasCompletedOnboarding = "hasCompletedOnboarding"
    }
}
