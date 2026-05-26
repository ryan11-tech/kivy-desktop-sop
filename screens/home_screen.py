import os

from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup
from kivy.clock import Clock
from kivy.graphics import Color, Rectangle, RoundedRectangle, Line

from services import recipes as recipes_svc
from theme import TH, load_theme, save_theme
from lang import L
from utils import (set_bg, fill_rounded, divider, make_label, spacer, hspacer,
                   gold_btn, ghost_btn, styled_btn, icon_btn, chip,
                   bottom_nav, type_chip_for_recipe,
                   load_data, save_data, get_mode, set_mode, check_admin_pin)


CUR_DIR = os.path.dirname(os.path.abspath(__file__))
FA_FONT = os.path.join(os.path.dirname(CUR_DIR), "assets", "fa-solid-900.ttf")


class DrawerMenu(BoxLayout):
    def __init__(self, manager, close_cb, **kw):
        super().__init__(orientation="vertical", **kw)
        self.manager = manager
        self.close_cb = close_cb

        set_bg(self, TH.bg)

        # Header
        hdr = BoxLayout(size_hint_y=None, height=110, padding=[20, 20, 20, 12], spacing=12)
        set_bg(hdr, TH.header_bg)

        from kivy.uix.image import Image as KivyImage
        logo_img = KivyImage(
            source="assets/logo.png",
            size_hint=(None, None),
            size=(44, 44),
            pos_hint={"center_y": 0.5},
            fit_mode="contain")
        hdr.add_widget(logo_img)

        title_col = BoxLayout(orientation="vertical",
                              pos_hint={"center_y": 0.5})
        title_col.add_widget(Label(
            text=L["app_title"], font_size=18, bold=True,
            color=TH.text_main, halign="left", valign="middle",
            size_hint_y=None, height=26,
            text_size=(180, None)))
        sub = Label(
            text=L["app_subtitle"], font_size=11,
            color=TH.grey, halign="left", valign="middle",
            size_hint_y=None, height=18,
            text_size=(180, None))
        title_col.add_widget(sub)

        # Mode chip
        mode_lbl = "ADMIN" if get_mode() == "Admin" else "STAFF"
        mode_chip = chip(mode_lbl, fg=TH.gold_text if get_mode() == "Admin" else TH.white,
                         bg=TH.primary if get_mode() == "Admin" else TH.card2,
                         font_size=9)
        title_col.add_widget(mode_chip)
        hdr.add_widget(title_col)
        self.add_widget(hdr)

        self.add_widget(spacer(8))

        items = [
            ("", "Home", "home"),
            ("", "Favorites", "favorites"),
            ("", "Settings", "settings"),
            ("", "Lock", "lock"),
            ("", "Admin Mode", "admin"),
            ("", "About", "about"),
        ]
        for icon, label, key in items:
            row = BoxLayout(
                size_hint_y=None, height=52,
                padding=[16, 4], spacing=14)
            icon_lbl = Label(
                text=icon, font_size=16,
                font_name=FA_FONT,
                size_hint=(None, None), size=(28, 44),
                halign="center", valign="middle",
                color=TH.primary)
            row.add_widget(icon_lbl)
            btn = Button(
                text=label,
                font_size=TH.fs_normal, bold=False,
                background_normal="", background_color=(0, 0, 0, 0),
                color=TH.text_main, halign="left", valign="middle")
            btn.bind(width=lambda w, v: setattr(w, "text_size", (v, None)))
            btn.nav_key = key
            btn.bind(on_press=self._on_item)
            row.add_widget(btn)
            self.add_widget(row)

        self.add_widget(BoxLayout())  # spacer
        self.add_widget(make_label(
            "v2.0  ·  Tea SOP",
            font_size=10, color=TH.grey,
            halign="center", height=24))
        self.add_widget(spacer(8))
        close_btn = ghost_btn(L["btn_close"], height=44)
        close_btn.bind(on_press=lambda x: self.close_cb())
        self.add_widget(close_btn)
        self.add_widget(spacer(12))

    def _on_item(self, btn):
        key = btn.nav_key
        self.close_cb()

        if key == "home":
            self.manager.transition.direction = "right"
            self.manager.current = "home"
        elif key == "favorites":
            home = self.manager.get_screen("home")
            home.nav_mode = "favorites"
            self.manager.transition.direction = "right"
            self.manager.current = "home"
        elif key == "search":
            home = self.manager.get_screen("home")
            home.nav_mode = "search"
            self.manager.transition.direction = "right"
            self.manager.current = "home"
        elif key == "settings":
            self.manager.transition.direction = "left"
            self.manager.current = "settings"
        elif key == "lock":
            self.manager.transition.direction = "left"
            self.manager.current = "pin"
        elif key == "admin":
            self._show_admin_pin_popup()
        elif key == "about":
            self._show_about()

    def _show_admin_pin_popup(self):
        content = BoxLayout(orientation="vertical", padding=20, spacing=12)
        set_bg(content, TH.bg)
        content.add_widget(make_label(
            "Enter Admin PIN", color=TH.primary,
            halign="center", height=32, bold=True,
            font_size=TH.fs_normal))
        pin_in = TextInput(
            hint_text="****", password=True,
            multiline=False, size_hint_y=None, height=48,
            font_size=18,
            background_color=TH.input_bg,
            foreground_color=TH.text_main,
            cursor_color=TH.primary,
            padding=[14, 14])
        content.add_widget(pin_in)
        error_lbl = make_label(
            "", color=TH.red, halign="center", height=24,
            font_size=12)
        content.add_widget(error_lbl)
        btns = BoxLayout(size_hint_y=None, height=46, spacing=8)
        ok = gold_btn("Unlock", height=46)
        cancel = ghost_btn("Cancel", height=46)
        btns.add_widget(ok)
        btns.add_widget(cancel)
        content.add_widget(btns)
        popup = Popup(title="Admin Login", content=content,
                      size_hint=(0.85, None), height=300,
                      background_color=TH.card,
                      separator_color=TH.primary)

        def _check(*a):
            if check_admin_pin(pin_in.text):
                set_mode("Admin")
                popup.dismiss()
                self.close_cb()
                self.manager.get_screen("home").build_ui()
            else:
                error_lbl.text = "Wrong Admin PIN"
        ok.bind(on_press=_check)
        cancel.bind(on_press=popup.dismiss)
        popup.open()

    def _show_about(self):
        content = BoxLayout(orientation="vertical", padding=20, spacing=10)
        set_bg(content, TH.bg)
        from kivy.uix.image import Image as KivyImage
        logo_box = BoxLayout(
            size_hint=(None, None), size=(56, 56),
            pos_hint={"center_y": 0.5})
        fill_rounded(logo_box, TH.primary, radius=14)
        logo_img = KivyImage(
            source="assets/logo.png",
            size_hint=(None, None),
            size=(40, 40),
            pos_hint={"center_x": 0.5, "center_y": 0.5},
            fit_mode="contain")
        logo_box.add_widget(logo_img)
        content.add_widget(logo_box)
        content.add_widget(spacer(4))
        content.add_widget(Label(
            text="Tea SOP", font_size=22, bold=True,
            color=TH.text_main, halign="center",
            size_hint_y=None, height=32))
        content.add_widget(Label(
            text="Version 2.0\nQuality Control Guide",
            font_size=12, color=TH.grey,
            halign="center", text_size=(280, None),
            size_hint_y=None, height=44))
        content.add_widget(spacer(8))
        ok = gold_btn("OK", height=44)
        content.add_widget(ok)
        popup = Popup(title="", content=content,
                      size_hint=(0.85, None), height=280,
                      background_color=TH.card,
                      separator_height=0)
        ok.bind(on_press=popup.dismiss)
        popup.open()


class HomeScreen(Screen):
    def __init__(self, **kw):
        super().__init__(**kw)
        self.search_text = ""
        self.nav_mode = "home"
        self.favorites_only = False

    def on_enter(self):
        self.favorites_only = (self.nav_mode == "favorites")
        self.build_ui()
        if self.nav_mode == "search":
            if hasattr(self, "search_input"):
                Clock.schedule_once(
                    lambda dt: setattr(self.search_input, "focus", True), 0.35)
        self.nav_mode = "home"

    def build_ui(self):
        import theme as theme_mod
        theme_mod.TH.reload()
        self.clear_widgets()
        data = load_data()

        root = BoxLayout(orientation="vertical")
        set_bg(root, TH.bg)

        # ── Top bar ────────────────────────────────────────────────────
        top = BoxLayout(size_hint_y=None, height=64, padding=[14, 10], spacing=10)
        set_bg(top, TH.bg)

        menu = icon_btn("",
                        on_press=lambda *_: self.open_drawer(),
                        size=(44, 44), font=FA_FONT,
                        fg=TH.text_main, bg=TH.card,
                        font_size=18, radius=12)
        top.add_widget(menu)

        title_col = BoxLayout(orientation="vertical")
        title_col.add_widget(Label(
            text=L["app_title"], font_size=18, bold=True,
            color=TH.text_main, halign="left", valign="middle",
            size_hint_y=None, height=24,
            text_size=(220, None)))
        sub_text = (L["favorites"] if self.favorites_only
                    else L["app_subtitle"])
        title_col.add_widget(Label(
            text=sub_text, font_size=11,
            color=TH.grey, halign="left", valign="middle",
            size_hint_y=None, height=16,
            text_size=(220, None)))
        top.add_widget(title_col)

        t = load_theme()
        is_dark = (t["mode"] == "Dark")
        mode_btn = icon_btn("" if is_dark else "",
                            on_press=lambda *_: self._toggle_mode(),
                            size=(44, 44), font=FA_FONT,
                            fg=TH.primary, bg=TH.card,
                            font_size=16, radius=12)
        top.add_widget(mode_btn)

        root.add_widget(top)

        # ── Search ────────────────────────────────────────────────────
        search_wrap = BoxLayout(size_hint_y=None, height=56, padding=[14, 4])
        search_box = BoxLayout(size_hint_y=None, height=46)
        fill_rounded(search_box, TH.card, radius=12, border_color=(1, 1, 1, 0.06))

        search_inner = BoxLayout(
            size_hint_y=None, height=46,
            padding=[14, 0], spacing=10)
        icon = Label(
            text="", font_size=14,
            font_name=FA_FONT,
            color=TH.grey,
            size_hint=(None, None), size=(20, 46),
            halign="center", valign="middle")
        search_inner.add_widget(icon)
        self.search_input = TextInput(
            hint_text="Search recipes",
            text=self.search_text,
            multiline=False, size_hint_y=None, height=42,
            font_size=TH.fs_normal,
            foreground_color=TH.text_main,
            background_color=(0, 0, 0, 0),
            background_normal="",
            cursor_color=TH.primary,
            hint_text_color=TH.grey,
            padding=[0, 10])
        self.search_input.bind(text=self.on_search)
        search_inner.add_widget(self.search_input)
        search_box.add_widget(search_inner)
        search_wrap.add_widget(search_box)
        root.add_widget(search_wrap)

        # ── List ────────────────────────────────────────────────────
        self.scroll_view = ScrollView(bar_width=2)
        self.list_layout = BoxLayout(
            orientation="vertical", spacing=12,
            padding=[14, 6, 14, 12], size_hint_y=None)
        self.list_layout.bind(minimum_height=self.list_layout.setter("height"))
        self._render_list(data)
        self.scroll_view.add_widget(self.list_layout)
        root.add_widget(self.scroll_view)

        # ── Bottom nav ────────────────────────────────────────────────
        active = "favorites" if self.favorites_only else "home"
        nav = bottom_nav(
            items=[
                ("home",      "", "Home"),
                ("favorites", "", "Favorites"),
                ("settings",  "", "Settings"),
                ("schedule",  "", "Schedule"),
            ],
            active_key=active,
            on_select=self._on_nav)
        # Patch font for icons in nav
        for cell in nav.children:
            if hasattr(cell, "children"):
                for c in cell.children:
                    if isinstance(c, Button):
                        c.font_name = FA_FONT
        root.add_widget(nav)

        self.add_widget(root)

    def _on_nav(self, key):
        if key == "home":
            self.favorites_only = False
            self.build_ui()
        elif key == "favorites":
            self.favorites_only = True
            self.build_ui()
        elif key == "settings":
            self.manager.transition.direction = "left"
            self.manager.current = "settings"
        elif key == "schedule":
            self.manager.transition.direction = "left"
            self.manager.current = "schedule"
            
    # ── Dark / Light toggle ─────────────────────────────────────────
    def _toggle_mode(self):
        import theme as theme_mod
        t = theme_mod.load_theme()
        new_mode = "Light" if t["mode"] == "Dark" else "Dark"
        t["mode"] = new_mode
        if new_mode == "Dark":
            t["bg"] = "#0A0A0A"
            t["card"] = "#141414"
        else:
            t["bg"] = "#F5F5F5"
            t["card"] = "#E8E8E8"
        theme_mod.save_theme(t)
        theme_mod.TH.reload()
        self.build_ui()

    def open_drawer(self):
        content = DrawerMenu(
            manager=self.manager,
            close_cb=lambda: popup.dismiss(),
            size_hint=(1, 1))
        popup = Popup(
            title="", content=content,
            size_hint=(0.78, 1.0), pos_hint={"x": 0},
            background_color=(0, 0, 0, 0), separator_height=0)
        popup.open()

    def _render_list(self, data):
        self.list_layout.clear_widgets()
        if hasattr(self, "scroll_view"):
            self.scroll_view.scroll_y = 1

        query = self.search_text.lower().strip()

        # Favorites-only tab
        if self.favorites_only and not query:
            favs = [(c["id"], r) for c in data["categories"]
                    for r in c["recipes"] if r.get("favorite")]
            if not favs:
                self._render_empty(
                    icon="",
                    title="No favorites yet",
                    subtitle="Tap the star on any recipe to save it.")
            else:
                self._build_fav_section(favs)
            return

        # Filter
        matched = []
        for cat in data["categories"]:
            matched_r = [r for r in cat["recipes"]
                         if query in r["name"].lower()] if query else cat["recipes"]
            if query and not matched_r and query not in cat["name"].lower():
                continue
            matched.append((cat, matched_r if query else None))

        if not matched:
            self._render_empty(
                icon="",
                title=L["no_results"],
                subtitle="Try a different search term.")
            return

        # Admin add card on top (admin only)
        if get_mode() == "Admin" and not query:
            add_btn = gold_btn(L["add_category"], height=48)
            add_btn.bind(on_press=self.show_add_category)
            self.list_layout.add_widget(add_btn)

        for cat, filtered in matched:
            self.list_layout.add_widget(self._build_cat_card(cat, filtered, query))

        # Favorites section under regular list
        favs = [(c["id"], r) for c in data["categories"]
                for r in c["recipes"] if r.get("favorite")]
        if favs and not query:
            self._build_fav_section(favs)

    def _render_empty(self, icon, title, subtitle):
        wrap = BoxLayout(
            orientation="vertical", spacing=12, padding=[24, 60, 24, 24],
            size_hint_y=None, height=240)
        ic = Label(
            text=icon, font_size=42,
            font_name=FA_FONT, color=TH.grey,
            size_hint_y=None, height=60,
            halign="center")
        wrap.add_widget(ic)
        wrap.add_widget(Label(
            text=title, font_size=TH.fs_large, bold=True,
            color=TH.text_main,
            size_hint_y=None, height=32,
            halign="center"))
        wrap.add_widget(Label(
            text=subtitle, font_size=TH.fs_small,
            color=TH.grey,
            size_hint_y=None, height=24,
            halign="center"))
        self.list_layout.add_widget(wrap)

    def _build_cat_card(self, cat, filtered, query):
        card = BoxLayout(
            orientation="vertical",
            size_hint_y=None, spacing=0, padding=0)
        card.bind(minimum_height=card.setter("height"))
        fill_rounded(card, TH.card, radius=14,
                     border_color=(1, 1, 1, 0.05))

        # Header row (tap → category)
        header = BoxLayout(
            size_hint_y=None, height=64,
            padding=[14, 8], spacing=10)

        # Accent square with icon/letter
        accent = BoxLayout(
            size_hint=(None, None), size=(44, 44),
            pos_hint={"center_y": 0.5})
        fill_rounded(accent, TH.primary, radius=12)
        icon_text = cat.get("icon", "") or cat["name"][:1].upper()
        accent.add_widget(Label(
            text=icon_text, font_size=20, bold=True,
            color=TH.gold_text,
            halign="center", valign="middle"))
        header.add_widget(accent)

        # Title col (tap = open category)
        title_col = Button(
            background_normal="", background_color=(0, 0, 0, 0),
            color=TH.text_main)
        title_col.cat_id = cat["id"]
        title_col.bind(on_press=self.go_category)

        # Stack vertically using a Label (tap-through over Button parent OK)
        title_wrap = BoxLayout(orientation="vertical")
        title_wrap.add_widget(Label(
            text=cat["name"], font_size=TH.fs_large, bold=True,
            color=TH.text_main,
            halign="left", valign="middle",
            size_hint_y=None, height=24,
            text_size=(220, None)))
        title_wrap.add_widget(Label(
            text=f"{len(cat['recipes'])} recipes",
            font_size=11, color=TH.grey,
            halign="left", valign="middle",
            size_hint_y=None, height=18,
            text_size=(220, None)))
        # Overlay button under title: clickable area
        title_overlay = BoxLayout()
        title_overlay.add_widget(title_col)
        # Use button only for click; place title labels above as visual
        # Simpler: just put button as wrapper around BoxLayout vertical
        # We use a single tappable: cat_btn with full label list isn't ideal,
        # so we keep a transparent button below labels.
        title_stack = BoxLayout(orientation="vertical")
        title_stack.add_widget(title_wrap)
        # tap-target: dedicated button row
        header.add_widget(title_stack)

        # Chevron / open icon
        chev = icon_btn("",
                        on_press=lambda *_, cid=cat["id"]: self._open_cat(cid),
                        size=(36, 36), font=FA_FONT,
                        fg=TH.primary, bg=TH.bg,
                        font_size=12, radius=10)
        header.add_widget(chev)

        card.add_widget(header)

        # Whole-card tap area: invisible button overlay across header area
        tap_btn = Button(
            background_normal="", background_color=(0, 0, 0, 0),
            size_hint_y=None, height=1)  # tiny phantom; rely on chevron + recipe rows
        # Skip — we'll use chevron + recipe row taps for nav

        # Divider
        card.add_widget(divider())

        # Recipe rows
        recipes = filtered if (query and filtered) else cat["recipes"][:3]
        for r in recipes:
            card.add_widget(self._recipe_row(r, cat["id"]))

        # "View all" if more recipes
        more = len(cat["recipes"]) - 3
        if not query and more > 0:
            view = Button(
                text=f"View all {len(cat['recipes'])} recipes  >",
                font_size=TH.fs_small, bold=True,
                size_hint_y=None, height=40,
                background_normal="", background_color=(0, 0, 0, 0),
                color=TH.primary, halign="center", valign="middle")
            view.cat_id = cat["id"]
            view.bind(on_press=self.go_category)
            card.add_widget(view)

        # Admin actions
        if get_mode() == "Admin":
            card.add_widget(divider())
            actions = BoxLayout(size_hint_y=None, height=44, padding=[10, 6], spacing=8)
            edit_b = icon_btn("",
                              on_press=lambda *_, cid=cat["id"]: self._edit_cat_byid(cid),
                              size=(36, 32), font=FA_FONT,
                              fg=TH.primary, bg=TH.card2,
                              font_size=12, radius=10)
            del_b = icon_btn("",
                             on_press=lambda *_, cid=cat["id"]: self._del_cat_byid(cid),
                             size=(36, 32), font=FA_FONT,
                             fg=TH.red, bg=TH.card2,
                             font_size=12, radius=10)
            actions.add_widget(BoxLayout())  # left spacer
            actions.add_widget(edit_b)
            actions.add_widget(del_b)
            card.add_widget(actions)

        card.add_widget(spacer(6))
        return card

    def _recipe_row(self, recipe, cat_id):
        row = Button(
            background_normal="", background_color=(0, 0, 0, 0),
            size_hint_y=None, height=44,
            color=TH.text_main)
        row.cat_id = cat_id
        row.recipe_id = recipe["id"]
        row.bind(on_press=self.go_recipe_direct)

        # Render text via canvas-overlapping label inside button
        # Simpler: set button text directly with bullet
        is_fav = recipe.get("favorite", False)
        prefix = " * " if is_fav else "   "
        row.text = f"{prefix}{recipe['name']}"
        row.font_size = TH.fs_small
        row.halign = "left"
        row.valign = "middle"
        row.bind(width=lambda w, v: setattr(w, "text_size", (v - 24, None)))
        if is_fav:
            row.color = TH.fav
        return row

    def _open_cat(self, cat_id):
        self.manager.transition.direction = "left"
        self.manager.get_screen("category").load(cat_id)
        self.manager.current = "category"

    def _edit_cat_byid(self, cat_id):
        class _F:
            pass
        f = _F()
        f.cat_id = cat_id
        self.show_edit_category(f)

    def _del_cat_byid(self, cat_id):
        class _F:
            pass
        f = _F()
        f.cat_id = cat_id
        self.confirm_delete_category(f)

    def _build_fav_section(self, favs):
        head = BoxLayout(size_hint_y=None, height=36, padding=[2, 4])
        head.add_widget(Label(
            text="★  " + L["favorites"],
            font_size=TH.fs_small, bold=True,
            color=TH.fav, halign="left", valign="middle",
            text_size=(300, None)))
        self.list_layout.add_widget(head)

        card = BoxLayout(orientation="vertical",
                         size_hint_y=None, padding=0, spacing=0)
        card.bind(minimum_height=card.setter("height"))
        fill_rounded(card, TH.card, radius=14)
        for cat_id, recipe in favs:
            row = self._recipe_row(recipe, cat_id)
            row.height = 48
            card.add_widget(row)
            card.add_widget(divider())
        # Strip last divider
        if card.children and isinstance(card.children[0], BoxLayout):
            card.remove_widget(card.children[0])
        self.list_layout.add_widget(card)

    def on_search(self, instance, value):
        self.search_text = value
        self.favorites_only = False
        self._render_list(load_data())

    def go_category(self, btn):
        self.manager.transition.direction = "left"
        self.manager.get_screen("category").load(btn.cat_id)
        self.manager.current = "category"

    def go_recipe_direct(self, btn):
        if not hasattr(btn, "recipe_id") or not hasattr(btn, "cat_id"):
            return
        self.manager.transition.direction = "left"
        self.manager.get_screen("recipe").load(btn.cat_id, btn.recipe_id)
        self.manager.current = "recipe"

    # ── Category CRUD popups ────────────────────────────────────────
    def show_edit_category(self, btn):
        cat_id = btn.cat_id
        data = load_data()
        cat = next(c for c in data["categories"] if c["id"] == cat_id)

        content = BoxLayout(orientation="vertical", padding=20, spacing=10)
        set_bg(content, TH.bg)
        content.add_widget(make_label(L["cat_name"], color=TH.primary, height=22,
                                      bold=True, font_size=11))
        name_in = TextInput(
            text=cat["name"], multiline=False,
            size_hint_y=None, height=46,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.text_main,
            cursor_color=TH.primary,
            padding=[14, 14])
        content.add_widget(name_in)
        content.add_widget(make_label(L["cat_icon"], color=TH.primary, height=22,
                                      bold=True, font_size=11))
        icon_in = TextInput(
            text=cat["icon"], multiline=False,
            size_hint_y=None, height=46,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.text_main,
            cursor_color=TH.primary,
            padding=[14, 14])
        content.add_widget(icon_in)
        content.add_widget(spacer(6))

        btns = BoxLayout(size_hint_y=None, height=46, spacing=10)
        s = gold_btn(L["btn_save"], height=46)
        c = ghost_btn(L["btn_cancel"], height=46)
        btns.add_widget(s)
        btns.add_widget(c)
        content.add_widget(btns)

        popup = Popup(title=L["edit_cat_title"], content=content,
                      size_hint=(0.88, None), height=320,
                      background_color=TH.card,
                      separator_color=TH.primary)
        s.bind(on_press=lambda x: self._save_edit_cat(
            cat_id, name_in.text, icon_in.text, popup))
        c.bind(on_press=popup.dismiss)
        popup.open()

    def _save_edit_cat(self, cat_id, name, icon, popup):
        if not name.strip():
            return
        recipes_svc.update_category(cat_id, name, icon)
        popup.dismiss()
        self.build_ui()

    def confirm_delete_category(self, btn):
        cat_id = btn.cat_id
        content = BoxLayout(orientation="vertical", padding=20, spacing=12)
        set_bg(content, TH.bg)
        content.add_widget(Label(
            text="", font_size=32, font_name=FA_FONT,
            color=TH.red, size_hint_y=None, height=42,
            halign="center"))
        content.add_widget(make_label(
            "Delete this category?", color=TH.text_main,
            halign="center", height=28, bold=True,
            font_size=TH.fs_normal))
        content.add_widget(make_label(
            L["del_cat_msg"], color=TH.grey,
            halign="center", height=24, font_size=11))
        content.add_widget(spacer(6))

        btns = BoxLayout(size_hint_y=None, height=46, spacing=10)
        yes = styled_btn(L["btn_delete"], color=TH.red, height=46)
        no = ghost_btn(L["btn_cancel"], height=46)
        btns.add_widget(no)
        btns.add_widget(yes)
        content.add_widget(btns)

        popup = Popup(title=L["confirm"], content=content,
                      size_hint=(0.85, None), height=300,
                      background_color=TH.card,
                      separator_color=TH.red)
        yes.bind(on_press=lambda x: self._do_delete_cat(cat_id, popup))
        no.bind(on_press=popup.dismiss)
        popup.open()

    def _do_delete_cat(self, cat_id, popup):
        recipes_svc.delete_category(cat_id)
        popup.dismiss()
        self.build_ui()

    def show_add_category(self, *args):
        content = BoxLayout(orientation="vertical", padding=20, spacing=10)
        set_bg(content, TH.bg)
        content.add_widget(make_label(L["cat_name"], color=TH.primary, height=22,
                                      bold=True, font_size=11))
        name_in = TextInput(
            hint_text=L["cat_hint"], multiline=False,
            size_hint_y=None, height=46,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.text_main,
            cursor_color=TH.primary,
            padding=[14, 14])
        content.add_widget(name_in)
        content.add_widget(make_label(L["cat_icon"], color=TH.primary, height=22,
                                      bold=True, font_size=11))
        icon_in = TextInput(
            hint_text=L["icon_hint"], multiline=False,
            size_hint_y=None, height=46,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.text_main,
            cursor_color=TH.primary,
            padding=[14, 14])
        content.add_widget(icon_in)
        content.add_widget(spacer(6))

        btns = BoxLayout(size_hint_y=None, height=46, spacing=10)
        s = gold_btn(L["btn_save"], height=46)
        c = ghost_btn(L["btn_cancel"], height=46)
        btns.add_widget(s)
        btns.add_widget(c)
        content.add_widget(btns)

        popup = Popup(title=L["add_cat_title"], content=content,
                      size_hint=(0.88, None), height=320,
                      background_color=TH.card,
                      separator_color=TH.primary)
        s.bind(on_press=lambda x: self._save_cat(name_in.text, icon_in.text, popup))
        c.bind(on_press=popup.dismiss)
        popup.open()

    def _save_cat(self, name, icon, popup):
        if not name.strip():
            return
        try:
            recipes_svc.add_category(name, icon)
        except ValueError as e:
            print("add_category error:", e)
            return
        popup.dismiss()
        self.build_ui()