# ZinmeAPP - Flutter + Backend API PRD

A mobile-first Flutter app that uses the Zin Mae backend API for a tea /
milk-tea shop. Staff use it during shop operations to prepare drinks, foods,
bases, and other items from recipes, and to follow opening, closing, and
operational SOPs. Admins maintain the content catalog and control which
Gmail/email accounts can access the shop.

This PRD is the source of truth for the new Flutter build. It does not depend
on the existing Kivy codebase or JSON schema.

Implementation status for the current v1 app: the codebase uses the Zin Mae
backend API through Dio cookies and Provider/ChangeNotifier controllers. Staff
catalog browsing, refresh, local settings, local favorites, and local PIN unlock
are supported. Admin user-access and basic recipe/SOP CRUD are wired to the
existing backend portal APIs. Rich media management, advanced content editing,
and final manual E2E signoff remain outside this code-cleanup pass.

---

## 1. Goals

- Build a new Flutter app for Android and iOS, optimized for phone-sized and
  tablet portrait use.
- Store all app data in the Zin Mae backend: API auth, PostgreSQL data, and
  backend-managed media storage.
- Support user registration with Gmail/email accounts.
- Require admin approval before any registered user can see shop content.
- Let each active user set their own personal app PIN for quick unlock on the
  same device.
- Keep favorites per user.
- Support draft/published content so admins can prepare changes before staff
  see them.
- Provide two main content types:
  - `recipe`: saved preparation instructions for drinks, foods, and other
    shop items.
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
- No multi-shop UI in v1, though the backend schema and API should allow it
  later.

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

- Users register with a Gmail/email address and password through the backend
  auth API.
- After registration, the backend creates or updates a user profile.
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
convenience. Real authorization must still come from the backend session,
database permissions, and server-side route checks.

Bootstrap behavior:

- If a registered user's normalized email matches the bootstrap admin list, a
  backend bootstrap flow or admin seed script grants `role = admin`.
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
- It is used for quick unlock when the backend API session is still valid.
- It does not replace backend authentication.
- PIN unlock is not login. It cannot create a backend session, refresh expired
  credentials, or bypass server-side permission checks.
- If the user signs out, clears app data, changes device, or the backend
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
| `recipe` | Preparation content | Drinks, foods, toppings, sauces, bases, and other shop items |
| `sop` | Standard operating procedure | Opening, closing, cleaning, prep, shutdown, maintenance, inventory |

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
- Recipe scaling is a view concern. The backend never stores scaled amounts.

### 5.4 Recipe

A recipe is saved preparation content for anything the shop makes or prepares.
Recipes are not limited to drinks.

Built-in recipe types:

- `drink`
- `food`
- `base`
- `topping`
- `sauce`
- `other`

Admins can add more recipe types later. Store recipe types as stable lowercase
keys so future custom types do not require a schema migration.

Requirements:

- A recipe has a required `recipeType`.
- A recipe may have base-level parameters and steps.
- A recipe may also have one or more named variants.
- Drink recipes default to two variants: `hot` and `cold`.
- Hot and Cold drink variants can have different parameters and different
  steps.
- Food and other recipes may use only base parameters/steps, or may define
  variants if needed.
- Each recipe must contain at least one parameter or one step across its base
  content or variants.
- Recipe quantities support a live servings multiplier from `x1` to `x99`.
- The multiplier applies to the visible recipe parameters for the selected
  base content or variant.

Recipe variant shape:

```jsonc
{
  "key": "hot",
  "name": "Hot",
  "parameters": [
    { "name": "Tea Base", "amount": 150, "unit": "ml" },
    { "name": "Milk", "amount": 40, "unit": "ml" }
  ],
  "steps": [
    "Warm the cup.",
    "Add tea base and milk.",
    "Stir until even."
  ]
}
```

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
    "recipeType": "drink",
    "parameters": [],
    "steps": [],
    "variants": [
      {
        "key": "hot",
        "name": "Hot",
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
      {
        "key": "cold",
        "name": "Cold",
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
    ]
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

- An SOP has a required `sopType` for filtering and grouping.
- An SOP has one parameter list.
- An SOP has one ordered step list.
- SOP parameters are fixed values by default.
- The servings multiplier does not apply to SOPs in v1.
- Each SOP must contain at least one parameter or one step.

Built-in SOP types:

- `opening`
- `closing`
- `cleaning`
- `prep`
- `maintenance`
- `inventory`
- `safety`
- `training`
- `other`

Admins can add more SOP types later. Store SOP types as stable lowercase keys
so future custom types do not require a schema migration.

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
    "sopType": "closing",
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
- recipe type
- SOP type
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
- Shows recipe type.
- Shows image if available.
- If the recipe has variants, shows variant tabs. Drink recipes default to
  Hot/Cold tabs.
- Shows servings stepper from `x1` to `x99`, with reset to `x1`.
- Selected base content or variant shows:
  - parameter table with scaled quantities
  - ordered steps for that base content or variant
- Favorite toggle is available to staff and admins.
- Admin-only edit action.

### 6.7 SOP detail screen

- Shows category breadcrumb and SOP name.
- Shows SOP type.
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

- Recipe type.
- Base parameters.
- Base steps.
- Variants. Drink recipes default to Hot and Cold variants.
- Variant parameters.
- Variant steps.

SOP fields:

- SOP type.
- Parameters.
- Steps.

Parameter input options:

- v1 may use structured rows with name/amount/unit fields.
- CSV paste/import can be added as a helper if useful.

Validation:

- Name is required.
- Category is required.
- Recipe type is required.
- Recipe must contain at least one parameter or one step across base content or
  variants.
- Drink recipes must include Hot and Cold variants.
- Each populated recipe variant must contain at least one parameter or one step.
- SOP must contain at least one parameter or one step.
- SOP type is required.
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
- Favorites are stored by authenticated user id.
- A user's favorites persist across devices because they are stored in
  the backend database.
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
affect shop behavior use the backend database.

### 6.12 Connectivity

v1 does not support offline use.

Requirements:

- Detect no connection.
- Show a clear no-connection screen or blocking banner.
- Do not promise stale cached content is valid.
- Writes require connection.
- Login/register/session/access refresh require connection.

Recommended dependency: `connectivity_plus`.

---

## 7. Backend data model

Use a fresh backend schema. Do not migrate the Kivy JSON structure.

The schema should include shops from the start even though v1 only uses one
shop. This avoids a painful migration later. The backend is the source of
truth, and the mobile app reads and writes through authenticated API requests.

### 7.1 Backend resources

```text
users
profiles
shops
shop_members
member_grants
categories
items
favorites
app_config
media_assets
```

The exact physical schema may be normalized for PostgreSQL, but API responses
should keep stable mobile-friendly shapes so the Flutter app can use typed
models.

### 7.2 User profile

Global auth profile.

```jsonc
{
  "id": "userId",
  "email": "staff@gmail.com",
  "normalizedEmail": "staff@gmail.com",
  "displayName": "Staff Name",
  "createdAt": "<ISO timestamp>",
  "lastSeenAt": "<ISO timestamp>"
}
```

### 7.3 Shop member

Shop-specific permission.

```jsonc
{
  "id": "memberId",
  "shopId": "main",
  "userId": "userId",
  "email": "staff@gmail.com",
  "normalizedEmail": "staff@gmail.com",
  "role": "staff",
  "accessStatus": "active",
  "createdAt": "<ISO timestamp>",
  "updatedAt": "<ISO timestamp>",
  "createdBy": "adminUserId",
  "updatedBy": "adminUserId"
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

### 7.4 Member grant

Admin-created access by Gmail/email address. This allows admins to grant access
before or after the user registers.

```jsonc
{
  "id": "grantId",
  "shopId": "main",
  "email": "staff@gmail.com",
  "normalizedEmail": "staff@gmail.com",
  "emailKey": "staff@gmail.com",
  "role": "staff",
  "accessStatus": "active",
  "createdAt": "<ISO timestamp>",
  "updatedAt": "<ISO timestamp>",
  "createdBy": "adminUserId",
  "updatedBy": "adminUserId"
}
```

`emailKey` is a safe deterministic key based on the normalized email. Use a
hash if needed to keep keys short and stable.

### 7.5 Category

```jsonc
{
  "id": "milk_tea",
  "shopId": "main",
  "name": "Milk Tea",
  "icon": "T",
  "order": 10,
  "createdAt": "<ISO timestamp>",
  "updatedAt": "<ISO timestamp>",
  "createdBy": "adminUserId",
  "updatedBy": "adminUserId"
}
```

### 7.6 Content item

One backend resource stores both recipes and SOPs.

```jsonc
{
  "id": "itemId",
  "shopId": "main",
  "contentType": "recipe",
  "status": "published",
  "categoryId": "milk_tea",
  "name": "Classic Milk Tea",
  "searchKeywords": ["classic", "milk", "tea"],
  "imageUrl": "https://...",
  "imagePath": "shops/main/items/itemId.jpg",
  "notes": "",
  "recipe": {
    "recipeType": "drink",
    "parameters": [],
    "steps": [],
    "variants": [
      {
        "key": "hot",
        "name": "Hot",
        "parameters": [],
        "steps": []
      },
      {
        "key": "cold",
        "name": "Cold",
        "parameters": [],
        "steps": []
      }
    ]
  },
  "sop": {
    "sopType": "other",
    "parameters": [],
    "steps": []
  },
  "order": 0,
  "publishedAt": "<ISO timestamp>",
  "publishedBy": "adminUserId",
  "createdAt": "<ISO timestamp>",
  "updatedAt": "<ISO timestamp>",
  "createdBy": "adminUserId",
  "updatedBy": "adminUserId"
}
```

Shape rules:

- `contentType` is the discriminator. UI must read it.
- `recipe` and `sop` objects are always present for schema stability.
- `status` is `draft` or `published`.
- Staff API responses include only published items.
- Admin API responses can include draft and published items.
- For `recipe`, use `recipe.recipeType`, `recipe.parameters`,
  `recipe.steps`, and `recipe.variants`.
- For `sop`, use `sop.parameters` and `sop.steps`.
- For `sop`, use `sop.sopType` for filtering.
- Built-in and custom recipe/SOP type keys are stored as lowercase stable
  strings.
- Unused sections are stored as empty arrays.
- `amount` is a double.
- Render amounts as integers when possible.

### 7.7 Favorites

```jsonc
{
  "userId": "userId",
  "shopId": "main",
  "itemIds": ["itemId1", "itemId2"],
  "updatedAt": "<ISO timestamp>"
}
```

### 7.8 App config

```jsonc
{
  "shopId": "main",
  "schemaVersion": 1,
  "defaultThemeMode": "dark",
  "primaryColor": "#8B0000",
  "backgroundColor": "#0A0A0A",
  "surfaceColor": "#141414",
  "languages": ["English", "Myanmar"],
  "recipeTypes": ["drink", "food", "base", "topping", "sauce", "other"],
  "sopTypes": ["opening", "closing", "cleaning", "prep", "maintenance", "inventory", "safety", "training", "other"]
}
```

---

## 8. Authorization requirements

The backend API must enforce access. The client UI is not trusted.

Rules:

- Signed-out users can only use public auth and health endpoints.
- Pending users can read only their own basic profile and permission state.
- Users without active shop permission cannot read categories, items, images,
  favorites, or app config.
- Active staff can read categories, app config, published items, and their own
  favorites.
- Active staff can write only their own favorites and device-independent user
  preferences explicitly allowed by the backend.
- Active admins can manage categories, items, app config, member grants, and
  members.
- Only active admins can upload, replace, or delete item images.
- Disabled users lose all shop data access on their next API request or session
  refresh.
- API responses must be filtered by role and access status before data reaches
  the mobile app.

The app must refresh session and permission state after registration, access
assignment, role changes, sign-in, and explicit refresh actions.

---

## 9. Backend API responsibilities

| Area | Purpose |
|------|---------|
| Auth | Register, sign in, sign out, refresh/check session, and return the current authenticated user. |
| Profile | Create profile records after registration and expose current profile data. |
| Access | Check bootstrap admin emails, apply member grants, assign roles, disable users, and return current shop permission. |
| Categories | List categories for active users and manage categories for admins. |
| Items | List published items for staff, list draft/published items for admins, and create/update/delete content for admins. |
| Favorites | Read and update the authenticated user's favorite item ids. |
| Media | Accept admin image uploads and return stable image URLs for mobile rendering. |
| Search | Support local in-memory search in v1; backend search can be added when content volume requires it. |
| Cleanup | Delete related items and media when an admin deletes a category or item. |

No shared staff PIN verification endpoint is needed in this version.

---

## 10. Tech stack

- Flutter stable channel.
- Dart 3.x.
- Backend API:
  - Zin Mae `zin_mae` backend
  - Hono API
  - PostgreSQL
  - Better Auth
  - backend-managed media storage
- HTTP API client: Dio with persisted backend cookies.
- State management: Provider and ChangeNotifier.
- Routing: Material routes plus a main shell for Home/Favorites/Schedule/Settings.

  > **Scheduling removed from mobile (planned — change-set 002).** The Schedule
  > tab and all booking-related screens (browse open shifts, book a shift, my
  > shifts, cancel booking, schedule alerts) are planned for removal from the
  > Flutter app. The `next-shift` widget on any home/attendance card is also
  > planned for removal. Shift-session selection moves to the web recruitment
  > flow: applicants choose available shift sessions during registration Step 3
  > (see `zin_mae` change-set 002). The mobile app's scope remains SOP browsing,
  > recipe browsing, attendance (clock-in/clock-out), favorites, and settings.
  > The backend `/staff/scheduling/*` staff self-booking endpoints are removed
  > too (change-set 002); the portal operational scheduling endpoints remain.
- Models: `freezed` + `json_serializable`, or hand-written serializers if the
  project wants less generated code.
- Local device settings: `shared_preferences`.
- Secure local PIN storage: `flutter_secure_storage`.
- Secure API session storage: `flutter_secure_storage` if the mobile auth flow
  uses bearer/session tokens instead of platform-managed cookies.
- Connectivity state: `connectivity_plus`.
- Lints: `flutter_lints`.

Do not migrate to Riverpod or go_router in the current backend API pass.

---

## 11. Client architecture

```text
lib/
  main.dart
  app.dart
  theme/
    app_colors.dart
    app_theme.dart
  l10n/
  core/
    api/
      api_client.dart
      api_error.dart
    auth/
      auth_controller.dart
      auth_repository.dart
      access_controller.dart
      pin_lock_service.dart
    repositories/
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

- Screens do not call the backend API directly.
- Screens use providers/controllers.
- Repositories are the only client layer that knows backend API paths.
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
- Widget tests for recipe detail base/variant behavior.
- Widget tests for recipe type and SOP type filtering.
- Widget tests for SOP detail behavior.
- Widget tests for admin content form validation.
- Backend integration and authorization tests:
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
- An admin can create a draft drink recipe with different Hot and Cold
  parameters and steps.
- An admin can create a food recipe with base parameters and steps.
- An admin can create an other-type recipe or custom recipe type.
- Draft content is visible to admins only.
- Published content is visible to staff.
- A staff user can open a drink recipe, switch Hot/Cold, and scale quantities
  to `x3`.
- A staff user can open a food recipe and scale quantities to `x3`.
- An admin can create an SOP with SOP type, parameters, and steps.
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
- What production process should create the first admin now that the temporary
  unauthenticated bootstrap endpoint has been removed?
