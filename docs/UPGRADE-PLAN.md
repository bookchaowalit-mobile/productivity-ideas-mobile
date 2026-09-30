# Upgrade Plan — Ideas Mobile

## Current state

Score: 7.5/10 — persisted ICE ranking with re-scoring, duplicate-safe restore, undo, a11y guideline tests and fail-closed signing; no export, icon or E2E flow yet.

## Backlog

### P0
- None open. (Release signing now fails closed without `android/key.properties`.)

### P1
- Export ideas as CSV/Markdown.
- Replace the template launcher icon with a real app icon (the application ID `com.bookchaowalit.*` is already set).
- Add a Maestro smoke flow for the main journey.
- Add a CI job that builds a signed release bundle from repository secrets (keystore decoded at runtime, never committed).

### P2
- Tablet layout (NavigationRail).
- Localisation (Thai/English) for UI strings.

## Done in this pass (pass 3)

- Bug fix: adding blocks a duplicate of an active idea, but restoring an archived idea did not, so "Dark mode" could end up active twice. Restore is now refused with a message when an active idea has the same title (`restoreWouldDuplicate`).
- Bug fix: duplicate detection ignored repeated whitespace differences (`Dark  mode` vs `dark mode`); the 120-character limit counted UTF-16 code units (now visible characters via `characters`, a direct dependency).
- P1 done: tap an idea to re-score it (dialog with impact/confidence/ease sliders and a live ICE preview; `copyWith` accepts scores and still validates 1–10).
- Error state: delete offers Undo (restores the original position). Rank badges are announced as "Rank N"; the ICE preview row wraps at large text.
- Edge-case unit tests: tier boundaries (49/50/149/150/399/400), min/max scores, whitespace duplicates, emoji limits, restore duplicates, re-score validation, malformed JSON scores, empty rankings. Widget tests: blocked duplicate restore, re-score flow, undo delete, a11y guidelines, 200% text scale at phone width.

## Done in pass 2

- Release builds no longer sign with the debug key: `android/app/build.gradle.kts` reads the ignored `android/key.properties` and a Gradle guard fails any release assemble/bundle without it (pattern from `bookchaowalit-goal-tracker-mobile`). Root `.gitignore` also ignores `key.properties`, `*.jks`, `*.keystore`; README documents the setup. Not build-verified here (no Android SDK/Gradle in this environment).
- Ideas now persist on device via `lib/data/list_repository.dart` (`ListRepository` interface, `shared_preferences` JSON store that skips malformed records such as scores outside 1-10, in-memory store for tests); the home screen loads on start, saves after add/archive/restore/delete and shows an error line when storage fails.
- Added repository tests (round trip, empty, malformed records, non-list payload) and widget tests for restore/archive-save and load failure.

## Done in pass 1

- Replaced the Expo/npm CI (which could never fail) with fail-closed Flutter CI: `dart format` check, `flutter analyze`, `flutter test`, debug APK on `main`.
- Implemented the core feature (capture ideas and rank them with ice (impact, confidence, ease) scoring) with pure-Dart logic in `lib/logic/`.
- Replaced placeholder Explore/Profile tabs with an About screen describing features and privacy.
- Added unit tests for the logic and widget tests for the main journey.
- Removed unused `go_router` / `flutter_riverpod` dependencies; README now matches the code.
