"""Unified recipe Add/Edit popup. Used by category_screen and recipe_screen.

Design: no type selector. All sections always visible (Parameters, Hot, Iced,
Steps). User fills whatever applies. Type derived on save.
"""
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup

from services import recipes as recipes_svc
from theme import TH
from utils import (set_bg, fill_rounded, divider, make_label, spacer,
                   gold_btn, ghost_btn, danger_btn, section_label)


def _ings_to_text(ings):
    out = []
    for i in ings:
        amt = i["amount"]
        a = int(amt) if amt == int(amt) else amt
        out.append(f"{i['name']},{a},{i['unit']}")
    return "\n".join(out)


def _input(text="", hint="", height=44, multiline=False):
    return TextInput(
        text=text, hint_text=hint,
        multiline=multiline, size_hint_y=None, height=height,
        font_size=TH.fs_small,
        background_color=TH.input_bg,
        foreground_color=TH.text_main,
        cursor_color=TH.primary,
        padding=[10, 10])


def _derive_type(params, hot, iced, steps):
    if hot or iced:
        return "drink"
    if params:
        return "sop"
    return "steps"


def show_recipe_form(cat_id, recipe=None, on_done=None):
    """Open Add (recipe=None) or Edit (recipe=dict) popup. Calls on_done() after save/delete."""
    is_edit = recipe is not None

    # Seed initial textarea content from recipe.
    init = {"parameters": "", "steps": "", "hot": "", "iced": ""}
    if is_edit:
        init["parameters"] = _ings_to_text(recipe.get("parameters", []))
        init["steps"] = "\n".join(recipe.get("steps", []))
        for v in recipe.get("variants", []):
            if v["type"] == "Hot":
                init["hot"] = _ings_to_text(v["ingredients"])
            elif v["type"] == "Iced":
                init["iced"] = _ings_to_text(v["ingredients"])

    scroll = ScrollView()
    inner = BoxLayout(
        orientation="vertical", spacing=8,
        padding=16, size_hint_y=None)
    inner.bind(minimum_height=inner.setter("height"))
    set_bg(inner, TH.bg)

    # Name
    inner.add_widget(section_label("RECIPE NAME *", height=22))
    name_in = _input(
        text=recipe["name"] if is_edit else "",
        hint="e.g. Myanmar Milk Tea")
    inner.add_widget(name_in)
    inner.add_widget(spacer(4))

    # Image
    inner.add_widget(section_label("IMAGE PATH (optional)", height=22))
    img_in = _input(
        text=recipe.get("image", "") if is_edit else "",
        hint="e.g. assets/recipes/foo.jpg")
    inner.add_widget(img_in)
    browse = ghost_btn("Browse...", height=36)

    def do_browse(*_):
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
    browse.bind(on_press=do_browse)
    inner.add_widget(browse)
    inner.add_widget(spacer(10))

    # Hint banner
    inner.add_widget(make_label(
        "Fill any sections that apply. Empty sections are ignored.",
        color=TH.grey, font_size=11, halign="left", height=20))
    inner.add_widget(spacer(4))

    # All four sections always visible
    inner.add_widget(section_label(
        "PARAMETERS  (name,amount,unit per line)", height=22))
    params_in = _input(text=init["parameters"],
                       hint="Water Volume,1200,ml\nTea Powder,100,g",
                       height=110, multiline=True)
    inner.add_widget(params_in)
    inner.add_widget(spacer(6))

    inner.add_widget(section_label(
        "HOT INGREDIENTS  (name,amount,unit per line)", height=22))
    hot_in = _input(text=init["hot"],
                    hint="Black Tea,150,ml",
                    height=100, multiline=True)
    inner.add_widget(hot_in)
    inner.add_widget(spacer(6))

    inner.add_widget(section_label(
        "ICED INGREDIENTS  (name,amount,unit per line)", height=22))
    iced_in = _input(text=init["iced"],
                     hint="Black Tea,180,ml",
                     height=100, multiline=True)
    inner.add_widget(iced_in)
    inner.add_widget(spacer(6))

    inner.add_widget(section_label("STEPS  (one per line)", height=22))
    steps_in = _input(text=init["steps"],
                      hint="Step 1\nStep 2",
                      height=120, multiline=True)
    inner.add_widget(steps_in)
    inner.add_widget(spacer(10))

    # Action buttons
    btn_row = BoxLayout(size_hint_y=None, height=44, spacing=8)
    save_btn = gold_btn("Save", height=44)
    cancel_btn = ghost_btn("Cancel", height=44)
    btn_row.add_widget(save_btn)
    btn_row.add_widget(cancel_btn)
    inner.add_widget(btn_row)

    if is_edit:
        del_btn = danger_btn("Delete Recipe", height=40)
        inner.add_widget(spacer(6))
        inner.add_widget(del_btn)

    err_lbl = make_label("", color=TH.red, height=22, halign="center",
                        font_size=11)
    inner.add_widget(err_lbl)

    scroll.add_widget(inner)

    title = "Edit Recipe" if is_edit else "Add Recipe"
    popup = Popup(
        title=title, content=scroll,
        size_hint=(0.95, 0.9),
        background_color=TH.card,
        separator_color=TH.primary)

    def do_save(*_):
        name = name_in.text.strip()
        if not name:
            err_lbl.text = "Name required."
            return
        params = recipes_svc.parse_ingredients(params_in.text)
        hot    = recipes_svc.parse_ingredients(hot_in.text)
        iced   = recipes_svc.parse_ingredients(iced_in.text)
        steps  = [s.strip() for s in steps_in.text.splitlines() if s.strip()]
        rtype  = _derive_type(params, hot, iced, steps)
        patch = {
            "name":       name,
            "type":       rtype,
            "image":      img_in.text.strip(),
            "parameters": params,
            "steps":      steps,
            "variants":   ([{"type": "Hot",  "ingredients": hot},
                            {"type": "Iced", "ingredients": iced}]
                           if rtype == "drink" else []),
        }
        try:
            if is_edit:
                recipes_svc.update_recipe(cat_id, recipe["id"], patch)
            else:
                recipes_svc.add_recipe(cat_id, patch)
        except (ValueError, KeyError) as e:
            err_lbl.text = str(e)
            return
        popup.dismiss()
        if on_done:
            on_done()

    def do_delete(*_):
        if not is_edit:
            return
        recipes_svc.delete_recipe(cat_id, recipe["id"])
        popup.dismiss()
        if on_done:
            on_done()

    save_btn.bind(on_press=do_save)
    cancel_btn.bind(on_press=popup.dismiss)
    if is_edit:
        del_btn.bind(on_press=do_delete)

    popup.open()
    return popup
