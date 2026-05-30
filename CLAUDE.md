# CLAUDE.md

> **This repository is the Flutter `ZinmeApp` staff app.** Despite the folder
> name (`kivy-desktop-sop`), the active app is Flutter — Material 3, Dio with
> persisted Better Auth cookies, Provider for state, backed by the Zin Mae API.
> The old Python/Kivy app is preserved under `legacy/kivy_desktop_sop/` for
> reference only. Do not treat the legacy Kivy guide as current.

## Read these first (canonical, in order)

1. [`AGENTS.md`](AGENTS.md) — project guide, architecture rules, code conventions, testing. The `ZinmeAPP - Project Guide` section is the current one; the `Tea SOP` section above it is legacy Kivy.
2. [`ARCHITECTURE-flutter.md`](ARCHITECTURE-flutter.md) — backend API contract and client architecture.
3. [`PRD-flutter.md`](PRD-flutter.md) — product behavior, roles, access states.
4. [`docs/CODE_CONVENTIONS.md`](docs/CODE_CONVENTIONS.md) and [`docs/AI_CODING_RULES.md`](docs/AI_CODING_RULES.md) — quality and AI guardrails.

This file defers to `AGENTS.md` for shared guidance. Do not duplicate it here.

## What the app does today

- Staff log in against the Zin Mae backend (`/api/staff/*`), persist the Better Auth session cookie, and change a temporary password on first login.
- Staff load assigned shops and pick an active shop (multi-shop staff see a selector; single-shop staff skip it).
- Published SOPs and recipes load from the backend for the active shop; favorites and local settings work; a per-device PIN unlock gates the app.
- Admin users manage staff access and basic SOP/recipe content through the portal APIs.
- Bundled mock SOP/recipe data is a dev-only fallback, enabled with `--dart-define` (`USE_API_CATALOG=false`).

## Source layout

```text
lib/
  main.dart, app.dart
  theme/                  app_colors.dart, app_theme.dart
  core/
    api/                  StaffApiClient, cookie store, API models
    auth/                 access controller, PIN lock + credential store
    staff/                staff session controller/state, secure store, shop, connectivity
    sops/  recipes/       remote + fallback repositories, catalog controllers, category mappers
    models/  search/  preferences/  firestore/  security/
  features/               staff_auth, home, category, item_detail, item_form,
                          favorites, settings, admin_users, pin, no_access, ...
  widgets/
```

Rules (full list in `AGENTS.md`): screens never create HTTP clients — go through repositories or `StaffApiClient`; controllers/providers own state; models own serialization; read `contentType`, never infer recipe vs SOP from populated fields; staff/admin visibility is a permission rule, not just a widget condition.

## Verify loop

```sh
dart format .
flutter analyze
flutter test
```

## Known debt

- Settings persists theme-mode / primary-color / language, but only the PIN toggle and font-size actually apply. Wiring the rest needs a design-system pass (screens hardcode `AppColors.*` instead of going through `Theme`) plus `flutter_localizations` for l10n.
- PIN is a per-device 4-digit default `2222`; per-user / server-issued PIN is planned later.
- Legacy Kivy app under `legacy/kivy_desktop_sop/` is frozen — edit only on explicit request.
