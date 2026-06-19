<div align="center">

<img src="assets/icon.png" width="120" alt="FocusNotch icon" />

# FocusNotch

### Make your MacBook's notch useful — a Pomodoro timer that lives in the notch.

[![macOS](https://img.shields.io/badge/macOS-14%2B-000000?logo=apple&logoColor=white)](https://www.apple.com/macos/)
[![Swift](https://img.shields.io/badge/Swift-5.9-F05138?logo=swift&logoColor=white)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/UI-SwiftUI-0A84FF)](https://developer.apple.com/xcode/swiftui/)
[![License: MIT](https://img.shields.io/badge/License-MIT-3DA639)](LICENSE)
[![Made for the notch](https://img.shields.io/badge/made_for-the_notch-FF6B5C)](#)

<br />

<img src="docs/showcase.png" width="720" alt="FocusNotch collapsed and expanded" />

</div>

---

When you're heads-down, FocusNotch shows the **time left** on the left of your notch
and your **session progress** on the right. Glance up — that's it. Move your cursor
to the notch and it **expands** into a full control panel: a big countdown, a
progress bar, your session tracker, transport controls, and a one-tap **Do Not
Disturb** toggle. No window. No Dock icon. Just your notch, finally doing something.

## ✨ Features

- 🎯 **Notch-native** — a panel pinned over the physical notch, floating above every Space and over fullscreen apps. Click-through when collapsed, so your menu bar keeps working.
- 👀 **Glanceable** — remaining time on the left, session dots on the right. Idle? It stays a clean, invisible notch.
- 🖱️ **Hover to expand** — a smooth, BoringNotch-style drop-down with the camera notch flowing into the panel (concave "ears", rounded corners, pure `#000` black).
- 🍅 **A real Pomodoro engine** — configurable focus / short break / long break, cycles before a long break, optional auto-start. The countdown is anchored to an absolute end time, so it stays accurate across sleep and app nap.
- 🌙 **Do Not Disturb** — toggle macOS Focus from the notch, or have it follow your work sessions automatically.
- 🔔 **Notifications & sounds** on every phase change.
- 📊 **Menu bar timer** mirroring the countdown, with the same controls — handy on external displays.
- 🚀 **Launch at login** and a friendly first-run **onboarding**.
- 🖥️ **No notch? No problem** — optionally shows a centered "island" on any Mac.

## 📦 Install

**Download** — grab the latest `FocusNotch.dmg` from the
[Releases](../../releases) page, open it, and drag FocusNotch to Applications.

> Until the app is notarized, macOS may warn on first open — **right-click the app → Open**, then confirm. (Notarization is on the roadmap.)

**Or build from source:**

```bash
brew install xcodegen        # one-time
git clone https://github.com/23aneessss/FocusNotch && cd FocusNotch
xcodegen generate
open FocusNotch.xcodeproj      # ⌘R to run
```

FocusNotch is an **agent app** (no Dock icon) — after launch, look for the timer in
your menu bar and the panel over your notch.

## 🌙 Do Not Disturb setup

Apple provides no public API for Focus, so FocusNotch runs a **Shortcut** that
accepts `on`/`off`. It defaults to the free
[`macos-focus-mode`](https://github.com/sindresorhus/macos-focus-mode) shortcut:

```bash
npx macos-focus-mode install
```

Then the moon button toggles Do Not Disturb — no Accessibility or other permissions
needed. Prefer your own shortcut? Point FocusNotch at it in **Settings → Focus**.

## 🧠 How it works

A borderless, non-activating `NSPanel` is pinned over the notch at the `.statusBar`
window level and joins every Space. `NotchController` tracks the cursor with paired
global + local `NSEvent` monitors (needed because the panel toggles
`ignoresMouseEvents` between states) and flips an observable `isOpen` flag, which
`NotchRootView` animates. The collapsed gap is kept perfectly centered on the
physical notch by using equal side widths, and expanded content sits **below** the
notch strip so the camera never hides it.

```
Sources/
├── App/        Lifecycle, shared environment
├── Pomodoro/   PomodoroEngine (state machine), settings, phases
├── Focus/      FocusController (Do Not Disturb via Shortcuts)
├── System/     Notifications, sounds, launch-at-login, screen + time helpers
├── Notch/      NSPanel, hover controller, geometry, status bar, settings & onboarding windows
└── Views/      SwiftUI: notch shape, collapsed/expanded views, components, onboarding, settings
```

## 🚀 Building a release (DMG)

The whole pipeline — build → sign → DMG → notarize → staple — is one command:

```bash
FN_SIGN_ID="Developer ID Application: Your Name (TEAMID)" \
FN_NOTARY_PROFILE="FocusNotchNotary" \
./scripts/release.sh
# → dist/FocusNotch-<version>.dmg
```

Omit `FN_NOTARY_PROFILE` for a signed-but-un-notarized build for local testing.
Notarization requires a paid Apple Developer membership, a **Developer ID
Application** certificate, and a `notarytool` keychain profile — see the header of
[`scripts/release.sh`](scripts/release.sh) for the one-time setup.

## 🗺️ Roadmap

- [ ] Notarized DMG release
- [ ] Focus stats & streaks
- [ ] Global hotkey (start / pause / skip)
- [ ] Session presets (25/5, 50/10, deep work)
- [ ] Theming & accent color
- [ ] Localization (FR included)

## 🤝 Contributing

Issues and PRs welcome. The project is generated with XcodeGen — edit `project.yml`
and run `xcodegen generate` after adding or removing files. The app icon and the
banner above are generated from code in [`Tools/`](Tools).

## 📄 License

[MIT](LICENSE) — free to use, fork, and build on. If you plan to **sell a
closed-source build**, swap in your own commercial / EULA terms first.

<div align="center">
<br />
<sub>Built with SwiftUI · Make your notch useful.</sub>
</div>
