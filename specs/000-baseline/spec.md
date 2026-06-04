# Feature Specification: ZinmeApp (Flutter) Baseline (As-Built)

**Feature Branch**: `000-baseline`

**Created**: 2026-06-04

**Status**: Baseline

**Input**: Reverse-documented from the existing Flutter app codebase to anchor
future specs. This is not a feature to build — it records what `ZinmeApp`
already does so that new `specs/<NNN>-<name>/` work can reference a known
starting point. Detailed operational guidance stays in `AGENTS.md`,
`ARCHITECTURE-flutter.md`, `PRD-flutter.md`, and `docs/`; durable principles
stay in `.specify/memory/constitution.md`. The backend lives in a separate repo
(`zin_mae`) and is out of scope here except as the API this app consumes.

## System Overview

`ZinmeApp` is the Flutter staff app for the **Zin Mae tea shop** (Material 3,
Dio with persisted Better Auth cookies, Provider state). It consumes the Zin Mae
API at `/api/staff/*` and persists the Better Auth session cookie across
restarts.

- `lib/features/` (UI): `auth`/`staff_auth`, `home`, `category`,
  `item_detail`/`item_form`, `favorites`, `search`, `pin`, `settings`,
  `staff_profile`, `admin_users`, `attendance`, `schedule`, `no_access`.
- `lib/core/` (logic): `api` (StaffApiClient, cookie store, API models), `auth`
  (access controller, PIN lock + credential store), `staff` (session
  controller/state, profile), `sops`/`recipes` (remote + fallback repositories,
  catalog controllers, category mappers), `attendance` (controller, models,
  repository, location service), `preferences`, `security` (privacy-screen
  guard), `search`, `models`, `config`, `firestore` (local-repo namespace; no
  Firebase package dependency).
- `lib/theme/`, `lib/widgets/`.

## User Scenarios & Testing *(as-built)*

### User Story 1 - Staff use SOPs and recipes (Priority: P1)

A staff member logs in against the backend, changes a temporary password on
first login, picks an active shop (multi-shop staff see a selector; single-shop
staff skip it), and reads published SOPs and recipes for that shop. Favorites
and local settings work; a per-device PIN gates the app.

**Why this priority**: This is the core staff-facing value and the reason the
app exists.

**Independent Test**: Log in as a seeded staff user against a running backend,
select a shop, and confirm published SOP/recipe content loads and a favorite
persists.

**Acceptance Scenarios**:

1. **Given** valid staff credentials and a temporary password, **When** the
   staff logs in for the first time, **Then** they must set a new password
   before reaching the catalog.
2. **Given** a staff member assigned to multiple shops, **When** they log in,
   **Then** they must select an active shop before content loads.
3. **Given** a selected active shop, **When** the catalog loads, **Then** only
   published SOPs and recipes for that shop are shown, keyed off `contentType`.

---

### User Story 2 - Staff clock in/out with location (Priority: P2)

A staff member clocks in and out for the active shop. The app captures device
GPS via `geolocator` and submits it; the backend validates against the shop's
coordinates/radius and is the source of truth for session timing. The app shows
current status and attendance history.

**Why this priority**: Attendance is a primary staff-operations feature on the
app and depends on auth + active shop.

**Independent Test**: With a selected shop, clock in from the attendance card,
confirm status flips to clocked-in, clock out, and confirm history shows the
closed session with worked minutes.

**Acceptance Scenarios**:

1. **Given** location permission granted and position inside the shop radius,
   **When** the staff clocks in, **Then** the app shows a clocked-in state.
2. **Given** the backend rejects the location (outside radius), **When** the
   staff clocks in, **Then** the app surfaces the rejection rather than faking
   success.
3. **Given** an open session, **When** the staff clocks out, **Then** the app
   reflects the backend-computed worked time and updates history.

---

### User Story 3 - Staff manage their profile and local settings (Priority: P3)

A staff member views and edits their own profile, manages favorites, and adjusts
local settings; a per-device PIN unlock and a privacy-screen guard protect the
app.

**Why this priority**: Self-service and device-local protection improve daily
use but are independent of catalog and attendance.

**Independent Test**: Open the profile screen, edit an allowed field, confirm it
persists; lock and unlock with the PIN; background the app and confirm the
privacy screen guards content.

**Acceptance Scenarios**:

1. **Given** an authenticated staff member, **When** they edit an allowed
   profile field, **Then** the change persists through the backend.
2. **Given** PIN gating enabled, **When** the app is reopened, **Then** the PIN
   screen blocks access until the correct PIN is entered.

### Edge Cases

- First-login temporary-password change is mandatory before catalog access.
- Single-shop vs multi-shop staff take different shop-selection paths.
- App falls back to bundled mock SOP/recipe data only when
  `--dart-define USE_API_CATALOG=false` (dev only).
- Better Auth session cookie must survive across app restarts (persisted).
- Location permission denied or unavailable: clock-in/out reflects the failure
  rather than silently succeeding.
- PIN is a per-device 4-digit default (`2222`); per-user/server-issued PIN is
  planned later.

## Requirements *(as-built)*

### Functional Requirements

- **FR-001**: The app MUST authenticate against the backend at `/api/staff/*`,
  persist the Better Auth session cookie, and enforce first-login password
  change before reaching the catalog.
- **FR-002**: The app MUST resolve assigned shops and support active-shop
  selection (selector for multi-shop, skip for single-shop).
- **FR-003**: The app MUST read published SOP and recipe content for the active
  shop, reading the `contentType`/`type` discriminator explicitly, with a
  dev-only bundled mock fallback.
- **FR-004**: The app MUST gate access with a per-device PIN (credential store)
  and a privacy-screen guard, and persist favorites and local settings (user
  preferences).
- **FR-005**: The app MUST consume staff attendance at `/api/staff/attendance/*`
  — capturing device GPS via `geolocator` for clock-in/out and showing
  attendance status and history — treating the backend as the source of truth
  for session timing and acceptance.
- **FR-006**: The app MUST let staff view and edit their own profile, and let
  admin users manage staff access and basic content through the portal APIs,
  with all authorization enforced by the backend.

### Key Entities

- **Staff User**: the authenticated person and their session/profile state.
- **Shop**: an assigned location; one is the active shop driving content and
  attendance.
- **SOP / Recipe**: published content for the active shop, identified by
  `contentType`.
- **Attendance Session / Status / History**: client view of clock-in/out state
  and past sessions returned by the backend.
- **Favorite / Local Setting / Preference / PIN**: device-local state for staff
  convenience and access gating.

## Success Criteria *(as-built)*

- **SC-001**: A seeded staff user can log in, select a shop, and view published
  content end-to-end against a running backend.
- **SC-002**: A staff member can clock in within the shop radius and clock out,
  with history reflecting backend-computed worked time.
- **SC-003**: `dart format .`, `flutter analyze`, and `flutter test` pass.

## Assumptions

- The app and the web system share one backend domain and one Better Auth
  identity model; the backend owns all authorization.
- The app has a widget/unit test suite (`flutter test`, ~26 test files) covering
  attendance, recipes, preferences, staff profile, PIN credential store, and
  theme.
- Firebase, Riverpod, and `go_router` are not in use; `geolocator` is a
  dependency for attendance location. There is no local database in v1.
- The `kivy-desktop-sop` folder name is historical; the active app is Flutter.

## How To Extend This Baseline

1. Run `/speckit-specify` to draft a new feature into its own
   `specs/<NNN>-<name>/spec.md`.
2. Reference this baseline and `.specify/memory/constitution.md`; do not restate
   them — note only what changes relative to as-built.
3. Proceed through `/speckit-plan` → `/speckit-tasks` → `/speckit-implement`,
   honoring the constitution's quality gates.

### Canonical source-of-truth files

- `AGENTS.md`, `ARCHITECTURE-flutter.md`, `PRD-flutter.md`, `docs/`,
  `lib/main.dart`, `lib/app.dart`, `lib/core/api/`.
