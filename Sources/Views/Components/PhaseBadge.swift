import SwiftUI

/// A small tinted capsule showing the current phase — icon + name in the phase
/// accent color over a soft accent background.
struct PhaseBadge: View {
    let phase: PomodoroPhase

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: phase.symbolName)
                .font(.system(size: 11, weight: .bold))
            Text(phase.title)
                .font(.system(size: 12.5, weight: .semibold))
        }
        .foregroundStyle(phase.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 5)
        .background(
            Capsule().fill(phase.accent.opacity(0.16))
        )
    }
}
