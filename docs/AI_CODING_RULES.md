# AI Coding Rules

These rules are for AI-assisted work on ZinmeAPP.

## Before Editing

- Read `PRD-flutter.md`, `ARCHITECTURE-flutter.md`, and `AGENTS.md` for the
  area being changed.
- Inspect existing code before choosing a pattern.
- Keep changes small enough to verify.
- Do not modify `legacy/kivy_desktop_sop/` unless the task is explicitly about
  the archived Kivy app.

## During Implementation

- Respect the layer boundary: UI -> controllers/providers -> repositories ->
  models/backend API.
- Never import Dio or backend API clients directly in screens.
- Do not store shop content in local JSON or SQLite.
- Do not infer item type from field presence. Always read `contentType`.
- Keep identifiers stable. Do not regenerate IDs when names change.
- Keep staff/admin authorization decisions testable outside widgets.
- Prefer typed helpers over ad hoc string parsing.

## Historical Firebase Notes

Firebase is not part of the current v1 implementation. Treat Firebase,
Riverpod, and go_router references as future-only unless a separate migration
task explicitly reopens that direction.

## If Firebase Is Added Later

- Use FlutterFire CLI output for `firebase_options.dart`.
- Add security rules and emulator tests with any Firestore or Storage behavior.
- Force-refresh ID tokens after sign-in, registration, grant changes, and role
  changes.
- Treat client-side admin checks as convenience only.

## Verification

Every meaningful change should include one of:

- A unit test for models, search, permissions, scaling, or parsing.
- A widget test for visible flow behavior.
- A short manual verification note when the behavior cannot be automated yet.

Before committing, run:

```sh
dart format .
flutter analyze
flutter test
```

If a command cannot run because dependencies or network access are unavailable,
record that explicitly in the final response.
