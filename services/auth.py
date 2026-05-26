"""PIN + mode (Staff/Admin) state."""
from services import storage


def get_pin():
    return storage.load_pin().get("pin", "1234")


def get_admin_pin():
    return storage.load_pin().get("admin_pin", "1234")


def is_pin_enabled():
    return storage.load_pin().get("enabled", True)


def set_pin_enabled(enabled):
    data = storage.load_pin()
    data["enabled"] = bool(enabled)
    storage.save_pin(data)


def change_pin(new_pin):
    data = storage.load_pin()
    data["pin"] = new_pin
    storage.save_pin(data)


def check_pin(entered):
    return entered == get_pin()


def check_admin_pin(entered):
    return entered == get_admin_pin()


def get_mode():
    return storage.load_pin().get("mode", "Staff")


def set_mode(mode):
    data = storage.load_pin()
    data["mode"] = mode
    storage.save_pin(data)


def is_admin():
    return get_mode() == "Admin"
