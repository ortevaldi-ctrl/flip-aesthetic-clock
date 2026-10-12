import Foundation

/// Wall time is the source of truth. Timers only ask for fresh projections of this state.
struct CountdownState: Codable, Equatable {
    enum Phase: String, Codable { case idle, running, paused, finished }
    private(set) var phase: Phase = .idle
    private(set) var duration: TimeInterval = 300
    private(set) var deadline: Date?
    private(set) var pausedRemaining: TimeInterval = 0
    static let maximumDuration: TimeInterval = 99 * 3600 + 59 * 60 + 59

    mutating func configure(seconds: TimeInterval) {
        guard phase == .idle || phase == .finished else { return }
        duration = seconds.isFinite ? min(Self.maximumDuration, max(0, seconds)) : 0
        phase = .idle; deadline = nil; pausedRemaining = 0
    }
    mutating func start(at now: Date) {
        guard phase == .idle, duration > 0 else { return }
        deadline = now.addingTimeInterval(duration)
        phase = .running
    }
    @discardableResult mutating func refresh(at now: Date) -> Bool {
        guard phase == .running, let deadline, now >= deadline else { return false }
        phase = .finished; self.deadline = nil; pausedRemaining = 0
        return true
    }
    mutating func pause(at now: Date) {
        guard phase == .running else { return }
        if refresh(at: now) { return }
        pausedRemaining = remaining(at: now)
        phase = .paused; deadline = nil
    }
    mutating func resume(at now: Date) {
        guard phase == .paused, pausedRemaining > 0 else { return }
        deadline = now.addingTimeInterval(pausedRemaining)
        pausedRemaining = 0; phase = .running
    }
    mutating func reset() { phase = .idle; deadline = nil; pausedRemaining = 0 }
    func remaining(at now: Date) -> TimeInterval {
        switch phase {
        case .idle: return duration
        case .paused: return pausedRemaining
        case .finished: return 0
        case .running: return max(0, deadline?.timeIntervalSince(now) ?? 0)
        }
    }
    func displaySeconds(at now: Date) -> Int { Int(ceil(remaining(at: now))) }
    func values(at now: Date) -> [String] {
        let seconds = displaySeconds(at: now)
        return [seconds / 3600, seconds / 60 % 60, seconds % 60].map { String(format: "%02d", $0) }
    }
}
