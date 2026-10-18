import Foundation

extension CountdownEvent {
    /// Example events dated relative to today, for previews, the widget gallery and the
    /// `-seedSamples` launch argument.
    static func samples(now: Date = .now, calendar: Calendar = .countdown) -> [CountdownEvent] {
        func day(_ offset: Int, yearsAgo: Int = 0) -> EventDay {
            let date = calendar.date(byAdding: .day, value: offset, to: now) ?? now
            let c = calendar.dateComponents([.year, .month, .day], from: date)
            return EventDay(year: (c.year ?? 2026) - yearsAgo, month: c.month ?? 1, day: c.day ?? 1)
        }
        return [
            CountdownEvent(title: "Wedding Anniversary", day: day(43, yearsAgo: 12), repeatsYearly: true,
                           emoji: "💍", theme: .rose, reminderDays: [0, 7, 30],
                           createdAt: calendar.date(byAdding: .day, value: -200, to: now) ?? now),
            CountdownEvent(title: "Mom’s Birthday", day: day(9, yearsAgo: 70), repeatsYearly: true,
                           emoji: "🎂", theme: .gold),
            CountdownEvent(title: "Lisbon", day: day(21), time: EventTime(hour: 7, minute: 30),
                           emoji: "✈️", theme: .ocean, notes: "Flight out of Dulles.",
                           createdAt: calendar.date(byAdding: .day, value: -30, to: now) ?? now),
            CountdownEvent(title: "Launch Day", day: day(120), emoji: "🚀", theme: .berry,
                           createdAt: calendar.date(byAdding: .day, value: -15, to: now) ?? now),
            CountdownEvent(title: "Half Marathon", day: day(-10), emoji: "🏃", theme: .forest, reminderDays: []),
        ]
    }
}
