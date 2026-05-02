import os
from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup
from kivy.graphics import Color, Rectangle, RoundedRectangle, Line
from theme import TH
from lang import L
from utils import (set_bg, gold_line, divider, make_label,
                   ghost_btn, card_box, load_data, save_data, get_mode)

class RecipeScreen(Screen):
    def __init__(self, **kw):
        super().__init__(**kw)
        self.active_tab    = "Hot"
        self.serving_count = 1
        self.edit_mode     = False

    def load(self, cat_id, recipe_id):
        self.cat_id        = cat_id
        self.recipe_id     = recipe_id
        self.serving_count = 1
        self.active_tab    = "Hot"
        self.edit_mode     = False
        self._build(cat_id, recipe_id)

    def _build(self, cat_id, recipe_id):
        self.clear_widgets()
        data   = load_data()
        cat    = next(c for c in data["categories"] if c["id"] == cat_id)
        recipe = next(r for r in cat["recipes"]     if r["id"] == recipe_id)

        root = BoxLayout(orientation="vertical")
        set_bg(root, TH.bg)
        root.add_widget(gold_line(2))
        
        # ── Recipe Image ────────────────────────────────────────────────────
        if recipe.get("image") and os.path.exists(recipe["image"]):
            from kivy.uix.image import Image as KivyImage
            img_box = BoxLayout(size_hint_y=None, height=200)
            img_widget = KivyImage(
                source=recipe["image"],
                fit_mode="contain")
            img_box.add_widget(img_widget)
            root.add_widget(img_box)
            root.add_widget(gold_line(1))

        # ── Header ──────────────────────────────────────────────────────────
        header = BoxLayout(size_hint_y=None, height=60, padding=[12, 8])
        set_bg(header, TH.header_bg)
        back = ghost_btn(L["btn_back"], height=44)
        back.size_hint_x = None
        back.width = 80
        def go_back(*a):
            self.edit_mode = False
            if self.manager:
                self.manager.transition.direction = "right"
                self.manager.current = "category"
        back.bind(on_press=go_back)
        header.add_widget(back)
        header.add_widget(make_label(
            recipe["name"], font_size=TH.fs_large,
            color=TH.primary, bold=True,
            halign="center", height=44))

        # EDIT / SAVE button
        if not self.edit_mode:
            action_btn = Button(
                text="EDIT", font_size=10, bold=True,
                size_hint=(None, None), size=(54, 36),
                background_normal="",
                background_color=(0, 0, 0, 0),
                color=TH.primary)
            def draw_edit_btn(w, *a):
                w.canvas.before.clear()
                with w.canvas.before:
                    Color(*TH.primary)
                    Line(rectangle=(w.x, w.y, w.width, w.height), width=0.8)
            action_btn.bind(pos=draw_edit_btn, size=draw_edit_btn)
            action_btn.bind(on_press=lambda x: self._enter_edit())
        else:
            action_btn = Button(
                text="SAVE", font_size=10, bold=True,
                size_hint=(None, None), size=(54, 36),
                background_normal="",
                background_color=TH.primary,
                color=TH.gold_text)
            action_btn.bind(on_press=lambda x: self._save_edits(recipe))

        if get_mode() == "Admin":
            header.add_widget(action_btn)
        root.add_widget(header)
        root.add_widget(gold_line(1))

        # ── Serving bar (view mode) / Hint bar (edit mode) ───────────────────
        if not self.edit_mode:
            calc_bar = BoxLayout(size_hint_y=None, height=48,
                                 padding=[12, 6], spacing=8)
            set_bg(calc_bar, TH.header_bg)
            calc_bar.add_widget(Label(
                text="Serving:", font_size=TH.fs_small, color=TH.grey,
                size_hint=(None, None), size=(70, 36)))
            minus_btn = Button(
                text="-", font_size=20, bold=True,
                size_hint=(None, None), size=(36, 36),
                background_normal="", background_color=TH.card,
                color=TH.primary)
            self.serving_lbl = Label(
                text=str(self.serving_count), font_size=16, bold=True,
                color=TH.primary, size_hint=(None, None), size=(44, 36))
            plus_btn = Button(
                text="+", font_size=20, bold=True,
                size_hint=(None, None), size=(36, 36),
                background_normal="", background_color=TH.primary,
                color=(0, 0, 0, 1))
            calc_bar.add_widget(minus_btn)
            calc_bar.add_widget(self.serving_lbl)
            calc_bar.add_widget(plus_btn)
            calc_bar.add_widget(BoxLayout())
            reset_btn = ghost_btn("Reset", height=36)
            reset_btn.font_size = TH.fs_small
            reset_btn.size_hint_x = None
            reset_btn.width = 56
            calc_bar.add_widget(reset_btn)
            root.add_widget(calc_bar)
            root.add_widget(divider())

            def update_serving(delta):
                self.serving_count = max(1, min(99, self.serving_count + delta))
                self.serving_lbl.text = str(self.serving_count)
                self._render_content(recipe)
            minus_btn.bind(on_press=lambda x: update_serving(-1))
            plus_btn.bind(on_press=lambda x: update_serving(1))
            reset_btn.bind(on_press=lambda x: update_serving(1 - self.serving_count))
        else:
            hint = BoxLayout(size_hint_y=None, height=34, padding=[12, 4])
            set_bg(hint, TH.header_bg)
            hint.add_widget(Label(
                text="Edit values below, then tap SAVE",
                font_size=TH.fs_small, color=TH.primary,
                halign="center"))
            root.add_widget(hint)
            root.add_widget(divider())

        # ── Scrollable content ───────────────────────────────────────────────
        scroll = ScrollView()
        self.content_layout = BoxLayout(
            orientation="vertical", spacing=12,
            padding=[12, 12], size_hint_y=None)
        self.content_layout.bind(
            minimum_height=self.content_layout.setter("height"))

        if self.edit_mode:
            self._render_edit(recipe)
        else:
            self._render_content(recipe)

        scroll.add_widget(self.content_layout)
        root.add_widget(scroll)      
        self.add_widget(root)

    # ── Edit mode ────────────────────────────────────────────────────────────
    def _enter_edit(self):
        self.edit_mode = True
        self._build(self.cat_id, self.recipe_id)

    def _cancel_edit(self):
        self.edit_mode = False
        self._build(self.cat_id, self.recipe_id)

    def _render_edit(self, recipe):
        self._edit_widgets = {}

        # Parameters
        if "parameters" in recipe:
            self.content_layout.add_widget(make_label(
                "PARAMETERS  (name  |  amount  |  unit)",
                font_size=TH.fs_small, color=TH.primary,
                bold=True, height=28))
            self.content_layout.add_widget(divider())

            self._edit_widgets["parameters"] = []
            for p in recipe["parameters"]:
                row = BoxLayout(size_hint_y=None, height=48,
                                spacing=6, padding=[2, 4])

                name_in = TextInput(
                    text=p["name"], multiline=False,
                    font_size=TH.fs_small,
                    background_color=TH.input_bg,
                    foreground_color=TH.text_main,
                    cursor_color=TH.primary,
                    size_hint_x=0.44,
                    size_hint_y=None, height=40)

                amt_str = (str(int(p["amount"]))
                           if p["amount"] == int(p["amount"])
                           else str(p["amount"]))
                amt_in = TextInput(
                    text=amt_str, multiline=False,
                    font_size=TH.fs_normal,
                    background_color=TH.input_bg,
                    foreground_color=TH.primary,
                    cursor_color=TH.primary,
                    size_hint_x=0.26,
                    size_hint_y=None, height=40)

                unit_in = TextInput(
                    text=p["unit"], multiline=False,
                    font_size=TH.fs_small,
                    background_color=TH.input_bg,
                    foreground_color=TH.text_main,
                    cursor_color=TH.primary,
                    size_hint_x=0.30,
                    size_hint_y=None, height=40)

                row.add_widget(name_in)
                row.add_widget(amt_in)
                row.add_widget(unit_in)
                self.content_layout.add_widget(row)
                self.content_layout.add_widget(divider())
                self._edit_widgets["parameters"].append(
                    (name_in, amt_in, unit_in))

        # Steps
        if "steps" in recipe:
            self.content_layout.add_widget(
                BoxLayout(size_hint_y=None, height=8))
            self.content_layout.add_widget(make_label(
                "STEPS", font_size=TH.fs_small,
                color=TH.primary, bold=True, height=28))
            self.content_layout.add_widget(divider())

            self._edit_widgets["steps"] = []
            for i, step in enumerate(recipe["steps"], 1):
                row = BoxLayout(
                    size_hint_y=None, height=72,
                    spacing=8, padding=[2, 4])

                num_lbl = Label(
                    text=str(i), font_size=12, bold=True,
                    color=TH.gold_text,
                    size_hint=(None, None), size=(28, 40))
                with num_lbl.canvas.before:
                    Color(*TH.primary)
                    RoundedRectangle(pos=num_lbl.pos,
                                     size=num_lbl.size, radius=[14])
                num_lbl.bind(
                    pos=lambda w, v: self._redraw_circle(w),
                    size=lambda w, v: self._redraw_circle(w))

                step_in = TextInput(
                    text=step, multiline=True,
                    font_size=TH.fs_small,
                    background_color=TH.input_bg,
                    foreground_color=TH.text_main,
                    cursor_color=TH.primary,
                    size_hint_y=None, height=64)

                row.add_widget(num_lbl)
                row.add_widget(step_in)
                self.content_layout.add_widget(row)
                self._edit_widgets["steps"].append(step_in)

        # Cancel button
        self.content_layout.add_widget(
            BoxLayout(size_hint_y=None, height=12))
        cancel_btn = ghost_btn("Cancel", height=44)
        cancel_btn.bind(on_press=lambda x: self._cancel_edit())
        self.content_layout.add_widget(cancel_btn)

    def _save_edits(self, recipe):
        data = load_data()
        cat  = next(c for c in data["categories"]
                    if c["id"] == self.cat_id)
        r    = next(rc for rc in cat["recipes"]
                    if rc["id"] == self.recipe_id)

        # Save parameters
        if "parameters" in r and "parameters" in self._edit_widgets:
            for idx, (name_in, amt_in, unit_in) in \
                    enumerate(self._edit_widgets["parameters"]):
                name = name_in.text.strip()
                unit = unit_in.text.strip()
                try:
                    amt = float(amt_in.text.strip())
                except ValueError:
                    amt = r["parameters"][idx]["amount"]
                if name:
                    r["parameters"][idx]["name"]   = name
                    r["parameters"][idx]["amount"] = amt
                    r["parameters"][idx]["unit"]   = unit

        # Save steps
        if "steps" in r and "steps" in self._edit_widgets:
            new_steps = [s.text.strip()
                         for s in self._edit_widgets["steps"]
                         if s.text.strip()]
            if new_steps:
                r["steps"] = new_steps

        save_data(data)

        # Success popup
        content = BoxLayout(orientation="vertical", padding=16, spacing=10)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        content.add_widget(BoxLayout(size_hint_y=None, height=8))
        content.add_widget(make_label(
            "Saved successfully!",
            color=TH.text_main, halign="center",
            font_size=TH.fs_normal, height=44))
        ok = gold_btn("OK", height=44)
        content.add_widget(ok)
        popup = Popup(title="", content=content,
                      size_hint=(0.72, 0.28),
                      background_color=TH.card,
                      separator_height=0)
        def _ok(*a):
            popup.dismiss()
            self.edit_mode = False
            self._build(self.cat_id, self.recipe_id)
        ok.bind(on_press=_ok)
        popup.open()

    # ── View mode renders ────────────────────────────────────────────────────
    def _render_content(self, recipe):
        self.content_layout.clear_widgets()
        m = self.serving_count
        if "parameters" in recipe:
            self._render_parameters(recipe["parameters"], m)
        if "steps" in recipe:
            self._render_steps(recipe["steps"])
        if "variants" in recipe:
            self._render_variants_tab(recipe["variants"], m)
        self.content_layout.add_widget(
            BoxLayout(size_hint_y=None, height=12))
        self.content_layout.add_widget(make_label(
            L["measure_note"], font_size=TH.fs_small,
            color=TH.grey, halign="center", height=28))
        self.content_layout.add_widget(
            BoxLayout(size_hint_y=None, height=12))

    def _render_parameters(self, parameters, m):
        self.content_layout.add_widget(make_label(
            L["parameters"], font_size=TH.fs_small,
            color=TH.grey, bold=True, height=24))
        card = BoxLayout(orientation="vertical",
                         size_hint_y=None, spacing=0, padding=0)
        card.bind(minimum_height=card.setter("height"))
        top = BoxLayout(size_hint_y=None, height=1)
        with top.canvas.before:
            Color(*TH.primary)
            Rectangle(pos=top.pos, size=top.size)
        card.add_widget(top)
        for idx, p in enumerate(parameters):
            amt     = p["amount"] * m
            amt_str = str(int(amt)) if amt == int(amt) else f"{amt:.1f}"
            row = BoxLayout(size_hint_y=None, height=40, padding=[12, 4])
            if idx % 2 == 0:
                with row.canvas.before:
                    Color(1, 1, 1, 0.04)
                    Rectangle(pos=row.pos, size=row.size)
            row.add_widget(Label(
                text=p["name"], font_size=TH.fs_normal,
                color=TH.text_main, halign="left",
                text_size=(200, None)))
            row.add_widget(Label(
                text=amt_str, font_size=16, bold=True,
                color=TH.primary, halign="center",
                text_size=(80, None)))
            row.add_widget(Label(
                text=p["unit"], font_size=TH.fs_small,
                color=TH.grey, halign="right",
                text_size=(60, None)))
            card.add_widget(row)
            if idx < len(parameters) - 1:
                card.add_widget(divider())
        self.content_layout.add_widget(card)

    def _render_steps(self, steps):
        self.content_layout.add_widget(make_label(
            L["steps"], font_size=TH.fs_small,
            color=TH.grey, bold=True, height=24))
        for i, step in enumerate(steps, 1):
            step_row = BoxLayout(
                orientation="horizontal",
                size_hint_y=None, spacing=8, padding=[4, 4])
            step_row.bind(minimum_height=step_row.setter("height"))
            circle = Label(
                text=str(i), font_size=12, bold=True,
                color=(0, 0, 0, 1),
                size_hint=(None, None), size=(28, 28))
            with circle.canvas.before:
                Color(*TH.primary)
                RoundedRectangle(pos=circle.pos, size=circle.size,
                                 radius=[14])
            circle.bind(
                pos=lambda w, v: self._redraw_circle(w),
                size=lambda w, v: self._redraw_circle(w))
            step_row.add_widget(circle)
            txt = Label(
                text=step, font_size=TH.fs_small,
                color=TH.white70, halign="left", valign="top",
                text_size=(300, None), size_hint_y=None)
            txt.bind(texture_size=lambda w, v: setattr(w, "height", v[1]+8))
            step_row.add_widget(txt)
            self.content_layout.add_widget(step_row)
            if i < len(steps):
                self.content_layout.add_widget(
                    BoxLayout(size_hint_y=None, height=4))

    def _redraw_circle(self, w):
        w.canvas.before.clear()
        with w.canvas.before:
            Color(*TH.primary)
            RoundedRectangle(pos=w.pos, size=w.size, radius=[14])

    def _render_variants_tab(self, variants, m):
        tab_row = BoxLayout(size_hint_y=None, height=44, spacing=6)
        self.tab_content = BoxLayout(
            orientation="vertical", size_hint_y=None)
        self.tab_content.bind(
            minimum_height=self.tab_content.setter("height"))

        def switch_tab(tab_type):
            self.active_tab = tab_type
            self._render_tab_content(variants, m)
            for child in tab_row.children:
                if hasattr(child, "tab_type"):
                    is_sel = (child.tab_type == tab_type)
                    child.background_color = TH.primary if is_sel else TH.card
                    child.color = (0, 0, 0, 1) if is_sel else TH.grey

        for variant in variants:
            is_hot  = (variant["type"] == "Hot")
            v_label = L["hot"] if is_hot else L["iced"]
            is_sel  = (self.active_tab == variant["type"])
            tab_btn = Button(
                text=v_label, font_size=TH.fs_normal, bold=True,
                background_normal="",
                background_color=TH.primary if is_sel else TH.card,
                color=(0, 0, 0, 1) if is_sel else TH.grey,
                size_hint_y=None, height=44)
            tab_btn.tab_type = variant["type"]
            tab_btn.bind(on_press=lambda b, *a: switch_tab(b.tab_type))
            tab_row.add_widget(tab_btn)

        self.content_layout.add_widget(tab_row)
        self.content_layout.add_widget(self.tab_content)
        self._render_tab_content(variants, m)

    def _render_tab_content(self, variants, m):
        self.tab_content.clear_widgets()
        variant = next(
            (v for v in variants if v["type"] == self.active_tab), None)
        if not variant:
            return
        vc = TH.hot if variant["type"] == "Hot" else TH.iced
        table = BoxLayout(orientation="vertical",
                          size_hint_y=None, spacing=0, padding=0)
        table.bind(minimum_height=table.setter("height"))
        top_line = BoxLayout(size_hint_y=None, height=3)
        _vc = vc
        def draw_top(w, *a):
            w.canvas.before.clear()
            with w.canvas.before:
                Color(*_vc)
                Rectangle(pos=w.pos, size=w.size)
        top_line.bind(pos=draw_top, size=draw_top)
        table.add_widget(top_line)
        hdr = BoxLayout(size_hint_y=None, height=32, padding=[12, 4])
        hdr.add_widget(Label(
            text=f"  {L['ingredient']}", font_size=10, bold=True,
            color=vc, halign="left", text_size=(200, None)))
        hdr.add_widget(Label(
            text=L["qty"], font_size=10, bold=True,
            color=vc, halign="center", text_size=(70, None)))
        hdr.add_widget(Label(
            text=L["unit"], font_size=10, bold=True,
            color=vc, halign="right", text_size=(60, None)))
        table.add_widget(hdr)
        table.add_widget(divider())
        ings = [i for i in variant["ingredients"] if i["amount"] > 0]
        for idx, ing in enumerate(ings):
            amt     = ing["amount"] * m
            amt_str = str(int(amt)) if amt == int(amt) else f"{amt:.1f}"
            row = BoxLayout(size_hint_y=None, height=44, padding=[12, 4])
            if idx % 2 == 0:
                with row.canvas.before:
                    Color(1, 1, 1, 0.03)
                    Rectangle(pos=row.pos, size=row.size)
            name_col = BoxLayout(orientation="horizontal")
            dot = Label(text="*", font_size=8, color=vc,
                        size_hint=(None, None), size=(16, 44))
            name_col.add_widget(dot)
            name_col.add_widget(Label(
                text=ing["name"], font_size=TH.fs_normal,
                color=TH.text_main, halign="left",
                text_size=(180, None)))
            row.add_widget(name_col)
            row.add_widget(Label(
                text=amt_str, font_size=18, bold=True,
                color=TH.primary, halign="center",
                text_size=(70, None)))
            row.add_widget(Label(
                text=ing["unit"], font_size=TH.fs_small,
                color=TH.grey, halign="right",
                text_size=(60, None)))
            table.add_widget(row)
            if idx < len(ings) - 1:
                table.add_widget(divider())
        self.tab_content.add_widget(table)