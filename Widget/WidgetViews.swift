import SwiftUI
import WidgetKit

struct CountdownWidgetView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CountdownEntry

    var body: some View {
        content
            .widgetURL(entry.event.flatMap { URL(string: "countdown://event/\($0.id.uuidString)") })
            .containerBackground(for: .widget) {
                if isAccessory {
                    Color.clear
                } else {
                    (entry.event?.theme ?? .slate).gradient
                }
            }
    }

    private var isAccessory: Bool {
        family == .accessoryCircular || family == .accessoryRectangular || family == .accessoryInline
    }

    @ViewBuilder
    private var content: some View {
        if let event = entry.event {
            switch family {
            case .accessoryCircular: CircularView(event: event, now: entry.date)
            case .accessoryRectangular: RectangularView(event: event, now: entry.date)
            case .accessoryInline: Text("\(event.displayEmoji) \(event.displayTitle) · \(event.shortPhrase(from: entry.date))")
            case .systemMedium: MediumView(event: event, following: entry.following, now: entry.date)
            default: SmallView(event: event, now: entry.date)
            }
        } else {
            EmptyWidgetView(accessory: isAccessory)
        }
    }
}

// MARK: - Home Screen

private struct SmallView: View {
    let event: CountdownEvent
    let now: Date

    var body: some View {
        let calendar = Calendar.countdown
        VStack(alignment: .leading, spacing: 0) {
            HStack(alignment: .top) {
                Text(event.displayEmoji).font(.title2)
                Spacer()
                if let nth = event.anniversaryNumber(from: now, calendar: calendar) {
                    Text(nth.ordinalText)
                        .font(.caption.weight(.bold))
                        .padding(.horizontal, 7)
                        .padding(.vertical, 2)
                        .background(.white.opacity(0.25), in: Capsule())
                }
            }
            Spacer(minLength: 0)
            BigCount(status: event.status(from: now, calendar: calendar), size: 50)
            Text(event.displayTitle)
                .font(.subheadline.weight(.semibold))
                .lineLimit(1)
                .padding(.top, 2)
        }
        .foregroundStyle(.white)
    }
}

private struct MediumView: View {
    let event: CountdownEvent
    let following: [CountdownEvent]
    let now: Date

    var body: some View {
        let calendar = Calendar.countdown
        HStack(alignment: .top, spacing: 16) {
            VStack(alignment: .leading, spacing: 0) {
                Text(event.displayEmoji).font(.title2)
                Spacer(minLength: 0)
                BigCount(status: event.status(from: now, calendar: calendar), size: 54)
                Text(event.displayTitle)
                    .font(.subheadline.weight(.semibold))
                    .lineLimit(1)
                Text(event.occurrenceText(from: now, calendar: calendar))
                    .font(.caption)
                    .opacity(0.85)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            if !following.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("THEN")
                        .font(.caption2.weight(.bold))
                        .opacity(0.75)
                    ForEach(following) { next in
                        HStack(spacing: 8) {
                            Text(next.displayEmoji)
                            VStack(alignment: .leading, spacing: 0) {
                                Text(next.displayTitle)
                                    .font(.caption.weight(.semibold))
                                    .lineLimit(1)
                                Text(next.phrase(from: now, calendar: calendar))
                                    .font(.caption2)
                                    .opacity(0.85)
                            }
                        }
                        .padding(8)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .foregroundStyle(.white)
    }
}

private struct BigCount: View {
    let status: CountdownStatus
    let size: CGFloat

    var body: some View {
        VStack(alignment: .leading, spacing: -4) {
            switch status {
            case .today:
                Text("Today")
                    .font(.system(size: size * 0.7, weight: .heavy, design: .rounded))
                Text("🎉 It’s here")
                    .font(.caption.weight(.semibold))
            case .upcoming(let days):
                Text(days.formatted())
                    .font(.system(size: size, weight: .heavy, design: .rounded))
                Text(days == 1 ? "DAY TO GO" : "DAYS TO GO")
                    .font(.caption2.weight(.bold))
                    .opacity(0.85)
            case .past(let days):
                Text(days.formatted())
                    .font(.system(size: size, weight: .heavy, design: .rounded))
                Text(days == 1 ? "DAY AGO" : "DAYS AGO")
                    .font(.caption2.weight(.bold))
                    .opacity(0.85)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.5)
        .monospacedDigit()
    }
}

// MARK: - Lock Screen

private struct CircularView: View {
    let event: CountdownEvent
    let now: Date

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            VStack(spacing: -2) {
                Text(event.displayEmoji).font(.system(size: 13))
                switch event.status(from: now, calendar: .countdown) {
                case .today:
                    Text("Today")
                        .font(.system(size: 13, weight: .bold, design: .rounded))
                case .upcoming(let days), .past(let days):
                    Text(days.formatted())
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .minimumScaleFactor(0.5)
                        .widgetAccentable()
                    Text("days")
                        .font(.system(size: 9, weight: .semibold))
                }
            }
            .lineLimit(1)
            .padding(4)
        }
    }
}

private struct RectangularView: View {
    let event: CountdownEvent
    let now: Date

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            Text("\(event.displayEmoji) \(event.displayTitle)")
                .font(.headline)
                .lineLimit(1)
            Text(event.phrase(from: now))
                .font(.system(.title3, design: .rounded).weight(.bold))
                .widgetAccentable()
                .lineLimit(1)
            Text(event.occurrenceText(from: now))
                .font(.caption)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

private struct EmptyWidgetView: View {
    let accessory: Bool

    var body: some View {
        if accessory {
            Text("⏳ Add an event")
                .font(.caption)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("⏳").font(.title)
                Spacer(minLength: 0)
                Text("Nothing to count down to")
                    .font(.subheadline.weight(.semibold))
                Text("Add an event in Countdown.")
                    .font(.caption)
                    .opacity(0.85)
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

#Preview(as: .systemSmall) {
    CountdownWidget()
} timeline: {
    let samples = CountdownEvent.samples()
    CountdownEntry(date: .now, event: samples[1], following: [])
    CountdownEntry(date: .now, event: samples[0], following: [])
}

#Preview(as: .systemMedium) {
    CountdownWidget()
} timeline: {
    let samples = CountdownEvent.samples()
    CountdownEntry(date: .now, event: samples[1], following: [samples[2], samples[0]])
}
