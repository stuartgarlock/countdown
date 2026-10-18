import SwiftUI

struct EventEditorView: View {
    let target: EditorTarget

    @Environment(EventStore.self) private var store
    @Environment(\.dismiss) private var dismiss

    @State private var draft: CountdownEvent
    @State private var date: Date
    @State private var hasTime: Bool
    @State private var confirmDelete = false
    @State private var notificationsDenied = false
    @FocusState private var titleFocused: Bool

    private static let emojis = ["💍", "❤️", "🎂", "🎉", "🥂", "✈️", "🏖️", "🏔️", "🎓", "👶",
                                 "🏠", "💼", "🚀", "🏆", "🎄", "🎃", "🎵", "⚾️", "🐶", "⭐️"]

    private enum ReminderOption: Int, CaseIterable, Identifiable {
        case onTheDay = 0, dayBefore = 1, weekBefore = 7, monthBefore = 30
        var id: Int { rawValue }
        var label: String {
            switch self {
            case .onTheDay: "On the day"
            case .dayBefore: "1 day before"
            case .weekBefore: "1 week before"
            case .monthBefore: "30 days before"
            }
        }
    }

    init(target: EditorTarget) {
        self.target = target
        let calendar = Calendar.countdown
        let event: CountdownEvent
        switch target {
        case .existing(let existing):
            event = existing
        case .new(let preset):
            let today = calendar.dateComponents([.year, .month, .day], from: .now)
            event = CountdownEvent(
                title: "",
                day: EventDay(year: today.year ?? 2026, month: today.month ?? 1, day: today.day ?? 1),
                repeatsYearly: preset?.repeatsYearly ?? false,
                emoji: preset?.emoji ?? "🎉",
                theme: preset?.theme ?? .sunset,
                reminderDays: preset?.reminderDays ?? [0, 7]
            )
        }
        _draft = State(initialValue: event)
        _hasTime = State(initialValue: event.time != nil)
        _date = State(initialValue: event.origin(calendar: calendar))
    }

    private var isNew: Bool {
        if case .new = target { return true }
        return false
    }

    private var preset: EventPreset? {
        if case .new(let preset) = target { return preset }
        return nil
    }

    /// The draft as it would be saved, for the live preview card.
    private var resolved: CountdownEvent {
        let calendar = Calendar.countdown
        var event = draft
        let c = calendar.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        event.day = EventDay(year: c.year ?? 2026, month: c.month ?? 1, day: c.day ?? 1)
        event.time = hasTime ? EventTime(hour: c.hour ?? 0, minute: c.minute ?? 0) : nil
        event.title = draft.title.trimmingCharacters(in: .whitespacesAndNewlines)
        if event.emoji.isEmpty { event.emoji = "🎉" }
        return event
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    EventCard(event: resolved, now: .now)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                        .animation(.default, value: resolved)
                }

                Section {
                    TextField(titlePlaceholder, text: $draft.title)
                        .font(.headline)
                        .focused($titleFocused)
                        .submitLabel(.done)
                        .accessibilityIdentifier("titleField")
                    emojiPicker
                }

                Section {
                    DatePicker(draft.repeatsYearly ? "First date" : "Date", selection: $date, displayedComponents: .date)
                    Toggle("Set a time", isOn: $hasTime.animation())
                    if hasTime {
                        DatePicker("Time", selection: $date, displayedComponents: .hourAndMinute)
                    }
                    Toggle("Repeats every year", isOn: $draft.repeatsYearly.animation())
                } footer: {
                    Text(draft.repeatsYearly
                         ? "For anniversaries and birthdays. Use the original date (the wedding, the birth) and Countdown counts which one is next."
                         : "A one-time event. Once it has passed it moves to Past.")
                }

                Section("Color") {
                    themePicker
                }

                Section {
                    ForEach(ReminderOption.allCases) { option in
                        Toggle(option.label, isOn: reminderBinding(option.rawValue))
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    if notificationsDenied {
                        Text("Notifications are turned off for Countdown. Turn them on in Settings › Apps › Countdown.")
                    } else {
                        Text("Reminders arrive at 9 AM, or at the event’s own time on the day.")
                    }
                }

                Section("Notes") {
                    TextField("Optional", text: $draft.notes, axis: .vertical)
                        .lineLimit(2...8)
                }

                if !isNew {
                    Section {
                        Button("Delete Event", role: .destructive) { confirmDelete = true }
                            .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle(isNew ? "New Event" : "Edit Event")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") { save() }
                        .disabled(resolved.title.isEmpty)
                }
            }
            .confirmationDialog("Delete this event?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Delete “\(draft.displayTitle)”", role: .destructive) {
                    store.delete(id: draft.id)
                    dismiss()
                }
            } message: {
                Text("Its reminders are cancelled too. This can’t be undone.")
            }
            .task {
                notificationsDenied = await NotificationScheduler.isDenied()
                if isNew { titleFocused = true }
            }
        }
    }

    private var titlePlaceholder: String {
        switch preset {
        case .anniversary: "e.g. Wedding Anniversary"
        case .birthday: "e.g. Mom’s Birthday"
        case .trip: "e.g. Lisbon"
        default: "What are you counting down to?"
        }
    }

    private var emojiPicker: some View {
        VStack(alignment: .leading, spacing: 10) {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 6) {
                    ForEach(Self.emojis, id: \.self) { emoji in
                        Button {
                            draft.emoji = emoji
                        } label: {
                            Text(emoji)
                                .font(.system(size: 28))
                                .frame(width: 44, height: 44)
                                .background(
                                    draft.emoji == emoji ? Color.accentColor.opacity(0.2) : Color.clear,
                                    in: RoundedRectangle(cornerRadius: 10, style: .continuous)
                                )
                        }
                        .buttonStyle(.plain)
                        .accessibilityAddTraits(draft.emoji == emoji ? .isSelected : [])
                    }
                }
            }
            HStack {
                Text("Or type any emoji")
                    .foregroundStyle(.secondary)
                Spacer()
                TextField("", text: $draft.emoji)
                    .multilineTextAlignment(.trailing)
                    .frame(width: 60)
                    .onChange(of: draft.emoji) { _, new in
                        // Keep only the newest character, so typing replaces rather than appends.
                        if new.count > 1, let last = new.last { draft.emoji = String(last) }
                    }
            }
        }
        .padding(.vertical, 4)
    }

    private var themePicker: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 10), count: 5), spacing: 14) {
            ForEach(EventTheme.allCases, id: \.self) { theme in
                Button {
                    draft.theme = theme
                } label: {
                    Circle()
                        .fill(theme.gradient)
                        .frame(width: 40, height: 40)
                        .overlay {
                            if draft.theme == theme {
                                Image(systemName: "checkmark")
                                    .font(.headline.bold())
                                    .foregroundStyle(.white)
                            }
                        }
                        .padding(4)
                        .overlay(Circle().strokeBorder(Color.primary.opacity(draft.theme == theme ? 0.5 : 0), lineWidth: 2))
                }
                .buttonStyle(.plain)
                .accessibilityLabel(theme.name)
                .accessibilityAddTraits(draft.theme == theme ? .isSelected : [])
            }
        }
        .padding(.vertical, 6)
    }

    private func reminderBinding(_ days: Int) -> Binding<Bool> {
        Binding(
            get: { draft.reminderDays.contains(days) },
            set: { on in
                if on {
                    if !draft.reminderDays.contains(days) { draft.reminderDays.append(days) }
                } else {
                    draft.reminderDays.removeAll { $0 == days }
                }
            }
        )
    }

    private func save() {
        let event = resolved
        store.save(event)
        if !event.reminderDays.isEmpty {
            // Ask for permission the first time it is actually needed, then plan again with it.
            Task {
                if await NotificationScheduler.requestAuthorizationIfNeeded() {
                    store.rescheduleNotifications()
                }
            }
        }
        dismiss()
    }
}

#Preview {
    EventEditorView(target: .new(.anniversary))
        .environment(EventStore())
}
