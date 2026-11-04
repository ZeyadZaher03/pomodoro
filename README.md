# Pomodoro

A menu bar focus timer for macOS, modeled on a cube desk timer. The time left lives in a pill in the menu bar. Click it to pick a session, pause, or end early.

- Sessions of 15, 30, 45, 60, 75, or 90 minutes. Your last pick is remembered.
- A ring of 60 orange ticks runs down as the session goes.
- The pill shows the time left in every state: the menu bar's own tint when idle, solid orange while running, and an orange outline while paused.
- When a session ends it plays a sound and posts a notification.
- Opens at login. Turn this off with the checkbox in the panel.
- Space starts and pauses while the panel is open.

Requires macOS 13 or later.

## Build

You need Xcode or the Xcode command line tools (`xcode-select --install`).

```bash
./build.sh            # builds build/Pomodoro.app
./build.sh --install  # also copies it to /Applications
```

The app is ad-hoc signed. If you download a build instead of building it yourself, macOS may block the first launch. Right-click the app and choose Open.

To redraw the app icon, run `swift scripts/make-icon.swift`. It writes `Resources/AppIcon.icns`.
