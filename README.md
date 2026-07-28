# Chess Vision Pro Mobile (Flutter)

Chess Vision Pro Mobile is the Android + iOS companion app for the Chess Vision Pro ecosystem, focused on **offline-first puzzle solving** and **engine-assisted analysis**.

- Mobile repo: https://github.com/akbartube51-a11y/chess-vision-pro-app
- Desktop reference: https://github.com/akbartube51-a11y/chess-vision-pro

---

## ✅ Code Completed

- [x] Flutter cross-platform app foundation established
- [x] Puzzle list/browse with rating, themes, and difficulty label
- [x] Interactive chessboard puzzle solving (tap-to-move, FEN-based)
- [x] Analysis board with move history and undo
- [x] Local persistence via SQLite (puzzle progress tracking)
- [x] Resume-aware progress (solved count, attempts)
- [x] Light + dark + system themes
- [x] Auto-flip board for Black
- [x] 10 built-in sample puzzles (seeded on first launch)
- [x] Android + iOS support from single codebase
- [x] Core architecture with providers, routing, repository abstraction, and reusable chess board widget
- [x] Baseline test coverage for chess logic and board rendering

---

## 🚧 Remaining Task List

- [x] Integrate **Stockfish 18** chess engine for stronger analysis and hints
- [ ] Add online puzzle sync/import pipeline (optional cloud mode)
- [ ] Expand puzzle dataset beyond seeded sample set
- [ ] Add advanced training modes (timed drills, custom themes, streak tracking)
- [ ] Improve accessibility with richer screen-reader semantics and voice guidance
- [ ] Add localization/internationalization support
- [ ] Increase test coverage (state management, repository layer, end-to-end flows)
- [ ] Add CI quality gates (format, analyze, test) on pull requests
- [ ] Add production-grade release pipeline and signing automation
- [ ] Add in-app privacy/permissions explainer screens
- [ ] Publish contribution guidelines and development roadmap

---

## Tech Stack

- **Flutter** (cross-platform UI)
- **Dart 3**
- **provider** — state management
- **go_router** — navigation
- **sqflite** — SQLite local storage
- **shared_preferences** — settings persistence

---

## App Architecture

```text
lib/
  core/
    theme/          ← AppTheme (light/dark + ChessBoardTheme extension)
    routing/        ← go_router configuration
    services/       ← DatabaseService (sqflite)
  features/
    home/           ← HomeScreen (dashboard + progress)
    puzzles/
      data/         ← PuzzleRepository, sample puzzle data
      domain/       ← Puzzle, PuzzleProgress models
      presentation/ ← PuzzleListScreen, PuzzleScreen, PuzzleProvider
    analysis/       ← AnalysisScreen (free-play board)
    settings/       ← SettingsScreen, SettingsProvider
  shared/
    chess_logic.dart            ← FEN parser, BoardState, Square, Piece
    widgets/chess_board_widget  ← Reusable board UI
```

Principles:
- Repository abstraction between UI and SQLite
- ChangeNotifier-based providers for reactive UI
- Offline-first: all data stored locally

### Engine integration details
- Added `ChessEngineService` abstraction for best-move + MultiPV + evaluation output.
- Added `StockfishChessEngineService` (UCI process adapter) with timeout/error handling.
- Puzzle screen now has a hint action backed by engine analysis.
- Analysis board now has a quick analysis action backed by engine analysis.
- If Stockfish is unavailable, the app shows a friendly message and continues without crashing.
- Configure engine executable path with `--dart-define=STOCKFISH_EXECUTABLE=/path/to/stockfish` when needed.

---

## Prerequisites

1. Flutter SDK ≥ 3.22 (`flutter --version`)
2. Android Studio (Android toolchain) or Xcode (iOS, macOS only)
3. Git

```bash
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

The app seeds 10 sample puzzles into SQLite on first launch.

---

## Build Commands

### Android APK (debug)

```bash
flutter build apk --debug
```

### Android APK (release)

```bash
flutter build apk --release
```

### Android App Bundle (Play Store)

```bash
flutter build appbundle --release
```

### iOS (macOS only)

```bash
flutter build ios --release
```

> iOS release/signing requires Apple Developer certificates and provisioning profiles.

---

## Tests

```bash
flutter test
```

Tests currently cover:
- `chess_logic_test.dart` — FEN parsing, move application, Square, Puzzle model
- `widget_test.dart` — ChessBoardWidget rendering

---

## Accessibility Notes

- Large, readable typography defaults
- Sufficient touch target size (44×44 dp minimum via Flutter defaults)
- Semantic board labels (`a1`–`h8` overlaid on board)
- Theme contrast tuned for board and analysis readability
- System theme auto-mode supported

---

## Release Requirements

To produce distributable builds:

- Android keystore configuration (`key.properties`, signing config in `android/app/build.gradle`)
- iOS signing setup in Xcode (Team, Bundle ID, Provisioning)
- Store listing metadata (icons, screenshots, privacy policy)

---

## License & Credits

Desktop project concept and ecosystem:
- https://github.com/akbartube51-a11y/chess-vision-pro

Developed under the AIM Akbar Hossain / Agartala Chess Academy ecosystem.
