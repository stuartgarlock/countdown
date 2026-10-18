import SwiftUI

struct EventListView: View {
    @Environment(EventStore.self) private var store
    @State private var path: [UUID] = []
    @State private var editor: EditorTarget?
    @State private var pendingDelete: CountdownEvent?

    var body: some View {
        NavigationStack(path: $path) {
            // Day counts change at midnight; a minute's tick is plenty and costs nothing.
            TimelineView(.periodic(from: .now, by: 60)) { context in
                content(now: context.date)
            }
            .navigationTitle("Countdown")
            .toolbar {
                if !store.events.isEmpty {
                    ToolbarItem(placement: .primaryAction) {
                        Button {
                            editor = .new(nil)
                        } label: {
                            Label("Add Event", systemImage: "plus")
                        }
                    }
                }
            }
            .navigationDestination(for: UUID.self) { id in
                EventDetailView(eventID: id)
            }
        }
        .sheet(item: $editor) { target in
            EventEditorView(target: target)
        }
        .confirmationDialog(
            "Delete this event?",
            isPresented: Binding(get: { pendingDelete != nil }, set: { if !$0 { pendingDelete = nil } }),
            titleVisibility: .visible,
            presenting: pendingDelete
        ) { event in
            Button("Delete “\(event.displayTitle)”", role: .destructive) {
                store.delete(id: event.id)
            }
        } message: { _ in
            Text("Its reminders are cancelled too. This can’t be undone.")
        }
        // Tapping a widget opens straight to its event.
        .onOpenURL { url in
            guard url.scheme == "countdown", url.host() == "event",
                  let id = UUID(uuidString: url.lastPathComponent),
                  store.event(id: id) != nil else { return }
            path = [id]
        }
        #if DEBUG
        // Screenshot hooks for the simulator: -openEvent <uuid> | -openEditor <uuid|new>.
        .task {
            let args = ProcessInfo.processInfo.arguments
            func value(after flag: String) -> String? {
                guard let i = args.firstIndex(of: flag), i + 1 < args.count else { return nil }
                return args[i + 1]
            }
            if let raw = value(after: "-openEvent"), let id = UUID(uuidString: raw) { path = [id] }
            if let raw = value(after: "-openEditor") {
                if let id = UUID(uuidString: raw), let event = store.event(id: id) {
                    editor = .existing(event)
                } else {
                    editor = .new(.anniversary)
                }
            }
        }
        #endif
    }

    @ViewBuilder
    private func content(now: Date) -> some View {
        if store.events.isEmpty {
            EmptyStateView { preset in editor = .new(preset) }
        } else {
            let groups = store.events.partitioned(now: now, calendar: .countdown)
            List {
                if let next = groups.upcoming.first {
                    row(next, now: now, style: .hero)
                }
                if groups.upcoming.count > 1 {
                    Section {
                        ForEach(groups.upcoming.dropFirst()) { row($0, now: now, style: .regular) }
                    } header: {
                        header("Coming Up")
                    }
                }
                if !groups.past.isEmpty {
                    Section {
                        ForEach(groups.past) { row($0, now: now, style: .past) }
                    } header: {
                        header("Past")
                    }
                }
            }
            .listStyle(.plain)
            .animation(.default, value: store.events)
        }
    }

    private func header(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
            .foregroundStyle(.secondary)
            .textCase(nil)
    }

    private func row(_ event: CountdownEvent, now: Date, style: EventCard.Style) -> some View {
        Button {
            path.append(event.id)
        } label: {
            EventCard(event: event, now: now, style: style)
        }
        .buttonStyle(.plain)
        .listRowSeparator(.hidden)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
        .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button {
                pendingDelete = event
            } label: {
                Label("Delete", systemImage: "trash")
            }
            .tint(.red)
            Button {
                editor = .existing(event)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            .tint(.indigo)
        }
        .contextMenu {
            Button {
                editor = .existing(event)
            } label: {
                Label("Edit", systemImage: "pencil")
            }
            Button(role: .destructive) {
                pendingDelete = event
            } label: {
                Label("Delete", systemImage: "trash")
            }
        }
    }
}

private struct EmptyStateView: View {
    let onPick: (EventPreset?) -> Void

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                Text("⏳").font(.system(size: 64))
                    .padding(.top, 40)
                Text("Nothing to count down to yet")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                Text("Add an anniversary, a birthday or the next big trip, and see how many days are left at a glance.")
                    .multilineTextAlignment(.center)
                    .foregroundStyle(.secondary)

                LazyVGrid(columns: [GridItem(.flexible(), spacing: 12), GridItem(.flexible(), spacing: 12)], spacing: 12) {
                    ForEach(EventPreset.allCases) { preset in
                        Button {
                            onPick(preset)
                        } label: {
                            VStack(spacing: 6) {
                                Text(preset.emoji).font(.largeTitle)
                                Text(preset.label).font(.subheadline.weight(.semibold))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 18)
                            .foregroundStyle(.white)
                            .background(preset.theme.gradient, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(preset.label)
                    }
                }
                .padding(.top, 8)

                Button("Something else") { onPick(nil) }
                    .font(.headline)
                    .padding(.top, 4)
            }
            .padding(24)
            .frame(maxWidth: 520)
            .frame(maxWidth: .infinity)
        }
    }
}

#Preview {
    EventListView()
        .environment(EventStore())
}
