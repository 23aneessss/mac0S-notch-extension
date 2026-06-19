import Foundation
import Observation

/// The Pomodoro state machine.
///
/// Timing is anchored to an absolute `endDate` rather than decremented on each
/// tick, so the countdown stays accurate across timer coalescing, app nap, and
/// short sleeps. The tick only refreshes the published `remaining` value.
@MainActor
@Observable
final class PomodoroEngine {
    enum RunState {
        case idle      // nothing scheduled, sitting at the start of a phase
        case running
        case paused
    }

    // MARK: Published state

    private(set) var phase: PomodoroPhase = .work
    private(set) var runState: RunState = .idle
    private(set) var remaining: TimeInterval
    /// Total focus sessions completed since launch (the lifetime counter).
    private(set) var completedSessions: Int = 0
    /// Focus sessions completed within the current long-break cycle (0...sessionsBeforeLongBreak).
    private(set) var cyclePosition: Int = 0

    // MARK: Dependencies

    private let settings: PomodoroSettings
    private let focus: FocusController

    /// Fired on every tick and state change. Used by AppKit consumers (status
    /// bar) that don't participate in SwiftUI's observation.
    var onChange: (() -> Void)?

    private var timer: Timer?
    private var endDate: Date?

    init(settings: PomodoroSettings, focus: FocusController) {
        self.settings = settings
        self.focus = focus
        self.remaining = settings.duration(for: .work)
    }

    // MARK: Derived values

    var isRunning: Bool { runState == .running }

    var totalForCurrentPhase: TimeInterval {
        settings.duration(for: phase)
    }

    /// Elapsed fraction of the current phase, 0...1.
    var progress: Double {
        let total = totalForCurrentPhase
        guard total > 0 else { return 0 }
        return min(1, max(0, 1 - remaining / total))
    }

    var sessionsBeforeLongBreak: Int {
        max(1, settings.sessionsBeforeLongBreak)
    }

    /// 1-based index of the focus session the user is on within the cycle.
    var currentSessionNumber: Int {
        min(cyclePosition + 1, sessionsBeforeLongBreak)
    }

    /// The phase that will follow the current one if it completes now.
    var upcomingPhase: PomodoroPhase {
        switch phase {
        case .work:
            return (cyclePosition + 1) >= sessionsBeforeLongBreak ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }

    // MARK: Commands

    /// Primary action: start, resume, or pause depending on the current state.
    func toggle() {
        switch runState {
        case .idle, .paused: start()
        case .running: pause()
        }
    }

    func start() {
        if remaining <= 0 { remaining = totalForCurrentPhase }
        endDate = Date().addingTimeInterval(remaining)
        runState = .running
        scheduleTimer()
        if phase == .work { focus.activate() }
        notifyChange()
    }

    func pause() {
        guard runState == .running else { return }
        recomputeRemaining()
        invalidateTimer()
        runState = .paused
        focus.deactivate()
        notifyChange()
    }

    /// Reset the current phase back to its full duration without advancing.
    func resetCurrentPhase() {
        invalidateTimer()
        remaining = totalForCurrentPhase
        endDate = nil
        runState = .idle
        focus.deactivate()
        notifyChange()
    }

    /// Reset the entire cycle back to the first focus session.
    func resetAll() {
        invalidateTimer()
        phase = .work
        cyclePosition = 0
        remaining = totalForCurrentPhase
        endDate = nil
        runState = .idle
        focus.deactivate()
        notifyChange()
    }

    /// Skip to the next phase immediately. A skipped focus phase still counts
    /// toward the cycle, matching common Pomodoro app behaviour.
    func skip() {
        advance(autoStartNext: false)
    }

    // MARK: Timer

    private func scheduleTimer() {
        invalidateTimer()
        let timer = Timer(timeInterval: 0.2, repeats: true) { [weak self] _ in
            MainActor.assumeIsolated { self?.tick() }
        }
        RunLoop.main.add(timer, forMode: .common)
        self.timer = timer
    }

    private func invalidateTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func tick() {
        guard runState == .running else { return }
        recomputeRemaining()
        if remaining <= 0 {
            advance(autoStartNext: true)
        } else {
            notifyChange()
        }
    }

    private func recomputeRemaining() {
        guard let endDate else { return }
        remaining = max(0, endDate.timeIntervalSinceNow)
    }

    // MARK: Phase transitions

    private func advance(autoStartNext: Bool) {
        invalidateTimer()
        let finished = phase

        if finished == .work {
            completedSessions += 1
            cyclePosition += 1
        }

        let next = upcomingPhaseAfter(finished)

        // Reset the cycle counter once a long break has been taken.
        if finished == .longBreak {
            cyclePosition = 0
        }

        phase = next
        remaining = totalForCurrentPhase
        endDate = nil
        runState = .idle

        // Focus mode follows the work phase only.
        if finished == .work {
            focus.deactivate()
        }

        announceTransition(from: finished, to: next)

        let shouldAutoStart = autoStartNext && ((next.isBreak && settings.autoStartBreaks) || (next == .work && settings.autoStartWork))
        if shouldAutoStart {
            start()
        } else {
            notifyChange()
        }
    }

    private func upcomingPhaseAfter(_ finished: PomodoroPhase) -> PomodoroPhase {
        switch finished {
        case .work:
            return cyclePosition >= sessionsBeforeLongBreak ? .longBreak : .shortBreak
        case .shortBreak, .longBreak:
            return .work
        }
    }

    private func announceTransition(from: PomodoroPhase, to: PomodoroPhase) {
        if settings.showNotifications {
            NotificationManager.shared.postPhaseChange(finished: from, next: to)
        }
        if settings.playSound {
            SoundPlayer.playTransition(into: to)
        }
    }

    private func notifyChange() {
        onChange?()
    }
}
