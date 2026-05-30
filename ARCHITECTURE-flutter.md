# ZinmeAPP - Flutter + Zin Mae Backend API Architecture

Companion to [PRD-flutter.md](./PRD-flutter.md).

Current v1 implementation stack:

- Flutter Material app.
- Zin Mae backend API for auth, staff session refresh, shops, SOPs, and
  recipes, and admin CRUD.
- Dio with cookie persistence for backend API sessions.
- Provider / ChangeNotifier for app state.
- SharedPreferences for local user preferences and local favorites.
- FlutterSecureStorage for per-user/device PIN verifiers.

- No offline mode in v1.

Firebase, Riverpod, and go_router notes in older documents are historical or
future-only. Do not migrate to them in this pass.

---

## 1. High-level system

```mermaid
flowchart LR
    subgraph Devices["Shop devices"]
        Staff["Staff app - Flutter"]
    end

    subgraph App["Flutter app"]
        UI["Screens"]
        State["Provider / ChangeNotifier controllers"]
        Repo["Repositories"]
        Dio["Dio API client + cookie store"]
    end

    subgraph Backend["Zin Mae backend"]
        Auth["Better Auth session endpoints"]
        API["Staff, shop, recipe, and SOP APIs"]
        DB["Backend database"]
    end

    Staff --> UI
    UI --> State
    State --> Repo
    Repo --> Dio
    Dio --> Auth
    Dio --> API
    API --> DB
```

The Flutter app is staff-facing by default. Admin accounts can also manage
staff access and basic recipe/SOP content through the same backend portal APIs.
Server-side backend permissions determine which shops and content can be read or
mutated.

---

## 2. Client layers

```mermaid
flowchart TB
    UI["Screens and widgets"]
    State["Provider / ChangeNotifier controllers"]
    Repo["Repositories"]
    Models["Typed models and serializers"]
    API["Dio StaffApiClient"]
    Backend["Zin Mae backend API"]

    UI --> State
    State --> Repo
    Repo --> Models
    Repo --> API
    API --> Backend
```

Rule: screens never call Dio or backend APIs directly. They consume typed
models and state from repositories/controllers, or use the shared
`StaffApiClient` for admin portal operations.

```text
lib/
  main.dart
  app.dart
  theme/
  l10n/
  core/
    auth/
    firestore/
    models/
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

---

## 3. Historical Firebase target, not current v1

The remaining Firebase-oriented flow is retained as historical planning context
only. Current implementation uses the Zin Mae backend API stack described
above.

### Registration and access flow

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant A as Flutter app
    participant Auth as Firebase Auth
    participant CF as Cloud Functions
    participant FS as Firestore

    U->>A: Register with Gmail/email + password
    A->>Auth: createUserWithEmailAndPassword
    Auth-->>CF: onAuthUserCreate trigger
    CF->>FS: create /users/{uid}
    CF->>FS: check bootstrap admin list and memberGrants
    alt email is bootstrap admin
        CF->>FS: create shops/{shopId}/members/{uid} role=admin active
        CF->>Auth: set custom claims admin
    else email has active grant
        CF->>FS: create shops/{shopId}/members/{uid} granted role active
        CF->>Auth: set custom claims role
    else no grant
        CF->>FS: create pending profile only
        CF->>Auth: set claims role=none pending
    end
    A->>Auth: force refresh token
    alt active role
        A->>U: Main app
    else no permission
        A->>U: No access screen
    end
```

No shop content is read until the refreshed token has an active `staff` or
`admin` claim for the configured shop.

---

## 4. Admin grants access by Gmail/email

```mermaid
sequenceDiagram
    autonumber
    participant Admin as Admin app
    participant CF as assignMemberByEmail
    participant Auth as Firebase Auth
    participant FS as Firestore

    Admin->>CF: {email, role}
    CF->>Auth: verify caller has admin claim
    CF->>FS: write shops/{shopId}/memberGrants/{emailKey}
    opt user already exists
        CF->>FS: write shops/{shopId}/members/{uid}
        CF->>Auth: set custom claims {shopId, role, active}
    end
    CF-->>Admin: success
```

If the user registers later, `onAuthUserCreate` picks up the existing grant and
activates the user.

---

## 5. Local PIN unlock

```mermaid
sequenceDiagram
    autonumber
    participant U as User
    participant A as Flutter app
    participant Secure as Secure local storage
    participant Auth as Firebase Auth

    A->>U: First active login asks change default PIN 2222 or keep for now
    U->>A: Set or keep personal PIN
    A->>Secure: store salted PIN verifier for current uid/device
    A->>A: Lock on manual lock, background >30s, or 15m inactivity
    U->>A: Enter PIN
    A->>Secure: verify PIN for current uid
    A->>Auth: confirm Firebase session still exists
    alt valid session and PIN
        A->>U: Unlock app
    else 5 failed PIN attempts
        A->>U: Require email/password login
    else signed out or expired
        A->>U: Require email/password login
    end
```

The PIN is not a Firebase credential and does not grant server access by
itself. Biometric unlock is outside v1 and may be added later as an optional
shortcut after a personal PIN exists.

---

## 6. Content write path

```mermaid
sequenceDiagram
    autonumber
    participant Admin as Admin app
    participant Storage as Firebase Storage
    participant FS as Firestore
    participant Rules as Security Rules
    participant Staff as Staff app

    Admin->>Admin: Fill Recipe or SOP form and choose draft/published
    opt image selected
        Admin->>Storage: upload shops/{shopId}/items/{itemId}.jpg
        Storage-->>Admin: imageUrl and imagePath
    end
    Admin->>FS: set shops/{shopId}/items/{itemId}
    FS->>Rules: require role=admin and active
    Rules-->>FS: allow
    FS-->>Admin: ack
    opt status is published
        FS-->>Staff: listener update
    end
```

`contentType` determines whether the UI reads the `recipe` or `sop` section.
Staff listeners only receive published items. Admin listeners can include draft
and published items

Within those sections, `recipe.recipeType` and `sop.sopType` drive filtering,
form behavior, and detail-screen layout. Staff listeners only receive
published items. Admin listeners can include draft and published items.

---

## 7. Firestore data tree

```mermaid
flowchart TB
    root["Firestore root"]
    users["/users/{uid}"]
    shops["/shops/{shopId}"]
    members["/shops/{shopId}/members/{uid}"]
    grants["/shops/{shopId}/memberGrants/{emailKey}"]
    cats["/shops/{shopId}/categories/{categoryId}"]
    items["/shops/{shopId}/items/{itemId}"]
    favs["/shops/{shopId}/favorites/{uid}"]
    cfg["/shops/{shopId}/appConfig/global"]

    root --> users
    root --> shops
    shops --> members
    shops --> grants
    shops --> cats
    shops --> items
    shops --> favs
    shops --> cfg
```

`items` stores both recipes and SOPs. This keeps favorites, search, and
cross-category lists simple. Items use `status = draft | published`; deleted
items are permanently removed.

---

## 8. Security model

Custom claims:

```json
{
  "shopId": "main",
  "role": "staff",
  "accessStatus": "active"
}
```

Required enforcement:

- No auth: no access.
- `role=none` or `accessStatus=pending`: own profile/no-access state only.
- `staff active`: read categories/config, read published items, and write own
  favorites.
- `admin active`: manage content, categories, settings, and users.
- Storage item images: read active members only, write admins only.

The app may hide admin UI, but security rules and callable functions are the
source of truth.

---

## 9. Connectivity

v1 does not support offline mode.

```mermaid
flowchart LR
    App["Flutter app"] --> Conn["Connectivity monitor"]
    Conn --> Online["Online - normal Firebase reads/writes"]
    Conn --> Offline["Offline - show no connection state"]
```

When offline:

- block login/register/access refresh
- block writes
- show no-connection state or blocking banner
- do not promise cached content is current

---

## 10. Environments

```mermaid
flowchart LR
    Local["Local Flutter app"] --> Emulators["Firebase Emulator Suite"]
    Staging["Staging build"] --> StagingFB["Firebase staging project"]
    Prod["Production build"] --> ProdFB["Firebase production project"]
```

Use emulators for security-rules tests and access-flow tests.

---

## 11. Open architecture questions

- Should Google Sign-In be added, or is email/password enough?
- Should the bootstrap admin email live in Cloud Function config instead of
  client code before the first internal test?
