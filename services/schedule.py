"""Domain operations on the schedule store.

Screens call these. Never call storage directly from a screen.
"""
import re
import secrets

from services import storage

DAYS = storage.DAYS


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


# ── Read ─────────────────────────────────────────────────────────────────────

def all_data():
    return storage.load_schedule()


def get_shifts(data):
    return data.get("shifts", [])


def get_staff(data):
    return data.get("staff", [])


def get_day_entries(data, day):
    return data["schedule"].get(day, [])


def get_tasks(data):
    return data.get("tasks", [])


def shifts_map(data):
    return {s["id"]: s for s in data.get("shifts", [])}


def staff_map(data):
    return {s["id"]: s for s in data.get("staff", [])}


# ── Shifts (definitions) ──────────────────────────────────────────────────────

def add_shift(name, start_time, end_time, color):
    name = name.strip()
    if not name:
        raise ValueError("name required")
    data = storage.load_schedule()
    existing = {s["id"] for s in data["shifts"]}
    shift = {
        "id":         _unique_id(_slugify(name), existing),
        "name":       name,
        "start_time": start_time.strip() or "00:00",
        "end_time":   end_time.strip()   or "00:00",
        "color":      color.strip()      or "#C9A84C",
    }
    data["shifts"].append(shift)
    storage.save_schedule(data)
    return shift


def delete_shift(shift_id):
    data = storage.load_schedule()
    data["shifts"] = [s for s in data["shifts"] if s["id"] != shift_id]
    # remove entries that reference this shift
    for day in DAYS:
        data["schedule"][day] = [
            e for e in data["schedule"][day]
            if e.get("shift_id") != shift_id
        ]
    storage.save_schedule(data)


# ── Staff ─────────────────────────────────────────────────────────────────────

def add_staff(name):
    name = name.strip()
    if not name:
        raise ValueError("name required")
    data = storage.load_schedule()
    existing = {s["id"] for s in data["staff"]}
    member = {
        "id":   _unique_id("staff_" + _slugify(name), existing),
        "name": name,
    }
    data["staff"].append(member)
    storage.save_schedule(data)
    return member


def delete_staff(staff_id):
    data = storage.load_schedule()
    data["staff"] = [s for s in data["staff"] if s["id"] != staff_id]
    # remove from all shift entries and tasks
    for day in DAYS:
        for entry in data["schedule"][day]:
            entry["staff"] = [sid for sid in entry.get("staff", [])
                               if sid != staff_id]
    for task in data["tasks"]:
        task["assigned_staff"] = [sid for sid in task.get("assigned_staff", [])
                                   if sid != staff_id]
    storage.save_schedule(data)


# ── Day schedule entries ───────────────────────────────────────────────────────

def add_day_entry(day, shift_id):
    data = storage.load_schedule()
    entry = {"shift_id": shift_id, "staff": []}
    data["schedule"][day].append(entry)
    storage.save_schedule(data)
    return entry


def delete_day_entry(day, entry_index):
    data = storage.load_schedule()
    entries = data["schedule"].get(day, [])
    if 0 <= entry_index < len(entries):
        entries.pop(entry_index)
    storage.save_schedule(data)


def assign_staff_to_entry(day, entry_index, staff_ids):
    data = storage.load_schedule()
    entries = data["schedule"].get(day, [])
    if 0 <= entry_index < len(entries):
        entries[entry_index]["staff"] = list(staff_ids)
    storage.save_schedule(data)


# ── Tasks ─────────────────────────────────────────────────────────────────────

def add_task(name, days=None):
    name = name.strip()
    if not name:
        raise ValueError("name required")
    data = storage.load_schedule()
    existing = {t["id"] for t in data["tasks"]}
    task = {
        "id":             _unique_id("task_" + _slugify(name), existing),
        "name":           name,
        "days":           days or [],
        "assigned_staff": [],
    }
    data["tasks"].append(task)
    storage.save_schedule(data)
    return task


def delete_task(task_id):
    data = storage.load_schedule()
    data["tasks"] = [t for t in data["tasks"] if t["id"] != task_id]
    storage.save_schedule(data)


def assign_staff_to_task(task_id, staff_ids):
    data = storage.load_schedule()
    task = next((t for t in data["tasks"] if t["id"] == task_id), None)
    if task is None:
        return False
    task["assigned_staff"] = list(staff_ids)
    storage.save_schedule(data)
    return True


# ── Week ──────────────────────────────────────────────────────────────────────

def clear_week():
    data = storage.load_schedule()
    data["schedule"] = {d: [] for d in DAYS}
    storage.save_schedule(data)