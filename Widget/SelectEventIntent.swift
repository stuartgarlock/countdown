import AppIntents
import WidgetKit

/// Lets a widget be pinned to one event. Left empty, it follows whatever is next.
struct SelectEventIntent: WidgetConfigurationIntent {
    static var title: LocalizedStringResource = "Choose Event"
    static var description = IntentDescription("Show one countdown, or leave it empty to always show what’s coming up next.")

    @Parameter(title: "Event")
    var event: EventEntity?
}

struct EventEntity: AppEntity {
    static var typeDisplayRepresentation: TypeDisplayRepresentation = "Event"
    static var defaultQuery = EventQuery()

    let id: UUID
    let title: String
    let emoji: String

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: "\(emoji) \(title)")
    }

    init(_ event: CountdownEvent) {
        id = event.id
        title = event.displayTitle
        emoji = event.displayEmoji
    }
}

struct EventQuery: EntityQuery {
    func entities(for identifiers: [UUID]) async throws -> [EventEntity] {
        EventsFile.load().filter { identifiers.contains($0.id) }.map(EventEntity.init)
    }

    func suggestedEntities() async throws -> [EventEntity] {
        let groups = EventsFile.load().partitioned(now: .now, calendar: .countdown)
        return (groups.upcoming + groups.past).map(EventEntity.init)
    }
}
