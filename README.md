# Chordtype

One-hand chorded keyboard trainer for English and Russian — built with Flutter Web.

**[Try it live →](https://nikachev.github.io/ChordType/)**

![English course · light theme](docs/screenshots/chordtype-practice-en.jpg)

![Russian course · dark theme](docs/screenshots/chordtype-practice-ru.jpg)

## How it works

Six keys on a standard keyboard map to chords that produce letters, punctuation, and commands. The trainer guides you through 18 progressive lessons per language — from single frequent chords to full messenger-style sentences.

**Input** — left-hand (`QWER / CV`) or right-hand (`UIOP / BN`) key sets, recognized by physical key code regardless of OS layout.

**Feedback** — optional next-chord and finger hints, error highlighting, WPM, accuracy stats, and browser-local progress saved between sessions.

**Offline-first** — static PWA, no backend, no accounts, no analytics.

## Development

```bash
flutter pub get
flutter run -d chrome
```

Requires Flutter SDK with Dart `>=3.3.0 <4.0.0`.

## Documentation

- [LAYOUT.md](LAYOUT.md) — layout tables, ergonomic rules, corpus data, and frequency analysis.
