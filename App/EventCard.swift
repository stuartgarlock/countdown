import SwiftUI

/// One event as a coloured card. The hero style is the next thing coming up; past events are
/// drained of colour so the eye skips them.
struct EventCard: View {
    enum Style { case hero, regular, past }

    let event: CountdownEvent
    let now: Date
    var style: Style = .regular

    private var isHero: Bool { style == .hero }

    var body: some View {
        let calendar = Calendar.countdown
        let status = event.status(from: now, calendar: calendar)
        let nth = event.anniversaryNumber(from: now, calendar: calendar)

        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .center, spacing: 14) {
                Text(event.displayEmoji)
                    .font(.system(size: isHero ? 40 : 30))
                    .frame(width: isHero ? 64 : 50, height: isHero ? 64 : 50)
                    .background(.white.opacity(0.18), in: RoundedRectangle(cornerRadius: 16, style: .continuous))

                VStack(alignment: .leading, spacing: 3) {
                    Text(event.displayTitle)
                        .font(isHero ? .title3.weight(.bold) : .headline)
                        .lineLimit(2)
                    Text(event.occurrenceText(from: now, calendar: calendar))
                        .font(.subheadline)
                        .opacity(0.85)
                        .lineLimit(1)
                    if let nth {
                        Text("\(nth.ordinalText) · since \(String(event.day.year))")
                            .font(.caption.weight(.bold))
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(.white.opacity(0.22), in: Capsule())
                            .padding(.top, 2)
                    }
                }

                Spacer(minLength: 8)

                DaysCounter(status: status, large: isHero)
            }

            if isHero {
                ProgressBar(value: event.progress(from: now, calendar: calendar))
            }
        }
        .padding(isHero ? 20 : 16)
        .foregroundStyle(.white)
        .background(event.theme.gradient, in: RoundedRectangle(cornerRadius: isHero ? 28 : 22, style: .continuous))
        .saturation(style == .past ? 0.2 : 1)
        .opacity(style == .past ? 0.75 : 1)
        .shadow(color: (event.theme.colors.last ?? .black).opacity(isHero ? 0.35 : 0.15), radius: isHero ? 16 : 6, y: 6)
        .contentShape(RoundedRectangle(cornerRadius: 22, style: .continuous))
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("\(event.displayTitle), \(event.phrase(from: now, calendar: calendar)), \(event.occurrenceText(from: now, calendar: calendar))")
    }
}

struct DaysCounter: View {
    let status: CountdownStatus
    var large = false

    var body: some View {
        VStack(alignment: .trailing, spacing: -2) {
            switch status {
            case .today:
                Text("Today")
                    .font(.system(size: large ? 32 : 24, weight: .heavy, design: .rounded))
            case .upcoming(let days):
                number(days)
                caption(days == 1 ? "day" : "days")
            case .past(let days):
                number(days)
                caption(days == 1 ? "day ago" : "days ago")
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.6)
    }

    private func number(_ value: Int) -> some View {
        Text(value.formatted())
            .font(.system(size: large ? 50 : 34, weight: .heavy, design: .rounded))
            .monospacedDigit()
            .contentTransition(.numericText())
    }

    private func caption(_ text: String) -> some View {
        Text(text)
            .font(.caption.weight(.semibold))
            .textCase(.uppercase)
            .opacity(0.85)
    }
}

struct ProgressBar: View {
    let value: Double

    var body: some View {
        GeometryReader { geo in
            ZStack(alignment: .leading) {
                Capsule().fill(.white.opacity(0.25))
                Capsule().fill(.white).frame(width: max(6, geo.size.width * value))
            }
        }
        .frame(height: 6)
        .accessibilityHidden(true)
    }
}

#Preview {
    let samples = CountdownEvent.samples()
    return VStack(spacing: 12) {
        EventCard(event: samples[0], now: .now, style: .hero)
        EventCard(event: samples[1], now: .now)
        EventCard(event: samples[4], now: .now, style: .past)
    }
    .padding()
}
