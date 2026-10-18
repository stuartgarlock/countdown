# App Store listing

Everything App Store Connect asks for, ready to paste. Screenshots are in `screenshots/`
(regenerate with the `testStoreScreenshots` UI test on an iPhone 17 Pro Max and an iPad Pro 13" simulator).

## New App (App Store Connect → Apps → +)

| Field | Value |
|---|---|
| Platform | iOS |
| Name | _to choose; must be unique on the store, max 30 characters. "Countdown" alone is taken._ |
| Primary language | English (U.S.) |
| Bundle ID | `llc.smggroup.countdown` |
| SKU | `countdown-ios` |
| User access | Full access |

The name under the icon on the phone stays **Countdown** whatever the store name is.

## App information

| Field | Value |
|---|---|
| Subtitle (30) | `Anniversaries & big days` |
| Category | Lifestyle (secondary: Productivity) |
| Content rights | Does not contain third-party content |
| Age rating | 4+ (answer "None" to every question) |
| Privacy Policy URL | https://github.com/stuartgarlock/countdown/blob/main/PRIVACY.md |
| Support URL | https://github.com/stuartgarlock/countdown/issues |
| Marketing URL | https://github.com/stuartgarlock/countdown |
| Copyright | `2026 SMG Group LLC` |

## Pricing and availability

Free · all countries and regions.

## App Privacy

**Data Not Collected.** (No analytics, no accounts, no network access; see `PRIVACY.md` and the
`PrivacyInfo.xcprivacy` manifests.)

## Version 1.0

**Promotional text (170)**

> Count down to the days that matter. Anniversaries and birthdays roll over every year and know which one is next.

**Description**

> Countdown keeps the days that matter in front of you: the anniversary, the birthday, the trip, the launch.
>
> ANNIVERSARIES THAT KNOW WHICH ONE IS NEXT
> Enter the original date (the wedding, the birth) and Countdown counts down to the next one every year, and tells you which it is: the 13th, the 70th. It also shows how long it has been: "4,340 days since November 30, 2014."
>
> BIG DAYS, TO THE MINUTE
> One-time events count down to the day, or to the minute if you give them a time. Afterwards they move quietly to Past.
>
> WIDGETS
> Home Screen and Lock Screen widgets show the next thing coming up, or pin the one you care about most.
>
> REMINDERS
> On the day, the day before, a week or a month ahead: choose per event.
>
> PRIVATE BY DESIGN
> No account, no ads, no analytics, no network access. Your events stay on your device.
>
> Countdown is open source under the MIT license: github.com/stuartgarlock/countdown

**Keywords (100)**

`anniversary,birthday,days until,countdown widget,event,wedding,trip,vacation,reminder,days left,date`

**What's New**

> First release.

## App Review information

| Field | Value |
|---|---|
| Sign-in required | No |
| Contact | Stuart Garlock, stuart@smggroup.llc |
| Notes | No account or network access. Tap a preset (e.g. Anniversary) on the first screen to create an event. Widgets: long-press the Home Screen → Edit → Add Widget → Countdown. |

## Export compliance

Answered in the build (`ITSAppUsesNonExemptEncryption = NO`); App Store Connect will not ask.
