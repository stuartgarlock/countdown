import Foundation
import UserNotifications

/// Local reminders only; nothing leaves the phone. Every change replaces the whole set, which is
/// simpler than diffing and cheap at this size.
enum NotificationScheduler {
    /// iOS keeps at most 64 pending local notifications per app. Stay under that and let the
    /// soonest win; the rest are queued on a later launch as these fire.
    static let budget = 60
    static let prefix = "countdown."

    static func requestAuthorizationIfNeeded() async -> Bool {
        let center = UNUserNotificationCenter.current()
        switch await center.notificationSettings().authorizationStatus {
        case .notDetermined:
            return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
        case .denied:
            return false
        default:
            return true
        }
    }

    static func isDenied() async -> Bool {
        await UNUserNotificationCenter.current().notificationSettings().authorizationStatus == .denied
    }

    static func reschedule(_ events: [CountdownEvent], now: Date = .now) async {
        let center = UNUserNotificationCenter.current()
        let ours = await center.pendingNotificationRequests()
            .map(\.identifier)
            .filter { $0.hasPrefix(prefix) }
        center.removePendingNotificationRequests(withIdentifiers: ours)

        let status = await center.notificationSettings().authorizationStatus
        guard status == .authorized || status == .provisional || status == .ephemeral else { return }

        let calendar = Calendar.countdown
        let byID = Dictionary(events.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        let plan = events
            .flatMap { $0.plannedReminders(from: now, calendar: calendar) }
            .sorted { $0.fireDate < $1.fireDate }
            .prefix(budget)

        for reminder in plan {
            guard let event = byID[reminder.eventID] else { continue }
            let content = UNMutableNotificationContent()
            content.title = "\(event.displayEmoji) \(event.displayTitle)"
            content.body = message(for: event, reminder: reminder, calendar: calendar)
            content.sound = .default
            content.threadIdentifier = event.id.uuidString

            // No time zone on the trigger: 9 AM means 9 AM wherever the phone is that day.
            var when = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: reminder.fireDate)
            when.calendar = Calendar(identifier: .gregorian)
            let trigger = UNCalendarNotificationTrigger(dateMatching: when, repeats: false)
            try? await center.add(UNNotificationRequest(identifier: reminder.identifier, content: content, trigger: trigger))
        }
    }

    private static func message(for event: CountdownEvent, reminder: PlannedReminder, calendar: Calendar) -> String {
        let nth = event.repeatsYearly
            ? calendar.component(.year, from: reminder.occurrence) - event.day.year
            : 0
        var dateStyle = Date.FormatStyle.dateTime.weekday(.wide).month(.abbreviated).day()
        if event.time != nil { dateStyle = dateStyle.hour().minute() }
        let date = reminder.occurrence.formatted(dateStyle)

        switch reminder.daysBefore {
        case 0:
            if let time = event.time, let start = calendar.date(bySettingHour: time.hour, minute: time.minute, second: 0, of: reminder.occurrence) {
                return "Starting now, \(start.formatted(date: .omitted, time: .shortened))."
            }
            return nth > 0 ? "Today’s the \(nth.ordinalText). 🎉" : "It’s today! 🎉"
        case 1:
            return nth > 0 ? "The \(nth.ordinalText) is tomorrow, \(date)." : "Tomorrow, \(date)."
        default:
            let lead = "In \(reminder.daysBefore) days, \(date)."
            return nth > 0 ? "\(lead) The \(nth.ordinalText)." : lead
        }
    }
}
