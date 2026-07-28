# Chess Vision Pro Mobile

Flutter app for offline chess puzzles and engine-assisted analysis.

## Features

- Puzzle browsing and solving
- Local progress tracking with SQLite
- Analysis board with undo and move history
- Stockfish-powered hints and quick analysis
- Light, dark, and system themes

## Tech stack

- Flutter
- Dart 3
- provider
- go_router
- sqflite
- shared_preferences

## Getting started

```bash
git clone https://github.com/akbartube51-a11y/chess-vision-pro-app.git
cd chess-vision-pro-app
flutter pub get
flutter run
```

## Prerequisites

- Flutter SDK 3.22 or newer
- Android Studio for Android or Xcode for iOS
- Git

## Build

```bash
flutter build apk --release
flutter build appbundle --release
flutter build ios --release
```

## Tests

```bash
flutter test
```

## Engine configuration

```bash
flutter run --dart-define=STOCKFISH_EXECUTABLE=/path/to/stockfish
```

## Project layout

```text
lib/
  core/
  features/
  shared/
```

## Credits

- Desktop reference: https://github.com/akbartube51-a11y/chess-vision-pro
- AIM Akbar Hossain / Agartala Chess Academy ecosystem
