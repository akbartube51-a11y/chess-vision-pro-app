# Chess Vision Pro Mobile

![Flutter](https://img.shields.io/badge/Flutter-3.x-blue?logo=flutter)
![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)
![Platform](https://img.shields.io/badge/Android%20%7C%20iOS-supported-brightgreen)

Chess Vision Pro Mobile is an Android + iOS Flutter app for the Chess Vision Pro ecosystem. It is designed for offline-first puzzle solving, local progress tracking, and engine-assisted analysis.

## What it does

- Browse and solve chess puzzles on a mobile board
- Track puzzle progress locally with SQLite
- Review moves and analyze positions
- Use engine-powered hints and quick analysis when Stockfish is available
- Support light, dark, and system themes

## Project status

### Completed

- Flutter cross-platform app foundation
- Puzzle list/browse with rating, themes, and difficulty labels
- Interactive chessboard puzzle solving with FEN-based movement
- Analysis board with move history and undo
- Local persistence via SQLite
- Resume-aware progress tracking
- Light, dark, and system themes
- Auto-flip board for Black
- Seeded sample puzzle set
- Android and iOS support from a single codebase
- Provider-based architecture with routing and repository abstraction
- Baseline test coverage for chess logic and board rendering
- Stockfish 18 engine integration for analysis and hints

### Remaining work

- Online puzzle sync/import pipeline
- Larger puzzle dataset
- Advanced training modes
- Richer accessibility and voice guidance
- Localization / internationalization
- Expanded tests
- CI quality gates
- Release/signing automation
- Privacy and permissions screens
- Contribution guidelines and roadmap

## Tech stack

- Flutter
- Dart 3
- provider
- go_router
- sqflite
- shared_preferences

## Repository structure

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
    chess_logic.dart
    widgets/chess_board_widget
```

## Getting started

```bash
git clone https://github.com/akbartube51-a11y/chess-vision-pro-app.git
cd chess-vision-pro-app
flutter pub get
flutter run
```

## Prerequisites

1. Flutter SDK 3.22 or newer
2. Android Studio for Android or Xcode for iOS
3. Git

Check your environment:

```bash
flutter doctor
```

## Build

### Android debug APK

```bash
flutter build apk --debug
```

### Android release APK

```bash
flutter build apk --release
```

### Android App Bundle

```bash
flutter build appbundle --release
```

### iOS release build

```bash
flutter build ios --release
```

> iOS release builds require Apple Developer certificates and provisioning profiles.

## Tests

```bash
flutter test
```

## Engine configuration

If Stockfish is not bundled in your environment, point the app to the executable:

```bash
flutter run --dart-define=STOCKFISH_EXECUTABLE=/path/to/stockfish
```

## Accessibility

- Large readable typography
- 44×44 dp minimum touch targets
- Semantic board labels
- Good board and analysis contrast
- System theme auto-mode

## Release requirements

- Android keystore and signing config
- iOS Team / Bundle ID / provisioning setup
- Store listing assets and privacy policy

## Credits

- Desktop ecosystem reference: https://github.com/akbartube51-a11y/chess-vision-pro
- Developed under the AIM Akbar Hossain / Agartala Chess Academy ecosystem
