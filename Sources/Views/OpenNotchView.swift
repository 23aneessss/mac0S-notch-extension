import SwiftUI

/// The expanded panel. A top spacer the height of the physical notch keeps
/// every control clear of the camera. Below it: a tinted phase badge with
/// session dots, a large hero countdown with the next phase, a slim gradient
/// progress bar, and a row of transport controls plus a Focus toggle.
struct OpenNotchView: View {
    @Bindable var engine: PomodoroEngine
    let focus: FocusController
    let geometry: NotchGeometry

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: geometry.notchHeight)

            VStack(alignment: .leading, spacing: 12) {
                header
                hero
                ProgressBar(progress: engine.progress, colors: engine.phase.gradient)
                    .frame(height: 5)
                controls
                    .padding(.top, 2)
            }
            .padding(.horizontal, 22)
            .padding(.top, 12)
            .padding(.bottom, 18)
        }
        .frame(width: geometry.openWidth, height: geometry.openHeight, alignment: .top)
    }

    private var header: some View {
        HStack(alignment: .center, spacing: 8) {
            PhaseBadge(phase: engine.phase)
            Spacer(minLength: 8)
            SessionDots(
                completed: engine.cyclePosition,
                total: engine.sessionsBeforeLongBreak,
                current: engine.currentSessionNumber,
                accent: engine.phase.accent,
                dotSize: 7,
                spacing: 6
            )
        }
    }

    private var hero: some View {
        HStack(alignment: .center) {
            Text(TimeFormatting.clock(engine.remaining))
                .font(.system(size: 44, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(.white)
                .contentTransition(.numericText())

            Spacer(minLength: 8)

            VStack(alignment: .trailing, spacing: 1) {
                Text("NEXT")
                    .font(.system(size: 9, weight: .bold))
                    .tracking(1.4)
                    .foregroundStyle(.white.opacity(0.32))
                Text(engine.upcomingPhase.title)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(.white.opacity(0.62))
                    .lineLimit(1)
            }
        }
    }

    private var controls: some View {
        HStack(spacing: 12) {
            ControlButton(
                systemName: engine.isRunning ? "pause.fill" : "play.fill",
                prominent: true,
                tint: engine.phase.accent,
                diameter: 40,
                help: engine.isRunning ? "Pause" : "Start"
            ) {
                engine.toggle()
            }

            ControlButton(systemName: "forward.fill", help: "Skip to next phase") {
                engine.skip()
            }

            ControlButton(systemName: "arrow.counterclockwise", help: "Reset this phase") {
                engine.resetCurrentPhase()
            }

            Spacer(minLength: 0)

            ControlButton(
                systemName: focus.isActive ? "moon.fill" : "moon",
                tint: focus.isActive ? engine.phase.accent : .white,
                help: "Toggle Focus / Do Not Disturb"
            ) {
                focus.toggleManually()
            }
        }
    }
}
