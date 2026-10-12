import Foundation

@MainActor final class TestClock {
    var date = Date(timeIntervalSince1970: 1_800_000_000)
    func advance(_ seconds: TimeInterval) { date = date.addingTimeInterval(seconds) }
}
@MainActor final class FakeCountdownNotifications: CountdownNotificationClient {
    var authorized = true
    var permissionRequests = 0
    var pending: Date?
    var cancelCount = 0
    var blockNextSchedule = false
    private var gate: CheckedContinuation<Void, Never>?
    private var onStarted: CheckedContinuation<Void, Never>?
    private var started = false
    func isAuthorized() async -> Bool { await Task.yield(); return authorized }
    func requestPermission() async -> Bool { permissionRequests += 1; return authorized }
    func cancel() { cancelCount += 1; pending = nil }
    func schedule(deadline: Date) async throws {
        if blockNextSchedule {
            blockNextSchedule = false
            await withCheckedContinuation { continuation in
                gate = continuation; started = true; onStarted?.resume(); onStarted = nil
            }
        }
        pending = deadline
    }
    func waitForBlockedSchedule() async {
        if started { return }
        await withCheckedContinuation { onStarted = $0 }
    }
    func finishBlockedSchedule() { gate?.resume(); gate = nil }
}

final class CountdownMemoryDefaults: UserDefaults, @unchecked Sendable {
    var values: [String: Any] = [:]
    override func data(forKey key: String) -> Data? { values[key] as? Data }
    override func bool(forKey key: String) -> Bool { values[key] as? Bool ?? false }
    override func set(_ value: Any?, forKey key: String) { values[key] = value }
}

@main struct CountdownChecks {
    @MainActor static func main() async throws {
        let clock = TestClock()
        var state = CountdownState()
        state.configure(seconds: 3723); state.start(at: clock.date)
        precondition(state.values(at: clock.date) == ["01", "02", "03"])
        clock.advance(62.5)
        precondition(state.values(at: clock.date) == ["01", "01", "01"])
        state.pause(at: clock.date)
        let fraction = state.remaining(at: clock.date)
        precondition(fraction == 3660.5)
        clock.advance(86400)
        precondition(state.remaining(at: clock.date) == fraction)
        state.resume(at: clock.date)
        precondition(state.deadline == clock.date.addingTimeInterval(fraction))
        clock.advance(fraction)
        precondition(state.refresh(at: clock.date))
        precondition(!state.refresh(at: clock.date) && state.values(at: clock.date) == ["00", "00", "00"])
        state.reset()
        precondition(state.phase == .idle && state.remaining(at: clock.date) == 3723)
        state.configure(seconds: 0); state.start(at: clock.date)
        precondition(state.phase == .idle)
        state.configure(seconds: .infinity)
        precondition(state.duration == 0)
        state.configure(seconds: CountdownState.maximumDuration)
        precondition(state.values(at: clock.date) == ["99", "59", "59"])
        state.start(at: clock.date)
        let restored = try JSONDecoder().decode(CountdownState.self, from: JSONEncoder().encode(state))
        precondition(restored == state)
        print("PASS: HH/MM/SS, zero duration, fractional pause, long pause, resume deadline, exact completion, reset and persisted deadline")

        let client = FakeCountdownNotifications()
        let notifications = CountdownNotifications(client: client, now: { clock.date })
        var feedbackCount = 0
        var saved: CountdownState?
        let controller = CountdownController(notifications: notifications, now: { clock.date }, persist: { saved = $0 }, feedback: { feedbackCount += 1 })
        controller.setActive(true)
        controller.configure(hours: 0, minutes: 0, seconds: 10)
        controller.start()
        await notifications.waitUntilSettled()
        precondition(client.permissionRequests == 0 && client.pending == nil)
        notifications.setEnabled(true)
        await notifications.waitUntilSettled()
        precondition(client.permissionRequests == 1 && client.pending == controller.state.deadline)
        clock.advance(2.25); controller.pause()
        await notifications.waitUntilSettled()
        precondition(controller.state.phase == .paused && controller.displayedSeconds == 8 && client.pending == nil)
        clock.advance(100); controller.resume()
        await notifications.waitUntilSettled()
        precondition(client.pending == clock.date.addingTimeInterval(7.75))
        controller.reset(); await notifications.waitUntilSettled()
        precondition(client.pending == nil && controller.displayedSeconds == 10)
        controller.start(); clock.advance(10); controller.refresh(); controller.refresh()
        await notifications.waitUntilSettled()
        precondition(feedbackCount == 1 && controller.state.phase == .finished && client.pending == nil && saved?.phase == .finished)
        print("PASS: no automatic permission prompt, explicit permission, pause cancellation, resume rescheduling, reset cancellation and one foreground completion alert")

        controller.reset(); controller.start(); controller.setActive(false)
        clock.advance(3); controller.setActive(true)
        precondition(controller.displayedSeconds == 7 && controller.state.phase == .running)
        controller.setActive(false); clock.advance(20); controller.setActive(true)
        await notifications.waitUntilSettled()
        precondition(controller.state.phase == .finished && controller.displayedSeconds == 0 && feedbackCount == 1)
        precondition(client.pending == nil)
        print("PASS: background return before deadline, expiry while locked, no replayed foreground alert and stale notification cleanup")

        controller.reset(); controller.start()
        await notifications.waitUntilSettled()
        let boundaryDeadline = client.pending
        clock.advance(10); controller.setActive(false)
        precondition(boundaryDeadline != nil && client.pending == boundaryDeadline)
        controller.setActive(true); await notifications.waitUntilSettled()
        precondition(controller.state.phase == .finished && client.pending == nil && feedbackCount == 1)
        print("PASS: locking exactly at expiry preserves the scheduled system alarm until foreground reconciliation")

        let denied = FakeCountdownNotifications(); denied.authorized = false
        let deniedNotifications = CountdownNotifications(client: denied, now: { clock.date })
        let deniedController = CountdownController(notifications: deniedNotifications, now: { clock.date })
        deniedNotifications.setEnabled(true)
        deniedController.configure(hours: 0, minutes: 0, seconds: 5); deniedController.start()
        await deniedNotifications.waitUntilSettled()
        precondition(deniedController.state.phase == .running && denied.pending == nil && deniedNotifications.message != nil)
        deniedNotifications.setEnabled(false); await deniedNotifications.waitUntilSettled()
        precondition(deniedNotifications.message == nil && denied.pending == nil)
        print("PASS: permission denied keeps countdown running, brief limitation message and option-off cancellation")

        let raceClient = FakeCountdownNotifications(); raceClient.blockNextSchedule = true
        let race = CountdownNotifications(client: raceClient, enabled: true, now: { clock.date })
        race.update(deadline: clock.date.addingTimeInterval(60))
        await raceClient.waitForBlockedSchedule()
        race.update(deadline: nil)
        raceClient.finishBlockedSchedule()
        await race.waitUntilSettled()
        precondition(raceClient.pending == nil && raceClient.permissionRequests == 0)
        raceClient.blockNextSchedule = true
        // A fresh fake permits another controlled in-flight scheduling race.
        let replacementClient = FakeCountdownNotifications(); replacementClient.blockNextSchedule = true
        let replacement = CountdownNotifications(client: replacementClient, enabled: true, now: { clock.date })
        replacement.update(deadline: clock.date.addingTimeInterval(10))
        await replacementClient.waitForBlockedSchedule()
        let latestDeadline = clock.date.addingTimeInterval(120)
        replacement.update(deadline: latestDeadline)
        replacementClient.finishBlockedSchedule()
        await replacement.waitUntilSettled()
        precondition(replacementClient.pending == latestDeadline)
        print("PASS: late scheduling cannot resurrect a cancelled notification or overwrite a newer resumed deadline")

        let defaults = CountdownMemoryDefaults()
        defaults.values["style"] = "Frosted Glass"
        defaults.values["favorites"] = ["Night City"]
        let iosPersistence = CountdownPersistence(defaults: defaults, namespace: "ios.countdown")
        let macPersistence = CountdownPersistence(defaults: defaults, namespace: "macos.countdown")
        iosPersistence.save(state); iosPersistence.saveNotificationsEnabled(true)
        precondition(iosPersistence.load() == state && iosPersistence.notificationsEnabled)
        precondition(macPersistence.load().phase == .idle && !macPersistence.notificationsEnabled)
        var pausedState = state; pausedState.pause(at: clock.date)
        macPersistence.save(pausedState)
        precondition(macPersistence.load() == pausedState && iosPersistence.load() == state)
        precondition(defaults.values["style"] as? String == "Frosted Glass")
        precondition(defaults.values["favorites"] as? [String] == ["Night City"])
        print("PASS: shared persistence reads existing iOS keys, isolates macOS data and preserves clock preferences/favorites")

    }
}
