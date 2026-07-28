# Privacy & Permissions

Chess Vision Pro stores puzzle content, sync metadata, solve progress, board/theme preferences, and locale settings locally on the device.

## External requests

- The app only makes network requests when the user triggers puzzle sync.
- Sync requests target the configured CSV URL in Settings, or the bundled sample mirror used for development/testing.
- The current implementation does not include analytics SDKs, ad SDKs, or background telemetry.

## Local storage

- SQLite stores puzzle rows, progress, and incremental sync state (`last_synced_at`, cursor, dataset version/hash, attribution, last error).
- Shared Preferences stores presentation settings such as theme, board preset, piece style, coordinate style, language, and the optional puzzle source URL.

## Source requirements

Only import openly licensed data. The included source adapter is designed for Lichess-compatible CSV exports and stores attribution metadata so contributors can document where puzzle data came from.

For large Lichess exports, use a decompressed CSV mirror or preprocess the `.zst` archive outside the app before hosting/importing it.

## Permissions

No special runtime permissions are required by the current feature set. Future desktop file import and richer speech integrations may introduce platform-specific prompts, which should be documented before release.
