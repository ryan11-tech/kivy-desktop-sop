# Tea SOP

Kivy desktop app for tea / milk-tea Standard Operating Procedure cards. Phone-shape window, single-user kiosk style.

## Run

```
pip install kivy
python main.py
```

Default PIN: `2222` (staff) / `1234` (admin).

## Project guide

See [CLAUDE.md](CLAUDE.md) for architecture, schema, conventions, and known debt.

# ZinmeAPP

Flutter starter for the Zinme tea recipe and SOP app.

This repository is now a Flutter app. The old Kivy implementation is preserved
under `legacy/kivy_desktop_sop/` for reference only.

## Current State

- Flutter 3.41.6 / Dart 3.11.4 target.
- Android and iOS project shells are generated.
- Staff authentication uses the Zin Mae backend API with persisted Better Auth
  cookies.
- Staff can load assigned shops, choose an active shop, browse published SOPs
  and recipes from the backend, refresh catalogs, use favorites, configure local
  settings, and unlock with a per-user device PIN.
- Admin users can manage staff access and basic recipe/SOP content through the
  backend portal APIs.
- Bundled mock SOP/recipe data is only a development fallback when explicitly
  enabled with `--dart-define`.

## Run

```sh
flutter pub get
flutter run
```

## Verify

```sh
dart format .
flutter analyze
flutter test
```

## Product Docs

- [PRD-flutter.md](PRD-flutter.md)
- [ARCHITECTURE-flutter.md](ARCHITECTURE-flutter.md)
- [docs/CODE_CONVENTIONS.md](docs/CODE_CONVENTIONS.md)
- [docs/AI_CODING_RULES.md](docs/AI_CODING_RULES.md)
- [docs/FIREBASE_SETUP.md](docs/FIREBASE_SETUP.md)

## Architecture

```text
lib/
  main.dart
  app.dart
  theme/
  core/
    auth/
    api/
    firestore/
    models/
    recipes/
    sops/
    staff/
    search/
  features/
  widgets/
```

Screens and widgets must not create HTTP clients directly. Keep backend access
behind repositories or `StaffApiClient`, keep app state in
controllers/providers, and keep model serialization and validation in
`core/models`.
