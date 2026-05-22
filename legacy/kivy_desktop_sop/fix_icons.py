import re

# ── home_screen.py ────────────────────────────────────────────────
with open("screens/home_screen.py", "r", encoding="utf-8") as f:
    s = f.read()
orig = s

# Top menu button
s = re.sub(
    r'menu = icon_btn\("[^"]*",\s*\n\s*on_press=lambda \*_: self\.open_drawer\(\),\s*\n\s*size=\(44, 44\), font=FA_FONT,\s*\n\s*fg=TH\.text_main, bg=TH\.card,\s*\n\s*font_size=18, radius=12\)',
    'menu = Button(\n            text="MENU", font_size=10, bold=True,\n            size_hint=(None, None), size=(54, 44),\n            background_normal="", background_color=(0, 0, 0, 0),\n            color=TH.text_main)\n        fill_rounded(menu, TH.card, radius=12)\n        menu.bind(on_press=lambda *_: self.open_drawer())',
    s)

# Mode toggle
s = re.sub(
    r'mode_btn = icon_btn\([^\n]*\n\s*on_press=lambda \*_: self\._toggle_mode\(\),\s*\n\s*size=\(44, 44\), font=FA_FONT,\s*\n\s*fg=TH\.primary, bg=TH\.card,\s*\n\s*font_size=16, radius=12\)',
    'mode_btn = Button(\n            text=("LIGHT" if is_dark else "DARK"), font_size=9, bold=True,\n            size_hint=(None, None), size=(54, 44),\n            background_normal="", background_color=(0, 0, 0, 0),\n            color=TH.primary)\n        fill_rounded(mode_btn, TH.card, radius=12)\n        mode_btn.bind(on_press=lambda *_: self._toggle_mode())',
    s)

# Chevron in cat card
s = re.sub(
    r'chev = icon_btn\("[^"]*",\s*\n\s*on_press=lambda \*_, cid=cat\["id"\]: self\._open_cat\(cid\),\s*\n\s*size=\(36, 36\), font=FA_FONT,\s*\n\s*fg=TH\.primary, bg=TH\.bg,\s*\n\s*font_size=12, radius=10\)',
    'chev = icon_btn(">",\n                        on_press=lambda *_, cid=cat["id"]: self._open_cat(cid),\n                        size=(36, 36),\n                        fg=TH.primary, bg=TH.bg,\n                        font_size=18, radius=10)',
    s)

# Edit/Del cat
s = re.sub(
    r'edit_b = icon_btn\("[^"]*",\s*\n\s*on_press=lambda \*_, cid=cat\["id"\]: self\._edit_cat_byid\(cid\),\s*\n\s*size=\(36, 32\), font=FA_FONT,\s*\n\s*fg=TH\.primary, bg=TH\.card2,\s*\n\s*font_size=12, radius=10\)',
    'edit_b = icon_btn("Edit",\n                              on_press=lambda *_, cid=cat["id"]: self._edit_cat_byid(cid),\n                              size=(48, 32),\n                              fg=TH.primary, bg=TH.card2,\n                              font_size=10, radius=10)',
    s)
s = re.sub(
    r'del_b = icon_btn\("[^"]*",\s*\n\s*on_press=lambda \*_, cid=cat\["id"\]: self\._del_cat_byid\(cid\),\s*\n\s*size=\(36, 32\), font=FA_FONT,\s*\n\s*fg=TH\.red, bg=TH\.card2,\s*\n\s*font_size=12, radius=10\)',
    'del_b = icon_btn("Del",\n                             on_press=lambda *_, cid=cat["id"]: self._del_cat_byid(cid),\n                             size=(48, 32),\n                             fg=TH.red, bg=TH.card2,\n                             font_size=10, radius=10)',
    s)

# Drawer items: drop FA icon column
s = re.sub(
    r'items = \[\s*\n\s*\("[^"]*", "Home", "home"\),\s*\n\s*\("[^"]*", "Favorites", "favorites"\),\s*\n\s*\("[^"]*", "Settings", "settings"\),\s*\n\s*\("[^"]*", "Lock", "lock"\),\s*\n\s*\("[^"]*", "Admin Mode", "admin"\),\s*\n\s*\("[^"]*", "About", "about"\),\s*\n\s*\]',
    'items = [\n            ("Home", "home"),\n            ("Favorites", "favorites"),\n            ("Settings", "settings"),\n            ("Lock", "lock"),\n            ("Admin Mode", "admin"),\n            ("About", "about"),\n        ]',
    s)

# Update drawer loop signature
s = s.replace("for icon, label, key in items:", "for label, key in items:")

# Remove icon_lbl block in drawer
s = re.sub(
    r'\s*icon_lbl = Label\(\s*\n\s*text=icon, font_size=16,\s*\n\s*font_name=FA_FONT,\s*\n\s*size_hint=\(None, None\), size=\(28, 44\),\s*\n\s*halign="center", valign="middle",\s*\n\s*color=TH\.primary\)\s*\n\s*row\.add_widget\(icon_lbl\)\s*\n',
    '\n',
    s)

# Bottom nav icons -> use bullet/dot
s = re.sub(
    r'items=\[\s*\n\s*\("home",\s*"[^"]*", "Home"\),\s*\n\s*\("favorites", "[^"]*", "Favorites"\),\s*\n\s*\("settings",\s*"[^"]*", "Settings"\),\s*\n\s*\],',
    'items=[\n                ("home",      "*", "Home"),\n                ("favorites", "*", "Favorites"),\n                ("settings",  "*", "Settings"),\n            ],',
    s)

# Empty state FA icon
s = re.sub(
    r'\s*ic = Label\(\s*\n\s*text="[^"]*", font_size=42,\s*\n\s*font_name=FA_FONT, color=TH\.grey,\s*\n\s*size_hint_y=None, height=60,\s*\n\s*halign="center"\)\s*\n\s*wrap\.add_widget\(ic\)\s*\n',
    '\n',
    s)

# Confirm-delete category icon line
s = re.sub(
    r'\s*content\.add_widget\(Label\(\s*\n\s*text="[^"]*", font_size=32, font_name=FA_FONT,\s*\n\s*color=TH\.red, size_hint_y=None, height=42,\s*\n\s*halign="center"\)\)\s*\n',
    '\n',
    s)

# Patch nav font block - drop
s = re.sub(
    r'\s*# Patch font for icons in nav\s*\n\s*for cell in nav\.children:\s*\n\s*if hasattr\(cell, "children"\):\s*\n\s*for c in cell\.children:\s*\n\s*if isinstance\(c, Button\):\s*\n\s*c\.font_name = FA_FONT\s*\n',
    '\n',
    s)

if s != orig:
    with open("screens/home_screen.py", "w", encoding="utf-8") as f:
        f.write(s)
    print("home_screen.py updated")
else:
    print("home_screen.py UNCHANGED")

# ── category_screen.py ────────────────────────────────────────────
with open("screens/category_screen.py", "r", encoding="utf-8") as f:
    s = f.read()
orig = s

s = re.sub(
    r'edit_b = icon_btn\("[^"]*",\s*\n\s*on_press=lambda \*_, rid=recipe\["id"\]: self\._edit_rec\(cat_id, rid\),\s*\n\s*size=\(36, 32\), font=FA_FONT,\s*\n\s*fg=TH\.primary, bg=TH\.card2,\s*\n\s*font_size=12, radius=10\)',
    'edit_b = icon_btn("Edit",\n                              on_press=lambda *_, rid=recipe["id"]: self._edit_rec(cat_id, rid),\n                              size=(48, 32),\n                              fg=TH.primary, bg=TH.card2,\n                              font_size=10, radius=10)',
    s)
s = re.sub(
    r'del_b = icon_btn\("[^"]*",\s*\n\s*on_press=lambda \*_, rid=recipe\["id"\]: self\._del_rec\(cat_id, rid\),\s*\n\s*size=\(36, 32\), font=FA_FONT,\s*\n\s*fg=TH\.red, bg=TH\.card2,\s*\n\s*font_size=12, radius=10\)',
    'del_b = icon_btn("Del",\n                             on_press=lambda *_, rid=recipe["id"]: self._del_rec(cat_id, rid),\n                             size=(48, 32),\n                             fg=TH.red, bg=TH.card2,\n                             font_size=10, radius=10)',
    s)

# Fav button - ASCII star
s = re.sub(
    r'fav_btn = Button\(\s*\n\s*text="[^"]*" if is_fav else "[^"]*",\s*\n\s*font_size=15, font_name=FA_FONT,\s*\n\s*size_hint=\(None, None\), size=\(34, 34\),\s*\n\s*background_normal="", background_color=\(0, 0, 0, 0\),\s*\n\s*color=TH\.fav if is_fav else TH\.grey\)',
    'fav_btn = Button(\n            text=("*" if is_fav else "+"),\n            font_size=22, bold=True,\n            size_hint=(None, None), size=(34, 34),\n            background_normal="", background_color=(0, 0, 0, 0),\n            color=TH.fav if is_fav else TH.grey)',
    s)

# Empty state FA icon
s = re.sub(
    r'\s*empty\.add_widget\(Label\(\s*\n\s*text="[^"]*", font_size=42,\s*\n\s*font_name=FA_FONT, color=TH\.grey,\s*\n\s*size_hint_y=None, height=60, halign="center"\)\)\s*\n',
    '\n',
    s)

if s != orig:
    with open("screens/category_screen.py", "w", encoding="utf-8") as f:
        f.write(s)
    print("category_screen.py updated")
else:
    print("category_screen.py UNCHANGED")
