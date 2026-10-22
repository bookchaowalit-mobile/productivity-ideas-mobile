# Ideas — Mobile

## Template copy

This repo is one of the name-substituted Flutter template copies in
`bookchaowalit-mobile`. The canonical Flutter template is
[`bookchaowalit-mobile/education-coursenotes-mobile`](https://github.com/bookchaowalit-mobile/education-coursenotes-mobile);
fixes land there first and are copied here (this repo owns its copy, no shared
package). Consolidation or archiving is pending owner decision D5 (BD-033), see
`repository-catalog/portfolio/MOBILE-CONSOLIDATION-2026-10.md` in solo-empire.

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

CI (`.github/workflows/build.yml`) pins Flutter in the workflow `env`,
resolves dependencies with `flutter pub get --enforce-lockfile`, runs the same
format/analyze/test checks (all fail closed) plus the shared
`platform-ci-workflows` `security.yml` scan, and builds a debug APK on pushes
to `main`.

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
