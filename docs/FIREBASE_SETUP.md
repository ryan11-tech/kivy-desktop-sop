# Firebase Setup Historical Placeholder

Firebase is intentionally not wired into the current v1 app. The active stack is
Zin Mae backend API + Dio cookies + Provider/ChangeNotifier. Use this file only
as historical planning context if a future Firebase migration is explicitly
approved.

## Planned Services

- Firebase Auth for email/password registration and sign-in.
- Firestore for users, members, categories, items, favorites, and app config.
- Storage for item images.
- Cloud Functions for member grants, custom claims, and cleanup triggers.

## Client Setup

1. Create Firebase projects for local/staging/prod.
2. Install and run FlutterFire CLI.
3. Generate `lib/firebase_options.dart`.
4. Add the PRD dependencies to `pubspec.yaml`.
5. Replace mock repositories with Firebase implementations.
6. Add Riverpod providers for auth, access, catalog, favorites, and settings.
7. Add `go_router` routes for auth, no-access, main app, detail, forms, and
   admin screens.

## Required Tests

- Emulator tests for Firestore and Storage rules.
- Unit tests for repository visibility filtering.
- Widget tests for signed-out, pending, staff, and admin gates.

## Security Rules Baseline

- Signed-out users read/write nothing.
- Pending users read only their own profile and access state.
- Active staff read published shop content and write their own favorites.
- Active admins manage content, categories, settings, members, grants, and
  images.
- Disabled users lose shop access after token refresh.
