# Tea Recipe & SOP App - Flutter + Firebase PRD

A mobile-first Flutter app with a Firebase backend for a tea / milk-tea shop.
Staff use it during shop operations to prepare drinks from recipes and follow
opening, closing, and operational SOPs. Admins maintain the content catalog and
control which Gmail/email accounts can access the shop.

This PRD is the source of truth for the new Flutter build. It does not depend
on the existing Kivy codebase or JSON schema.

---

## 1. Goals

- Build a new Flutter app for Android and iOS, optimized for phone-sized and
  tablet portrait use.
- Store all app data in Firebase: Auth, Firestore, Storage, and Cloud
  Functions.
- Support user registration with Gmail/email accounts.
- Require admin approval before any registered user can see shop content.
- Let each active user set their own personal app PIN for quick unlock on the
  same device.
- Keep favorites per user.
- Support draft/published content so admins can prepare changes before staff
  see them.
- Provide two main content types:
  - `recipe`: drink preparation content with Hot and Cold variants.
  - `sop`: operational procedures such as opening, closing, cleaning, or
    end-of-day tasks.
- Let admins create and maintain categories, recipes, SOPs, images, and user
  access.
- Keep the current color identity while allowing a fully redesigned modern UI.

## 2. Non-goals

- No migration from the current Kivy JSON files. v1 starts from scratch.
- No SQLite or local database.
- No shared shop-wide staff PIN.
- No guest or anonymous mode.
- No offline mode in v1. If there is no connection, show a no-connection state.
- No POS integration, order tracking, sales analytics, printing, or PDF export.
- No web build in v1.
- No multi-shop UI in v1, though the Firestore schema should allow it later.

---

## 3. Visual direction

The Flutter UI does not need to copy the current Kivy screens. It should feel
modern, clean, fast, and easy to use during a real shop shift.

### 3.1 Color identity

Use the current app colors as the base palette:

| Token | Color | Source |
|-------|-------|--------|
| Primary | `#8B0000` | current active theme primary |
| Background | `#0A0A0A` | current active theme background |
| Surface / card | `#141414` | current active theme card |
| Default gold accent | `#C9A84C` | existing theme preset |
| Amber accent | `#E8A020` | existing theme preset |
| Silver accent | `#A8A8B0` | existing theme preset |
| Success | `#22B55A` | existing green preset |
| Info | `#2278E8` | existing blue preset |
| Hot marker | `#E65926` | current hot color approximation |
| Cold marker | `#3399F2` | current cold color approximation |
| Favorite | `#F2C733` | current favorite color approximation |

Dark mode is the default. Light mode may be supported, but the primary visual
identity is dark red + black + dark surfaces.

### 3.2 UX principles

- First screen after access should be the usable app, not a marketing page.
- Design for repeated use by busy staff: clear hierarchy, large tap targets,
  fast search, minimal typing, and no decorative clutter.
- Use Material 3 conventions where they fit.
- Use modern cards, bottom navigation, tabs, sheets, dialogs, and compact
  admin controls.
- Use icons for frequent actions: favorite, edit, delete, search, lock, add,
  image upload, and theme.
- The content view must make quantities and steps easy to scan.
- Admin controls must be visible only to admins.

---

## 4. Users, access, and roles

### 4.1 Roles

| Role | Capabilities |
|------|--------------|
| `admin` | Full access. Manage users, categories, recipes, SOPs, images, app settings, and content deletes. |
| `staff` | Browse assigned published content, search, view recipes and SOPs, scale recipe quantities, toggle personal favorites, and manage their own local PIN. |
| `none` | Registered but not approved. Can only see a no-access screen. Cannot read shop content. |

There is no guest role. Every user must authenticate first.

### 4.2 Registration

- Users register with a Gmail/email address and password through Firebase Auth.
- After registration, the app creates or updates a user profile.
- New users default to `role = none` and `accessStatus = pending`.
- A pending user sees only a no-access screen:
  - no categories
  - no recipes
  - no SOPs
  - no favorites
  - no cached shop content
- Admins can grant access by Gmail/email address from the admin user-management
  screen.

### 4.3 Admin bootstrap

For the first prototype, one or more admin Gmail/email addresses may be
hard-coded in app/backend configuration.

Important rule: client-side hardcoding is only for routing and prototype
convenience. Real authorization must still come from Firebase Auth custom
claims and Firestore/Storage security rules.

Bootstrap behavior:

- If a registered user's normalized email matches the bootstrap admin list, a
  Cloud Function or admin seed script grants `role = admin`.
- After bootstrap, that admin can assign `staff` or `admin` access to other
  Gmail/email accounts.
- Before production, move bootstrap admin emails to environment configuration
  or a secure deployment setting.

### 4.4 User access assignment

Admins can assign access by Gmail/email address.

Required admin actions:

- Add user by email.
- Set role: `staff` or `admin`.
- Disable access.
- Re-enable access.
- Remove access from the shop.
- View pending registered users.

Email matching uses a normalized email key:

- trim whitespace
- lowercase

### 4.5 Personal PIN

Each active user can set their own personal app PIN.

PIN behavior:

- The PIN is per user and per device.
- The default first-time PIN is `2222`.
- After the user's first active login, if no personal PIN exists on the device,
  the app asks whether they want to change the default PIN now or keep `2222`
  for now.
- It is used for quick unlock when the Firebase session is still valid.
- It does not replace Firebase Auth.
- PIN unlock is not login. It cannot create a Firebase session, refresh expired
  credentials, or bypass server-side permission checks.
- If the user signs out, clears app data, changes device, or the Firebase
  session expires, they must sign in again with email/password.
- PIN storage should use secure local storage and never be stored in plaintext.
- Admins cannot see a user's PIN.
- A user can change or remove their own PIN from Settings.
- Manual Lock immediately returns to the PIN screen if a local PIN exists.
- The app locks when sent to background for more than 30 seconds.
- The app locks after 15 minutes of inactivity by default.
- After 5 failed PIN attempts, quick unlock is disabled until the user signs in
  again with email/password.
- Biometric unlock is not in v1. It may be added later as an optional shortcut
  after a user has configured a personal PIN.

Recommended dependency: `flutter_secure_storage`.

---

## 5. Domain model

### 5.1 Category

A category groups recipes and SOPs. Examples:

- Black Tea
- Milk Tea
- Opening SOP
- Closing SOP
- Cleaning

Fields:

- name
- icon
- manual order

### 5.2 Content item

The app has two main content item types.

| Type | Meaning | Main use |
|------|---------|----------|
| `recipe` | Drink preparation content | Hot/Cold drink instructions and quantities |
| `sop` | Standard operating procedure | Opening, closing, cleaning, prep, shutdown |

The app uses `recipe` as the stable data enum and "Recipe" as the user-facing
label.

### 5.3 Parameter

A parameter is a quantity row:

```json
{ "name": "Black Tea", "amount": 150.0, "unit": "ml" }
```

Rules:

- `name` is required.
- `amount` is a number.
- `unit` is a short string such as `ml`, `g`, `pcs`, `spoon`, or `min`.
- For recipes, amounts are stored as the per-1-serving value.
- Recipe scaling is a view concern. Firestore never stores scaled amounts.

### 5.4 Recipe

A recipe is a drink-preparation item.

Requirements:

- A recipe has exactly two variants: `hot` and `cold`.
- Hot and Cold can have different parameters.
- Hot and Cold can have different steps.
- Each variant must contain at least one parameter or one step.
- Recipe quantities support a live servings multiplier from `x1` to `x99`.
- The multiplier applies only to the selected variant's parameters.

Recipe shape:

```jsonc
{
  "contentType": "recipe",
  "status": "published",
  "name": "Classic Milk Tea",
  "categoryId": "milk_tea",
  "imageUrl": "https://...",
  "imagePath": "shops/main/items/abc.jpg",
  "notes": "",
  "recipe": {
    "hot": {
      "parameters": [
        { "name": "Tea Base", "amount": 150, "unit": "ml" },
        { "name": "Milk", "amount": 40, "unit": "ml" }
      ],
      "steps": [
        "Warm the cup.",
        "Add tea base and milk.",
        "Stir until even."
      ]
    },
    "cold": {
      "parameters": [
        { "name": "Tea Base", "amount": 180, "unit": "ml" },
        { "name": "Milk", "amount": 35, "unit": "ml" },
        { "name": "Ice", "amount": 1, "unit": "cup" }
      ],
      "steps": [
        "Fill shaker with ice.",
        "Add tea base and milk.",
        "Shake and serve."
      ]
    }
  }
}
```

### 5.5 SOP

An SOP is an operational procedure, not a drink variant.

Examples:

- Opening shop
- Closing shop
- Prepare black tea base
- Clean espresso machine
- End-of-day fridge check

Requirements:

- An SOP has one parameter list.
- An SOP has one ordered step list.
- An SOP has a subtype for filtering and grouping.
- SOP parameters are fixed values by default.
- The servings multiplier does not apply to SOPs in v1.
- Each SOP must contain at least one parameter or one step.

Allowed SOP subtypes:

- `opening`
- `closing`
- `cleaning`
- `prep`
- `other`

SOP shape:

```jsonc
{
  "contentType": "sop",
  "status": "published",
  "name": "Closing SOP",
  "categoryId": "closing",
  "imageUrl": "",
  "imagePath": "",
  "notes": "",
  "sop": {
    "subtype": "closing",
    "parameters": [
      { "name": "Sanitizer", "amount": 20, "unit": "ml" },
      { "name": "Checklist Time", "amount": 10, "unit": "min" }
    ],
    "steps": [
      "Turn off non-essential machines.",
      "Clean counters and prep area.",
      "Check fridge temperature.",
      "Lock the front door."
    ]
  }
}
```

---

## 6. Functional requirements

### 6.1 Auth and access

- App opens to an auth gate.
- If not signed in, show login/register screen.
- User can register with Gmail/email + password.
- User can sign in with Gmail/email + password.
- If the signed-in user has no active role, show no-access screen only.
- If the signed-in user is active staff/admin, show the main app.
- Drawer or settings must include Lock and Sign out.
- Lock uses personal PIN if configured.
- Sign out clears the local unlocked state.

### 6.2 No-access screen

Shown after login when the user has no active shop permission.

Screen content:

- "No access assigned"
- Signed-in email address
- Short instruction to ask an admin for access
- Refresh/check-again button
- Sign out button

This screen must not read or render shop categories, recipes, SOPs, or
favorites.

### 6.3 Home

Home is optimized for staff use.

Required UI:

- Top app bar with drawer/menu, title, search, and lock.
- Tabs or segmented control for:
  - All
  - Recipes
  - SOPs
  - Favorites
- Search by content name, category name, and parameter name.
- Category sections or filter chips.
- Recent or frequently used content can be added later, but is not required
  for v1.
- Admin-only add button.

### 6.4 Search

Search is required on screens where users browse lists:

- Home.
- Category.
- Favorites.
- Admin content management.
- Admin user management.

Content search must support:

- content name
- category name
- content type: Recipe or SOP
- SOP subtype
- parameter name
- step text
- notes

Admin user search must support:

- email
- display name
- role
- access status

For v1, content search can be local in-memory search over the loaded shop
content. Staff search results must include only `published` content.

### 6.5 Category screen

- Shows category name, icon, and item count.
- Lists recipes and SOPs in manual order.
- Staff see only published items.
- Admins can filter by All / Draft / Published.
- Each row/card shows:
  - content type chip: Recipe or SOP
  - status chip for admins: Draft or Published
  - name
  - favorite star
  - short preview
  - optional image thumbnail
  - admin-only edit/delete actions
- Admins can add a new item in the category.

### 6.6 Recipe detail screen

- Shows category breadcrumb and recipe name.
- Shows image if available.
- Shows Hot/Cold pill tabs.
- Shows servings stepper from `x1` to `x99`, with reset to `x1`.
- Selected variant shows:
  - parameter table with scaled quantities
  - ordered steps for that variant
- Favorite toggle is available to staff and admins.
- Admin-only edit action.

### 6.7 SOP detail screen

- Shows category breadcrumb and SOP name.
- Shows SOP subtype.
- Shows image if available.
- Shows parameter table.
- Shows ordered steps.
- No servings multiplier in v1.
- Favorite toggle is available to staff and admins.
- Admin-only edit action.

### 6.8 Content form

Admin-only. One form can create or edit either content type.

Required fields:

- Type selector: Recipe or SOP.
- Name.
- Category.
- Optional image upload.
- Optional notes.
- Status: Draft or Published.

Recipe fields:

- Hot parameters.
- Hot steps.
- Cold parameters.
- Cold steps.

SOP fields:

- SOP subtype.
- Parameters.
- Steps.

Parameter input options:

- v1 may use structured rows with name/amount/unit fields.
- CSV paste/import can be added as a helper if useful.

Validation:

- Name is required.
- Category is required.
- Recipe must have Hot and Cold objects.
- Each Recipe variant must contain at least one parameter or one step.
- SOP must contain at least one parameter or one step.
- SOP subtype is required.
- Amounts must parse as numbers.
- Draft items are visible to admins only.
- Published items are visible to staff and admins.

Form actions:

- Save Draft.
- Publish.
- Cancel.
- Delete.

### 6.9 Categories CRUD

Admin-only.

- Add category.
- Rename category.
- Change icon.
- Reorder categories.
- Delete category with confirmation.
- Deleting a category permanently deletes the category, its items, and their
  images. This action must use a strong confirmation dialog.

### 6.10 Favorites

- Favorites are per user.
- Staff and admins can favorite recipes and SOPs.
- Favorites are stored by `uid`.
- A user's favorites persist across devices because they are stored in
  Firestore.
- If an item is deleted, it should disappear from favorites.
- Staff favorites show only published items.

### 6.11 Settings

Staff settings:

- Theme mode if supported.
- Font size.
- Language.
- Set/change/remove personal PIN.
- Sign out.

Admin settings:

- Everything staff can do.
- User access management.
- App content settings.
- Category/content management shortcuts.

Settings that affect only the current device use local storage. Settings that
affect shop behavior use Firestore.

### 6.12 Connectivity

v1 does not support offline use.

Requirements:

- Detect no connection.
- Show a clear no-connection screen or blocking banner.
- Do not promise stale cached content is valid.
- Writes require connection.
- Login/register/access refresh require connection.

Recommended dependency: `connectivity_plus`.

---

## 7. Firestore data model

Use a fresh schema. Do not migrate the Kivy JSON structure.

The schema should include `/shops/{shopId}` from the start even though v1 only
uses one shop. This avoids a painful migration later.

### 7.1 Data tree

```text
/users/{uid}
/shops/{shopId}
/shops/{shopId}/members/{uid}
/shops/{shopId}/memberGrants/{emailKey}
/shops/{shopId}/categories/{categoryId}
/shops/{shopId}/items/{itemId}
/shops/{shopId}/favorites/{uid}
/shops/{shopId}/appConfig/global
```

### 7.2 `users/{uid}`

Global auth profile.

```jsonc
{
  "email": "staff@gmail.com",
  "normalizedEmail": "staff@gmail.com",
  "displayName": "Staff Name",
  "createdAt": "<Timestamp>",
  "lastSeenAt": "<Timestamp>"
}
```

### 7.3 `shops/{shopId}/members/{uid}`

Shop-specific permission.

```jsonc
{
  "uid": "firebaseUid",
  "email": "staff@gmail.com",
  "normalizedEmail": "staff@gmail.com",
  "role": "staff",
  "accessStatus": "active",
  "createdAt": "<Timestamp>",
  "updatedAt": "<Timestamp>",
  "createdBy": "<uid>",
  "updatedBy": "<uid>"
}
```

Allowed roles:

- `admin`
- `staff`
- `none`

Allowed access statuses:

- `pending`
- `active`
- `disabled`

### 7.4 `shops/{shopId}/memberGrants/{emailKey}`

Admin-created access by Gmail/email address. This allows admins to grant access
before or after the user registers.

```jsonc
{
  "email": "staff@gmail.com",
  "normalizedEmail": "staff@gmail.com",
  "role": "staff",
  "accessStatus": "active",
  "createdAt": "<Timestamp>",
  "updatedAt": "<Timestamp>",
  "createdBy": "<uid>",
  "updatedBy": "<uid>"
}
```

`emailKey` is a safe deterministic key based on the normalized email. Use a
hash if needed to avoid invalid Firestore document characters.

### 7.5 `shops/{shopId}/categories/{categoryId}`

```jsonc
{
  "name": "Milk Tea",
  "icon": "T",
  "order": 10,
  "createdAt": "<Timestamp>",
  "updatedAt": "<Timestamp>",
  "createdBy": "<uid>",
  "updatedBy": "<uid>"
}
```

### 7.6 `shops/{shopId}/items/{itemId}`

One collection stores both recipes and SOPs.

```jsonc
{
  "contentType": "recipe",
  "status": "published",
  "categoryId": "milk_tea",
  "name": "Classic Milk Tea",
  "searchKeywords": ["classic", "milk", "tea"],
  "imageUrl": "https://...",
  "imagePath": "shops/main/items/itemId.jpg",
  "notes": "",
  "recipe": {
    "hot": {
      "parameters": [],
      "steps": []
    },
    "cold": {
      "parameters": [],
      "steps": []
    }
  },
  "sop": {
    "subtype": "other",
    "parameters": [],
    "steps": []
  },
  "order": 0,
  "publishedAt": "<Timestamp>",
  "publishedBy": "<uid>",
  "createdAt": "<Timestamp>",
  "updatedAt": "<Timestamp>",
  "createdBy": "<uid>",
  "updatedBy": "<uid>"
}
```

Shape rules:

- `contentType` is the discriminator. UI must read it.
- `recipe` and `sop` objects are always present for schema stability.
- `status` is `draft` or `published`.
- Staff can read only published items.
- Admins can read draft and published items.
- For `recipe`, use `recipe.hot` and `recipe.cold`.
- For `sop`, use `sop.parameters` and `sop.steps`.
- For `sop`, use `sop.subtype` for filtering.
- Unused sections are stored as empty arrays.
- `amount` is a double.
- Render amounts as integers when possible.

### 7.7 `shops/{shopId}/favorites/{uid}`

```jsonc
{
  "itemIds": ["itemId1", "itemId2"],
  "updatedAt": "<Timestamp>"
}
```

### 7.8 `shops/{shopId}/appConfig/global`

```jsonc
{
  "schemaVersion": 1,
  "defaultThemeMode": "dark",
  "primaryColor": "#8B0000",
  "backgroundColor": "#0A0A0A",
  "surfaceColor": "#141414",
  "languages": ["English", "Myanmar"]
}
```

---

## 8. Security rules requirements

Security rules must enforce access. The client UI is not trusted.

Rules:

- Signed-out users can read/write nothing.
- Pending users can read only their own basic profile and permission state.
- Users without active shop permission cannot read categories, items, images,
  favorites, or app config.
- Active staff can read categories, items, app config, and their own favorites.
- Active staff can read only published items.
- Active staff can write only their own favorites.
- Active admins can manage categories, items, app config, member grants, and
  members.
- Only active admins can upload or delete item images.
- Disabled users lose all shop data access after token refresh.

Auth custom claims should include:

```json
{
  "shopId": "main",
  "role": "staff",
  "accessStatus": "active"
}
```

The app must force-refresh the ID token after registration, access assignment,
role changes, and sign-in.

---

## 9. Cloud Functions

| Function | Trigger | Purpose |
|----------|---------|---------|
| `onAuthUserCreate` | Firebase Auth user created | Create user profile, check bootstrap admin emails, check member grants, create member record if needed. |
| `assignMemberByEmail` | HTTPS callable, admin-only | Grant or update access for a Gmail/email address. |
| `disableMember` | HTTPS callable, admin-only | Disable a user's shop access. |
| `onMemberWrite` | Firestore member write | Sync role/shop/access status into Auth custom claims. |
| `onCategoryDelete` | Firestore category delete | Permanently delete related items and their Storage images. |
| `onItemDelete` | Firestore item delete | Delete the item's Storage image if present. |
| `onItemWrite` | Firestore item write | Maintain search keywords and audit fields if not handled client-side. |

No shared staff PIN verification function is needed in this version.

---

## 10. Tech stack

- Flutter stable channel.
- Dart 3.x.
- Firebase:
  - `firebase_core`
  - `firebase_auth`
  - `cloud_firestore`
  - `firebase_storage`
  - `cloud_functions`
- State management: Riverpod.
- Routing: `go_router`.
- Models: `freezed` + `json_serializable`, or hand-written serializers if the
  project wants less generated code.
- Local device settings: `shared_preferences`.
- Secure local PIN storage: `flutter_secure_storage`.
- Connectivity state: `connectivity_plus`.
- Image loading/cache: `cached_network_image`.
- Lints: `flutter_lints`.

Do not mix Riverpod and Provider.

---

## 11. Client architecture

```text
lib/
  main.dart
  app.dart
  firebase_options.dart
  theme/
    app_colors.dart
    app_theme.dart
  l10n/
  core/
    auth/
      auth_controller.dart
      access_controller.dart
      pin_lock_service.dart
    firestore/
      category_repository.dart
      item_repository.dart
      favorites_repository.dart
      member_repository.dart
    models/
      category.dart
      content_item.dart
      parameter.dart
      recipe_variant.dart
      member.dart
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

- Screens do not call Firestore directly.
- Screens use providers/controllers.
- Repositories are the only client layer that knows Firebase collection paths.
- Models own serialization and validation.
- UI reads `contentType` and never infers item type from populated fields.

---

## 12. Testing requirements

Minimum tests:

- Unit tests for content item serializers.
- Unit tests for recipe and SOP validation.
- Unit tests for amount scaling.
- Unit tests for normalized email keys.
- Unit tests for draft/published visibility rules in repositories.
- Unit tests for search matching.
- Widget tests for login/register/no-access flows.
- Widget tests for recipe detail Hot/Cold behavior.
- Widget tests for SOP detail behavior.
- Widget tests for admin content form validation.
- Emulator security-rules tests:
  - no permission cannot read shop data
  - staff cannot write items/categories
  - staff can write own favorites
  - admin can manage users/content
  - disabled user loses access

---

## 13. Acceptance criteria for v1

- A new user can register with Gmail/email and password.
- A registered user without permission sees only the no-access screen.
- A hard-coded bootstrap admin email can become admin for the prototype.
- An admin can grant staff access to a Gmail/email account.
- A staff user with access can sign in and see shop content.
- A user can set, change, and remove their own personal PIN.
- First active login uses default PIN `2222` and asks whether to change it.
- After 5 failed PIN attempts, quick unlock requires email/password sign-in.
- Favorites are stored per user and persist across devices.
- An admin can create a category.
- An admin can create a draft recipe with different Hot and Cold parameters
  and steps.
- Draft content is visible to admins only.
- Published content is visible to staff.
- A staff user can open a recipe, switch Hot/Cold, and scale quantities to
  `x3`.
- An admin can create an SOP with subtype, parameters, and steps.
- A staff user can open an SOP and follow its steps.
- Search works on Home, Category, Favorites, admin content management, and
  admin user management screens.
- A user without active permission cannot read categories, items, favorites, or
  images.
- If there is no connection, the app shows a no-connection state.
- The app uses the current dark red / black / dark surface color identity while
  presenting a modern Flutter UI.

---

## 14. Open questions

- Should Google Sign-In be added, or is Gmail/email + password enough for v1?
- Should SOPs ever support a multiplier, or are SOP quantities always fixed?
- What is the exact bootstrap admin Gmail/email for the prototype?
