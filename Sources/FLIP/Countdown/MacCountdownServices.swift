import AppKit
import UserNotifications

@MainActor final class MacCountdownNotificationClient: NSObject, CountdownNotificationClient, UNUserNotificationCenterDelegate {
    static let identifier = "flip.countdown.finished"
    private let center = UNUserNotificationCenter.current()
    var onForegroundDelivery: (() -> Void)?
    override init() { super.init(); center.delegate = self }
    func isAuthorized() async -> Bool {
        let status = await center.notificationSettings().authorizationStatus
        return status == .authorized || status == .provisional
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
        let rounded = Date(timeIntervalSince1970: ceil(deadline.timeIntervalSince1970))
        var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second, .timeZone], from: rounded)
        components.calendar = calendar
        try await center.add(UNNotificationRequest(identifier: Self.identifier, content: content,
                                                  trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)))
    }
    nonisolated func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification,
                                           withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        Task { @MainActor [weak self] in
            if !NSApp.isHidden && NSApp.windows.contains(where: { $0.isVisible && !$0.isMiniaturized && $0.occlusionState.contains(.visible) }) {
                completionHandler([])
                self?.onForegroundDelivery?()
            } else { completionHandler([.banner, .sound]) }
        }
    }
}

extension CountdownController {
    static func macLive() -> CountdownController {
        let persistence = CountdownPersistence(namespace: "macos.countdown")
        let client = MacCountdownNotificationClient()
        let notices = CountdownNotifications(client: client, enabled: persistence.notificationsEnabled,
                                              saveEnabled: persistence.saveNotificationsEnabled,
                                              deniedMessage: "Sin permiso no habrá aviso del sistema cuando FLIP esté oculta o cerrada. El temporizador sigue funcionando; permite las notificaciones en Ajustes del Sistema.",
                                              failureMessage: "macOS no pudo programar el aviso. La cuenta atrás continúa y mostrará el resultado al volver a FLIP.")
        let controller = CountdownController(state: persistence.load(), notifications: notices, persist: persistence.save,
                                             feedback: {
            if notices.enabled && notices.message == nil && !NSApp.isActive { return }
            MacCountdownAlarm.play()
        },
                                             resumeFeedback: { !notices.enabled || notices.message != nil })
        client.onForegroundDelivery = { [weak controller] in controller?.refresh() }
        return controller
    }
}

@MainActor private enum MacCountdownAlarm {
    static var sound: NSSound?
    static func play() {
        guard let url = Bundle.main.url(forResource: "CountdownAlarm", withExtension: "wav"),
              let alarm = NSSound(contentsOf: url, byReference: false) else { NSSound.beep(); return }
        sound?.stop()
        sound = alarm
        alarm.volume = 1
        alarm.play()
    }
}
