import Foundation

// MARK: - Stored shape

/// A calendar day with no time zone attached: "3 March 2014", wherever the phone happens to be.
///
/// Kept as Gregorian components rather than a `Date` so an anniversary never slides a day when
/// you travel. A `Date` is an instant, and midnight in New York is still the 2nd in California.
struct EventDay: Codable, Hashable, Sendable {
    var year: Int
    var month: Int
    var day: Int
}

/// Wall-clock time, for events that start at a particular moment (a flight, a launch).
struct EventTime: Codable, Hashable, Sendable {
    var hour: Int
    var minute: Int
}

enum EventTheme: String, Codable, CaseIterable, Sendable {
    case sunset, rose, berry, lavender, ocean, teal, forest, gold, slate
}

struct CountdownEvent: Codable, Identifiable, Hashable, Sendable {
    var id: UUID
    var title: String
    var day: EventDay
    /// nil = all day; the countdown runs to the start of the day.
    var time: EventTime?
    /// Anniversaries and birthdays: comes round every year, and counts which one it is.
    var repeatsYearly: Bool
    var emoji: String
    var theme: EventTheme
    /// Days before each occurrence to send a reminder. 0 is the day itself.
    var reminderDays: [Int]
    var notes: String
    var createdAt: Date

    init(
        id: UUID = UUID(),
        title: String,
        day: EventDay,
        time: EventTime? = nil,
        repeatsYearly: Bool = false,
        emoji: String = "🎉",
        theme: EventTheme = .sunset,
        reminderDays: [Int] = [0, 7],
        notes: String = "",
        createdAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.day = day
        self.time = time
        self.repeatsYearly = repeatsYearly
        self.emoji = emoji
        self.theme = theme
        self.reminderDays = reminderDays
        self.notes = notes
        self.createdAt = createdAt
    }

    // Tolerant decoding: a field added in a later version, or a theme that no longer exists,
    // must never cost the whole saved list.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        id = try c.decodeIfPresent(UUID.self, forKey: .id) ?? UUID()
        title = try c.decodeIfPresent(String.self, forKey: .title) ?? ""
        day = try c.decode(EventDay.self, forKey: .day)
        time = try c.decodeIfPresent(EventTime.self, forKey: .time)
        repeatsYearly = try c.decodeIfPresent(Bool.self, forKey: .repeatsYearly) ?? false
        emoji = try c.decodeIfPresent(String.self, forKey: .emoji) ?? "🎉"
        theme = (try? c.decodeIfPresent(EventTheme.self, forKey: .theme)) ?? .sunset
        reminderDays = try c.decodeIfPresent([Int].self, forKey: .reminderDays) ?? []
        notes = try c.decodeIfPresent(String.self, forKey: .notes) ?? ""
        createdAt = try c.decodeIfPresent(Date.self, forKey: .createdAt) ?? .now
    }

    static var encoder: JSONEncoder {
        let e = JSONEncoder()
        e.dateEncodingStrategy = .iso8601
        e.outputFormatting = [.prettyPrinted, .sortedKeys]
        return e
    }

    static var decoder: JSONDecoder {
        let d = JSONDecoder()
        d.dateDecodingStrategy = .iso8601
        return d
    }
}

enum CountdownStatus: Hashable, Sendable {
    case upcoming(days: Int)
    case today
    case past(days: Int)
}

// MARK: - Calendar

extension Calendar {
    /// Gregorian in the phone's current zone. The stored components are Gregorian, so the maths
    /// has to be too, even for someone whose display calendar is Buddhist or Japanese.
    static var countdown: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = .current
        c.locale = .current
        return c
    }

    func isLeapYear(_ year: Int) -> Bool {
        guard let feb29 = date(from: DateComponents(year: year, month: 2, day: 29)) else { return false }
        return component(.month, from: feb29) == 2
    }

    /// Whole calendar days between the days containing two instants. DST-safe: a 23-hour day
    /// still counts as one.
    func days(from start: Date, to end: Date) -> Int {
        dateComponents([.day], from: startOfDay(for: start), to: startOfDay(for: end)).day ?? 0
    }
}

// MARK: - Date maths

extension CountdownEvent {
    /// The occurrence that falls in `year`. A 29 February anniversary is kept on the 28th in
    /// common years; that is when people actually celebrate it, and it stays in February.
    func occurrence(inYear year: Int, calendar: Calendar) -> Date {
        var c = DateComponents(year: year, month: day.month, day: day.day)
        if day.month == 2, day.day == 29, !calendar.isLeapYear(year) { c.day = 28 }
        c.hour = time?.hour ?? 0
        c.minute = time?.minute ?? 0
        return calendar.date(from: c) ?? .distantFuture
    }

    /// The original date: when it began for an anniversary, the event itself for a one-off.
    func origin(calendar: Calendar) -> Date {
        occurrence(inYear: day.year, calendar: calendar)
    }

    /// The occurrence to count towards. A yearly event stays on today's occurrence for the whole
    /// of its day, then rolls to next year. It never rolls back before its own first date, so a
    /// wedding set for next June counts to next June and is not yet anyone's "1st".
    func nextOccurrence(from now: Date, calendar: Calendar) -> Date {
        guard repeatsYearly else { return origin(calendar: calendar) }
        let today = calendar.startOfDay(for: now)
        var year = max(calendar.component(.year, from: now), day.year)
        while true {
            let candidate = occurrence(inYear: year, calendar: calendar)
            if calendar.startOfDay(for: candidate) >= today { return candidate }
            year += 1
        }
    }

    /// Calendar days to go; 0 today, negative once a one-off has passed.
    func daysUntil(from now: Date, calendar: Calendar) -> Int {
        calendar.days(from: now, to: nextOccurrence(from: now, calendar: calendar))
    }

    func status(from now: Date, calendar: Calendar) -> CountdownStatus {
        let days = daysUntil(from: now, calendar: calendar)
        if days > 0 { return .upcoming(days: days) }
        if days == 0 { return .today }
        return .past(days: -days)
    }

    /// Which anniversary the next occurrence is: 13 for the 13th. Nil for one-offs and for
    /// the original date itself.
    func anniversaryNumber(from now: Date, calendar: Calendar) -> Int? {
        guard repeatsYearly else { return nil }
        let n = calendar.component(.year, from: nextOccurrence(from: now, calendar: calendar)) - day.year
        return n > 0 ? n : nil
    }

    /// Exact time left to the start of the next occurrence, or nil once it has begun.
    func preciseRemaining(from now: Date, calendar: Calendar) -> DateComponents? {
        let target = nextOccurrence(from: now, calendar: calendar)
        guard target > now else { return nil }
        return calendar.dateComponents([.day, .hour, .minute, .second], from: now, to: target)
    }

    /// How far through the wait we are, 0...1. A yearly event measures from its last
    /// occurrence; a one-off from the day it was added.
    func progress(from now: Date, calendar: Calendar) -> Double {
        let target = nextOccurrence(from: now, calendar: calendar)
        var start = min(createdAt, now)
        if repeatsYearly,
           let previous = calendar.date(byAdding: .year, value: -1, to: target),
           previous >= origin(calendar: calendar) {
            start = previous
        }
        let total = target.timeIntervalSince(start)
        guard total > 0 else { return 1 }
        return min(max(now.timeIntervalSince(start) / total, 0), 1)
    }

    /// Days since the original date: "4,612 days together". Nil until it has happened.
    func daysSinceOrigin(from now: Date, calendar: Calendar) -> Int? {
        let days = calendar.days(from: origin(calendar: calendar), to: now)
        return days > 0 ? days : nil
    }
}

// MARK: - Reminders

struct PlannedReminder: Hashable, Sendable {
    var eventID: UUID
    var fireDate: Date
    var occurrence: Date
    var daysBefore: Int

    var identifier: String {
        "countdown.\(eventID.uuidString).\(Int(occurrence.timeIntervalSince1970)).\(daysBefore)"
    }
}

extension CountdownEvent {
    static let reminderHour = 9

    /// Reminders still to come, soonest first. A yearly event plans two occurrences ahead, so
    /// next year's reminder is already queued even if the app is not opened for a year.
    func plannedReminders(from now: Date, calendar: Calendar, occurrences: Int = 2) -> [PlannedReminder] {
        guard !reminderDays.isEmpty else { return [] }

        var targets = [nextOccurrence(from: now, calendar: calendar)]
        if repeatsYearly {
            while targets.count < occurrences, let last = targets.last,
                  let dayAfter = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: last)) {
                targets.append(nextOccurrence(from: dayAfter, calendar: calendar))
            }
        }

        var plan: [PlannedReminder] = []
        for occurrence in targets {
            let occurrenceDay = calendar.startOfDay(for: occurrence)
            for daysBefore in Set(reminderDays).sorted() where daysBefore >= 0 {
                guard let fireDay = calendar.date(byAdding: .day, value: -daysBefore, to: occurrenceDay) else { continue }
                var c = calendar.dateComponents([.year, .month, .day], from: fireDay)
                if daysBefore == 0, let time {
                    c.hour = time.hour
                    c.minute = time.minute
                } else {
                    c.hour = Self.reminderHour
                    c.minute = 0
                }
                guard let fire = calendar.date(from: c), fire > now else { continue }
                plan.append(PlannedReminder(eventID: id, fireDate: fire, occurrence: occurrence, daysBefore: daysBefore))
            }
        }
        return plan.sorted { $0.fireDate < $1.fireDate }
    }
}

// MARK: - Ordering

extension Array where Element == CountdownEvent {
    /// Soonest first, then everything that has passed, most recent first.
    func partitioned(now: Date, calendar: Calendar) -> (upcoming: [CountdownEvent], past: [CountdownEvent]) {
        let keyed = map { (event: $0, days: $0.daysUntil(from: now, calendar: calendar),
                           at: $0.nextOccurrence(from: now, calendar: calendar)) }
        let upcoming = keyed.filter { $0.days >= 0 }
            .sorted { ($0.at, $0.event.title) < ($1.at, $1.event.title) }
            .map(\.event)
        let past = keyed.filter { $0.days < 0 }
            .sorted { $0.at > $1.at }
            .map(\.event)
        return (upcoming, past)
    }
}

extension Int {
    /// 13 → "13th", in the phone's language.
    var ordinalText: String {
        let f = NumberFormatter()
        f.numberStyle = .ordinal
        return f.string(from: NSNumber(value: self)) ?? "\(self)"
    }
}
