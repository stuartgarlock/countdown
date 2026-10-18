import SwiftUI
import WidgetKit

@main
struct CountdownWidgetBundle: WidgetBundle {
    var body: some Widget {
        CountdownWidget()
    }
}

struct CountdownWidget: Widget {
    var body: some WidgetConfiguration {
        AppIntentConfiguration(kind: "CountdownWidget", intent: SelectEventIntent.self, provider: CountdownProvider()) { entry in
            CountdownWidgetView(entry: entry)
        }
        .configurationDisplayName("Countdown")
        .description("Days until your next big day, or one you choose.")
        .supportedFamilies([.systemSmall, .systemMedium, .accessoryCircular, .accessoryRectangular, .accessoryInline])
    }
}

struct CountdownEntry: TimelineEntry {
    let date: Date
    let event: CountdownEvent?
    let following: [CountdownEvent]
}

struct CountdownProvider: AppIntentTimelineProvider {
    func placeholder(in context: Context) -> CountdownEntry {
        let samples = CountdownEvent.samples()
        return entry(at: .now, events: samples, selected: nil)
    }

    func snapshot(for configuration: SelectEventIntent, in context: Context) async -> CountdownEntry {
        let events = EventsFile.load()
        // The widget gallery shows a real example rather than an empty card.
        if events.isEmpty && context.isPreview { return placeholder(in: context) }
        return entry(at: .now, events: events, selected: configuration.event?.id)
    }

    /// The count only changes at midnight, so the timeline is one entry now and one at each of
    /// the next seven midnights. The app reloads it whenever the list changes.
    func timeline(for configuration: SelectEventIntent, in context: Context) async -> Timeline<CountdownEntry> {
        let events = EventsFile.load()
        let calendar = Calendar.countdown
        var dates = [Date.now]
        var midnight = calendar.startOfDay(for: .now)
        for _ in 0..<7 {
            guard let next = calendar.date(byAdding: .day, value: 1, to: midnight) else { break }
            midnight = next
            dates.append(next)
        }
        let entries = dates.map { entry(at: $0, events: events, selected: configuration.event?.id) }
        return Timeline(entries: entries, policy: .atEnd)
    }

    private func entry(at date: Date, events: [CountdownEvent], selected: UUID?) -> CountdownEntry {
        let groups = events.partitioned(now: date, calendar: .countdown)
        // A pinned event that has since been deleted falls back to "next" rather than going blank.
        let chosen = selected.flatMap { id in events.first { $0.id == id } } ?? groups.upcoming.first
        let following = groups.upcoming.filter { $0.id != chosen?.id }.prefix(2)
        return CountdownEntry(date: date, event: chosen, following: Array(following))
    }
}
