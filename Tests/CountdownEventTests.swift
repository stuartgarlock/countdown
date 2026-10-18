import XCTest

/// The date maths is the part that has to be right on a day nobody is watching: the morning of
/// an anniversary, a leap year, the weekend the clocks change.
final class CountdownEventTests: XCTestCase {
    private let calendar: Calendar = {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "America/New_York")!
        return c
    }()

    private func at(_ y: Int, _ m: Int, _ d: Int, _ h: Int = 12, _ min: Int = 0) -> Date {
        calendar.date(from: DateComponents(year: y, month: m, day: d, hour: h, minute: min))!
    }

    private func ymd(_ date: Date) -> DateComponents {
        calendar.dateComponents([.year, .month, .day], from: date)
    }

    func testOneOffCountsCalendarDaysNotHours() {
        let trip = CountdownEvent(title: "Trip", day: EventDay(year: 2026, month: 11, day: 20))
        // One minute before midnight is still a whole calendar day further out than the morning after.
        XCTAssertEqual(trip.daysUntil(from: at(2026, 10, 18, 23, 59), calendar: calendar), 33)
        XCTAssertEqual(trip.daysUntil(from: at(2026, 10, 19, 0, 1), calendar: calendar), 32)
        XCTAssertEqual(trip.status(from: at(2026, 11, 20, 8), calendar: calendar), .today)
        XCTAssertEqual(trip.status(from: at(2026, 11, 22), calendar: calendar), .past(days: 2))
        XCTAssertNil(trip.anniversaryNumber(from: at(2026, 10, 18), calendar: calendar))
    }

    func testAnniversaryStaysOnTodayThenRollsToNextYear() {
        let wedding = CountdownEvent(title: "Wedding", day: EventDay(year: 2014, month: 3, day: 3), repeatsYearly: true)

        XCTAssertEqual(wedding.daysUntil(from: at(2026, 10, 18), calendar: calendar), 136)
        XCTAssertEqual(wedding.anniversaryNumber(from: at(2026, 10, 18), calendar: calendar), 13)

        // Late on the day itself it is still today, and still the 13th.
        XCTAssertEqual(wedding.status(from: at(2027, 3, 3, 23, 30), calendar: calendar), .today)
        XCTAssertEqual(wedding.anniversaryNumber(from: at(2027, 3, 3, 23, 30), calendar: calendar), 13)

        // Just after midnight it is a year away (2028 is a leap year, so 365 not 364) and the 14th.
        XCTAssertEqual(wedding.daysUntil(from: at(2027, 3, 4, 0, 1), calendar: calendar), 365)
        XCTAssertEqual(wedding.anniversaryNumber(from: at(2027, 3, 4, 0, 1), calendar: calendar), 14)
    }

    func testLeapDayFallsOnFeb28InCommonYears() {
        let leapling = CountdownEvent(title: "Leap", day: EventDay(year: 2024, month: 2, day: 29), repeatsYearly: true)
        XCTAssertEqual(ymd(leapling.nextOccurrence(from: at(2026, 10, 18), calendar: calendar)),
                       DateComponents(year: 2027, month: 2, day: 28))
        XCTAssertEqual(ymd(leapling.nextOccurrence(from: at(2028, 1, 1), calendar: calendar)),
                       DateComponents(year: 2028, month: 2, day: 29))
    }

    func testRepeatingEventInTheFutureStartsOnItsOwnDate() {
        let wedding = CountdownEvent(title: "Wedding", day: EventDay(year: 2027, month: 6, day: 12), repeatsYearly: true)
        XCTAssertEqual(ymd(wedding.nextOccurrence(from: at(2026, 10, 18), calendar: calendar)),
                       DateComponents(year: 2027, month: 6, day: 12))
        XCTAssertNil(wedding.anniversaryNumber(from: at(2026, 10, 18), calendar: calendar),
                     "the wedding itself is not anyone's 0th anniversary")
        XCTAssertNil(wedding.daysSinceOrigin(from: at(2026, 10, 18), calendar: calendar))
    }

    func testDaysAcrossTheClockChange() {
        // US clocks go forward on 14 March 2027; that 23-hour day is still one day.
        let spring = CountdownEvent(title: "Spring", day: EventDay(year: 2027, month: 3, day: 20))
        XCTAssertEqual(spring.daysUntil(from: at(2027, 3, 10, 0, 30), calendar: calendar), 10)
    }

    func testTimedEventCountsToTheMinute() {
        let flight = CountdownEvent(title: "Flight", day: EventDay(year: 2026, month: 10, day: 19),
                                    time: EventTime(hour: 7, minute: 30))
        let left = flight.preciseRemaining(from: at(2026, 10, 18, 22, 0), calendar: calendar)
        XCTAssertEqual(left?.day, 0)
        XCTAssertEqual(left?.hour, 9)
        XCTAssertEqual(left?.minute, 30)
        XCTAssertEqual(flight.daysUntil(from: at(2026, 10, 18, 22, 0), calendar: calendar), 1)
        XCTAssertNil(flight.preciseRemaining(from: at(2026, 10, 19, 8, 0), calendar: calendar), "it has started")
    }

    func testRemindersSkipThePastAndQueueNextYear() {
        let wedding = CountdownEvent(title: "Wedding", day: EventDay(year: 2014, month: 3, day: 3),
                                     repeatsYearly: true, reminderDays: [7, 0])
        let plan = wedding.plannedReminders(from: at(2027, 2, 28), calendar: calendar)
        let fired = plan.map { calendar.dateComponents([.year, .month, .day, .hour], from: $0.fireDate) }
        // 24 Feb 2027 has already gone. 2028 is a leap year, so a week before 3 March is the 25th.
        XCTAssertEqual(fired, [
            DateComponents(year: 2027, month: 3, day: 3, hour: 9),
            DateComponents(year: 2028, month: 2, day: 25, hour: 9),
            DateComponents(year: 2028, month: 3, day: 3, hour: 9),
        ])
        XCTAssertEqual(Set(plan.map(\.identifier)).count, plan.count, "identifiers must be unique")
    }

    func testTimedReminderOnTheDayFiresAtTheEventTime() {
        let flight = CountdownEvent(title: "Flight", day: EventDay(year: 2026, month: 10, day: 25),
                                    time: EventTime(hour: 7, minute: 30), reminderDays: [0, 1])
        let plan = flight.plannedReminders(from: at(2026, 10, 18), calendar: calendar)
        XCTAssertEqual(plan.map { calendar.dateComponents([.day, .hour, .minute], from: $0.fireDate) }, [
            DateComponents(day: 24, hour: 9, minute: 0),
            DateComponents(day: 25, hour: 7, minute: 30),
        ])
    }

    func testOrderingIsSoonestFirstThenMostRecentPast() {
        let now = at(2026, 10, 18)
        let events = [
            CountdownEvent(title: "Long ago", day: EventDay(year: 2026, month: 1, day: 1)),
            CountdownEvent(title: "Far", day: EventDay(year: 2027, month: 6, day: 1)),
            CountdownEvent(title: "Recent", day: EventDay(year: 2026, month: 10, day: 1)),
            CountdownEvent(title: "Today", day: EventDay(year: 2026, month: 10, day: 18)),
            CountdownEvent(title: "Birthday", day: EventDay(year: 1956, month: 10, day: 27), repeatsYearly: true),
        ]
        let groups = events.partitioned(now: now, calendar: calendar)
        XCTAssertEqual(groups.upcoming.map(\.title), ["Today", "Birthday", "Far"])
        XCTAssertEqual(groups.past.map(\.title), ["Recent", "Long ago"])
    }

    func testDecodingSurvivesMissingAndUnknownFields() throws {
        let json = #"[{"id":"6F9619FF-8B86-D011-B42D-00C04FC964FF","title":"Old","day":{"year":2020,"month":1,"day":2},"theme":"neon","futureField":true}]"#
        let events = try CountdownEvent.decoder.decode([CountdownEvent].self, from: Data(json.utf8))
        XCTAssertEqual(events.count, 1)
        XCTAssertEqual(events[0].theme, .sunset)
        XCTAssertFalse(events[0].repeatsYearly)
        XCTAssertEqual(events[0].reminderDays, [])
        XCTAssertNil(events[0].time)
    }

    func testRoundTrip() throws {
        let original = CountdownEvent(title: "Lisbon", day: EventDay(year: 2026, month: 11, day: 8),
                                      time: EventTime(hour: 7, minute: 30), emoji: "✈️", theme: .ocean,
                                      reminderDays: [0, 1], notes: "TAP")
        let data = try CountdownEvent.encoder.encode([original])
        let back = try CountdownEvent.decoder.decode([CountdownEvent].self, from: data)
        XCTAssertEqual(back.first?.title, original.title)
        XCTAssertEqual(back.first?.day, original.day)
        XCTAssertEqual(back.first?.time, original.time)
        XCTAssertEqual(back.first?.theme, original.theme)
        XCTAssertEqual(back.first?.reminderDays, original.reminderDays)
    }
}
