import SwiftUI

@MainActor final class FavoritesStore: ObservableObject {
    @Published private(set) var names: Set<String>
    private let defaults: UserDefaults
    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        if let array = defaults.array(forKey: "favorites") as? [String] {
            names = Set(array)
        } else if let string = defaults.string(forKey: "favorites"), let data = string.data(using: .utf8), let array = try? JSONDecoder().decode([String].self, from: data) {
            names = Set(array)
        } else { names = [] }
    }
    func contains(_ style: ClockStyle) -> Bool { names.contains(style.rawValue) }
    func toggle(_ style: ClockStyle) {
        if !names.insert(style.rawValue).inserted { names.remove(style.rawValue) }
        defaults.set(names.sorted(), forKey: "favorites")
    }
}
