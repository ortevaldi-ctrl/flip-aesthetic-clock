import UIKit
import UserNotifications
import AudioToolbox
import AVFoundation

@MainActor final class IOSCountdownNotificationClient: NSObject, CountdownNotificationClient, UNUserNotificationCenterDelegate {
    static let identifier = "flip.countdown.finished"
    private let center = UNUserNotificationCenter.current()
    var onForegroundDelivery: (() -> Void)?
    override init() { super.init(); center.delegate = self }
    func isAuthorized() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional || status == .ephemeral
    }
    func requestPermission() async -> Bool {
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .notDetermined {
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        }
        return await isAuthorized()
    }
    func cancel() {
        center.removePendingNotificationRequests(withIdentifiers: [Self.identifier])
        center.removeDeliveredNotifications(withIdentifiers: [Self.identifier])
    }
    func schedule(deadline: Date) async throws {
        guard deadline > Date() else { return }
        let content = UNMutableNotificationContent()
        content.title = "FLIP — Tiempo terminado"
        content.body = "Tu temporizador ha llegado a cero."
        content.sound = UNNotificationSound(named: UNNotificationSoundName("CountdownAlarm.wav"))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(secondsFromGMT: 0)!
        let roundedDeadline = Date(timeIntervalSince1970: ceil(deadline.timeIntervalSince1970))
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: roundedDeadline)
        components.calendar = calendar
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        try await center.add(UNNotificationRequest(identifier: Self.identifier, content: content, trigger: trigger))
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                           withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        // The controller provides a single foreground sound/haptic. Suppress a duplicate system sound.
        Task { @MainActor [weak self] in
            if UIApplication.shared.applicationState == .active {
                completionHandler([])
                self?.onForegroundDelivery?()
            } else {
                completionHandler([.banner, .sound])
            }
        }
    }
}

extension CountdownController {
    static func live() -> CountdownController {
        let defaults = UserDefaults.standard
        let persistence = CountdownPersistence(defaults: defaults, namespace: "ios.countdown")
        let client = IOSCountdownNotificationClient()
        let notifications = CountdownNotifications(client: client, enabled: persistence.notificationsEnabled,
                                                     saveEnabled: persistence.saveNotificationsEnabled)
        let controller = CountdownController(state: persistence.load(), notifications: notifications, persist: persistence.save, feedback: {
            IOSCountdownAlarm.play()
            UINotificationFeedbackGenerator().notificationOccurred(.success)
            UIAccessibility.post(notification: .announcement, argument: "Tiempo terminado")
        })
        client.onForegroundDelivery = { [weak controller] in controller?.refresh() }
        return controller
    }
}

@MainActor private final class IOSCountdownAlarm: NSObject, AVAudioPlayerDelegate {
    static let shared = IOSCountdownAlarm()
    private var player: AVAudioPlayer?
    static func play() { shared.playAlarm() }
    private func playAlarm() {
        do {
            guard let url = Bundle.main.url(forResource: "CountdownAlarm", withExtension: "wav") else { return }
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.playback, options: [.mixWithOthers])
            try session.setActive(true)
            player = try AVAudioPlayer(contentsOf: url)
            player?.delegate = self
            player?.volume = 1
            player?.play()
        } catch { AudioServicesPlayAlertSound(1005) }
    }
    nonisolated func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        Task { @MainActor in
            self.player = nil
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
        }
    }
}
