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
from theme import TH, load_theme, save_theme
from lang import L
from utils import (set_bg, gold_line, divider, make_label,
                   gold_btn, ghost_btn, styled_btn,
                   load_data, save_data, get_mode, set_mode, check_admin_pin)


class DrawerMenu(BoxLayout):
    def __init__(self, manager, close_cb, **kw):
        super().__init__(orientation="vertical", **kw)
        self.manager  = manager
        self.close_cb = close_cb

        # Background
        set_bg(self, TH.bg)

        # Top accent line
        self.add_widget(gold_line(3))

        # Header
        hdr = BoxLayout(size_hint_y=None, height=120, padding=[20, 20, 20, 10], spacing=15)
        set_bg(hdr, TH.bg)

        # Menu Icon
        CUR_DIR = os.path.dirname(os.path.abspath(__file__))
        FA_FONT = os.path.join(os.path.dirname(CUR_DIR), "assets", "fa-solid-900.ttf")
        
        menu_btn = Button(
            text="\uf0c9", font_size=24,
            font_name=FA_FONT,
            size_hint=(None, None), size=(44, 44),
            pos_hint={"center_y": 0.5},
            background_normal="", background_color=(0,0,0,0),
            color=TH.primary)
        menu_btn.bind(on_press=lambda x: self.close_cb())
        hdr.add_widget(menu_btn)

        title_col = BoxLayout(orientation="vertical",
                              pos_hint={"center_y": 0.5})
        title_col.add_widget(Label(
            text=L["app_title"], font_size=16, bold=True,
            color=TH.primary, halign="left",
            size_hint_y=None, height=28))
        title_col.add_widget(Label(
            text=L["app_subtitle"], font_size=10,
            color=TH.white40, halign="left",
            size_hint_y=None, height=18))
        hdr.add_widget(title_col)
        self.add_widget(hdr)
        self.add_widget(gold_line(1))
        self.add_widget(BoxLayout(size_hint_y=None, height=8))

        # Menu items with icons
        items = [
        ("\uf015", "Home",       "home"),
        ("\uf005", "Favorites",  "favorites"),
        ("\uf013", "Settings",   "settings"),
        ("\uf023", "Lock",       "lock"),
        ("\uf084", "Admin Mode", "admin"),
        ("\uf129", "About",      "about"),
        ]
        
        # Correct Font Path
        CUR_DIR = os.path.dirname(os.path.abspath(__file__))
        FA_FONT = os.path.join(os.path.dirname(CUR_DIR), "assets", "fa-solid-900.ttf")
        
        for icon, label, key in items:
            row = BoxLayout(
                size_hint_y=None, height=52,
                padding=[16, 4], spacing=12)
     
            icon_lbl = Label(
                text=icon, font_size=18,
                font_name=FA_FONT,
                size_hint=(None, None), size=(32, 44),
                halign="center", valign="middle",
                color=TH.primary)
            row.add_widget(icon_lbl)

            btn = Button(
                    text=label,
                    font_size=TH.fs_normal, bold=False,
                    size_hint_y=None, height=44,
                    background_normal="", background_color=(0,0,0,0),
                    color=TH.white, halign="left")
            btn.nav_key = key
            btn.bind(on_press=self._on_item)
            row.add_widget(btn)
            self.add_widget(row)
            self.add_widget(divider())

        self.add_widget(BoxLayout())

        # Version info
        self.add_widget(make_label(
            "v2.0  ·  Tea SOP",
            font_size=10, color=TH.grey,
            halign="center", height=24))
        self.add_widget(BoxLayout(size_hint_y=None, height=8))

        # Close button
        close_btn = ghost_btn(L["btn_close"], height=48)
        close_btn.bind(on_press=lambda x: self.close_cb())
        self.add_widget(close_btn)
        self.add_widget(BoxLayout(size_hint_y=None, height=16))

    def _redraw_logo(self, w):
        from kivy.graphics import RoundedRectangle
        w.canvas.before.clear()
        with w.canvas.before:
            Color(*TH.primary)
            RoundedRectangle(pos=w.pos, size=w.size, radius=[12])

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

        elif key == "export":
            self._do_export()

        elif key == "import":
            self._do_import()
            
        elif key == "admin":
            self._show_admin_pin_popup()
        elif key == "about":
            self._show_about()
            
    def _do_export(self):
        import json, os
        from utils import load_data
        from kivy.uix.popup import Popup
        data = load_data()
        export_path = os.path.join(
            os.path.expanduser("~"), "Desktop", "tea_sop_export.json")
        try:
            with open(export_path, "w", encoding="utf-8") as f:
                json.dump(data, f, ensure_ascii=False, indent=2)
            msg = f"Exported to:\n{export_path}"
        except Exception as e:
            msg = f"Export failed:\n{e}"

        content = BoxLayout(orientation="vertical", padding=16, spacing=10)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        content.add_widget(Label(
            text=msg, font_size=TH.fs_small,
            color=TH.white, halign="center",
            text_size=(300, None), size_hint_y=None, height=80))
        ok = gold_btn("OK", height=44)
        content.add_widget(ok)
        popup = Popup(title="Export", content=content,
                      size_hint=(0.88, 0.40),
                      background_color=TH.card,
                      separator_height=0)
        ok.bind(on_press=popup.dismiss)
        popup.open()

    def _do_import(self):
        import json, os
        from utils import save_data
        from kivy.uix.popup import Popup
        import_path = os.path.join(
            os.path.expanduser("~"), "Desktop", "tea_sop_export.json")
        try:
            with open(import_path, "r", encoding="utf-8") as f:
                data = json.load(f)
            save_data(data)
            msg = "Import successful!\nRestart or go Home to refresh."
        except FileNotFoundError:
            msg = "File not found:\ntea_sop_export.json on Desktop"
        except Exception as e:
            msg = f"Import failed:\n{e}"

        content = BoxLayout(orientation="vertical", padding=16, spacing=10)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        content.add_widget(Label(
            text=msg, font_size=TH.fs_small,
            color=TH.white, halign="center",
            text_size=(300, None), size_hint_y=None, height=80))
        ok = gold_btn("OK", height=44)
        content.add_widget(ok)
        popup = Popup(title="Import", content=content,
                      size_hint=(0.88, 0.40),
                      background_color=TH.card,
                      separator_height=0)
        ok.bind(on_press=popup.dismiss)
        popup.open()
        
    def _show_admin_pin_popup(self):
        from kivy.uix.popup import Popup
        from kivy.uix.textinput import TextInput
        content = BoxLayout(orientation="vertical", padding=16, spacing=10)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        content.add_widget(BoxLayout(size_hint_y=None, height=6))
        content.add_widget(make_label(
            "Enter Admin PIN", color=TH.primary,
            halign="center", height=32))
        pin_in = TextInput(
            hint_text="****", password=True,
            multiline=False, size_hint_y=None, height=44,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.text_main,
            cursor_color=TH.primary)
        content.add_widget(pin_in)
        error_lbl = make_label(
            "", color=TH.red, halign="center", height=28)
        content.add_widget(error_lbl)
        btns = BoxLayout(size_hint_y=None, height=44, spacing=8)
        ok = gold_btn("OK", height=44)
        cancel = ghost_btn("Cancel", height=44)
        btns.add_widget(ok)
        btns.add_widget(cancel)
        content.add_widget(btns)
        popup = Popup(title="Admin Login", content=content,
                      size_hint=(0.85, 0.45),
                      background_color=TH.card)
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
        from kivy.uix.popup import Popup
        content = BoxLayout(orientation="vertical", padding=16, spacing=10)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        content.add_widget(BoxLayout(size_hint_y=None, height=8))
        content.add_widget(Label(
            text="Tea SOP", font_size=22, bold=True,
            color=TH.primary, halign="center",
            size_hint_y=None, height=36))
        content.add_widget(Label(
            text="Version 2.0\nQuality Control Guide\n\nManage your tea recipes\nwith ease.",
            font_size=TH.fs_small, color=TH.white70,
            halign="center", text_size=(300, None),
            size_hint_y=None, height=90))
        ok = gold_btn("OK", height=44)
        content.add_widget(ok)
        popup = Popup(title="About", content=content,
                      size_hint=(0.88, 0.52),
                      background_color=TH.card,
                      separator_height=0)
        ok.bind(on_press=popup.dismiss)
        popup.open()

class HomeScreen(Screen):
    def __init__(self, **kw):
        super().__init__(**kw)
        self.search_text   = ""
        self.nav_mode      = "home"   # "home" | "favorites" | "search"
        self.favorites_only = False

    def on_enter(self):
        self.favorites_only = (self.nav_mode == "favorites")
        self.build_ui()

        if self.nav_mode == "search":
            if hasattr(self, 'search_input'):
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
        # ── Header ──────────────────────────────────────────────────────────
        header = BoxLayout(size_hint_y=None, height=48, padding=[12,6])
        set_bg(header, TH.header_bg)

        menu_btn = Button(
            text="MENU", font_size=10, bold=True,
            size_hint=(None,None), size=(48,36),
            background_normal="", background_color=(0,0,0,0),
            color=TH.primary)
        def draw_menu_btn(w, *a):
            w.canvas.before.clear()
            with w.canvas.before:
                Color(*TH.card)
                RoundedRectangle(pos=w.pos, size=w.size, radius=[6])
                Color(*TH.primary)
                Line(rounded_rectangle=(w.x,w.y,w.width,w.height,6), width=1.0)
        menu_btn.bind(pos=draw_menu_btn, size=draw_menu_btn)
        menu_btn.bind(on_press=lambda x: self.open_drawer())
        header.add_widget(menu_btn)

        header.add_widget(Label(
            text=L["app_title"], font_size=15, bold=True,
            color=TH.primary, halign="center"))

        # Dark / Light mode toggle button
        t = load_theme()
        mode_icon = "LIGHT" if t["mode"] == "Dark" else "DARK"
        mode_btn = Button(
            text=mode_icon, font_size=9, bold=True,
            size_hint=(None,None), size=(48,36),
            background_normal="", background_color=(0,0,0,0),
            color=TH.grey)
        def draw_mode_btn(w, *a):
            w.canvas.before.clear()
            with w.canvas.before:
                Color(*TH.card)
                RoundedRectangle(pos=w.pos, size=w.size, radius=[6])
        mode_btn.bind(pos=draw_mode_btn, size=draw_mode_btn)
        mode_btn.bind(on_press=lambda x: self._toggle_mode())
        header.add_widget(mode_btn)

        root.add_widget(header)
        root.add_widget(gold_line(1))

        # ── Search Bar ──────────────────────────────────────────────────────
        search_row = BoxLayout(size_hint_y=None, height=52, padding=[12, 8])
        set_bg(search_row, TH.bg)
        self.search_input = TextInput(
            hint_text=L["search_hint"],
            multiline=False, size_hint_y=None, height=40,
            font_size=TH.fs_normal,
            foreground_color=TH.text_main,
            background_color=TH.card,
            background_normal="", # Fix: Remove default white background
            cursor_color=TH.primary,
            hint_text_color=TH.grey,
            padding=[16, 10])
        self.search_input.bind(text=self.on_search)
        search_row.add_widget(self.search_input)
        root.add_widget(search_row)
        root.add_widget(divider())

        # ── List ────────────────────────────────────────────────────────────
        self.scroll_view = ScrollView()
        self.list_layout = BoxLayout(
            orientation="vertical", spacing=10,
            padding=[12,12], size_hint_y=None)
        self.list_layout.bind(minimum_height=self.list_layout.setter("height"))
        self._render_list(data)
        self.scroll_view.add_widget(self.list_layout)
        root.add_widget(self.scroll_view)

        # ── Bottom Nav ──────────────────────────────────────────────────────
        self.add_widget(root)

    # ── Dark / Light toggle ─────────────────────────────────────────────────
    def _toggle_mode(self):
        import theme as theme_mod
        t = theme_mod.load_theme()
        new_mode = "Light" if t["mode"] == "Dark" else "Dark"
        t["mode"] = new_mode
        if new_mode == "Dark":
            t["bg"]   = "#0A0A0A"
            t["card"] = "#141414"
        else:
            t["bg"]   = "#F5F5F5"
            t["card"] = "#E8E8E8"
        theme_mod.save_theme(t)
        theme_mod.TH.reload()
        self.build_ui()
    def open_drawer(self):
        content = DrawerMenu(
            manager=self.manager,
            close_cb=lambda: popup.dismiss(),
            size_hint=(1,1))
        popup = Popup(
            title="", content=content,
            size_hint=(0.72,1.0), pos_hint={"x":0},
            background_color=(0,0,0,0), separator_height=0)
        popup.open()

    def _render_list(self, data):
        self.list_layout.clear_widgets()
        
        # Reset scroll to top
        if hasattr(self, 'scroll_view'):
            self.scroll_view.scroll_y = 1
            
        query = self.search_text.lower().strip()

        # Favorites-only mode: show only the favorites card
        if self.favorites_only and not query:
            favs = [(c["id"], r) for c in data["categories"]
                    for r in c["recipes"] if r.get("favorite")]
            if not favs:
                self.list_layout.add_widget(make_label(
                    L.get("no_favorites", "No favorites yet."),
                    color=TH.grey, halign="center", height=60))
            else:
                self._build_fav_card(favs)
            return

        matched = []
        for cat in data["categories"]:
            matched_r = [r for r in cat["recipes"]
                         if query in r["name"].lower()] if query else cat["recipes"]
            if query and not matched_r and query not in cat["name"].lower():
                continue
            matched.append((cat, matched_r if query else None))

        if not matched:
            self.list_layout.add_widget(BoxLayout(size_hint_y=None, height=20))
            self.list_layout.add_widget(make_label(
                L["no_results"], color=TH.grey,
                halign="center", height=40))
            self.list_layout.add_widget(make_label(
                "Tap '+ Add New Category' to get started.",
                color=TH.grey, halign="center",
                font_size=TH.fs_small, height=30))
            return

        for cat, filtered in matched:
            # Re-implementing the most stable layout pattern
            cat_card = BoxLayout(
                orientation="vertical",
                size_hint_y=None, 
                spacing=0, 
                padding=0)
            
            # Setup background drawing FIRST
            with cat_card.canvas.before:
                Color(*TH.card)
                cat_card._bg_rect = Rectangle(pos=cat_card.pos, size=cat_card.size)
                # Subtle dark divider at the bottom of the card
                Color(*TH.divider)
                cat_card._bg_line = Line(points=[cat_card.x, cat_card.y, cat_card.right, cat_card.y], width=1)

            def _update_cat_bg(w, *a):
                if hasattr(w, '_bg_rect'):
                    w._bg_rect.pos = w.pos
                    w._bg_rect.size = w.size
                if hasattr(w, '_bg_line'):
                    w._bg_line.points = [w.x, w.y, w.right, w.y]
            cat_card.bind(pos=_update_cat_bg, size=_update_cat_bg)
            
            # Now add children...
            accent_line = BoxLayout(size_hint_y=None, height=4)
            def draw_accent(w, *a):
                w.canvas.before.clear()
                with w.canvas.before:
                    Color(*TH.primary)
                    RoundedRectangle(pos=w.pos, size=w.size, radius=[10,10,0,0])
            accent_line.bind(pos=draw_accent, size=draw_accent)
            cat_card.add_widget(accent_line)

            # ... other children added below ...
            # After adding all children, bind the height
            # (Wait, the existing code adds them sequentially, so we'll just fix the cat_card init)

            card_header = BoxLayout(
                size_hint_y=None, height=58,
                padding=[14, 8], spacing=8)

            icon_text = cat.get("icon", "")
            display_text = f"{icon_text}  {cat['name']}" if icon_text else cat["name"]
            cat_btn = Button(
                text=display_text,
                font_size=TH.fs_large, bold=True,
                background_normal="", background_color=(0,0,0,0),
                color=TH.white, halign="left")
            cat_btn.cat_id = cat["id"]
            cat_btn.bind(on_press=self.go_category)
            card_header.add_widget(cat_btn)

            count_lbl = Label(
                text=f"{len(cat['recipes'])}",
                font_size=10, bold=True, color=TH.gold_text,
                size_hint=(None,None), size=(28,28))
            def draw_badge(w, *a):
                w.canvas.before.clear()
                with w.canvas.before:
                    Color(*TH.primary)
                    RoundedRectangle(pos=w.pos, size=w.size, radius=[14])
            count_lbl.bind(pos=draw_badge, size=draw_badge)
            card_header.add_widget(count_lbl)

            edit_btn = Button(
                text=L["btn_edit"], font_size=9, bold=True,
                size_hint=(None,None), size=(38,30),
                background_normal="", background_color=(0,0,0,0),
                color=TH.primary)
            def draw_edit(w, *a):
                w.canvas.before.clear()
                with w.canvas.before:
                    Color(*TH.card2)
                    RoundedRectangle(pos=w.pos, size=w.size, radius=[6])
                    Color(*TH.primary)
                    Line(rounded_rectangle=(w.x,w.y,w.width,w.height,6), width=0.9)
            edit_btn.bind(pos=draw_edit, size=draw_edit)
            edit_btn.cat_id = cat["id"]
            edit_btn.bind(on_press=self.show_edit_category)
            if get_mode() == "Admin":
                card_header.add_widget(edit_btn)

            del_btn = Button(
                text=L["btn_del"], font_size=9, bold=True,
                size_hint=(None,None), size=(38,30),
                background_normal="", background_color=(0,0,0,0),
                color=TH.red)
            def draw_del(w, *a):
                w.canvas.before.clear()
                with w.canvas.before:
                    Color(*TH.card2)
                    RoundedRectangle(pos=w.pos, size=w.size, radius=[6])
                    Color(*TH.red)
                    Line(rounded_rectangle=(w.x,w.y,w.width,w.height,6), width=0.9)
            del_btn.bind(pos=draw_del, size=draw_del)
            del_btn.cat_id = cat["id"]
            del_btn.bind(on_press=self.confirm_delete_category)
            if get_mode() == "Admin":
                card_header.add_widget(del_btn)
            cat_card.add_widget(card_header)
            cat_card.add_widget(divider())

            if query and filtered:
                for r in filtered:
                    rb = Button(
                        text=f"  {r['name']}",
                        font_size=TH.fs_small,
                        size_hint_y=None, height=36,
                        background_normal="", background_color=(0,0,0,0),
                        color=TH.white70, halign="left")
                    rb.recipe_id = r["id"]
                    rb.cat_id = cat["id"]
                    rb.bind(on_press=self.go_recipe_direct)
                    cat_card.add_widget(rb)
            else:
                for r in cat["recipes"][:3]:
                    rb = Button(
                        text=f"  · {r['name']}",
                        font_size=TH.fs_small,
                        size_hint_y=None, height=34,
                        background_normal="", background_color=(0,0,0,0),
                         color=TH.white70, halign="left")
                    rb.cat_id    = cat["id"]
                    rb.recipe_id = r["id"]
                    rb.bind(on_press=self.go_recipe_direct)
                    cat_card.add_widget(rb)
                if len(cat["recipes"]) > 3:
                    cat_card.add_widget(Label(
                        text=f"  + {len(cat['recipes'])-3} more ...",
                        font_size=TH.fs_small, color=TH.grey,
                        size_hint_y=None, height=28,
                        halign="left", text_size=(360,None)))

            view_btn = Button(
                text=f"View All ›",
                font_size=TH.fs_small, bold=True,
                size_hint_y=None, height=36,
                background_normal="", background_color=(0,0,0,0),
                color=TH.primary, halign="right")
            view_btn.cat_id = cat["id"]
            view_btn.bind(on_press=self.go_category)
            cat_card.add_widget(view_btn)
            cat_card.add_widget(BoxLayout(size_hint_y=None, height=6))
            
            # Crucial: Bind height AFTER adding all children to ensure correct minimum_height calculation
            cat_card.bind(minimum_height=cat_card.setter("height"))
            
            self.list_layout.add_widget(cat_card)

        # Favorites section
        favs = [(c["id"],r) for c in data["categories"]
                for r in c["recipes"] if r.get("favorite")]
        if favs and not query:
            self._build_fav_card(favs)

        self.list_layout.add_widget(BoxLayout(size_hint_y=None, height=6))
        if get_mode() == "Admin":
            add_btn = gold_btn(L["add_category"], height=48)
            add_btn.bind(on_press=self.show_add_category)
            self.list_layout.add_widget(add_btn)

    def _build_fav_card(self, favs):
        fav_card = BoxLayout(
            orientation="vertical",
            size_hint_y=None, spacing=0, padding=0)
        fav_card.bind(minimum_height=fav_card.setter("height")) 

        def draw_fav_card(w, *a):
            w.canvas.before.clear()
            with w.canvas.before:
                Color(*TH.card)
                RoundedRectangle(pos=w.pos, size=w.size, radius=[10])
        fav_card.bind(pos=draw_fav_card, size=draw_fav_card)

        fav_accent = BoxLayout(size_hint_y=None, height=3)
        def draw_fav_acc(w, *a):
            w.canvas.before.clear()
            with w.canvas.before:
                Color(*TH.fav)
                RoundedRectangle(pos=w.pos, size=w.size, radius=[10,10,0,0])
        fav_accent.bind(pos=draw_fav_acc, size=draw_fav_acc)
        fav_card.add_widget(fav_accent)

        fav_hdr = BoxLayout(size_hint_y=None, height=44, padding=[12,6])
        fav_hdr.add_widget(Label(
            text=L["favorites"], font_size=TH.fs_normal,
            bold=True, color=TH.fav, halign="left"))
        fav_card.add_widget(fav_hdr)
        fav_card.add_widget(divider())

        for cat_id, recipe in favs:
            fb = Button(
                text=f"  {recipe['name']}",
                font_size=TH.fs_small,
                size_hint_y=None, height=34,
                background_normal="", background_color=(0,0,0,0),
                color=(1,1,1,0.7), halign="left")
            fb.recipe_id = recipe["id"]
            fb.cat_id = cat_id
            fb.bind(on_press=self.go_recipe_direct)
            fav_card.add_widget(fb)
        fav_card.add_widget(BoxLayout(size_hint_y=None, height=8))
        self.list_layout.add_widget(fav_card)

    def on_search(self, instance, value):
        self.search_text   = value
        self.favorites_only = False
        self._render_list(load_data())

    def go_category(self, btn):
        self.manager.transition.direction = "left"
        self.manager.get_screen("category").load(btn.cat_id)
        self.manager.current = "category"

    def go_recipe_direct(self, btn):
        if not hasattr(btn, 'recipe_id') or not hasattr(btn, 'cat_id'):
            return
        self.manager.transition.direction = "left"
        self.manager.get_screen("recipe").load(btn.cat_id, btn.recipe_id)
        self.manager.current = "recipe"

    def show_edit_category(self, btn):
        cat_id = btn.cat_id
        data   = load_data()
        cat    = next(c for c in data["categories"] if c["id"]==cat_id)
        
        # UI Fix: Adjust padding and use auto-wrapping labels
        content = BoxLayout(orientation="vertical", padding=[20, 16, 20, 16], spacing=10)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        
        # Label with halign left to ensure it stays inside the box
        content.add_widget(make_label(L["cat_name"], color=TH.primary, height=28, halign="left"))
        
        name_in = TextInput(text=cat["name"], multiline=False,
                            size_hint_y=None, height=44,
                            font_size=TH.fs_normal,
                            background_color=TH.input_bg,
                            foreground_color=TH.text_main,
                            cursor_color=TH.primary)
        content.add_widget(name_in)
        
        content.add_widget(make_label(L["cat_icon"], color=TH.primary, height=28, halign="left"))
        
        icon_in = TextInput(text=cat["icon"], multiline=False,
                            size_hint_y=None, height=44,
                            font_size=TH.fs_normal,
                            background_color=TH.input_bg,
                            foreground_color=TH.text_main,
                            cursor_color=TH.primary)
        content.add_widget(icon_in)
        
        btns = BoxLayout(size_hint_y=None, height=44, spacing=12)
        s = gold_btn(L["btn_save"], height=44)
        c = ghost_btn(L["btn_cancel"], height=44)
        btns.add_widget(s); btns.add_widget(c)
        content.add_widget(btns)
        
        popup = Popup(title=L["edit_cat_title"], content=content,
                      size_hint=(0.85, None), height=320, # Fixed height for better control
                      background_color=TH.card)
        s.bind(on_press=lambda x: self._save_edit_cat(
            cat_id, name_in.text, icon_in.text, popup))
        c.bind(on_press=popup.dismiss)
        popup.open()

    def _save_edit_cat(self, cat_id, name, icon, popup):
        if not name.strip(): return
        data = load_data()
        cat  = next(c for c in data["categories"] if c["id"]==cat_id)
        cat["name"] = name.strip()
        cat["icon"] = icon.strip() or ""
        save_data(data); popup.dismiss(); self.build_ui()

    def confirm_delete_category(self, btn):
        cat_id  = btn.cat_id
        content = BoxLayout(orientation="vertical", padding=16, spacing=12)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        content.add_widget(BoxLayout(size_hint_y=None, height=8))
        content.add_widget(make_label(L["del_cat_msg"], color=TH.white,
                                      halign="center", height=36))
        btns = BoxLayout(size_hint_y=None, height=44, spacing=8)
        yes = styled_btn(L["btn_delete"], color=TH.red, height=44)
        no  = ghost_btn(L["btn_cancel"], height=44)
        btns.add_widget(yes); btns.add_widget(no)
        content.add_widget(btns)
        popup = Popup(title=L["confirm"], content=content,
                      size_hint=(0.82,0.30), background_color=TH.card)
        yes.bind(on_press=lambda x: self._do_delete_cat(cat_id, popup))
        no.bind(on_press=popup.dismiss)
        popup.open()

    def _do_delete_cat(self, cat_id, popup):
        data = load_data()
        data["categories"] = [c for c in data["categories"] if c["id"]!=cat_id]
        save_data(data); popup.dismiss(); self.build_ui()

    def show_add_category(self, *args):
        # UI Fix: Adjust padding and use auto-wrapping labels
        content = BoxLayout(orientation="vertical", padding=[20, 16, 20, 16], spacing=10)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        
        # Label with halign left to ensure it stays inside the box
        content.add_widget(make_label(L["cat_name"], color=TH.primary, height=28, halign="left"))
        
        name_in = TextInput(hint_text=L["cat_hint"], multiline=False,
                            size_hint_y=None, height=44,
                            font_size=TH.fs_normal,
                            background_color=TH.input_bg,
                            foreground_color=TH.text_main,
                            cursor_color=TH.primary)
        content.add_widget(name_in)
        
        content.add_widget(make_label(L["cat_icon"], color=TH.primary, height=28, halign="left"))
        
        icon_in = TextInput(hint_text=L["icon_hint"], multiline=False,
                            size_hint_y=None, height=44,
                            font_size=TH.fs_normal,
                            background_color=TH.input_bg,
                            foreground_color=TH.text_main,
                            cursor_color=TH.primary)
        content.add_widget(icon_in)
        
        btns = BoxLayout(size_hint_y=None, height=44, spacing=12)
        s = gold_btn(L["btn_save"], height=44)
        c = ghost_btn(L["btn_cancel"], height=44)
        btns.add_widget(s); btns.add_widget(c)
        content.add_widget(btns)
        
        popup = Popup(title=L["add_cat_title"], content=content,
                      size_hint=(0.85, None), height=320, # Fixed height for better control
                      background_color=TH.card)
        s.bind(on_press=lambda x: self._save_cat(
            name_in.text, icon_in.text, popup))
        c.bind(on_press=popup.dismiss)
        popup.open()

    def _save_cat(self, name, icon, popup):
        if not name.strip(): return
        data = load_data()
        data["categories"].append({
            "id":      name.strip().lower().replace(" ","_"),
            "name":    name.strip(),
            "icon":    icon.strip() or "",
            "recipes": []
        })
        save_data(data); popup.dismiss(); self.build_ui()