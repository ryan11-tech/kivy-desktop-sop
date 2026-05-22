"""Atomic JSON read/write + schema migration.

All disk IO for the app goes through here. Screens never call json directly.
"""
import json
import os
import re
import tempfile
from datetime import datetime, timezone

ROOT      = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA_DIR  = os.path.join(ROOT, "data")

SCHEMA_VERSION = 2


def _now_iso():
    return datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")


def read_json(path, default):
    try:
        with open(path, "r", encoding="utf-8") as f:
            return json.load(f)
    except (FileNotFoundError, json.JSONDecodeError):
        return default


def write_json(path, data):
    """Atomic write: tmp file in same dir, then os.replace."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    fd, tmp = tempfile.mkstemp(prefix=".tmp_", dir=os.path.dirname(path))
    try:
        with os.fdopen(fd, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        os.replace(tmp, path)
    except Exception:
        if os.path.exists(tmp):
            os.remove(tmp)
        raise


def _slugify(name):
    s = re.sub(r"[^a-z0-9]+", "_", name.lower()).strip("_")
    return s or "item"


def _strip_external_image(path):
    """Drop image paths that point outside the project (other machines, etc.)."""
    if not path:
        return ""
    norm = path.replace("\\", "/")
    if norm.startswith(ROOT.replace("\\", "/")):
        return os.path.relpath(norm, ROOT).replace("\\", "/")
    if os.path.isabs(norm) or re.match(r"^[a-zA-Z]:", norm):
        return ""
    return norm


def _infer_recipe_type(recipe):
    if "variants" in recipe:
        return "drink"
    if "parameters" in recipe:
        return "sop"
    return "steps"


def _migrate_v1_to_v2(data):
    """v1 → v2: add `type` discriminator, normalise images, add updated_at."""
    now = _now_iso()
    for cat in data.get("categories", []):
        for r in cat.get("recipes", []):
            r.setdefault("type", _infer_recipe_type(r))
            r["image"] = _strip_external_image(r.get("image", ""))
            r.setdefault("favorite", False)
            r.setdefault("notes", "")
            r.setdefault("updated_at", now)
    return data


MIGRATIONS = [
    (1, 2, _migrate_v1_to_v2),
]


def _migrate(data):
    """Run migrations in order until data is at SCHEMA_VERSION."""
    v = data.get("schema_version", 1)
    for src, dst, fn in MIGRATIONS:
        if v == src:
            data = fn(data)
            data["schema_version"] = dst
            v = dst
    return data


def load_recipes():
    path = os.path.join(DATA_DIR, "recipes.json")
    data = read_json(path, {"schema_version": SCHEMA_VERSION, "categories": []})
    if data.get("schema_version", 1) < SCHEMA_VERSION:
        data = _migrate(data)
        write_json(path, data)
    return data


def save_recipes(data):
    data["schema_version"] = SCHEMA_VERSION
    path = os.path.join(DATA_DIR, "recipes.json")
    write_json(path, data)


def load_pin():
    path = os.path.join(DATA_DIR, "pin.json")
    return read_json(path, {
        "pin": "1234", "admin_pin": "1234",
        "enabled": True, "mode": "Staff",
    })


def save_pin(data):
    write_json(os.path.join(DATA_DIR, "pin.json"), data)


def load_theme_raw():
    path = os.path.join(DATA_DIR, "theme.json")
    return read_json(path, None)


def save_theme_raw(data):
    write_json(os.path.join(DATA_DIR, "theme.json"), data)


def load_lang_raw():
    path = os.path.join(DATA_DIR, "lang.json")
    return read_json(path, None)


def save_lang_raw(data):
    write_json(os.path.join(DATA_DIR, "lang.json"), data)
