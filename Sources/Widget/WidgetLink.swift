import Foundation

enum FLIPWidgetLink {
    static let url = URL(string: "flip-clock://open/clock")!
    static func accepts(_ url: URL) -> Bool {
        url.scheme?.lowercased() == "flip-clock" && url.host?.lowercased() == "open" && url.path == "/clock"
    }
}
