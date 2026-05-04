# Tea SOP — Flutter + Firebase PRD

A Flutter rewrite of the existing Kivy desktop Tea SOP app, using Firebase as the
backend. Phone-shaped UI, kiosk-style usage in a tea/milk-tea shop. Staff prepare
drinks following parameters; admins maintain the recipe catalog.

This PRD is the source of truth for building the Flutter version. Defer to the
existing Kivy app (`./CLAUDE.md`, `./screens/*.py`) for visual/UX intent and recipe
domain rules — but **do not** carry over its JSON storage model.

---

## 1. Goals

- **Same domain** as the Kivy app: categories → recipes; recipes are one of three
  shapes (SOP, Drink, Steps); per-recipe servings multiplier.
- **Two roles**: `admin` (full CRUD on the catalog) and `staff` (read-only view +
  multiplier + favorites).
- **Firebase backend** — Firestore (recipe data), Firebase Auth (login), Firebase
  Storage (recipe images).
- **Multi-device, real-time sync**: an admin update on one device appears on staff
  tablets within seconds.
- **Mobile-first** Flutter (Android + iOS), but works on a tablet kiosk in
  portrait orientation. Window size proxy for desktop = 400×700.
- **Offline-tolerant for reads.** Staff devices should keep functioning if the
  Wi-Fi drops mid-shift. Writes can require connectivity.

## 2. Non-goals

- No multi-tenant / multi-shop support in v1. One Firebase project = one shop.
- No order tracking, sales analytics, or POS integration.
- No PDF export, printing, or recipe sharing to external apps.
- No SQL — Firestore only.
- No web build in v1 (Flutter web later if needed).

---

## 3. Users & roles

| Role | Capabilities |
|------|--------------|
| `admin`  | Everything `staff` can do. Create / edit / delete categories. Create / edit / delete recipes. Upload images. Change app settings. Change PINs. Manage user accounts (invite/remove). |
| `staff`  | Sign in. Browse categories. View recipes. Apply servings multiplier (×1…×99). Toggle personal favorites. Search. Switch theme/language locally. |

There is no "guest" role. All access requires sign-in.

### Auth flow

- **Admin** signs in with **email + password** (Firebase Auth). Admins are
  invited by another admin (creates the Auth user + assigns `role: admin` in
  Firestore). The first admin is bootstrapped manually in the Firebase console.
- **Staff** signs in with a **shared shop PIN** mapped to a single shop-wide
  staff account. PIN auth is implemented as: client posts `{pin}` to a Cloud
  Function which verifies against `secrets/staff_pin` (hash + pepper) and
  returns a custom token. Client signs in with `signInWithCustomToken`.
- The PIN can be rotated by an admin from Settings.
- Default after app launch = signed-out → PIN screen (matches current Kivy UX).
  Admins use a "Sign in as admin" link from the PIN screen to switch to
  email/password auth.

### Role enforcement

- Role is stored in `users/{uid}.role` and mirrored into a Firebase Auth
  **custom claim** (`role: admin | staff`) by a Cloud Function whenever the
  Firestore doc changes. Security rules check the claim — never trust the
  client.
- Mode switching ("Admin Mode" vs "Staff Mode") inside the app is a UI affordance
  only; it shows/hides admin buttons. The actual permission is the Auth claim.

---

## 4. Functional requirements

### 4.1 Authentication

- PIN screen on cold start. 4-digit numeric (configurable length).
- "Sign in as admin" path → email + password form.
- Lock screen accessible from the drawer; returns to PIN.
- Auto-lock after N minutes of inactivity (default 15, admin-configurable).

### 4.2 Home

- Top app bar: drawer toggle, app title, theme toggle (Light/Dark).
- Search field — substring match on recipe name and category name.
- List of category cards. Each card shows up to 3 preview recipe rows + a
  "View all" link.
- Favorites section pinned below the category list.
- Bottom nav: Home / Favorites / Settings.
- Admin-only: "+ Add Category" button at top of list.

### 4.3 Category screen

- Header with category name and recipe count.
- Vertical list of recipe cards. Each card:
  - Type chip (SOP / DRINK / STEPS).
  - Favorite star (toggle).
  - Recipe name (tap → opens recipe).
  - Preview line: for drinks, show first 2 ingredients per Hot/Iced variant; for
    SOPs, "{n} parameters · {m} steps"; for Steps, "{n} steps".
  - Swipe horizontally to toggle favorite (mirror current Kivy behavior).
  - Admin-only: edit and delete icon buttons.
- Admin-only: "+ Add New Recipe" button at the top of the list.

### 4.4 Recipe screen

- Header with category breadcrumb + recipe name.
- Recipe image (if any).
- Type chip + counts strip.
- **Servings stepper** (`× 1` … `× 99`, with reset). All quantities multiply
  live. The stored amounts are the per-1-serving values; multiplication is a
  view concern.
- Body rendering, branched by `type`:
  - **`sop`**: Parameters table (name | amount × m | unit) followed by Steps.
  - **`drink`**: Hot / Iced pill tabs; selected tab shows ingredient table.
  - **`steps`**: Numbered steps only.
- Admin-only EDIT button in the top bar → opens the unified Recipe Form.

### 4.5 Recipe Form (admin only)

One form for both Add and Edit. All sections always visible — user fills what
applies; type is derived on save. (This matches the latest Kivy app behavior;
older designs with a Type pill are deprecated.)

Fields:

- Recipe name (required).
- Image (upload to Firebase Storage; preview in form). Optional.
- Parameters (multi-line CSV: `name, amount, unit` per line).
- Hot ingredients (same CSV format).
- Iced ingredients (same CSV format).
- Steps (one per line).
- Save / Cancel / (edit only) Delete.

Type derivation on save:

```
if hot or iced  → "drink"
else if params  → "sop"
else            → "steps"
```

Empty sections are stored as empty arrays; the UI hides empty sections.

### 4.6 Categories CRUD (admin only)

- Add Category: name (required) + icon (single grapheme or short string).
- Edit Category: rename + change icon. Recipes under the category are unaffected.
- Delete Category: requires confirm modal. **Cascades to recipes** (a Cloud
  Function deletes child recipes + their images in Storage).

### 4.7 Settings

- Theme: Light / Dark, primary color preset, background preset.
- Font size: Small / Medium / Large.
- Language: English, Myanmar (extendable later via Firestore-backed strings).
- PIN management (admin only): change staff PIN, change admin email password
  (delegates to Firebase Auth).
- About: version, link to PRD.

Settings that only affect the **current device** (theme, language, font size)
are stored in `SharedPreferences`. Settings that affect **the shop** (PINs,
recipe content) live in Firestore.

---

## 5. Data model (Firestore)

Firestore is schemaless, but we enforce shapes via security rules and a
client-side serializer (Dart classes with `freezed` or hand-written
`fromJson`/`toJson`).

### Top-level collections

```
/users/{uid}                  — auth profile + role
/categories/{categoryId}      — category metadata
/categories/{categoryId}/recipes/{recipeId}  — recipes (subcollection)
/userFavorites/{uid}          — per-user favorites doc (one doc per user)
/secrets/staff_pin            — server-only; hashed PIN. Read denied to clients.
/appConfig/global             — shop-wide settings (auto-lock minutes, etc.)
```

### `users/{uid}` document

```jsonc
{
  "email": "alice@shop.example",     // null for staff PIN account
  "role":  "admin",                  // "admin" | "staff"
  "displayName": "Alice",
  "createdAt": <Timestamp>,
  "lastSeenAt": <Timestamp>
}
```

### `categories/{categoryId}` document

```jsonc
{
  "name":       "Black Tea Base",
  "icon":       "T",                 // short string, optional
  "order":      10,                  // for manual ordering; lower = first
  "createdAt":  <Timestamp>,
  "updatedAt":  <Timestamp>,
  "createdBy":  "<uid>",
  "updatedBy":  "<uid>"
}
```

`categoryId` is a Firestore-generated 20-char ID. The legacy slug-style IDs in
the Kivy JSON are not migrated; they're regenerated.

### `categories/{categoryId}/recipes/{recipeId}` document

Single document shape covering all three recipe types. Empty arrays for
sections that don't apply.

```jsonc
{
  "name":        "Black Tea Concentrate",
  "type":        "sop",              // "sop" | "drink" | "steps"
  "imageUrl":    "https://firebasestorage.../recipes/xyz.jpg",
  "imagePath":   "recipes/xyz.jpg",  // Storage path, for deletion
  "notes":       "",
  "parameters": [
    { "name": "Water Volume", "amount": 1200, "unit": "ml" },
    { "name": "Salt",         "amount": 1,    "unit": "g"  }
  ],
  "steps": [
    "Measure 1200 ml of water using a graduate beaker.",
    "Add 1 g of salt into the water."
  ],
  "variants": [
    { "type": "Hot",  "ingredients": [ { "name": "Black Tea", "amount": 150, "unit": "ml" } ] },
    { "type": "Iced", "ingredients": [ { "name": "Black Tea", "amount": 180, "unit": "ml" } ] }
  ],
  "order":       0,
  "createdAt":   <Timestamp>,
  "updatedAt":   <Timestamp>,
  "createdBy":   "<uid>",
  "updatedBy":   "<uid>"
}
```

Notes on shape:

- `type` is the **discriminator** — UI must read it, not infer from which
  arrays are non-empty.
- `parameters[]`, `steps[]`, `variants[]` are **all always present** (possibly
  empty). This avoids "key existence vs empty" ambiguity in clients.
- `amount` is a `double`. Render as integer when `amount == amount.floor()`.
- `imagePath` is the Storage path — kept so a delete can also remove the blob.

### `userFavorites/{uid}` document

Favorites are personal. Don't mix into the recipe doc (that would cause
contention and unnecessary writes).

```jsonc
{
  "recipeIds": ["categoryId/recipeId", "categoryId2/recipeId2", ...],
  "updatedAt": <Timestamp>
}
```

A favorite is identified by the path `{categoryId}/{recipeId}` so a deleted
recipe can be cleaned up easily.

### `secrets/staff_pin` document

```jsonc
{
  "hash":      "<argon2id hash>",
  "algo":      "argon2id",
  "rotatedAt": <Timestamp>,
  "rotatedBy": "<uid>"
}
```

Security rules: deny **all** client reads/writes. Only the PIN-verification
Cloud Function (running with admin SDK) accesses this doc.

### `appConfig/global` document

```jsonc
{
  "autoLockMinutes": 15,
  "languages":       ["English", "Myanmar"],
  "schemaVersion":   1
}
```

Read by all signed-in users. Writes admin-only.

---

## 6. Security rules (sketch)

```
rules_version = '2';
service cloud.firestore {
  match /databases/{db}/documents {
    function isSignedIn() { return request.auth != null; }
    function isAdmin() {
      return isSignedIn() && request.auth.token.role == "admin";
    }

    match /users/{uid} {
      allow read:   if isSignedIn() && (request.auth.uid == uid || isAdmin());
      allow write:  if isAdmin();
    }

    match /categories/{cid} {
      allow read:  if isSignedIn();
      allow write: if isAdmin();

      match /recipes/{rid} {
        allow read:  if isSignedIn();
        allow write: if isAdmin();
      }
    }

    match /userFavorites/{uid} {
      allow read, write: if isSignedIn() && request.auth.uid == uid;
    }

    match /secrets/{doc} {
      allow read, write: if false;  // server-only
    }

    match /appConfig/{doc} {
      allow read:  if isSignedIn();
      allow write: if isAdmin();
    }
  }
}
```

Storage rules: images under `recipes/` are read by any signed-in user, write
admin-only.

---

## 7. Cloud Functions

| Function | Trigger | Purpose |
|----------|---------|---------|
| `onUserDocWrite`       | Firestore `users/{uid}` write | Sync `role` field into Auth custom claim. |
| `verifyStaffPin`       | HTTPS callable | Check submitted PIN against `secrets/staff_pin`; on success, mint a custom token for the shared `staff` user. |
| `rotateStaffPin`       | HTTPS callable, admin-only | Hash and store a new PIN. |
| `onCategoryDelete`     | Firestore delete | Cascade-delete child recipes + their Storage images. |
| `onRecipeDelete`       | Firestore delete | Delete the recipe's Storage image (if any). |
| `onRecipeWrite`        | Firestore write | Touch `appConfig/global.recipesUpdatedAt` for client cache hints (optional). |

---

## 8. Tech stack

- **Flutter** (stable channel, ≥ 3.22).
- **Dart** ≥ 3.4.
- **State management**: `Riverpod` (preferred) or `Provider`. Pick one; do not
  mix.
- **Routing**: `go_router`.
- **Firebase plugins**:
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`
  - `firebase_storage`
  - `cloud_functions`
- **Local prefs**: `shared_preferences`.
- **Image cache**: `cached_network_image`.
- **Models**: `freezed` + `json_serializable` for `Recipe`, `Category`, etc.
- **Lints**: `flutter_lints` + project-specific rules.
- **Tests**:
  - Unit tests for serialization and the type-derivation function.
  - Widget tests for the Recipe Form (Add and Edit cases, all 3 types).
  - Integration tests for sign-in flows.

## 9. Architecture (client)

```
lib/
  main.dart                     — bootstrap, Firebase.initializeApp
  app.dart                      — MaterialApp + go_router config
  theme/                        — color presets, light/dark
  l10n/                         — English, Myanmar ARB files
  core/
    auth/                       — auth state, role gating
    firestore/                  — typed converters, repository interfaces
    models/                     — Recipe, Category, Variant, Ingredient, Favorites
  features/
    splash/
    pin/
    home/                       — categories list + search
    category/
    recipe/                     — view + servings stepper
    recipe_form/                — unified Add/Edit form
    settings/
  widgets/                      — buttons, chips, pill tabs, stat rows, etc.
```

Rule (mirroring the Kivy app's CLAUDE.md): **screens never call Firestore
directly.** They go through a repository layer in `core/firestore/`. The
repository layer is the only place that knows about `cloud_firestore`.

---

## 10. Migration

There is no automated migration from the Kivy `data/recipes.json` to Firestore
in v1. Reasoning: schemas differ (Firestore-generated IDs, image upload, role
model). Provide a one-shot CLI script (`tools/import_kivy_json.dart` or a
Cloud Function) for admins to seed Firestore from the existing JSON if
needed; this is a v1.1 task.

---

## 11. Open questions

- Do we want **per-shop** isolation later? If yes, prefix all top-level
  collections with `/shops/{shopId}/…` from the start to avoid a painful
  migration. Recommendation: yes — adopt the prefix even in v1.
- Should staff have **personal accounts** (email/password) instead of a
  shop-wide PIN? Helps with audit (`updatedBy` for favorites, last-seen
  per-person) but increases onboarding friction. Default v1: shared PIN.
- **Offline writes**: Firestore supports them, but PIN auth requires a Cloud
  Function call which needs the network. Document that admin actions are
  online-only in v1.
- Image upload size cap (suggest 2 MB; resize client-side before upload).
- Analytics — do we add Firebase Analytics to track which recipes are viewed
  most? Out of v1 scope, but the data model leaves room.

---

## 12. Acceptance criteria for v1

- An admin can sign in, create a category, create one recipe of each type,
  upload an image, and see the changes on a separate signed-in staff device
  within 5 seconds.
- A staff user can sign in with PIN, browse categories, view a recipe, scale
  it ×3, and toggle a favorite. Favorites persist across sign-out / sign-in.
- Deleting a category deletes its recipes and their images.
- A non-admin client cannot mutate categories, recipes, or PINs (verified by
  emulator-based security-rules tests).
- App launches and shows cached content offline; a banner reads "Offline —
  recipes may be stale" when the network is gone.
- Theme/language settings persist on the device only.
