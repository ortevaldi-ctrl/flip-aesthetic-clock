import Foundation
import Combine

@MainActor final class CountdownController: ObservableObject {
    @Published private(set) var state: CountdownState
    @Published private(set) var displayedSeconds: Int
    let notifications: CountdownNotifications
    private let now: () -> Date
    private let persist: (CountdownState) -> Void
    private let resumeFeedback: () -> Bool
    private let feedback: () -> Void
    private var timer: Timer?
    private var active = false

    init(state: CountdownState = CountdownState(), notifications: CountdownNotifications,
         now: @escaping () -> Date = Date.init, persist: @escaping (CountdownState) -> Void = { _ in },
         feedback: @escaping () -> Void = {}, resumeFeedback: @escaping () -> Bool = { false }) {
        self.state = state; self.notifications = notifications; self.now = now
        self.persist = persist; self.feedback = feedback; self.resumeFeedback = resumeFeedback
        displayedSeconds = state.displaySeconds(at: now())
    }
    deinit { timer?.invalidate() }
    var values: [String] {
        [displayedSeconds / 3600, displayedSeconds / 60 % 60, displayedSeconds % 60].map { String(format: "%02d", $0) }
    }
    func configure(hours: Int, minutes: Int, seconds: Int) {
        state.configure(seconds: Double(hours * 3600 + minutes * 60 + seconds)); changed()
    }
    func start() { state.start(at: now()); changed() }
    func pause() {
        let instant = now()
        refresh(at: instant, allowFeedback: true)
        state.pause(at: instant); changed()
    }
    func resume() { state.resume(at: now()); changed() }
    func reset() { state.reset(); changed() }
    func setActive(_ value: Bool) {
        let wasActive = active
        active = value
        if !value {
            // Leave the already scheduled system notice intact when locking at the deadline.
            timer?.invalidate(); timer = nil
            return
        }
        // Expiry while locked is represented visually on return, without replaying the background alert.
        refresh(allowFeedback: wasActive || resumeFeedback())
        notifications.update(deadline: state.deadline)
        scheduleTick()
    }
    func refresh(allowFeedback: Bool = true) { refresh(at: now(), allowFeedback: allowFeedback) }
    private func refresh(at instant: Date, allowFeedback: Bool) {
        let finished = state.refresh(at: instant)
        let seconds = state.displaySeconds(at: instant)
        if displayedSeconds != seconds { displayedSeconds = seconds }
        if finished {
            persist(state); timer?.invalidate()
            notifications.update(deadline: nil)
            if active && allowFeedback { feedback() }
        }
    }
    private func changed() {
        displayedSeconds = state.displaySeconds(at: now())
        persist(state)
        notifications.update(deadline: state.deadline)
        scheduleTick()
    }
    private func scheduleTick() {
        timer?.invalidate(); timer = nil
        guard active, state.phase == .running, let deadline = state.deadline else { return }
        let remaining = max(0, deadline.timeIntervalSince(now()))
        let fraction = remaining - floor(remaining)
        let delay = min(1, remaining, fraction > 0.001 ? fraction + 0.002 : 1)
        let next = Timer(timeInterval: max(0.01, delay), repeats: false) { [weak self] _ in
            MainActor.assumeIsolated { self?.refresh(); self?.scheduleTick() }
        }
        RunLoop.main.add(next, forMode: .common); timer = next
    }
}
