# ZinmeApp (Flutter) Constitution

This repository is the Flutter **`ZinmeApp`** staff app for the **Zin Mae tea
shop** (Material 3, Dio with persisted Better Auth cookies, Provider state),
backed by the Zin Mae API at `/api/staff/*`. The folder name
(`kivy-desktop-sop`) is historical; the active app is Flutter. The legacy
Python/Kivy app is frozen under `legacy/kivy_desktop_sop/`.

This constitution states the durable principles for changes to this repo. It
does not replace `AGENTS.md`, `ARCHITECTURE-flutter.md`, `PRD-flutter.md`, or
`docs/`, which remain the canonical operational guides. The web system lives in
a separate repo (`zin_mae`) with its own constitution and owns the backend and
all authorization; this constitution is scoped to the app only.

## Core Principles

### I. Layered Separation of Concerns (NON-NEGOTIABLE)

Each layer has one job and may not reach past its neighbor.

- `features/` is UI. `core/` repositories and `StaffApiClient` are the only
  layers that know backend paths. Controllers/providers own state; models own
  serialization. Screens and widgets never create HTTP clients — they go through
  repositories or `StaffApiClient`.

A UI layer that performs its own IO, or a widget that builds an HTTP client, is
a defect regardless of whether it works.

### II. Backend Is the Source of Truth for Security

Authorization is decided by the backend. Flutter widget visibility and route
gating are **user-experience checks only** — hiding UI is not authorization.
Staff/admin visibility is a permission rule, not merely a widget condition. The
app persists the Better Auth session cookie and trusts the server's decisions.

### III. Explicit Contracts and Types

- Prefer small typed Dart classes over loose `Map<String, dynamic>`; use
  `Map<String, Object?>` only at JSON boundaries.
- Models own their own serialization; keep them aligned with the backend's
  documented payloads (`ARCHITECTURE-flutter.md`).
- Read the discriminator explicitly (`contentType` / `type`). Never infer
  whether an item is a SOP or a recipe from which fields happen to be populated.

### IV. Test Behavior, Not Just Types

`flutter analyze` is a gate, not behavior coverage. Behavior changes must add or
update tests for: model serialization, SOP/recipe visibility, amount scaling,
email normalization, search matching, attendance flow and location handling,
preferences, PIN credential store, and staff profile. Mock only external
boundaries. If test infrastructure is genuinely missing, document the gap and
the manual verification performed — do not silently skip.

### V. Minimal Footprint, No Premature Abstraction

Make the smallest change that solves the task and preserve behavior outside its
scope. Reuse the existing `core/`/`features/` layering and shared helpers before
adding new abstractions. Do not add a dependency unless the task (or the PRD)
requires it now. No DI container, plugin system, or bespoke framework inside the
app.

### VI. Convention Consistency

- Group imports as SDK / third-party / local, sorted within each group.
- Comment the non-obvious *why* (a constraint, a workaround); never restate what
  the code already says.
- No emojis in code, rule-bearing docs, or commit messages.
- Follow `docs/CODE_CONVENTIONS.md` and `docs/AI_CODING_RULES.md`.

### VII. Safe Data and Secrets

Never hardcode secrets. Persisted session cookies and PIN credentials are
sensitive — keep them in the existing secure stores. Avoid logging tokens or
personal data.

## Technology Constraints

- **Domain:** Zin Mae staff operations — read published SOP/recipe content for
  the active shop, favorites and local settings, per-device PIN unlock,
  attendance (clock-in/out with device GPS), staff profile, and basic admin
  management against the portal APIs.
- **Backend integration:** authenticate against `/api/staff/*`, persist the
  Better Auth session cookie, treat the Zin Mae API as the backend. Coordinate
  breaking contract changes with the `zin_mae` repo.
- **Dependencies:** `geolocator` is used for attendance location capture.
  Firebase, Riverpod, and `go_router` are NOT in use — future-only unless a task
  explicitly calls for them. There is no local database in v1; local state uses
  preferences/secure storage. (`docs/FIREBASE_SETUP.md` and a `core/firestore/`
  namespace exist but carry no Firebase package dependency.)
- **Legacy:** `legacy/kivy_desktop_sop/` (Python/Kivy) is frozen — edit only on
  explicit request.

## Development Workflow and Quality Gates

- Before committing, run `dart format .`, `flutter analyze`, and `flutter test`.
- **Every meaningful change** answers: were tests added/updated for changed
  behavior; do models still match the backend payloads; was authorization
  treated as a backend concern (not faked in the UI); were secrets/PII kept out
  of logs and committed files?

## Governance

- This constitution governs principles. `AGENTS.md` remains the canonical
  operational guidance and is expected to agree with it; if they conflict, the
  stricter rule wins and the conflict is resolved in the same change.
- New work flows through the spec-kit cycle: `/speckit-constitution` →
  `/speckit-specify` → (`/speckit-clarify`) → `/speckit-plan` →
  `/speckit-tasks` → `/speckit-implement`. Each feature spec lives in its own
  `specs/<NNN>-<name>/` directory and must reference this constitution and the
  baseline in `specs/000-baseline/`.
- Amendments require updating this file, bumping the version, and noting the
  rationale. Complexity that violates a principle must be justified in the spec
  that introduces it or it is rejected.

**Version**: 1.0.0 | **Ratified**: 2026-06-04 | **Last Amended**: 2026-06-04
