import Foundation

/// What the editor sheet is open for.
enum EditorTarget: Identifiable {
    case new(EventPreset?)
    case existing(CountdownEvent)

    var id: String {
        switch self {
        case .new(let preset): "new-\(preset?.rawValue ?? "blank")"
        case .existing(let event): event.id.uuidString
        }
    }
}

/// Starting points offered on the empty screen. Each just pre-fills the editor.
enum EventPreset: String, CaseIterable, Identifiable {
    case anniversary, birthday, trip, bigDay

    var id: String { rawValue }

    var label: String {
        switch self {
        case .anniversary: "Anniversary"
        case .birthday: "Birthday"
        case .trip: "Trip"
        case .bigDay: "Big Day"
        }
    }

    var emoji: String {
        switch self {
        case .anniversary: "💍"
        case .birthday: "🎂"
        case .trip: "✈️"
        case .bigDay: "🎉"
        }
    }

    var theme: EventTheme {
        switch self {
        case .anniversary: .rose
        case .birthday: .gold
        case .trip: .ocean
        case .bigDay: .sunset
        }
    }

    var repeatsYearly: Bool { self == .anniversary || self == .birthday }

    var reminderDays: [Int] { repeatsYearly ? [0, 7] : [0, 1] }
}
