"""Domain operations on the recipes store.

Screens call these. Never call services.storage directly from a screen.
"""
import re
import secrets

from services import storage


def _slugify(name):
    s = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
    return s or "item"


def _unique_id(base, existing_ids):
    if base not in existing_ids:
        return base
    while True:
        candidate = f"{base}_{secrets.token_hex(2)}"
        if candidate not in existing_ids:
            return candidate


def all_data():
    return storage.load_recipes()


def find_category(data, cat_id):
    return next((c for c in data["categories"] if c["id"] == cat_id), None)


def find_recipe(data, cat_id, recipe_id):
    cat = find_category(data, cat_id)
    if cat is None:
        return None
    return next((r for r in cat["recipes"] if r["id"] == recipe_id), None)


def add_category(name, icon=""):
    name = name.strip()
    if not name:
        raise ValueError("name required")
    data = storage.load_recipes()
    existing = {c["id"] for c in data["categories"]}
    cat = {
        "id":      _unique_id(_slugify(name), existing),
        "name":    name,
        "icon":    icon.strip(),
        "recipes": [],
    }
    data["categories"].append(cat)
    storage.save_recipes(data)
    return cat


def update_category(cat_id, name, icon):
    data = storage.load_recipes()
    cat = find_category(data, cat_id)
    if cat is None:
        return False
    cat["name"] = name.strip() or cat["name"]
    cat["icon"] = icon.strip()
    storage.save_recipes(data)
    return True


def delete_category(cat_id):
    data = storage.load_recipes()
    data["categories"] = [c for c in data["categories"] if c["id"] != cat_id]
    storage.save_recipes(data)


def add_recipe(cat_id, recipe):
    """recipe: dict with name + type + (parameters/steps/variants)."""
    name = recipe.get("name", "").strip()
    if not name:
        raise ValueError("name required")
    data = storage.load_recipes()
    cat  = find_category(data, cat_id)
    if cat is None:
        raise KeyError(cat_id)
    existing = {r["id"] for r in cat["recipes"]}
    recipe["id"] = _unique_id(_slugify(name), existing)
    recipe.setdefault("favorite", False)
    recipe.setdefault("notes", "")
    recipe["updated_at"] = storage._now_iso()
    cat["recipes"].append(recipe)
    storage.save_recipes(data)
    return recipe


def update_recipe(cat_id, recipe_id, patch):
    data = storage.load_recipes()
    r = find_recipe(data, cat_id, recipe_id)
    if r is None:
        return False
    for k, v in patch.items():
        if k == "id":
            continue
        r[k] = v
    r["updated_at"] = storage._now_iso()
    storage.save_recipes(data)
    return True


def delete_recipe(cat_id, recipe_id):
    data = storage.load_recipes()
    cat  = find_category(data, cat_id)
    if cat is None:
        return False
    cat["recipes"] = [r for r in cat["recipes"] if r["id"] != recipe_id]
    storage.save_recipes(data)
    return True


def toggle_favorite(cat_id, recipe_id):
    data = storage.load_recipes()
    r = find_recipe(data, cat_id, recipe_id)
    if r is None:
        return False
    r["favorite"] = not r.get("favorite", False)
    r["updated_at"] = storage._now_iso()
    storage.save_recipes(data)
    return r["favorite"]


def parse_ingredients(text):
    """Parse 'name,amount,unit' lines into ingredient dicts."""
    out = []
    for line in text.strip().splitlines():
        parts = [p.strip() for p in line.split(",")]
        if len(parts) != 3:
            continue
        try:
            amount = float(parts[1])
        except ValueError:
            continue
        out.append({"name": parts[0], "amount": amount, "unit": parts[2]})
    return out
