# Chess Vision Pro

Chess Vision Pro is a Flutter puzzle-training app focused on offline-first tactics practice, accessibility, and modular data import.

## Highlights

- **Online puzzle sync pipeline** with a source abstraction, retry/backoff orchestration, chunked imports, and incremental sync metadata.
- **Larger dataset support** through lazy list pagination, batched database upserts, rating/source indexes, and stream-based CSV parsing.
- **Advanced training modes**: classic, timed, streak, theme-focused, and review queue foundations.
- **Accessibility improvements**: semantic chessboard labels, keyboard-first board navigation, configurable voice guidance, and clearer focus states.
- **Localization scaffolding** using Flutter `gen-l10n` with English + Spanish baseline locale support.
- **Board modernization** with configurable board presets, piece styles, coordinate layouts, and persistent UI preferences.
- **Quality gates** via GitHub Actions for formatting, analysis, tests, and debug Android builds.
- **Release scaffolding** for future desktop artifacts and signing prerequisites.

## Architecture overview

```text
lib/
  core/
    accessibility/
    localization/
    routing/
    services/
    theme/
  features/
    analysis/
    home/
    puzzles/
      data/
      domain/
      presentation/
    settings/
  shared/
```

### Puzzle sync/import pipeline

- `PuzzleSource` defines a reusable contract for remote feeds.
- `LichessPuzzleSource` streams a Lichess-compatible CSV export line-by-line.
- `PuzzleSyncService` applies retry/backoff and persists incremental sync metadata.
- `PuzzleRepository` upserts imported puzzles in batches and stores sync state locally.

The default sample URL points at the repository fixture for safe development/testing. For full Lichess exports, host a **decompressed CSV mirror** or preprocess the `.zst` archive outside the app before import.

## Data source and licensing notes

- Import **only openly licensed** sources such as CC0 / CC BY datasets.
- Sync metadata stores attribution, cursor, dataset version/hash, and last sync time.
- Do not commit proprietary puzzle datasets or signing secrets.

## Getting started

```bash
git clone https://github.com/akbartube51-a11y/chess-vision-pro-app.git
cd chess-vision-pro-app
flutter pub get
flutter gen-l10n
flutter run
```

### Optional engine configuration

```bash
flutter run --dart-define=STOCKFISH_EXECUTABLE=/path/to/stockfish
```

## Import/bootstrap workflow

Normalize a remote CSV feed into newline-delimited JSON for offline processing:

```bash
dart run tool/bootstrap_puzzles.dart --output=/tmp/puzzles.jsonl
```

Optional flags:

- `--url=https://example.com/puzzles.csv`
- `--batch-size=500`

## Testing and validation

```bash
flutter gen-l10n
flutter test
flutter analyze --fatal-infos
dart format --output=none --set-exit-if-changed .
```

## CI

`.github/workflows/flutter_ci.yml` runs:

- `flutter pub get`
- `dart format --output=none --set-exit-if-changed .`
- `flutter analyze --fatal-infos`
- `flutter test`
- `flutter build apk --debug`

## Release and signing automation

`.github/workflows/release.yml` provides a manual/tag-triggered scaffold for Linux, Windows, and macOS artifacts. The workflow skips platforms until the generated platform folders exist.

Recommended secrets before enabling signing/notarization:

- `MACOS_CERTIFICATE`
- `MACOS_CERTIFICATE_PASSWORD`
- `WINDOWS_PFX_BASE64`
- `WINDOWS_PFX_PASSWORD`

## Accessibility and privacy

- The chessboard supports keyboard navigation with arrow keys plus Enter/Space to play moves.
- Voice guidance can be toggled and switched between concise and detailed modes.
- Privacy information is available in-app and in [`docs/privacy_and_permissions.md`](docs/privacy_and_permissions.md).

## More docs

- [CONTRIBUTING.md](CONTRIBUTING.md)
- [ROADMAP.md](ROADMAP.md)
- [docs/privacy_and_permissions.md](docs/privacy_and_permissions.md)
