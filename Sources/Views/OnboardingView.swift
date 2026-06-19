import SwiftUI

/// First-launch welcome screen. Introduces the notch UI, lets the user opt into
/// launch-at-login and Do Not Disturb, and explains the one-time DND setup.
struct OnboardingView: View {
    @Bindable var settings: PomodoroSettings
    let dndAvailable: Bool
    let onFinish: () -> Void

    private let accent = PomodoroPhase.work.accent

    var body: some View {
        VStack(spacing: 0) {
            header
            features
            options
            footer
        }
        .frame(width: 460)
        .background(Color(nsColor: .windowBackgroundColor))
    }

    private var header: some View {
        VStack(spacing: 10) {
            Image(nsImage: NSApp.applicationIconImage)
                .resizable()
                .frame(width: 72, height: 72)
            Text("Welcome to FocusNotch")
                .font(.system(size: 22, weight: .bold))
            Text("A Pomodoro timer that lives in your notch.")
                .font(.system(size: 13))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 32)
        .padding(.bottom, 24)
    }

    private var features: some View {
        VStack(alignment: .leading, spacing: 18) {
            FeatureRow(
                icon: "hand.point.up.left",
                tint: accent,
                title: "Hover the notch",
                detail: "Glance for time left and sessions; hover to expand the full controls."
            )
            FeatureRow(
                icon: "timer",
                tint: accent,
                title: "Focus & breaks, automatically",
                detail: "Work sessions, short and long breaks, and cycles — tuned in Settings."
            )
            FeatureRow(
                icon: "moon.fill",
                tint: accent,
                title: "Do Not Disturb",
                detail: dndAvailable
                    ? "Tap the moon to silence notifications during focus."
                    : "Tap the moon to toggle Focus. Install the shortcut once: run \u{201C}npx macos-focus-mode install\u{201D} in Terminal."
            )
        }
        .padding(.horizontal, 36)
        .padding(.bottom, 22)
    }

    private var options: some View {
        VStack(spacing: 10) {
            Toggle("Launch FocusNotch at login", isOn: $settings.launchAtLogin)
            Toggle("Turn on Do Not Disturb during focus sessions", isOn: $settings.focusEnabled)
        }
        .toggleStyle(.switch)
        .padding(.horizontal, 36)
        .padding(.bottom, 24)
    }

    private var footer: some View {
        VStack(spacing: 8) {
            Button(action: finish) {
                Text("Start focusing")
                    .font(.system(size: 14, weight: .semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
            }
            .buttonStyle(.borderedProminent)
            .tint(accent)
            .controlSize(.large)

            Text("Look for the timer in your menu bar and over your notch.")
                .font(.system(size: 11))
                .foregroundStyle(.tertiary)
        }
        .padding(.horizontal, 36)
        .padding(.bottom, 28)
    }

    private func finish() {
        settings.hasCompletedOnboarding = true
        onFinish()
    }
}

private struct FeatureRow: View {
    let icon: String
    let tint: Color
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(tint)
                .frame(width: 26, height: 26)
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 14, weight: .semibold))
                Text(detail)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
    }
}
