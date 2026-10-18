import SwiftUI

@main
struct CountdownApp: App {
    @State private var store = EventStore()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            EventListView()
                .environment(store)
        }
        // Yearly events roll over while the app sits in the background, so every return to the
        // foreground re-plans reminders and redraws the widgets.
        .onChange(of: scenePhase) { _, phase in
            if phase == .active { store.refresh() }
        }
    }
}
