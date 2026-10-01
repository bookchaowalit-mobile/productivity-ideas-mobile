# Ideas — Mobile

Capture ideas and rank them with ICE (impact, confidence, ease) scoring.

Part of [Chaowalit Greepoke](https://bookchaowalit.com)'s 101 Portfolio Projects.

## Features

- Add ideas with impact, confidence and ease scores (1-10)
- Ranked by ICE score
- Archive and delete ideas

Data is saved on this device with `shared_preferences` (JSON under a
versioned key); there is no account, backend, analytics or network access.

## Tech Stack

- **Framework:** Flutter (CI pinned to 3.47.5) + Material 3
- **Language:** Dart
- **State:** `StatefulWidget` / `setState`; the core logic is pure Dart in
  `lib/logic/` and unit-tested without widgets
- **Persistence:** `shared_preferences` behind a small `ListRepository`
  interface in `lib/data/` (in-memory implementation for tests)

## Develop and verify

```bash
flutter pub get
dart format --output=none --set-exit-if-changed lib test
flutter analyze
flutter test
flutter run
```

CI (`.github/workflows/build.yml`) runs the same format/analyze/test checks
and fails closed; a debug APK is built on pushes to `main`.

## Build

```bash
# Android
flutter build apk --debug
```

Release builds (`flutter build apk --release` / `appbundle`) fail on purpose
until signing is configured; they never fall back to the debug key. To sign,
create an upload keystore outside the repo and add the ignored
`android/key.properties`:

```properties
storePassword=...
keyPassword=...
keyAlias=upload
storeFile=/absolute/path/to/upload-keystore.jks
```

Never commit `key.properties` or keystores (both are git-ignored).

## Related

- **Frontend:** [bookchaowalit-website/ideas-frontend](https://github.com/bookchaowalit-website/ideas-frontend)
- **Portfolio:** [bookchaowalit.com](https://bookchaowalit.com)

## License

MIT
