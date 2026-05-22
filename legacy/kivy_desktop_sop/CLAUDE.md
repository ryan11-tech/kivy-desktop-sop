# Tea SOP — Project Guide

A Kivy desktop app that displays Standard Operating Procedure cards for tea / milk-tea preparation. Phone-shaped window (400×700), single-user, kiosk-style. Used by staff in a shop.

## Stack

- **Python 3.10+**, **Kivy 2.3.x** for UI.
- **JSON files on disk** as the data store (`data/*.json`). No database, no network, no async.
- Single process. Single user. No auth beyond a shared PIN.

Run: `python main.py`. Install: `pip install kivy`.

## Architecture (target)

Three layers. Keep them separate.

```
main.py              entry, ScreenManager wiring only
screens/             pure UI. No JSON. No file IO. No business logic.
services/            all data IO, validation, migrations, domain rules
data/                JSON files (recipes, pin, theme, lang)
assets/              fonts, images
theme.py / lang.py   read-only globals (TH, L) loaded once via services
utils.py             Kivy widget helpers only (buttons, labels, draw)
```

Rule: **screens never touch JSON**. They call `services.recipes.list()`, `services.recipes.update(...)`, etc. If a screen imports `json`, that's a bug.

## Data schema

`data/recipes.json` is versioned. The first key is always `schema_version`. Migrations live in `services/storage.py`.

```json
{
  "schema_version": 2,
  "categories": [
    {
      "id": "black_tea_base",
      "name": "Black Tea Base",
      "icon": "",
      "recipes": [
        {
          "id": "base_001",
          "name": "Black Tea Concentrate",
          "type": "sop" | "drink" | "steps",
          "favorite": false,
          "notes": "",
          "image": "assets/recipes/black_tea.jpg",
          "updated_at": "2026-05-03T10:00:00Z",

          "parameters": [{"name": "...", "amount": 1.0, "unit": "g"}],
          "steps":      ["..."],
          "variants":   [{"type": "Hot"|"Iced", "ingredients": [{"name":"...","amount":1.0,"unit":"ml"}]}]
        }
      ]
    }
  ]
}
```

### Recipe types

- `sop`     — `parameters[]` + `steps[]` (e.g. brewing a base).
- `drink`   — `variants[]` with Hot / Iced ingredient lists.
- `steps`   — `steps[]` only (procedure with no quantities).

Always read the `type` field. Do not infer the shape from which keys are present.

### IDs

- IDs are stable. Renaming a category or recipe must **not** change its `id`.
- New IDs are generated as `slugify(name) + short_random_suffix` to avoid collisions.
- Lookup is always by `id`, never by `name`.

### Images

- Stored as **paths relative to project root** (e.g. `assets/recipes/foo.jpg`).
- Absolute paths from another machine (`C:/Users/.../`) are stripped on migration.

## `data/pin.json`

```json
{ "pin": "2222", "admin_pin": "1234", "enabled": true, "mode": "Staff" }
```

- `mode`: "Staff" or "Admin". Admin sees edit/delete/add buttons, Staff doesn't.
- `mode` resets to "Staff" on every app start (see `splash_screen.go_next`).
- PIN is plaintext. This is a kiosk app on a trusted device. Don't add hashing without a real threat model.

## Conventions

### Code

- **No business logic in screens.** Screen methods set up widgets and bind callbacks. Callbacks call services.
- **No bare `except:`.** Catch the specific exception you can handle. Let the rest crash — `main.py` has a top-level handler.
- **Atomic writes.** Use `services.storage.write_json` (write to `*.tmp`, `os.replace`). Never write directly with `open(path,"w")`.
- **No comments explaining what code does.** Comment only non-obvious *why* (a constraint, a workaround, a Kivy quirk).
- **No emojis** in code, comments, or commit messages.
- **Imports**: stdlib, third-party, local — three blocks, alphabetised inside each.

### Kivy

- Each screen has one `build_ui()` (or `_build()`) that builds from scratch on `on_enter`. That's the rebuild model. Keep it.
- For canvas drawing, define one local `def draw(w, *_):` and `bind(pos=draw, size=draw)`. Don't redefine the same draw closure five times in one method — extract a helper to `utils.py`.
- Tkinter is **lazy-imported** inside the function that needs the file picker. Never at module top level — it pulls in `tkinter` for users who never open the dialog.
- Use `Clock.schedule_once` for navigation that must happen after the current frame. Never use `time.sleep` on the main thread.

### Schema changes

When you change the recipe schema:

1. Bump `SCHEMA_VERSION` in `services/storage.py`.
2. Add a migration function `_migrate_v{N-1}_to_v{N}(data)`.
3. Append it to the `MIGRATIONS` list.
4. Update this file's "Data schema" section.

Migrations run on load. They are pure functions over the dict. Never break old files.

## Things we don't do

- Don't add a real database (SQLite, etc.) until the recipe count needs it. ~1000 recipes still fits JSON fine.
- Don't add async / threads. Kivy main loop + small JSON files = fast enough.
- Don't introduce a new dependency without removing one. Keep the install one-liner.
- Don't build a "framework" inside the app. No event bus, no DI, no plugin system. This is a 6-screen app.
- Don't add unit tests for trivial Kivy widget code. Test the services layer only (data shape, migration, parsing).
- Don't auto-generate IDs from user-typed names without a uniqueness check.

## Workflow

- Edit. Run `python main.py`. Click through the affected screen. That's the test loop.
- Default PIN: `2222` (user) / `1234` (admin). The admin button in the drawer prompts for the admin PIN.
- To reset everything: delete `data/theme.json` and `data/pin.json`. They regenerate.

## Known debt (track here)

- `home_screen.py` is 800 lines. The drawer should move to its own file when next touched.
- `lang.py` hardcodes three languages in one Python dict. If a fourth language is added, move strings to `data/lang.json`.
- No undo for delete operations. Categories and recipes are gone on save.
