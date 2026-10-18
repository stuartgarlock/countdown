import SwiftUI

struct EventDetailView: View {
    let eventID: UUID

    @Environment(EventStore.self) private var store
    @Environment(\.dismiss) private var dismiss
    @State private var editor: EditorTarget?

    var body: some View {
        Group {
            if let event = store.event(id: eventID) {
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    EventDetailContent(event: event, now: context.date)
                }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        Button("Edit") { editor = .existing(event) }
                    }
                }
            } else {
                ContentUnavailableView("Event deleted", systemImage: "calendar.badge.minus")
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.hidden, for: .navigationBar)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(item: $editor) { EventEditorView(target: $0) }
        .onChange(of: store.event(id: eventID) == nil) { _, gone in
            if gone { dismiss() }
        }
    }
}

private struct EventDetailContent: View {
    let event: CountdownEvent
    let now: Date

    private let calendar = Calendar.countdown

    var body: some View {
        let status = event.status(from: now, calendar: calendar)
        let nth = event.anniversaryNumber(from: now, calendar: calendar)

        ScrollView {
            VStack(spacing: 30) {
                VStack(spacing: 10) {
                    Text(event.displayEmoji)
                        .font(.system(size: 76))
                    Text(event.displayTitle)
                        .font(.largeTitle.bold())
                        .multilineTextAlignment(.center)
                    Text(event.occurrenceText(from: now, calendar: calendar))
                        .font(.headline)
                        .opacity(0.85)
                    if let nth {
                        Text("The \(nth.ordinalText)")
                            .font(.subheadline.weight(.bold))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 5)
                            .background(.white.opacity(0.22), in: Capsule())
                    }
                }

                headline(status, nth: nth)

                if let remaining = event.preciseRemaining(from: now, calendar: calendar) {
                    Ticker(remaining: remaining)
                }

                if case .past = status {} else {
                    progressCard
                }

                if event.repeatsYearly, let since = event.daysSinceOrigin(from: now, calendar: calendar) {
                    sinceCard(days: since)
                }

                if !event.notes.isEmpty {
                    card {
                        Text(event.notes)
                            .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 32)
            .frame(maxWidth: 600)
            .frame(maxWidth: .infinity)
        }
        .foregroundStyle(.white)
        .background(event.theme.gradient.ignoresSafeArea())
    }

    @ViewBuilder
    private func headline(_ status: CountdownStatus, nth: Int?) -> some View {
        VStack(spacing: 0) {
            switch status {
            case .today:
                Text("Today")
                    .font(.system(size: 88, weight: .heavy, design: .rounded))
                Text(nth.map { "It’s the \($0.ordinalText). Enjoy it." } ?? "Enjoy it.")
                    .font(.title3.weight(.semibold))
            case .upcoming(let days):
                bigNumber(days)
                Text(days == 1 ? "day to go" : "days to go")
                    .font(.title3.weight(.semibold))
                    .opacity(0.9)
            case .past(let days):
                bigNumber(days)
                Text(days == 1 ? "day ago" : "days ago")
                    .font(.title3.weight(.semibold))
                    .opacity(0.9)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.4)
    }

    private func bigNumber(_ value: Int) -> some View {
        Text(value.formatted())
            .font(.system(size: 120, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
    }

    private var progressCard: some View {
        let value = event.progress(from: now, calendar: calendar)
        return card {
            VStack(alignment: .leading, spacing: 10) {
                HStack {
                    Text(event.repeatsYearly ? "Through the year" : "Since you added it")
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(value.formatted(.percent.precision(.fractionLength(0))))
                        .font(.subheadline.weight(.bold))
                        .monospacedDigit()
                }
                ProgressBar(value: value)
            }
        }
    }

    private func sinceCard(days: Int) -> some View {
        let origin = event.origin(calendar: calendar)
        let span = calendar.dateComponents([.year, .month, .day], from: origin, to: calendar.startOfDay(for: now))
        let parts = [
            span.year.flatMap { $0 > 0 ? "\($0) \($0 == 1 ? "year" : "years")" : nil },
            span.month.flatMap { $0 > 0 ? "\($0) \($0 == 1 ? "month" : "months")" : nil },
            span.day.flatMap { $0 > 0 ? "\($0) \($0 == 1 ? "day" : "days")" : nil },
        ].compactMap { $0 }

        return card {
            VStack(alignment: .leading, spacing: 4) {
                Text("\(days.formatted()) days")
                    .font(.title2.weight(.heavy))
                    .monospacedDigit()
                Text("since \(origin.formatted(date: .long, time: .omitted))")
                    .font(.subheadline.weight(.semibold))
                if !parts.isEmpty {
                    Text(ListFormatter.localizedString(byJoining: parts))
                        .font(.subheadline)
                        .opacity(0.85)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func card<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(18)
            .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

/// Days, hours, minutes and seconds to the start, ticking.
private struct Ticker: View {
    let remaining: DateComponents

    var body: some View {
        HStack(spacing: 10) {
            unit(remaining.day ?? 0, "days")
            unit(remaining.hour ?? 0, "hrs")
            unit(remaining.minute ?? 0, "min")
            unit(remaining.second ?? 0, "sec")
        }
    }

    private func unit(_ value: Int, _ label: String) -> some View {
        VStack(spacing: 2) {
            Text(label == "days" ? value.formatted() : String(format: "%02d", value))
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .monospacedDigit()
                .contentTransition(.numericText())
                .lineLimit(1)
                .minimumScaleFactor(0.5)
            Text(label)
                .font(.caption2.weight(.semibold))
                .textCase(.uppercase)
                .opacity(0.8)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.white.opacity(0.16), in: RoundedRectangle(cornerRadius: 14, style: .continuous))
    }
}

#Preview {
    NavigationStack {
        EventDetailContent(event: CountdownEvent.samples()[0], now: .now)
    }
}
