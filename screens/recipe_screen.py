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
from utils import (set_bg, fill_rounded, divider, make_label, spacer,
                   ghost_btn, gold_btn, card_box, icon_btn, chip,
                   pill_tab_row, stepper, stat_row, step_item,
                   load_data, save_data, get_mode)

CUR_DIR = os.path.dirname(os.path.abspath(__file__))
FA_FONT = os.path.join(os.path.dirname(CUR_DIR), "assets", "fa-solid-900.ttf")

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
        data = load_data()
        cat = next(c for c in data["categories"] if c["id"] == cat_id)
        recipe = next(r for r in cat["recipes"] if r["id"] == recipe_id)

        rtype = recipe.get("type") or (
            "drink" if "variants" in recipe else
            "sop" if "parameters" in recipe else "steps")

        root = BoxLayout(orientation="vertical")
        set_bg(root, TH.bg)

        # ── Top bar ─────────────────────────────────────────────────────
        top = BoxLayout(size_hint_y=None, height=64, padding=[14, 10], spacing=10)
        set_bg(top, TH.bg)

        def go_back(*a):
            self.edit_mode = False
            if self.manager:
                self.manager.transition.direction = "right"
                self.manager.get_screen("category").load(self.cat_id)
                self.manager.current = "category"

        back = icon_btn("<",
                        on_press=go_back,
                        size=(44, 40),
                        fg=TH.text_main, bg=TH.card,
                        font_size=22, radius=12)
        top.add_widget(back)

        title_col = BoxLayout(orientation="vertical")
        title_col.add_widget(Label(
            text=cat["name"], font_size=11, bold=True,
            color=TH.grey, halign="left", valign="middle",
            size_hint_y=None, height=14,
            text_size=(220, None)))
        title_col.add_widget(Label(
            text=recipe["name"], font_size=18, bold=True,
            color=TH.text_main, halign="left", valign="middle",
            size_hint_y=None, height=24,
            text_size=(220, None)))
        top.add_widget(title_col)

        # Right action: EDIT/SAVE for admin
        if get_mode() == "Admin":
            if not self.edit_mode:
                action_btn = Button(
                    text="EDIT", font_size=11, bold=True,
                    size_hint=(None, None), size=(60, 40),
                    background_normal="", background_color=(0, 0, 0, 0),
                    color=TH.primary)
                fill_rounded(action_btn, TH.card, radius=12,
                             border_color=TH.primary)
                action_btn.bind(on_press=lambda *_: self._enter_edit())
            else:
                action_btn = Button(
                    text="SAVE", font_size=11, bold=True,
                    size_hint=(None, None), size=(60, 40),
                    background_normal="", background_color=(0, 0, 0, 0),
                    color=TH.gold_text)
                fill_rounded(action_btn, TH.primary, radius=12)
                action_btn.bind(on_press=lambda x: self._save_edits(recipe))
            top.add_widget(action_btn)
        else:
            top.add_widget(BoxLayout(size_hint=(None, None), size=(40, 40)))

        root.add_widget(top)

        # ── Recipe image (if present) ───────────────────────────────────
        img_path = recipe.get("image", "")
        if img_path:
            full = (img_path if os.path.isabs(img_path)
                    else os.path.join(os.path.dirname(CUR_DIR), img_path))
            if os.path.exists(full):
                from kivy.uix.image import Image as KivyImage
                img_box = BoxLayout(size_hint_y=None, height=180,
                                    padding=[14, 0])
                img_wrap = BoxLayout(size_hint_y=None, height=180)
                fill_rounded(img_wrap, TH.card2, radius=14)
                img_widget = KivyImage(
                    source=full,
                    fit_mode="cover",
                    keep_ratio=True,
                    allow_stretch=True)
                img_wrap.add_widget(img_widget)
                img_box.add_widget(img_wrap)
                root.add_widget(img_box)

        # ── Hero strip: type chip + favorite + name (already shown in top)
        meta = BoxLayout(size_hint_y=None, height=40,
                         padding=[14, 8], spacing=8)
        if rtype == "drink":
            tchip = chip("DRINK", fg=TH.gold_text, bg=TH.primary, font_size=10)
        elif rtype == "sop":
            tchip = chip("SOP", fg=TH.gold_text, bg=TH.primary, font_size=10)
        else:
            tchip = chip("STEPS", fg=TH.text_main, bg=TH.card2, font_size=10)
        meta.add_widget(tchip)

        # Counts
        n_p = len(recipe.get("parameters", []))
        n_s = len(recipe.get("steps", []))
        meta_text = []
        if n_p:
            meta_text.append(f"{n_p} params")
        if n_s:
            meta_text.append(f"{n_s} steps")
        if "variants" in recipe:
            meta_text.append(f"{len(recipe['variants'])} variants")
        meta.add_widget(Label(
            text=" · ".join(meta_text),
            font_size=11, color=TH.grey,
            halign="left", valign="middle",
            text_size=(280, None)))
        root.add_widget(meta)

        # ── Serving stepper / Edit hint ────────────────────────────────
        if not self.edit_mode:
            stepper_wrap = BoxLayout(
                size_hint_y=None, height=80,
                padding=[14, 4, 14, 8])

            def update_serving(delta):
                self.serving_count = max(1, min(99, self.serving_count + delta))
                self.serving_lbl.text = f"x {self.serving_count}"
                self._render_content(recipe)

            stp, val_lbl = stepper(
                value_text=f"x {self.serving_count}",
                on_minus=lambda: update_serving(-1),
                on_plus=lambda: update_serving(1),
                on_reset=lambda: update_serving(1 - self.serving_count),
                label_text="Serving")
            self.serving_lbl = val_lbl
            stepper_wrap.add_widget(stp)
            root.add_widget(stepper_wrap)
        else:
            hint = BoxLayout(size_hint_y=None, height=42,
                             padding=[14, 6])
            inner = BoxLayout()
            fill_rounded(inner, TH.card2, radius=10)
            inner.add_widget(Label(
                text="Edit values below, then tap SAVE",
                font_size=TH.fs_small, color=TH.primary,
                halign="center", valign="middle"))
            hint.add_widget(inner)
            root.add_widget(hint)

        # ── Scrollable content ──────────────────────────────────────────
        scroll = ScrollView(bar_width=2)
        self.content_layout = BoxLayout(
            orientation="vertical", spacing=14,
            padding=[14, 8, 14, 24], size_hint_y=None)
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
        if "variants" in recipe:
            self._render_variants_tab(recipe["variants"], m)
        if "parameters" in recipe:
            self._render_parameters(recipe["parameters"], m)
        if "steps" in recipe:
            self._render_steps(recipe["steps"])
        self.content_layout.add_widget(spacer(8))
        self.content_layout.add_widget(make_label(
            L["measure_note"], font_size=11,
            color=TH.grey, halign="center", height=24))
        self.content_layout.add_widget(spacer(8))

    def _render_parameters(self, parameters, m):
        self.content_layout.add_widget(self._section_header(L["parameters"]))
        card = BoxLayout(orientation="vertical",
                         size_hint_y=None, spacing=0, padding=0)
        card.bind(minimum_height=card.setter("height"))
        fill_rounded(card, TH.card, radius=14)

        for idx, p in enumerate(parameters):
            amt = p["amount"] * m
            amt_str = str(int(amt)) if amt == int(amt) else f"{amt:.1f}"
            card.add_widget(stat_row(
                p["name"], amt_str, p["unit"],
                alt_bg=(idx % 2 == 0),
                accent=TH.primary))
            if idx < len(parameters) - 1:
                card.add_widget(divider())
        self.content_layout.add_widget(card)

    def _render_steps(self, steps):
        self.content_layout.add_widget(self._section_header(L["steps"]))
        card = BoxLayout(
            orientation="vertical",
            size_hint_y=None, spacing=4,
            padding=[10, 10])
        card.bind(minimum_height=card.setter("height"))
        fill_rounded(card, TH.card, radius=14)
        for i, step in enumerate(steps, 1):
            card.add_widget(step_item(i, step))
            if i < len(steps):
                line = BoxLayout(size_hint_y=None, height=1, padding=[40, 0])
                d = BoxLayout(size_hint_y=None, height=1)
                with d.canvas:
                    Color(*TH.divider)
                    rect = Rectangle(pos=d.pos, size=d.size)
                d.bind(pos=lambda w, v: setattr(rect, "pos", v),
                       size=lambda w, v: setattr(rect, "size", v))
                line.add_widget(d)
                card.add_widget(line)
        self.content_layout.add_widget(card)

    def _section_header(self, text):
        wrap = BoxLayout(size_hint_y=None, height=24, padding=[2, 0])
        lbl = Label(
            text=text.upper(), font_size=11, bold=True,
            color=TH.primary, halign="left", valign="middle",
            text_size=(360, None))
        wrap.add_widget(lbl)
        return wrap

    def _redraw_circle(self, w):
        w.canvas.before.clear()
        with w.canvas.before:
            Color(*TH.primary)
            RoundedRectangle(pos=w.pos, size=w.size, radius=[14])

    def _render_variants_tab(self, variants, m):
        self._variants_ref = variants
        self._variants_m = m

        # Pill tab row
        options = []
        for v in variants:
            label = L["hot"] if v["type"] == "Hot" else L["iced"]
            accent = TH.hot if v["type"] == "Hot" else TH.iced
            options.append((v["type"], label, accent))

        def on_select(value):
            self.active_tab = value
            self._build(self.cat_id, self.recipe_id)

        self.content_layout.add_widget(
            pill_tab_row(options, self.active_tab, on_select, height=44))

        self.tab_content = BoxLayout(
            orientation="vertical", size_hint_y=None, spacing=8)
        self.tab_content.bind(
            minimum_height=self.tab_content.setter("height"))
        self.content_layout.add_widget(self.tab_content)
        self._render_tab_content(variants, m)

    def _render_tab_content(self, variants, m):
        self.tab_content.clear_widgets()
        variant = next(
            (v for v in variants if v["type"] == self.active_tab), None)
        if not variant:
            return
        vc = TH.hot if variant["type"] == "Hot" else TH.iced

        # Section header
        head = BoxLayout(size_hint_y=None, height=22, padding=[2, 0])
        head.add_widget(Label(
            text=f"{L['ingredient']}",
            font_size=11, bold=True,
            color=vc, halign="left", valign="middle",
            text_size=(360, None)))
        self.tab_content.add_widget(head)

        table = BoxLayout(orientation="vertical",
                          size_hint_y=None, spacing=0, padding=0)
        table.bind(minimum_height=table.setter("height"))
        fill_rounded(table, TH.card, radius=14)

        ings = [i for i in variant["ingredients"] if i["amount"] > 0]
        for idx, ing in enumerate(ings):
            amt = ing["amount"] * m
            amt_str = str(int(amt)) if amt == int(amt) else f"{amt:.1f}"
            table.add_widget(stat_row(
                ing["name"], amt_str, ing["unit"],
                alt_bg=(idx % 2 == 0),
                accent=vc))
            if idx < len(ings) - 1:
                table.add_widget(divider())
        self.tab_content.add_widget(table)