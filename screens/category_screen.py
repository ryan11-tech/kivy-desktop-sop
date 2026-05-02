import tkinter as tk
from tkinter import filedialog
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
from utils import (set_bg, gold_line, divider, make_label,
                   card_box, gold_btn, ghost_btn, danger_btn,
                   outline_btn, section_label, load_data, save_data,
                   get_mode)

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
        cat  = next(c for c in data["categories"] if c["id"] == cat_id)

        root = BoxLayout(orientation="vertical")
        set_bg(root, TH.bg)
        root.add_widget(gold_line(2))

        # ── Header ──────────────────────────────────────────────────────────
        header = BoxLayout(size_hint_y=None, height=62, padding=[14, 8])
        set_bg(header, TH.header_bg)

        back = Button(
            text=L["btn_back"], font_size=TH.fs_small, bold=True,
            size_hint=(None, None), size=(70, 36),
            background_normal="", background_color=(0,0,0,0),
            color=TH.primary)
        back.bind(on_press=lambda x: self._go_back())
        header.add_widget(back)

        header.add_widget(Label(
            text=cat["name"],
            font_size=TH.fs_large, bold=True,
            color=TH.primary, halign="center"))

        count_box = BoxLayout(
            size_hint=(None, None), size=(70, 36),
            pos_hint={"center_y": 0.5})
        set_bg(count_box, (0,0,0,0))
        count_box.add_widget(Label(
            text=f"{len(cat['recipes'])} {L['recipes_count']}",
            font_size=10, color=TH.grey,
            halign="right"))
        header.add_widget(count_box)
        root.add_widget(header)
        root.add_widget(gold_line(1))

        # ── Recipe List ──────────────────────────────────────────────────────
        scroll = ScrollView()
        layout = BoxLayout(
            orientation="vertical", spacing=10,
            padding=[14, 14], size_hint_y=None)
        layout.bind(minimum_height=layout.setter("height"))

        for recipe in cat["recipes"]:
            r_card = self._make_recipe_card(recipe, cat_id)
            layout.add_widget(r_card)

        if get_mode() == "Admin":
            add_btn = gold_btn(L["add_recipe"], height=52)
            add_btn.bind(on_press=lambda x: self.show_add_recipe(cat_id))
            layout.add_widget(add_btn)

        scroll.add_widget(layout)
        root.add_widget(scroll)

        # ── Bottom Nav ───────────────────────────────────────────────────────
        self.add_widget(root)

    def _go_back(self):
        import theme as theme_mod
        theme_mod.TH.reload()
        self.manager.transition.direction = "right"
        self.manager.current = "home"

    def _make_recipe_card(self, recipe, cat_id):
        """Recipe card with image strip, swipe-to-favorite, edit/del."""

        # Determine recipe type for image strip color & label
        if "variants" in recipe:
            strip_color = TH.primary
            strip_label = "HOT\nICED"
        elif "parameters" in recipe:
            strip_color = TH.primary
            strip_label = "SOP"
        else:
            strip_color = TH.primary
            strip_label = "STEP"

        def do_toggle():
            self._toggle_fav_direct(recipe["id"], cat_id)

        card = SwipeFavCard(
            toggle_cb=do_toggle,
            orientation="vertical",
            size_hint_y=None, padding=0, spacing=0)
        card.bind(minimum_height=card.setter("height"))

        def draw_card(w, *a):
            w.canvas.before.clear()
            with w.canvas.before:
                Color(*TH.card)
                Rectangle(pos=w.pos, size=w.size)
                Color(*TH.divider)
                Line(rectangle=(w.x, w.y, w.width, w.height), width=0.8)
        card.bind(pos=draw_card, size=draw_card)

        # ── Title Row ────────────────────────────────────────────────────────
        title_row = BoxLayout(size_hint_y=None, height=52, padding=[0, 6])

        # Image strip (replaces thin gold bar)
        img_strip = BoxLayout(
            size_hint_x=None, width=36,
            orientation="vertical")

        def draw_strip(w, *a):
            w.canvas.before.clear()
            with w.canvas.before:
                Color(*strip_color)
                Rectangle(pos=w.pos, size=w.size)
        img_strip.bind(pos=draw_strip, size=draw_strip)

        strip_lbl = Label(
            text=strip_label,
            font_size=8, bold=True,
            color=(0, 0, 0, 0.85),
            halign="center", valign="middle")
        img_strip.add_widget(strip_lbl)
        title_row.add_widget(img_strip)
        title_row.add_widget(BoxLayout(size_hint_x=None, width=8))

        # Fav indicator
        is_fav   = recipe.get("favorite", False)
        fav_text = L["btn_fav"] if is_fav else L["btn_unfav"]
        fav_col  = TH.fav if is_fav else TH.grey
        fav_btn  = Button(
            text=fav_text, font_size=9, bold=True,
            size_hint=(None, None), size=(36, 30),
            background_normal="", background_color=(0,0,0,0),
            color=fav_col)
        fav_btn.recipe_id = recipe["id"]
        fav_btn.cat_id    = cat_id
        fav_btn.bind(on_press=self.toggle_favorite)
        title_row.add_widget(fav_btn)
        title_row.add_widget(BoxLayout(size_hint_x=None, width=4))

        # Recipe name button
        name_btn = Button(
            text=recipe["name"],
            font_size=TH.fs_normal, bold=True,
            background_normal="", background_color=(0,0,0,0),
            color=TH.white, halign="left")
        name_btn.recipe_id = recipe["id"]
        name_btn.cat_id    = cat_id
        name_btn.bind(on_press=self.go_recipe)
        title_row.add_widget(name_btn)

        # Edit button
        edit_btn = Button(
            text=L["btn_edit"], font_size=10, bold=True,
            size_hint=(None, None), size=(44, 30),
            background_normal="", background_color=(0,0,0,0),
            color=TH.primary)
        def draw_edit(w, *a):
            w.canvas.before.clear()
            with w.canvas.before:
                Color(*TH.primary)
                Line(rectangle=(w.x, w.y, w.width, w.height), width=0.8)
        edit_btn.bind(pos=draw_edit, size=draw_edit)
        edit_btn.recipe_id = recipe["id"]
        edit_btn.cat_id    = cat_id
        edit_btn.bind(on_press=self.show_edit_recipe)
        if get_mode() == "Admin":
            title_row.add_widget(edit_btn)
            title_row.add_widget(BoxLayout(size_hint_x=None, width=6))

        # Delete button
        del_btn = Button(
           text=L["btn_del"], font_size=10, bold=True,
           size_hint=(None, None), size=(44, 30),
           background_normal="", background_color=TH.red,
            color=TH.white)
        del_btn.recipe_id = recipe["id"]
        del_btn.cat_id    = cat_id
        del_btn.bind(on_press=self.confirm_delete_recipe)
        if get_mode() == "Admin":
            title_row.add_widget(del_btn)
            title_row.add_widget(BoxLayout(size_hint_x=None, width=10))

        card.add_widget(title_row)
        card.add_widget(divider())

        # ── Preview Row ──────────────────────────────────────────────────────
        preview_box = BoxLayout(
            orientation="horizontal",
            size_hint_y=None, height=48,
            padding=[14, 6], spacing=12)

        if "variants" in recipe and recipe["variants"]:
            for v in recipe["variants"]:
                vc    = TH.hot if v["type"] == "Hot" else TH.iced
                label = "HOT" if v["type"] == "Hot" else "ICED"
                ings  = [i for i in v["ingredients"] if i["amount"] > 0]

                v_col = BoxLayout(orientation="vertical",
                                  size_hint_y=None, height=36, spacing=2)
                v_col.add_widget(Label(
                    text=label, font_size=9, bold=True,
                    color=vc, halign="left",
                    size_hint_y=None, height=14,
                    text_size=(160, None)))
                preview_text = "  ".join(
                    [f"{int(i['amount']) if i['amount']==int(i['amount']) else i['amount']}{i['unit']} {i['name']}"
                     for i in ings[:2]])
                if len(ings) > 2:
                    preview_text += f"  +{len(ings)-2} more"
                v_col.add_widget(Label(
                    text=preview_text or "-",
                    font_size=9, color=TH.grey,
                    halign="left",
                    size_hint_y=None, height=18,
                    text_size=(160, None)))
                preview_box.add_widget(v_col)

        elif "steps" in recipe:
            preview_box.add_widget(Label(
                text=f"{len(recipe['steps'])} steps",
                font_size=TH.fs_small, color=TH.grey,
                halign="left", text_size=(300, None)))

        elif "parameters" in recipe:
            preview_box.add_widget(Label(
                text=f"{len(recipe['parameters'])} parameters",
                font_size=TH.fs_small, color=TH.grey,
                halign="left", text_size=(300, None)))

        card.add_widget(preview_box)
        return card

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