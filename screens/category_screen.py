import os

from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup
from kivy.uix.spinner import Spinner
from kivy.graphics import Color, Rectangle, RoundedRectangle, Line

from theme import TH
from lang import L
from utils import (set_bg, fill_rounded, divider, make_label, spacer, hspacer,
                   card_box, gold_btn, ghost_btn, danger_btn, icon_btn, chip,
                   type_chip_for_recipe,
                   outline_btn, section_label, load_data, save_data,
                   get_mode)

CUR_DIR = os.path.dirname(os.path.abspath(__file__))
FA_FONT = os.path.join(os.path.dirname(CUR_DIR), "assets", "fa-solid-900.ttf")

# ── Swipe-to-Favorite card ───────────────────────────────────────────────────

class SwipeFavCard(BoxLayout):
    """BoxLayout that detects a horizontal swipe to toggle favorite."""
    def __init__(self, toggle_cb=None, **kwargs):
        super().__init__(**kwargs)
        self._touch_x  = None
        self._toggle_cb = toggle_cb

    def on_touch_down(self, touch):
        if self.collide_point(*touch.pos):
            self._touch_x = touch.x
        return super().on_touch_down(touch)

    def on_touch_up(self, touch):
        if self._touch_x is not None:
            dx = touch.x - self._touch_x
            if abs(dx) > 80 and self.collide_point(*touch.pos):
                if self._toggle_cb:
                    self._toggle_cb()
            self._touch_x = None
        return super().on_touch_up(touch)


# ── CategoryScreen ────────────────────────────────────────────────────────────

class CategoryScreen(Screen):
    def __init__(self, **kw):
        super().__init__(**kw)
        self.current_cat_id = None

    def on_enter(self):
        if self.current_cat_id:
            self.load(self.current_cat_id)

    def load(self, cat_id):
        self.current_cat_id = cat_id
        self.clear_widgets()
        data = load_data()
        cat = next(c for c in data["categories"] if c["id"] == cat_id)

        root = BoxLayout(orientation="vertical")
        set_bg(root, TH.bg)

        # ── Top bar ─────────────────────────────────────────────────────
        top = BoxLayout(size_hint_y=None, height=64, padding=[14, 10], spacing=10)
        set_bg(top, TH.bg)

        back = icon_btn("<",
                        on_press=lambda *_: self._go_back(),
                        size=(44, 40),
                        fg=TH.text_main, bg=TH.card,
                        font_size=22, radius=12)
        top.add_widget(back)

        title_col = BoxLayout(orientation="vertical")
        title_col.add_widget(Label(
            text=cat["name"], font_size=18, bold=True,
            color=TH.text_main, halign="left", valign="middle",
            size_hint_y=None, height=24,
            text_size=(220, None)))
        title_col.add_widget(Label(
            text=f"{len(cat['recipes'])} {L['recipes_count']}",
            font_size=11, color=TH.grey,
            halign="left", valign="middle",
            size_hint_y=None, height=16,
            text_size=(220, None)))
        top.add_widget(title_col)

        # Spacer right
        top.add_widget(BoxLayout(size_hint=(None, None), size=(40, 40)))

        root.add_widget(top)

        # Subtle top divider
        root.add_widget(divider())

        # ── Recipe List ─────────────────────────────────────────────────
        scroll = ScrollView(bar_width=2)
        layout = BoxLayout(
            orientation="vertical", spacing=12,
            padding=[14, 12, 14, 18], size_hint_y=None)
        layout.bind(minimum_height=layout.setter("height"))

        if get_mode() == "Admin":
            add_btn = gold_btn(L["add_recipe"], height=48)
            add_btn.bind(on_press=lambda x: self.show_add_recipe(cat_id))
            layout.add_widget(add_btn)

        if not cat["recipes"]:
            empty = BoxLayout(
                orientation="vertical", spacing=10,
                padding=[24, 60, 24, 24], size_hint_y=None, height=200)
            empty.add_widget(Label(
                text="", font_size=42,
                font_name=FA_FONT, color=TH.grey,
                size_hint_y=None, height=60, halign="center"))
            empty.add_widget(Label(
                text="No recipes yet", font_size=TH.fs_large, bold=True,
                color=TH.text_main, size_hint_y=None, height=28,
                halign="center"))
            empty.add_widget(Label(
                text="Tap '+ Add New Recipe' to start.",
                font_size=TH.fs_small, color=TH.grey,
                size_hint_y=None, height=24, halign="center"))
            layout.add_widget(empty)
        else:
            for recipe in cat["recipes"]:
                layout.add_widget(self._make_recipe_card(recipe, cat_id))

        scroll.add_widget(layout)
        root.add_widget(scroll)
        self.add_widget(root)

    def _go_back(self):
        import theme as theme_mod
        theme_mod.TH.reload()
        self.manager.transition.direction = "right"
        self.manager.current = "home"

    def _make_recipe_card(self, recipe, cat_id):
        """Recipe card: rounded, type chip, fav toggle, swipe-to-fav, admin actions."""

        rtype = recipe.get("type") or (
            "drink" if "variants" in recipe else
            "sop" if "parameters" in recipe else "steps")

        def do_toggle():
            self._toggle_fav_direct(recipe["id"], cat_id)

        card = SwipeFavCard(
            toggle_cb=do_toggle,
            orientation="vertical",
            size_hint_y=None, padding=0, spacing=0)
        card.bind(minimum_height=card.setter("height"))
        fill_rounded(card, TH.card, radius=14, border_color=(1, 1, 1, 0.05))

        # ── Header row: type chip + fav star
        head = BoxLayout(
            size_hint_y=None, height=44,
            padding=[12, 8, 12, 4], spacing=8)

        # Type chip
        if rtype == "drink":
            tchip = chip("DRINK", fg=TH.gold_text, bg=TH.primary, font_size=9)
        elif rtype == "sop":
            tchip = chip("SOP", fg=TH.gold_text, bg=TH.primary, font_size=9)
        else:
            tchip = chip("STEPS", fg=TH.text_main, bg=TH.card2, font_size=9)
        head.add_widget(tchip)

        head.add_widget(BoxLayout())  # spacer

        # Favorite star
        is_fav = recipe.get("favorite", False)
        fav_btn = Button(
            text="" if is_fav else "",
            font_size=15, font_name=FA_FONT,
            size_hint=(None, None), size=(34, 34),
            background_normal="", background_color=(0, 0, 0, 0),
            color=TH.fav if is_fav else TH.grey)
        fav_btn.recipe_id = recipe["id"]
        fav_btn.cat_id = cat_id
        fav_btn.bind(on_press=self.toggle_favorite)
        head.add_widget(fav_btn)

        card.add_widget(head)

        # ── Recipe name (tap → open)
        name_btn = Button(
            text=recipe["name"],
            font_size=TH.fs_large, bold=True,
            background_normal="", background_color=(0, 0, 0, 0),
            color=TH.text_main, halign="left", valign="middle",
            size_hint_y=None, height=36,
            padding=[12, 0])
        name_btn.bind(width=lambda w, v: setattr(w, "text_size", (v - 24, None)))
        name_btn.recipe_id = recipe["id"]
        name_btn.cat_id = cat_id
        name_btn.bind(on_press=self.go_recipe)
        card.add_widget(name_btn)

        # ── Preview line
        if rtype == "drink" and recipe.get("variants"):
            preview = BoxLayout(
                size_hint_y=None, height=40,
                padding=[12, 4, 12, 6], spacing=12)
            for v in recipe["variants"]:
                vc = TH.hot if v["type"] == "Hot" else TH.iced
                label = "HOT" if v["type"] == "Hot" else "ICED"
                ings = [i for i in v["ingredients"] if i["amount"] > 0]

                v_col = BoxLayout(orientation="vertical", spacing=1)
                v_col.add_widget(Label(
                    text=label, font_size=9, bold=True,
                    color=vc, halign="left", valign="middle",
                    size_hint_y=None, height=14,
                    text_size=(160, None)))
                preview_text = " · ".join(
                    [f"{int(i['amount']) if i['amount']==int(i['amount']) else i['amount']}{i['unit']} {i['name']}"
                     for i in ings[:2]])
                if len(ings) > 2:
                    preview_text += f"  +{len(ings)-2}"
                v_col.add_widget(Label(
                    text=preview_text or "-",
                    font_size=10, color=TH.grey,
                    halign="left", valign="middle",
                    size_hint_y=None, height=16,
                    text_size=(160, None)))
                preview.add_widget(v_col)
            card.add_widget(preview)

        elif rtype == "sop":
            preview = BoxLayout(
                size_hint_y=None, height=28,
                padding=[12, 0, 12, 6])
            n_p = len(recipe.get("parameters", []))
            n_s = len(recipe.get("steps", []))
            preview.add_widget(Label(
                text=f"{n_p} parameters · {n_s} steps",
                font_size=11, color=TH.grey,
                halign="left", valign="middle",
                text_size=(280, None)))
            card.add_widget(preview)

        else:
            preview = BoxLayout(
                size_hint_y=None, height=28,
                padding=[12, 0, 12, 6])
            preview.add_widget(Label(
                text=f"{len(recipe.get('steps', []))} steps",
                font_size=11, color=TH.grey,
                halign="left", valign="middle",
                text_size=(280, None)))
            card.add_widget(preview)

        # ── Admin actions
        if get_mode() == "Admin":
            card.add_widget(divider())
            actions = BoxLayout(
                size_hint_y=None, height=44,
                padding=[10, 6], spacing=8)
            actions.add_widget(BoxLayout())
            edit_b = icon_btn("",
                              on_press=lambda *_, rid=recipe["id"]: self._edit_rec(cat_id, rid),
                              size=(36, 32), font=FA_FONT,
                              fg=TH.primary, bg=TH.card2,
                              font_size=12, radius=10)
            del_b = icon_btn("",
                             on_press=lambda *_, rid=recipe["id"]: self._del_rec(cat_id, rid),
                             size=(36, 32), font=FA_FONT,
                             fg=TH.red, bg=TH.card2,
                             font_size=12, radius=10)
            actions.add_widget(edit_b)
            actions.add_widget(del_b)
            card.add_widget(actions)
        else:
            card.add_widget(spacer(8))

        return card

    def _edit_rec(self, cat_id, recipe_id):
        class _F:
            pass
        f = _F()
        f.cat_id = cat_id
        f.recipe_id = recipe_id
        self.show_edit_recipe(f)

    def _del_rec(self, cat_id, recipe_id):
        class _F:
            pass
        f = _F()
        f.cat_id = cat_id
        f.recipe_id = recipe_id
        self.confirm_delete_recipe(f)

    # ── Favorite helpers ─────────────────────────────────────────────────────

    def _toggle_fav_direct(self, recipe_id, cat_id):
        """Called by swipe gesture."""
        data   = load_data()
        cat    = next(c for c in data["categories"] if c["id"] == cat_id)
        recipe = next(r for r in cat["recipes"] if r["id"] == recipe_id)
        recipe["favorite"] = not recipe.get("favorite", False)
        save_data(data)
        self.load(cat_id)

    def toggle_favorite(self, btn):
        """Called by FAV button tap."""
        data   = load_data()
        cat    = next(c for c in data["categories"]
                      if c["id"] == btn.cat_id)
        recipe = next(r for r in cat["recipes"]
                      if r["id"] == btn.recipe_id)
        recipe["favorite"] = not recipe.get("favorite", False)
        save_data(data)
        self.load(btn.cat_id)

    def go_recipe(self, btn):
        self.manager.transition.direction = "left"
        self.manager.get_screen("recipe").load(btn.cat_id, btn.recipe_id)
        self.manager.current = "recipe"

    # ── Edit Recipe ──────────────────────────────────────────────────────────

    def show_edit_recipe(self, btn):
        cat_id    = btn.cat_id
        recipe_id = btn.recipe_id
        data      = load_data()
        cat       = next(c for c in data["categories"]
                         if c["id"] == cat_id)
        recipe    = next(r for r in cat["recipes"]
                         if r["id"] == recipe_id)

        scroll = ScrollView()
        inner  = BoxLayout(
            orientation="vertical", spacing=8,
            padding=16, size_hint_y=None)
        inner.bind(minimum_height=inner.setter("height"))
        inner.add_widget(gold_line(1))
        inner.add_widget(BoxLayout(size_hint_y=None, height=6))
        inner.add_widget(section_label("RECIPE NAME", height=24))
        name_in = TextInput(
            text=recipe["name"], multiline=False,
            size_hint_y=None, height=44,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.white,
            cursor_color=TH.primary)
        inner.add_widget(name_in)
        inner.add_widget(BoxLayout(size_hint_y=None, height=4))
        inner.add_widget(section_label("IMAGE PATH (optional)", height=24))
        img_edit_in = TextInput(
            text=recipe.get("image", ""),
            hint_text="e.g. C:/images/thai_tea.jpg",
            multiline=False, size_hint_y=None, height=44,
            font_size=TH.fs_small,
            background_color=TH.input_bg,
            foreground_color=TH.white)
        inner.add_widget(img_edit_in)
        browse_btn2 = ghost_btn("Browse...", height=40)
        def browse_img2(x):
            import tkinter as tk
            from tkinter import filedialog
            root_tk = tk.Tk()
            root_tk.withdraw()
            path = filedialog.askopenfilename(
                title="Select Image",
                filetypes=[("Image files", "*.jpg *.jpeg *.png *.webp")])
            root_tk.destroy()
            if path:
                img_edit_in.text = path
        browse_btn2.bind(on_press=browse_img2)
        inner.add_widget(browse_btn2)
        hot_text = iced_text = steps_text = ""
        if "variants" in recipe:
            for v in recipe["variants"]:
                lines = "\n".join(
                    f"{i['name']},{int(i['amount']) if i['amount']==int(i['amount']) else i['amount']},{i['unit']}"
                    for i in v["ingredients"])
                if v["type"] == "Hot": hot_text  = lines
                else:                  iced_text = lines
        if "steps" in recipe:
            steps_text = "\n".join(recipe["steps"])

        inner.add_widget(BoxLayout(size_hint_y=None, height=4))
        inner.add_widget(section_label(
            "HOT INGREDIENTS  (name,amount,unit)", height=24))
        hot_in = TextInput(
            text=hot_text, size_hint_y=None, height=100,
            font_size=TH.fs_small,
            background_color=TH.input_bg,
            foreground_color=TH.white)
        inner.add_widget(hot_in)

        inner.add_widget(BoxLayout(size_hint_y=None, height=4))
        inner.add_widget(section_label(
            "ICED INGREDIENTS  (name,amount,unit)", height=24))
        iced_in = TextInput(
            text=iced_text, size_hint_y=None, height=100,
            font_size=TH.fs_small,
            background_color=TH.input_bg,
            foreground_color=TH.white)
        inner.add_widget(iced_in)

        inner.add_widget(BoxLayout(size_hint_y=None, height=4))
        inner.add_widget(section_label(
            "STEPS  (one per line)", height=24))
        steps_in = TextInput(
            text=steps_text, size_hint_y=None, height=100,
            font_size=TH.fs_small,
            background_color=TH.input_bg,
            foreground_color=TH.white)
        inner.add_widget(steps_in)

        inner.add_widget(BoxLayout(size_hint_y=None, height=8))
        btns = BoxLayout(size_hint_y=None, height=44, spacing=8)
        s = gold_btn("Save", height=44)
        c = ghost_btn("Cancel", height=44)
        btns.add_widget(s)
        btns.add_widget(c)
        inner.add_widget(btns)
        scroll.add_widget(inner)

        popup = Popup(
            title="Edit Recipe", content=scroll,
            size_hint=(0.95, 0.88),
            background_color=TH.card)
        s.bind(on_press=lambda x: self._save_edit_recipe(
            cat_id, recipe_id,
            name_in.text, hot_in.text,
            iced_in.text, steps_in.text,
            img_edit_in.text, popup))
        c.bind(on_press=popup.dismiss)
        popup.open()

    def _parse_ingredients(self, text):
        ings = []
        for line in text.strip().splitlines():
            parts = line.strip().split(",")
            if len(parts) == 3:
                try:
                    ings.append({
                        "name":   parts[0].strip(),
                        "amount": float(parts[1].strip()),
                        "unit":   parts[2].strip()})
                except:
                    pass
        return ings

    def _save_edit_recipe(self, cat_id, recipe_id,
                          name, hot_t, iced_t, steps_t, img_path, popup):
        if not name.strip(): return
        data   = load_data()
        cat    = next(c for c in data["categories"]
                      if c["id"] == cat_id)
        recipe = next(r for r in cat["recipes"]
                      if r["id"] == recipe_id)
        recipe["name"] = name.strip()
        if img_path.strip():
            recipe["image"] = img_path.strip()
        elif "image" in recipe:
            del recipe["image"]
        hi = self._parse_ingredients(hot_t)
        ii = self._parse_ingredients(iced_t)
        ss = [s.strip() for s in steps_t.splitlines() if s.strip()]
        if hi or ii:
            recipe["variants"] = [
                {"type": "Hot",  "ingredients": hi},
                {"type": "Iced", "ingredients": ii}]
            recipe.pop("steps", None)
        if ss:
            recipe["steps"] = ss
            if not hi and not ii:
                recipe.pop("variants", None)
        save_data(data)
        popup.dismiss()
        self.load(cat_id)

    # ── Delete Recipe ────────────────────────────────────────────────────────

    def confirm_delete_recipe(self, btn):
        cat_id    = btn.cat_id
        recipe_id = btn.recipe_id
        content   = BoxLayout(
            orientation="vertical", padding=16, spacing=12)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        content.add_widget(BoxLayout(size_hint_y=None, height=8))
        content.add_widget(make_label(
            "Delete this recipe?\nThis cannot be undone.",
            color=TH.white, halign="center",
            font_size=TH.fs_normal, height=52))
        btns = BoxLayout(size_hint_y=None, height=44, spacing=8)
        yes = danger_btn("Delete", height=44)
        no  = ghost_btn("Cancel", height=44)
        btns.add_widget(yes)
        btns.add_widget(no)
        content.add_widget(btns)
        popup = Popup(
            title="", content=content,
            size_hint=(0.85, 0.34),
            background_color=TH.card,
            separator_height=0)
        yes.bind(on_press=lambda x: self._do_delete_recipe(
            cat_id, recipe_id, popup))
        no.bind(on_press=popup.dismiss)
        popup.open()

    def _do_delete_recipe(self, cat_id, recipe_id, popup):
        data = load_data()
        cat  = next(c for c in data["categories"]
                    if c["id"] == cat_id)
        cat["recipes"] = [
            r for r in cat["recipes"] if r["id"] != recipe_id]
        save_data(data)
        popup.dismiss()
        self.load(cat_id)

    # ── Add Recipe ───────────────────────────────────────────────────────────

    def show_add_recipe(self, cat_id):
        scroll = ScrollView()
        inner  = BoxLayout(
            orientation="vertical", spacing=8,
            padding=16, size_hint_y=None)
        inner.bind(minimum_height=inner.setter("height"))
        inner.add_widget(gold_line(1))
        inner.add_widget(BoxLayout(size_hint_y=None, height=6))
        inner.add_widget(section_label("RECIPE NAME", height=24))
        name_in = TextInput(
            hint_text=L["recipe_hint"],                                                                                     
            multiline=False, size_hint_y=None, height=44,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.white,
            cursor_color=TH.primary)
        inner.add_widget(name_in)        
        inner.add_widget(BoxLayout(size_hint_y=None, height=4))
        inner.add_widget(section_label("FORMAT", height=24))
        inner.add_widget(BoxLayout(size_hint_y=None, height=4))
        inner.add_widget(section_label("IMAGE PATH (optional)", height=24))
        img_in = TextInput(
            hint_text="e.g. C:/images/thai_tea.jpg",
            multiline=False, size_hint_y=None, height=44,
            font_size=TH.fs_small,
            background_color=TH.input_bg,
            foreground_color=TH.white)
        inner.add_widget(img_in)
        fmt_sp = Spinner(
            text="Hot and Iced",
            values=["Hot and Iced", "Steps Only"],
            size_hint_y=None, height=44,
            font_size=TH.fs_normal,
            background_normal="",
            background_color=TH.input_bg,
            color=TH.white)
        inner.add_widget(fmt_sp)
        browse_btn = ghost_btn("Browse...", height=40)
        def browse_img(x):
            import tkinter as tk
            from tkinter import filedialog
            root_tk = tk.Tk()
            root_tk.withdraw()
            path = filedialog.askopenfilename(
                title="Select Image",
                filetypes=[("Image files", "*.jpg *.jpeg *.png *.webp")])
            root_tk.destroy()
            if path:
                img_in.text = path
        browse_btn.bind(on_press=browse_img)
        inner.add_widget(browse_btn) 
        inner.add_widget(BoxLayout(size_hint_y=None, height=4))
        inner.add_widget(section_label(
            "HOT INGREDIENTS  (name,amount,unit)", height=24))
        hot_in = TextInput(
            hint_text="Black Tea,150,ml",
            size_hint_y=None, height=100,
            font_size=TH.fs_small,
            background_color=TH.input_bg,
            foreground_color=TH.white)
        inner.add_widget(hot_in)

        inner.add_widget(BoxLayout(size_hint_y=None, height=4))
        inner.add_widget(section_label(
            "ICED INGREDIENTS  (name,amount,unit)", height=24))
        iced_in = TextInput(
            hint_text="Black Tea,180,ml",
            size_hint_y=None, height=100,
            font_size=TH.fs_small,
            background_color=TH.input_bg,
            foreground_color=TH.white)
        inner.add_widget(iced_in)

        inner.add_widget(BoxLayout(size_hint_y=None, height=4))
        inner.add_widget(section_label(
            "STEPS  (one per line)", height=24))
        steps_in = TextInput(
            hint_text="Step 1\nStep 2",
            size_hint_y=None, height=100,
            font_size=TH.fs_small,
            background_color=TH.input_bg,
            foreground_color=TH.white)
        inner.add_widget(steps_in)

        inner.add_widget(BoxLayout(size_hint_y=None, height=8))
        btns = BoxLayout(size_hint_y=None, height=44, spacing=8)
        s = gold_btn("Save", height=44)
        c = ghost_btn("Cancel", height=44)
        btns.add_widget(s)
        btns.add_widget(c)
        inner.add_widget(btns)
        scroll.add_widget(inner)

        popup = Popup(
            title="Add Recipe", content=scroll,
            size_hint=(0.95, 0.88),
            background_color=TH.card)
        s.bind(on_press=lambda x: self._save_recipe(
            cat_id, name_in.text, fmt_sp.text,
            hot_in.text, iced_in.text, steps_in.text,
            img_in.text, popup))
        c.bind(on_press=popup.dismiss)
        popup.open()

    def _save_recipe(self, cat_id, name, fmt,
                     hot_t, iced_t, steps_t, img_path, popup):
        if not name.strip(): return
        data   = load_data()
        cat    = next(c for c in data["categories"]
                      if c["id"] == cat_id)
        recipe = {
            "id":   name.strip().lower().replace(" ", "_"),
            "name": name.strip()}
        if img_path.strip():
            recipe["image"] = img_path.strip()
        if fmt == "Hot and Iced":
            recipe["variants"] = [
                {"type": "Hot",
                 "ingredients": self._parse_ingredients(hot_t)},
                {"type": "Iced",
                 "ingredients": self._parse_ingredients(iced_t)}]
        else:
            recipe["steps"] = [
                s.strip() for s in steps_t.splitlines() if s.strip()]
        cat["recipes"].append(recipe)
        save_data(data)
        popup.dismiss()
        self.load(cat_id)