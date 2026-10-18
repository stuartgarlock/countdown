import Foundation

/// The saved list, as one JSON file in the App Group container so the app and the widget read the
/// same thing. A few dozen events is a few kilobytes; a database would be ceremony.
enum EventsFile {
    static let appGroup = "group.llc.smggroup.countdown"

    static var directory: URL {
        if let shared = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroup) {
            return shared
        }
        // No group container (an unsigned test run): keep working rather than lose the data.
        return FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
    }

    static var url: URL { directory.appendingPathComponent("events.json") }

    static func load() -> [CountdownEvent] {
        guard let data = try? Data(contentsOf: url) else { return [] }
        return (try? CountdownEvent.decoder.decode([CountdownEvent].self, from: data)) ?? []
    }

    static func save(_ events: [CountdownEvent]) throws {
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        try CountdownEvent.encoder.encode(events).write(to: url, options: .atomic)
    }
}
