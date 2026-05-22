# Code Conventions

## Dart And Flutter

- Keep widgets focused on layout, interaction, and view formatting.
- Keep domain decisions in models, repositories, controllers, or providers.
- Use immutable models with explicit constructors.
- Use `Map<String, Object?>` at JSON boundaries.
- Avoid `dynamic` outside narrow parser boundaries.
- Prefer `Future` and `Stream` APIs from repositories instead of passing SDK
  objects into UI.
- Prefer composition over inheritance for widgets and services.
- Keep feature folders shallow until complexity proves they need subdivision.

## Naming

- Dart package name: `zinme_app`.
- App display name: `ZinmeAPP`.
- Content enum values match stored Firestore strings:
  - `recipe`
  - `sop`
  - `draft`
  - `published`
  - `admin`
  - `staff`
  - `none`
  - `pending`
  - `active`
  - `disabled`

## State And Routing

- Use Riverpod when app state moves beyond the current mock setup.
- Use `go_router` when auth/no-access/main/detail routing becomes real.
- Do not introduce Provider, BLoC, GetX, or a custom event bus.
- Keep Firebase listeners in repositories or provider-backed controllers.

## UI

- Use Material 3 components.
- Dark red, black, dark surface, and gold remain the primary identity.
- Staff workflows should optimize for scanning and repeated use.
- Use icons for frequent actions such as add, edit, delete, favorite, search,
  lock, and settings.
- Do not create marketing or landing pages inside the app flow.
- Admin controls must be clearly separated from staff actions.

## Errors

- User-facing errors should be plain and actionable.
- Pending users must see only no-access state and profile/access refresh actions.
- Offline state must not claim cached shop content is valid.
- Repository errors should preserve enough context for logs and tests.

## Dependencies

Allowed planned dependencies from the PRD:

- `firebase_core`
- `firebase_auth`
- `cloud_firestore`
- `firebase_storage`
- `cloud_functions`
- `flutter_riverpod`
- `go_router`
- `shared_preferences`
- `flutter_secure_storage`
- `connectivity_plus`
- `cached_network_image`
- `flutter_lints`

Add them only when implementing the feature that needs them.
