import Foundation
import Observation
import WidgetKit
import os

@MainActor
@Observable
final class EventStore {
    private(set) var events: [CountdownEvent]

    @ObservationIgnored
    private let log = Logger(subsystem: "llc.smggroup.countdown", category: "store")

    init() {
        events = EventsFile.load()
        #if DEBUG
        let args = ProcessInfo.processInfo.arguments
        if args.contains("-resetData") {
            events = []
            persist()
        }
        if args.contains("-seedSamples"), events.isEmpty {
            events = CountdownEvent.samples()
            persist()
        }
        #endif
    }

    func event(id: UUID) -> CountdownEvent? {
        events.first { $0.id == id }
    }

    func save(_ event: CountdownEvent) {
        if let i = events.firstIndex(where: { $0.id == event.id }) {
            events[i] = event
        } else {
            events.append(event)
        }
        persist()
    }

    func delete(id: UUID) {
        events.removeAll { $0.id == id }
        persist()
    }

    func refresh() {
        WidgetCenter.shared.reloadAllTimelines()
        rescheduleNotifications()
    }

    func rescheduleNotifications() {
        let snapshot = events
        Task { await NotificationScheduler.reschedule(snapshot) }
    }

    private func persist() {
        do {
            try EventsFile.save(events)
        } catch {
            log.error("Saving events failed: \(error.localizedDescription, privacy: .public)")
        }
        WidgetCenter.shared.reloadAllTimelines()
        rescheduleNotifications()
    }
}
