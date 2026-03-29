# Time Zones (iOS)

An iOS app for viewing multiple timezones at a glance — the iPhone companion to [TimeZonesMenuBarApp](https://github.com/m-tse/TimeZonesMenuBarApp).

## Why

Most timezone apps just show you the current time in different cities. That's not very useful — you can Google that. What you actually need is to answer questions like "if I schedule a call for 3pm my time, what time is that for them?" or "what time was it in Tokyo when that incident fired at 2am?" This app lets you drag a time ruler and see all your cities update simultaneously, so you can scrub forward or backward through the day and instantly see the answer.

It's also designed to be dead simple to read. Day and night hours are visually distinct, date changes are color-coded, and hour deltas are shown relative to whichever city you tap — no mental math required.

## Features

- **Multiple timezones** — add cities from a curated list with search
- **Draggable time ruler** — scrub through the full 24 hours, updating all cities simultaneously
- **Day/night visualization** — timeline ticks are light for daytime hours and dark for nighttime
- **Reference city** — tap any city to set it as your reference point; hour deltas adjust accordingly
- **Rename cities** — long-press any city to give it a custom alias
- **Jump to date** — tap the date on any row to open a date picker and see all timezones on a future or past date
- **Date indicators** — each city shows its current date, colored red if behind your reference city's day, green if ahead
- **Hour delta** — shows the offset from your reference city (e.g. `-6h`, `+1h`)
- **Auto-sorted** — cities are always ordered by UTC offset (west to east)
- **Swipe to remove** — swipe left on any city to remove it

## Requirements

- iOS 16.0 or later

## Privacy

See [PRIVACY_POLICY.md](PRIVACY_POLICY.md).
