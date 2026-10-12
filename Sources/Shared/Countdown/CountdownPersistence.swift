import Foundation

/// Separate namespaces keep macOS and iOS countdowns independent; existing keys retain their format.
@MainActor final class CountdownPersistence {
    private let defaults: UserDefaults
    private let namespace: String
    init(defaults: UserDefaults = .standard, namespace: String) { self.defaults = defaults; self.namespace = namespace }
    func load() -> CountdownState {
        defaults.data(forKey: namespace + ".state").flatMap { try? JSONDecoder().decode(CountdownState.self, from: $0) } ?? CountdownState()
    }
    func save(_ state: CountdownState) {
        if let data = try? JSONEncoder().encode(state) { defaults.set(data, forKey: namespace + ".state") }
    }
    var notificationsEnabled: Bool { defaults.bool(forKey: namespace + ".notifications") }
    func saveNotificationsEnabled(_ value: Bool) { defaults.set(value, forKey: namespace + ".notifications") }
}
