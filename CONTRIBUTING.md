# Contributing

## Local setup

```bash
flutter pub get
flutter test
flutter analyze --fatal-infos
```

Use `dart format --output=none --set-exit-if-changed .` before submitting changes.

## Development workflow

1. Keep changes modular and repository-scoped.
2. Prefer extending existing providers/repositories over rewriting screens.
3. Preserve accessibility labels, keyboard support, and localization coverage when adding UI.
4. Only import openly licensed puzzle data; document attribution in code or PR notes.

## Puzzle data work

- The online sync adapter expects a Lichess-compatible CSV export.
- For very large datasets, sync/import in chunks and avoid loading entire exports into memory.
- Use `tool/bootstrap_puzzles.dart` to normalize a remote CSV source into newline-delimited JSON for offline workflows.

## CI and release

- Pull requests are gated by formatting, analysis, and tests in `.github/workflows/flutter_ci.yml`.
- Desktop release automation is scaffolded in `.github/workflows/release.yml`; generated `linux/`, `windows/`, or `macos/` folders and signing secrets must exist before enabling signed releases.
