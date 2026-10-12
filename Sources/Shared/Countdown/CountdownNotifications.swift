import Foundation
import Combine

@MainActor protocol CountdownNotificationClient: AnyObject {
    func isAuthorized() async -> Bool
    func requestPermission() async -> Bool
    func cancel()
    func schedule(deadline: Date) async throws
}

/// Serial reconciliation prevents a late scheduling callback from restoring a paused/reset alarm.
@MainActor final class CountdownNotifications: ObservableObject {
    @Published private(set) var enabled: Bool
    @Published private(set) var message: String?
    @Published private(set) var requestingPermission = false
    private let client: CountdownNotificationClient
    private var deadline: Date?
    private var revision = 0
    private var permissionRevision = 0
    private var worker: Task<Void, Never>?
    private var permissionTask: Task<Void, Never>?
    private let now: () -> Date
    private let deniedMessage: String
    private let failureMessage: String
    private let saveEnabled: (Bool) -> Void

    init(client: CountdownNotificationClient, enabled: Bool = false, now: @escaping () -> Date = Date.init,
         saveEnabled: @escaping (Bool) -> Void = { _ in },
         deniedMessage: String = "Sin permiso, el aviso solo funciona con FLIP abierta. Activa las notificaciones de FLIP en Ajustes para recibirlo con el iPhone bloqueado.",
         failureMessage: String = "No se pudo programar el aviso. El temporizador continúa funcionando con FLIP abierta.") {
        self.client = client; self.enabled = enabled; self.now = now; self.saveEnabled = saveEnabled
        self.deniedMessage = deniedMessage; self.failureMessage = failureMessage
    }
    func setEnabled(_ value: Bool) {
        enabled = value; saveEnabled(value)
        permissionRevision += 1
        let token = permissionRevision
        requestingPermission = value
        message = nil
        reconcile()
        guard value else { requestingPermission = false; return }
        // This is the only path that asks permission: the user explicitly enables the option.
        permissionTask = Task { [weak self] in
            guard let self else { return }
            let authorized = await client.requestPermission()
            guard token == permissionRevision, enabled else { return }
            requestingPermission = false
            if !authorized { message = deniedMessage }
            reconcile()
        }
    }
    func update(deadline: Date?) { self.deadline = deadline; reconcile() }
    private func reconcile() {
        revision += 1
        client.cancel()
        guard worker == nil else { return }
        worker = Task { [weak self] in guard let self else { return }; await self.process() }
    }
    private func process() async {
        while true {
            let token = revision
            let target = deadline
            client.cancel()
            if enabled && !requestingPermission {
                let authorized = await client.isAuthorized()
                if token != revision { continue }
                if authorized {
                    message = nil
                    if let target, target > now() {
                        do { try await client.schedule(deadline: target) }
                        catch { if token == revision { message = failureMessage } }
                    }
                } else { message = deniedMessage }
            } else if !enabled { message = nil }
            // If schedule suspended while the user paused, this next pass removes the stale request.
            if token == revision { worker = nil; return }
        }
    }
    func waitUntilSettled() async {
        await permissionTask?.value
        while let worker { await worker.value }
    }
}
