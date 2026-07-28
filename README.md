# Chess Vision Pro Mobile (Flutter)

Chess Vision Pro Mobile is the Android + iOS companion app for the Chess Vision Pro ecosystem, focused on **offline-first puzzle solving** and **engine-assisted analysis**.

- Mobile repo: https://github.com/akbartube51-a11y/chess-vision-pro-app
- Desktop reference: https://github.com/akbartube51-a11y/chess-vision-pro

---

## Planned Feature Set (Parity-Oriented)

- Puzzle list/browse with metadata (rating, themes, source, FEN)
- Interactive chessboard puzzle solving flow
- Analysis screen/panel with pluggable engine provider
- Local persistence for puzzle data and user progress
- Resume last puzzle/session
- Light + dark themes
- Android + iOS support from single codebase
- Update-ready architecture (app version check + puzzle pack versioning)

---

## Tech Stack

- **Flutter** (cross-platform UI)
- **Dart**
- Local storage (SQLite/Isar/Hive; final choice depends on implementation phase)
- Chess logic package (legal moves / board state)
- Engine provider abstraction for future Stockfish/native integration

---

## Prerequisites

1. Flutter SDK installed
2. Android Studio (Android toolchain)
3. Xcode (for iOS builds, macOS only)
4. Git

Verify:

```bash
flutter --version
flutter doctor
```

---

## Getting Started

```bash
git clone https://github.com/akbartube51-a11y/chess-vision-pro-app.git
cd chess-vision-pro-app
flutter pub get
flutter run
```

---

## Build Commands

### Android APK (release)

```bash
flutter build apk --release
```

Output (default):
- `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

### iOS Release Build

```bash
flutter build ios --release
```

> iOS release/signing requires Apple Developer certificates and provisioning profiles.

---

## Auto-Update Strategy

### App Update
- **Android:** in-app update flow (if enabled) or Play Store redirect fallback.
- **iOS:** App Store version check and redirect.

### Content Update (Puzzle Packs)
- Maintain local content version metadata.
- Check remote/latest version endpoint.
- Download/import updated puzzle packs when newer versions are available.

---

## Suggested Architecture

```text
lib/
  core/
    theme/
    routing/
    services/
  features/
    home/
    puzzles/
      data/
      domain/
      presentation/
    analysis/
    settings/
  shared/
```

Principles:
- Repository abstraction between UI and data source
- Engine provider abstraction for future native integration
- Offline-first behavior by default

---

## Accessibility Notes

- Large, readable typography defaults
- Sufficient touch target size
- Semantic labels for actionable controls
- Theme contrast tuned for board and analysis readability

---

## Release Requirements

To produce distributable builds:

- Android keystore configuration (`key.properties`, signing config)
- iOS signing setup in Xcode (Team, Bundle ID, Provisioning)
- Store listing metadata (icons, screenshots, privacy policy)

---

## Project Status

This repository is configured as the mobile app target and documentation baseline. If you want, next step is full code scaffolding + feature implementation with CI workflows.

---

## License & Credits

Desktop project concept and ecosystem:
- https://github.com/akbartube51-a11y/chess-vision-pro

Developed under the AIM Akbar Hossain / Agartala Chess Academy ecosystem.
