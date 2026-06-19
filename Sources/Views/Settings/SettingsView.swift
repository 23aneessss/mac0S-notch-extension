import SwiftUI

/// Preferences window content. Tabbed: Timer, Behaviour, Focus, About.
struct SettingsView: View {
    @Bindable var settings: PomodoroSettings
    let focus: FocusController

    var body: some View {
        TabView {
            timerTab
                .tabItem { Label("Timer", systemImage: "timer") }
            behaviourTab
                .tabItem { Label("Behavior", systemImage: "slider.horizontal.3") }
            focusTab
                .tabItem { Label("Focus", systemImage: "moon") }
            aboutTab
                .tabItem { Label("About", systemImage: "info.circle") }
        }
        .frame(width: 460, height: 560)
    }

    // MARK: Timer

    private var timerTab: some View {
        Form {
            Section("Durations") {
                stepperRow("Focus", value: $settings.workMinutes, range: 1...120, unit: "min")
                stepperRow("Short break", value: $settings.shortBreakMinutes, range: 1...60, unit: "min")
                stepperRow("Long break", value: $settings.longBreakMinutes, range: 1...60, unit: "min")
            }
            Section("Cycle") {
                stepperRow("Sessions before long break", value: $settings.sessionsBeforeLongBreak, range: 1...12, unit: "")
            }
            Section {
                Button("Reset to defaults") { settings.resetToDefaults() }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Behaviour

    private var behaviourTab: some View {
        Form {
            Section("Automation") {
                Toggle("Auto-start breaks", isOn: $settings.autoStartBreaks)
                Toggle("Auto-start next focus session", isOn: $settings.autoStartWork)
            }
            Section("Alerts") {
                Toggle("Play sound on phase change", isOn: $settings.playSound)
                Toggle("Show notifications", isOn: $settings.showNotifications)
            }
            Section("Display") {
                Toggle("Show on Macs without a notch", isOn: $settings.showOnNonNotchDisplays)
                Toggle("Launch at login", isOn: $settings.launchAtLogin)
            }
        }
        .formStyle(.grouped)
    }

    // MARK: Focus

    private var focusTab: some View {
        Form {
            Section {
                Toggle("Enable Do Not Disturb during focus sessions", isOn: $settings.focusEnabled)
            } footer: {
                Text("The moon button on the notch always toggles Do Not Disturb manually. macOS has no public API for Focus, so FocusNotch flips the Control Center toggle — this needs Accessibility permission (you'll be asked the first time).")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Permission") {
                HStack {
                    Text("Accessibility access")
                    Spacer()
                    Text(focus.accessibilityGranted ? "Granted" : "Not granted")
                        .foregroundStyle(focus.accessibilityGranted ? .green : .secondary)
                }
                Button("Open Accessibility Settings…") {
                    focus.openAccessibilitySettings()
                }
                Button("Test Do Not Disturb toggle") {
                    focus.toggleManually()
                }
            }
        }
        .formStyle(.grouped)
    }

    // MARK: About

    private var aboutTab: some View {
        VStack(spacing: 14) {
            Image(systemName: "timer")
                .font(.system(size: 54, weight: .light))
                .foregroundStyle(.tint)
            Text("FocusNotch")
                .font(.title2.bold())
            Text("Make your notch useful.")
                .foregroundStyle(.secondary)
            Text("Version \(appVersion)")
                .font(.caption)
                .foregroundStyle(.secondary)
            Spacer()
        }
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var appVersion: String {
        let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "\(v) (\(b))"
    }

    // MARK: Helpers

    private func stepperRow(_ title: String, value: Binding<Int>, range: ClosedRange<Int>, unit: String) -> some View {
        HStack {
            Text(title)
            Spacer()
            Text(unit.isEmpty ? "\(value.wrappedValue)" : "\(value.wrappedValue) \(unit)")
                .foregroundStyle(.secondary)
                .monospacedDigit()
            Stepper("", value: value, in: range)
                .labelsHidden()
        }
    }
}
