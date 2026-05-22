# ZinmeAPP - Project Guide

A Flutter app for tea / milk-tea recipes and shop SOPs. The app is mobile-first
for Android and iOS, with Firebase planned for Auth, Firestore, Storage, and
Cloud Functions.

The old Kivy implementation lives in `legacy/kivy_desktop_sop/`. Do not edit it
unless the user specifically asks for legacy reference work.

## Stack

- Flutter stable, currently Flutter 3.41.6 with Dart 3.11.4.
- Material 3.
- Firebase later: `firebase_core`, `firebase_auth`, `cloud_firestore`,
  `firebase_storage`, and `cloud_functions`.
- Planned state/routing: Riverpod and `go_router`.
- No SQLite, no local JSON datastore, no offline-first database in v1.

## Architecture

```text
lib/
  main.dart
  app.dart
  theme/
    app_colors.dart
    app_theme.dart
  core/
    auth/
    firestore/
    models/
    search/
  features/
    auth/
    no_access/
    home/
    category/
    item_detail/
    item_form/
    favorites/
    settings/
    admin_users/
  widgets/
```

Rules:

- Screens and widgets do not import Firebase SDK packages.
- Repositories are the only client layer that knows Firebase collection paths.
- Controllers/providers own app state and workflow decisions.
- Models own serialization, parsing, validation, and small domain helpers.
- UI must read `contentType`; never infer recipe vs SOP from populated fields.
- Staff/admin visibility is a permission rule, not a widget condition only.

## Product Source Of Truth

- `PRD-flutter.md` defines product behavior.
- `ARCHITECTURE-flutter.md` defines the Firebase and client architecture.
- `docs/CODE_CONVENTIONS.md` defines code quality standards.
- `docs/AI_CODING_RULES.md` defines guardrails for AI-assisted coding.

## Code Conventions

- Prefer small typed Dart classes over loosely typed `Map<String, dynamic>`.
- Use `Map<String, Object?>` for JSON boundaries.
- Keep imports grouped as Dart SDK, Flutter/package, local; sort within groups.
- Prefer `const` widgets and immutable model objects.
- Do not add a dependency unless the feature needs it now or the PRD already
  names it for the current implementation step.
- Do not mix Riverpod and Provider.
- Do not put business logic in widgets beyond simple view formatting.
- Avoid broad `catch` blocks. Catch the specific exception that can be handled.
- No comments that restate obvious code. Comment constraints and tradeoffs only.
- No emojis in code, docs intended for rules, or commit messages.

## Firebase Boundaries

When Firebase is added:

- Add `firebase_options.dart` through FlutterFire CLI, do not hand-write config.
- Put Firestore reads/writes in `core/firestore/*_repository.dart`.
- Put Auth session and custom-claim refresh logic in `core/auth`.
- Put Cloud Functions calls behind repository/controller methods.
- Security rules are the source of truth. UI hiding is not authorization.

## Testing

Minimum expected test coverage for new behavior:

- Model serialization and validation.
- Recipe and SOP visibility rules.
- Amount scaling.
- Email normalization and member grant keys.
- Search matching.
- Widget tests for main flows touched by the change.

Run before committing:

```sh
dart format .
flutter analyze
flutter test
```
