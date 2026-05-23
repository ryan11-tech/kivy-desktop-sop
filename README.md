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
- The app has a small mocked catalog UI for recipes, SOPs, favorites, admin
  controls, recipe variants, and serving scaling.
- Firebase is not wired yet. Repository interfaces and model seams are already
  in place for that work.

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
    firestore/
    models/
    search/
  features/
  widgets/
```

Screens and widgets must not import Firebase SDK packages directly. Put
Firebase access behind repositories, put app state in controllers/providers, and
keep model serialization and validation in `core/models`.
