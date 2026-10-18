# Countdown

A small, native iOS app for counting down to the days that matter: anniversaries, birthdays, trips and launches.

- **Anniversaries and birthdays come round every year**, and Countdown knows which one is next ("the 13th"). Enter the original date (the wedding, the birth) and it does the rest.
- **One-time events** (a trip, a launch) count down to the day, or to the minute if you give them a time, then move to *Past*.
- **Home Screen and Lock Screen widgets.** Pin one event, or let the widget follow whatever is next.
- **Reminders** on the day, the day before, a week or a month ahead.
- **Private by design.** No accounts, no analytics, no network access. See [PRIVACY.md](PRIVACY.md).

Built with SwiftUI, WidgetKit and App Intents. iOS 18 or later, iPhone and iPad.

## How it counts

Dates are stored as plain calendar days (year, month, day), not as instants, so an anniversary never slips a day when you travel across time zones. The countdown is in calendar days (the morning before the day is "1 day", not "0.6 days"), and a yearly event stays on *Today* for the whole of its day before rolling to next year. A 29 February anniversary is marked on 28 February in common years. All of this is covered by unit tests in [`Tests/`](Tests/CountdownEventTests.swift).

## Building

The Xcode project is generated from [`project.yml`](project.yml) by [XcodeGen](https://github.com/yonaskolb/XcodeGen):

```sh
brew install xcodegen
xcodegen generate
open Countdown.xcodeproj
```

To run on your own device, change `DEVELOPMENT_TEAM` in `project.yml` to your team ID, and the bundle identifiers and App Group (`group.llc.smggroup.countdown`) to ones you own.

## Testing

```sh
xcodebuild test -project Countdown.xcodeproj -scheme Countdown \
  -destination 'platform=iOS Simulator,name=iPhone 17 Pro'
```

- `CountdownTests`: the date maths, including leap days, daylight-saving changes, year rollover and reminder planning.
- `CountdownUITests`: drives the app in the simulator (create, open, edit, delete, swipe-to-delete) and adds the widget to the Home Screen. `testStoreScreenshots` produces the App Store screenshots as test attachments.

Debug builds accept `-resetData`, `-seedSamples`, `-openEvent <uuid>` and `-openEditor <uuid|new>` as launch arguments.

## Layout

| Path | What |
|---|---|
| `Shared/` | The model and date maths, storage, colours, used by both the app and the widget |
| `App/` | The SwiftUI app: list, detail, editor, reminders |
| `Widget/` | The WidgetKit extension and its "Choose Event" configuration |
| `Tools/make-icon.swift` | Draws the app icon |

## License

MIT. See [LICENSE](LICENSE).
