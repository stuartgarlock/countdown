import Foundation

extension CountdownEvent {
    var displayTitle: String { title.isEmpty ? "Untitled" : title }
    var displayEmoji: String { emoji.isEmpty ? "🎉" : emoji }

    /// "Sat, Nov 15", plus the year when it is not this year and the time for timed events.
    func occurrenceText(from now: Date, calendar: Calendar = .countdown) -> String {
        let date = nextOccurrence(from: now, calendar: calendar)
        var style = Date.FormatStyle.dateTime.weekday(.abbreviated).month(.abbreviated).day()
        if calendar.component(.year, from: date) != calendar.component(.year, from: now) { style = style.year() }
        if time != nil { style = style.hour().minute() }
        return date.formatted(style)
    }

    /// "in 43 days", "Tomorrow", "Today", "10 days ago".
    func phrase(from now: Date, calendar: Calendar = .countdown) -> String {
        switch status(from: now, calendar: calendar) {
        case .today: "Today"
        case .upcoming(1): "Tomorrow"
        case .upcoming(let days): "in \(days.formatted()) days"
        case .past(1): "Yesterday"
        case .past(let days): "\(days.formatted()) days ago"
        }
    }

    /// The tightest form, for the inline Lock Screen widget: "43d", "Today".
    func shortPhrase(from now: Date, calendar: Calendar = .countdown) -> String {
        switch status(from: now, calendar: calendar) {
        case .today: "Today"
        case .upcoming(let days): "\(days.formatted())d"
        case .past(let days): "\(days.formatted())d ago"
        }
    }
}
