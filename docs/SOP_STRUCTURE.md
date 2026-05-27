# Existing SOP Structure

This document captures the SOP shape currently used by the Flutter app so the
backend schema and API can store the same data in the database instead of
keeping it only in local mock objects.

Source files:

- `lib/core/models/content_item.dart`
- `lib/core/models/parameter.dart`
- `lib/core/models/category.dart`
- `lib/core/firestore/mock_catalog_repository.dart`
- `lib/core/search/content_search.dart`
- `lib/features/item_detail/item_detail_screen.dart`

## Current Model

SOPs are stored as `ContentItem` records. A `ContentItem` can be either a
recipe or an SOP, selected by `contentType`.

For SOP rows:

- `contentType` must be `sop`.
- `status` is `draft` or `published`.
- Shared item fields hold identity, category, notes, image, and ordering.
- The nested `sop` object holds SOP-specific data.
- The nested `recipe` object still exists, but is empty/default for SOP items.

## Content Item Fields

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | Stable item id. Passed separately into `ContentItem.fromJson`. |
| `contentType` | enum string | yes | `recipe` or `sop`. SOP items use `sop`. |
| `status` | enum string | yes | `draft` or `published`. |
| `categoryId` | string | yes | Links to a category. |
| `name` | string | yes | SOP display name. |
| `notes` | string | no | Used as first preview text when present. |
| `imageUrl` | string | no | Public or signed image URL for display. Empty string today. |
| `imagePath` | string | no | Backend/media storage path. Empty string today. |
| `recipe` | object | yes | Empty/default object for SOP records. |
| `sop` | object | yes | SOP-specific content. |
| `order` | integer | yes | Manual ordering inside lists/categories. Defaults to `0`. |

## SOP Object Fields

The Dart model is `SopContent`.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `sopType` | string | yes | Stable lowercase key for filtering/grouping. Example: `opening`. |
| `parameters` | array of `Parameter` | conditional | Required if `steps` is empty. |
| `steps` | array of string | conditional | Required if `parameters` is empty. Ordered by array index. |

Validation rules:

- `sop.sopType` cannot be empty.
- SOP content must include at least one parameter or one step.
- SOP parameters are fixed values.
- SOPs do not use the recipe servings multiplier in v1.

## Parameter Fields

The same `Parameter` model is used by recipes and SOPs.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `name` | string | yes | Parameter label. Current parser trims whitespace but does not validate empty names. |
| `amount` | double | yes | Must be numeric. Parser accepts a number or numeric string. |
| `unit` | string | yes | Short unit such as `ml`, `g`, `round`, `C`, `min`. |

The app formats whole numbers without decimals and trims trailing decimal zeros
for non-integers.

## Category Fields

SOPs are grouped by category through `categoryId`.

| Field | Type | Required | Notes |
|-------|------|----------|-------|
| `id` | string | yes | Stable category id. |
| `name` | string | yes | Display name. |
| `icon` | string | no | Current app uses short text icons such as `O`. |
| `order` | integer | yes | Manual sort order. Defaults to `0`. |

Current mock SOP category:

```json
{
  "id": "opening",
  "name": "Opening SOP",
  "icon": "O",
  "order": 20
}
```

## Existing Mock SOP

Current mock data has one SOP item:

```json
{
  "id": "closing_checklist",
  "contentType": "sop",
  "status": "published",
  "categoryId": "opening",
  "name": "Opening Counter Checklist",
  "notes": "Daily setup before first customer service.",
  "imageUrl": "",
  "imagePath": "",
  "recipe": {
    "recipeType": "other",
    "parameters": [],
    "steps": [],
    "variants": []
  },
  "sop": {
    "sopType": "opening",
    "parameters": [
      {
        "name": "Sanitizer check",
        "amount": 1,
        "unit": "round"
      },
      {
        "name": "Fridge temperature",
        "amount": 4,
        "unit": "C"
      }
    ],
    "steps": [
      "Turn on lights and counter equipment.",
      "Check fridge temperature and sanitizer level.",
      "Prepare cups, lids, straws, and receipt paper."
    ]
  },
  "order": 20
}
```

Note: the mock id is `closing_checklist`, but the item name and `sopType` are
for opening. Treat the id as mock-only and do not copy that mismatch into seed
data.

## Built-In SOP Types From PRD

Use stable lowercase keys:

- `opening`
- `closing`
- `cleaning`
- `prep`
- `maintenance`
- `inventory`
- `safety`
- `training`
- `other`

Admins can add custom SOP type keys later. Store keys as lowercase stable
strings, and keep the display label separate if custom labels are needed.

## UI Behavior

The detail screen renders SOPs like this:

- Category name or `Uncategorized`.
- Content type chip: `SOP`.
- Status chip: `Draft` or `Published`.
- Notes, when present.
- `sop.sopType` uppercased.
- Parameter table from `sop.parameters`.
- Ordered steps from `sop.steps`.

If parameters are empty, the UI shows `No quantities yet.` If steps are empty,
the UI shows `No steps yet.`

## Search Behavior

Current local search includes:

- SOP item name.
- Content kind label: `SOP`.
- `sop.sopType`.
- Notes.
- Category name.
- SOP parameter names.
- SOP step text.

The backend can start by returning all visible SOP content and keep search
local in the Flutter app. Backend search can be added later using the same
fields.

## Visibility Rules

Visibility is currently handled in `ContentItem.canBeSeenBy`.

- Inactive members see nothing.
- Admins can see draft and published items.
- Staff can see only published items.

The backend must enforce the same rule before returning API responses.

## Recommended Backend Storage

The Flutter app can consume either nested JSON responses or normalized API
responses. PostgreSQL should keep enough structure to support ordering,
validation, filtering, and future editing.

Recommended minimum tables:

```text
categories
content_items
sop_parameters
sop_steps
```

### `categories`

```text
id              text primary key
shop_id         text not null
name            text not null
icon            text not null default ''
sort_order      integer not null default 0
created_at      timestamptz not null
updated_at      timestamptz not null
created_by      text null
updated_by      text null
```

### `content_items`

```text
id              text primary key
shop_id         text not null
content_type    text not null check content_type in ('recipe', 'sop')
status          text not null check status in ('draft', 'published')
category_id     text not null references categories(id)
name            text not null
notes           text not null default ''
image_url       text not null default ''
image_path      text not null default ''
sop_type        text null
recipe_type     text null
sort_order      integer not null default 0
published_at    timestamptz null
published_by    text null
created_at      timestamptz not null
updated_at      timestamptz not null
created_by      text null
updated_by      text null
```

For SOP items:

- `content_type = 'sop'`
- `sop_type` is required.
- `recipe_type` can be null or `other`, depending on the final backend style.

### `sop_parameters`

```text
id              text primary key
item_id         text not null references content_items(id) on delete cascade
name            text not null
amount          numeric not null
unit            text not null
sort_order      integer not null
```

### `sop_steps`

```text
id              text primary key
item_id         text not null references content_items(id) on delete cascade
body            text not null
sort_order      integer not null
```

## Alternative JSONB Storage

For faster scaffold work, the backend can store the whole SOP payload as JSONB
on `content_items`:

```text
sop             jsonb not null default '{"sopType":"other","parameters":[],"steps":[]}'
recipe          jsonb not null default '{"recipeType":"other","parameters":[],"steps":[],"variants":[]}'
```

JSONB is quicker to implement and matches the current Flutter model closely.
Normalized tables are better for admin editing, reporting, validation, and
future backend search.

## Recommended API Shape

The API response should match the Flutter `ContentItem.toJson` shape and add
`id` in the response body.

```json
{
  "id": "opening_counter_checklist",
  "contentType": "sop",
  "status": "published",
  "categoryId": "opening",
  "name": "Opening Counter Checklist",
  "imageUrl": "",
  "imagePath": "",
  "notes": "Daily setup before first customer service.",
  "recipe": {
    "recipeType": "other",
    "parameters": [],
    "steps": [],
    "variants": []
  },
  "sop": {
    "sopType": "opening",
    "parameters": [
      {
        "name": "Sanitizer check",
        "amount": 1,
        "unit": "round"
      }
    ],
    "steps": [
      "Turn on lights and counter equipment."
    ]
  },
  "order": 20
}
```

Recommended endpoints:

```text
GET    /api/categories
GET    /api/items?contentType=sop
GET    /api/items/:id
POST   /api/items
PATCH  /api/items/:id
DELETE /api/items/:id
```

Admin-only write endpoints should validate the same rules as the Flutter model.
Staff read endpoints should return only published SOP items.

## Backend Validation Checklist

- `contentType` must be `sop` for SOP create/update.
- `status` must be `draft` or `published`.
- `name` is required.
- `categoryId` is required and must exist.
- `sop.sopType` is required.
- At least one SOP parameter or one SOP step is required.
- Every parameter must have `name`, numeric `amount`, and `unit`.
- Steps should be non-empty strings after trimming.
- Preserve parameter and step order.
- Staff can read only `published` SOPs.
- Admins can read, create, edit, publish, unpublish, and delete SOPs.
