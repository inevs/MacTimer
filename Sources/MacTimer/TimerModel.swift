import Foundation
import Observation

/// Countdown-Logik. Zeitbasis ist ein festes Enddatum, daher entsteht kein Drift.
@MainActor
@Observable
final class TimerModel {
    enum State: Equatable {
        case idle, running, finished
    }

    private(set) var state: State = .idle
    private(set) var remaining: TimeInterval = 0

    @ObservationIgnored var onFinish: (() -> Void)?
    @ObservationIgnored private var endDate: Date?
    @ObservationIgnored private var tickTask: Task<Void, Never>?
    @ObservationIgnored private let now: () -> Date
    @ObservationIgnored private let autoTick: Bool

    /// - Parameters:
    ///   - now: Uhr, in Tests austauschbar.
    ///   - autoTick: Bei `false` muss `tick()` manuell aufgerufen werden (Tests).
    init(now: @escaping () -> Date = Date.init, autoTick: Bool = true) {
        self.now = now
        self.autoTick = autoTick
    }

    var isLastMinute: Bool { state == .running && remaining <= 60 }

    var displayText: String { Self.format(remaining) }

    func start(duration: TimeInterval) {
        endDate = now().addingTimeInterval(duration)
        state = .running
        tick()
        startTicking()
    }

    /// Verlängert oder verkürzt die Restzeit. Nach Ablauf startet `+` einen neuen Countdown.
    func adjust(by seconds: TimeInterval) {
        switch state {
        case .idle:
            return
        case .finished:
            guard seconds > 0 else { return }
            start(duration: seconds)
        case .running:
            guard let endDate else { return }
            self.endDate = max(now(), endDate.addingTimeInterval(seconds))
            tick()
        }
    }

    func stop() {
        tickTask?.cancel()
        tickTask = nil
        endDate = nil
        remaining = 0
        state = .idle
    }

    func tick() {
        guard state == .running, let endDate else { return }
        remaining = max(0, endDate.timeIntervalSince(now()))
        if remaining <= 0 {
            state = .finished
            tickTask?.cancel()
            tickTask = nil
            onFinish?()
        }
    }

    private func startTicking() {
        guard autoTick else { return }
        tickTask?.cancel()
        tickTask = Task { [weak self] in
            while !Task.isCancelled {
                try? await Task.sleep(for: .milliseconds(200))
                guard let self else { return }
                self.tick()
            }
        }
    }

    // MARK: - Formatierung & Eingabe

    /// `MM:SS`, ab einer Stunde `H:MM:SS`. Es wird aufgerundet, damit `00:00` erst bei Ablauf erscheint.
    static func format(_ interval: TimeInterval) -> String {
        let total = max(0, Int(interval.rounded(.up)))
        let hours = total / 3600
        let minutes = (total % 3600) / 60
        let seconds = total % 60
        if hours > 0 {
            return String(format: "%d:%02d:%02d", hours, minutes, seconds)
        }
        return String(format: "%02d:%02d", minutes, seconds)
    }

    /// Akzeptiert Minuten (`10`, `7,5`, `7.5`) oder `MM:SS` (`7:30`). Maximal 24 Stunden.
    static func parseDuration(_ input: String) -> TimeInterval? {
        let text = input.trimmingCharacters(in: .whitespaces).replacingOccurrences(of: ",", with: ".")
        let parts = text.split(separator: ":", omittingEmptySubsequences: false)
        let seconds: TimeInterval
        switch parts.count {
        case 1:
            guard let minutes = Double(text), minutes.isFinite else { return nil }
            seconds = (minutes * 60).rounded()
        case 2:
            guard let minutes = Int(parts[0]), let secs = Int(parts[1]),
                  minutes >= 0, (0..<60).contains(secs) else { return nil }
            seconds = TimeInterval(minutes * 60 + secs)
        default:
            return nil
        }
        guard seconds > 0, seconds <= 24 * 3600 else { return nil }
        return seconds
    }
}
