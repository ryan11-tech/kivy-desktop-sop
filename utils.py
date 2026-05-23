from kivy.uix.boxlayout import BoxLayout
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.graphics import Color, Rectangle, RoundedRectangle, Line

from services import auth, storage
from theme import TH, _hex_color


def load_data():
    return storage.load_recipes()


def save_data(data):
    storage.save_recipes(data)


def load_pin():
    return storage.load_pin()


def save_pin(data):
    storage.save_pin(data)

def set_bg(widget, color):
    widget.canvas.before.clear()
    with widget.canvas.before:
        Color(*color)
        rect = Rectangle(pos=widget.pos, size=widget.size)
    widget.bind(
        pos=lambda w,v: setattr(rect,"pos",v),
        size=lambda w,v: setattr(rect,"size",v))

def gold_line(height=1):
    from kivy.uix.widget import Widget
    d = BoxLayout(size_hint_y=None, height=height)
    try:
        with d.canvas:
            Color(*TH.primary)
            rect = Rectangle(pos=d.pos, size=d.size)
        d.bind(
            pos=lambda w, v: setattr(rect, "pos", v),
            size=lambda w, v: setattr(rect, "size", v))
    except Exception as e:
        print(f"gold_line error: {e}")
    return d

def divider():
    d = BoxLayout(size_hint_y=None, height=1)
    try:
        with d.canvas:
            Color(*TH.divider)
            rect = Rectangle(pos=d.pos, size=d.size)
        d.bind(
            pos=lambda w, v: setattr(rect, "pos", v),
            size=lambda w, v: setattr(rect, "size", v))
    except Exception as e:
        print(f"divider error: {e}")
    return d

def make_label(text, font_size=None, color=None, bold=False,
               halign="left", size_hint_y=None, height=40):
    color     = color or TH.white
    font_size = font_size or TH.fs_normal
    lbl = Label(
        text=text, font_size=font_size, color=color, bold=bold,
        halign=halign, valign="middle",
        size_hint_y=size_hint_y, height=height)
    
    # Update text_size when the label width changes to ensure proper wrapping/clipping
    lbl.bind(width=lambda w, v: setattr(w, 'text_size', (v, None)))
    return lbl

def card_box(padding=14, spacing=8):
    box = BoxLayout(
        orientation="vertical", padding=padding,
        spacing=spacing, size_hint_y=None)
    box.bind(minimum_height=box.setter("height"))
    with box.canvas.before:
        Color(*TH.card)
        box._rect = Rectangle(pos=box.pos, size=box.size)
    box.bind(
        pos=lambda w,v: setattr(w._rect,"pos",v),
        size=lambda w,v: setattr(w._rect,"size",v))
    return box

def gold_btn(text, height=50):
    btn = Button(
        text=text, size_hint_y=None, height=height,
        font_size=TH.fs_normal, bold=True,
        background_normal="",
        background_color=TH.primary,
        color=TH.gold_text)
    return btn

def ghost_btn(text, height=50):
    btn = Button(
        text=text, size_hint_y=None, height=height,
        font_size=TH.fs_normal, bold=True,
        background_normal="",
        background_color=(0,0,0,0),
        color=TH.primary)
    return btn

def danger_btn(text, height=50):
    btn = Button(
        text=text, size_hint_y=None, height=height,
        font_size=TH.fs_normal, bold=True,
        background_normal="",
        background_color=TH.red,
        color=TH.white)
    return btn

def outline_btn(text, height=50):
    btn = Button(
        text=text, size_hint_y=None, height=height,
        font_size=TH.fs_normal, bold=True,
        background_normal="",
        background_color=(0,0,0,0),
        color=TH.grey)

    def draw_outline(w, *a):
        w.canvas.before.clear()
        with w.canvas.before:
            Color(*TH.divider)
            Line(rectangle=(w.x+1, w.y+1, w.width-2, w.height-2), width=1)
    btn.bind(pos=draw_outline, size=draw_outline)
    return btn

def styled_btn(text, color=None, height=50):
    """Flexible button — color sets the text color."""
    btn = Button(
        text=text, size_hint_y=None, height=height,
        font_size=TH.fs_normal, bold=True,
        background_normal="",
        background_color=TH.card,
        color=color or TH.white)
    return btn

def section_label(text, height=28):
    return make_label(
        text, font_size=TH.fs_small,
        color=TH.grey, bold=True, height=height)


def spacer(h=8):
    return BoxLayout(size_hint_y=None, height=h)


def hspacer(w=8):
    return BoxLayout(size_hint_x=None, width=w)


def fill_rounded(widget, color, radius=12, border_color=None, border_width=1.0):
    """Persist a rounded background that resizes with the widget."""
    widget.canvas.before.clear()
    with widget.canvas.before:
        widget._fill_color = Color(*color)
        widget._fill_rect = RoundedRectangle(
            pos=widget.pos, size=widget.size, radius=[radius])
        if border_color is not None:
            widget._border_color = Color(*border_color)
            widget._border_line = Line(
                rounded_rectangle=(widget.x, widget.y, widget.width, widget.height, radius),
                width=border_width)

    def _redraw(w, *_):
        w._fill_rect.pos = w.pos
        w._fill_rect.size = w.size
        if hasattr(w, "_border_line"):
            w._border_line.rounded_rectangle = (w.x, w.y, w.width, w.height, radius)
    widget.bind(pos=_redraw, size=_redraw)
    return widget


def chip(text, fg=None, bg=None, padding=(10, 4), font_size=None, bold=True):
    """Small rounded label, e.g. SOP / HOT / ICED type indicator."""
    fg = fg or TH.gold_text
    bg = bg or TH.primary
    fs = font_size or 10
    pad_x, pad_y = padding
    lbl = Label(
        text=text, font_size=fs, bold=bold, color=fg,
        size_hint=(None, None), height=22 + pad_y * 2,
        halign="center", valign="middle")
    lbl.bind(texture_size=lambda w, v: setattr(
        w, "width", v[0] + pad_x * 2))
    fill_rounded(lbl, bg, radius=11)
    return lbl


def rounded_card(padding=16, spacing=8, bg=None, border=None, radius=14):
    bg = bg or TH.card
    box = BoxLayout(
        orientation="vertical", padding=padding,
        spacing=spacing, size_hint_y=None)
    box.bind(minimum_height=box.setter("height"))
    fill_rounded(box, bg, radius=radius, border_color=border)
    return box


def icon_btn(text, on_press=None, size=(44, 44), font=None, fg=None, bg=None,
             font_size=18, radius=12, bold=True):
    """Compact tappable icon/text button with rounded bg."""
    btn = Button(
        text=text, font_size=font_size, bold=bold,
        size_hint=(None, None), size=size,
        background_normal="", background_color=(0, 0, 0, 0),
        color=fg or TH.primary,
        halign="center", valign="middle")
    if font:
        btn.font_name = font
    fill_rounded(btn, bg or TH.card, radius=radius)
    if on_press:
        btn.bind(on_press=on_press)
    return btn


def screen_header(title, on_back=None, right=None, height=56):
    """Consistent top bar: optional back arrow, centered title, optional right widget."""
    bar = BoxLayout(
        size_hint_y=None, height=height,
        padding=[12, 6], spacing=8)
    set_bg(bar, TH.bg)
    if on_back:
        back = icon_btn("<", on_press=lambda *_: on_back(),
                        size=(40, 40), fg=TH.primary,
                        bg=TH.card, font_size=20)
        bar.add_widget(back)
    else:
        bar.add_widget(BoxLayout(size_hint=(None, None), size=(40, 40)))
    title_lbl = Label(
        text=title, font_size=TH.fs_large, bold=True,
        color=TH.primary, halign="center", valign="middle")
    bar.add_widget(title_lbl)
    if right is not None:
        bar.add_widget(right)
    else:
        bar.add_widget(BoxLayout(size_hint=(None, None), size=(40, 40)))
    return bar


def pill_tab_row(options, active_value, on_select, height=42, spacing=6):
    """Segmented control. options: list of (value, label, accent_color or None)."""
    row = BoxLayout(size_hint_y=None, height=height, spacing=spacing)
    for value, label, accent in options:
        is_sel = (value == active_value)
        accent = accent or TH.primary
        btn = Button(
            text=label, font_size=TH.fs_small, bold=True,
            background_normal="", background_color=(0, 0, 0, 0),
            color=TH.gold_text if is_sel else TH.grey,
            size_hint_y=None, height=height)
        btn.tab_value = value
        bg_col = accent if is_sel else TH.card
        fill_rounded(btn, bg_col, radius=height // 2)
        btn.bind(on_press=lambda b, *_: on_select(b.tab_value))
        row.add_widget(btn)
    return row


def stepper(value_text, on_minus, on_plus, on_reset=None, label_text=None):
    """Big +/- with prominent number. Used for serving multiplier."""
    box = BoxLayout(
        size_hint_y=None, height=64,
        padding=[12, 8], spacing=10)
    fill_rounded(box, TH.card2, radius=14)
    if label_text:
        box.add_widget(Label(
            text=label_text, font_size=TH.fs_small,
            color=TH.grey, halign="left", valign="middle",
            size_hint=(None, None), size=(80, 48)))
    minus = icon_btn("-", on_press=lambda *_: on_minus(),
                     size=(44, 44), fg=TH.primary, bg=TH.bg,
                     font_size=24)
    val = Label(
        text=value_text, font_size=24, bold=True,
        color=TH.primary, halign="center", valign="middle",
        size_hint=(1, None), height=44)
    plus = icon_btn("+", on_press=lambda *_: on_plus(),
                    size=(44, 44), fg=TH.gold_text, bg=TH.primary,
                    font_size=24)
    box.add_widget(minus)
    box.add_widget(val)
    box.add_widget(plus)
    if on_reset:
        reset = icon_btn("Reset", on_press=lambda *_: on_reset(),
                         size=(58, 44), fg=TH.grey, bg=TH.bg,
                         font_size=11, radius=10)
        box.add_widget(reset)
    return box, val


def stat_row(name, value, unit, alt_bg=False, accent=None):
    """Table row for parameters/ingredients with prominent numeric column."""
    accent = accent or TH.primary
    row = BoxLayout(size_hint_y=None, height=48, padding=[14, 4], spacing=8)
    if alt_bg:
        with row.canvas.before:
            Color(1, 1, 1, 0.03)
            rect = Rectangle(pos=row.pos, size=row.size)
        row.bind(
            pos=lambda w, v: setattr(rect, "pos", v),
            size=lambda w, v: setattr(rect, "size", v))
    name_lbl = Label(
        text=name, font_size=TH.fs_normal,
        color=TH.text_main, halign="left", valign="middle",
        size_hint_x=0.55)
    name_lbl.bind(width=lambda w, v: setattr(w, "text_size", (v, None)))
    val_lbl = Label(
        text=str(value), font_size=20, bold=True,
        color=accent, halign="right", valign="middle",
        size_hint_x=0.28)
    val_lbl.bind(width=lambda w, v: setattr(w, "text_size", (v, None)))
    unit_lbl = Label(
        text=unit, font_size=TH.fs_small,
        color=TH.grey, halign="left", valign="middle",
        size_hint_x=0.17)
    unit_lbl.bind(width=lambda w, v: setattr(w, "text_size", (v, None)))
    row.add_widget(name_lbl)
    row.add_widget(val_lbl)
    row.add_widget(unit_lbl)
    return row


def step_item(num, text):
    """Numbered step row. Number circle + wrapping text."""
    row = BoxLayout(
        orientation="horizontal",
        size_hint_y=None, spacing=12,
        padding=[4, 8])
    row.bind(minimum_height=row.setter("height"))
    circle = Label(
        text=str(num), font_size=14, bold=True,
        color=TH.gold_text,
        size_hint=(None, None), size=(32, 32),
        halign="center", valign="middle")
    fill_rounded(circle, TH.primary, radius=16)
    txt = Label(
        text=text, font_size=TH.fs_normal,
        color=TH.text_main, halign="left", valign="top",
        size_hint_y=None)
    txt.bind(
        width=lambda w, v: setattr(w, "text_size", (v, None)),
        texture_size=lambda w, v: setattr(w, "height", max(v[1] + 6, 32)))
    row.add_widget(circle)
    row.add_widget(txt)
    return row


def bottom_nav(items, active_key, on_select, height=64):
    """Bottom nav bar. items: list of (key, icon_text, label)."""
    bar = BoxLayout(
        size_hint_y=None, height=height,
        padding=[6, 6], spacing=4)
    set_bg(bar, TH.header_bg)
    for key, icon, label in items:
        is_sel = (key == active_key)
        col = TH.primary if is_sel else TH.grey
        cell = BoxLayout(orientation="vertical", spacing=2)
        ic = Button(
            text=icon, font_size=18, bold=True,
            background_normal="", background_color=(0, 0, 0, 0),
            color=col, size_hint_y=None, height=28)
        lb = Label(
            text=label, font_size=10, bold=is_sel,
            color=col, size_hint_y=None, height=18,
            halign="center", valign="middle")
        ic.nav_key = key
        ic.bind(on_press=lambda b, *_: on_select(b.nav_key))
        cell.add_widget(ic)
        cell.add_widget(lb)
        bar.add_widget(cell)
    return bar


def type_chip_for_recipe(recipe):
    """Map recipe type → small label chip."""
    rtype = recipe.get("type") or (
        "drink" if "variants" in recipe else
        "sop" if "parameters" in recipe else "steps")
    if rtype == "drink":
        return chip("DRINK", fg=TH.gold_text, bg=TH.primary)
    if rtype == "sop":
        return chip("SOP", fg=TH.gold_text, bg=TH.primary)
    return chip("STEPS", fg=TH.white, bg=TH.card2)
    
def get_mode():
    return auth.get_mode()


def set_mode(mode):
    auth.set_mode(mode)


def check_admin_pin(entered):
    return auth.check_admin_pin(entered)

def make_bottom_nav(manager, active="home"):
    outer = BoxLayout(orientation="vertical", size_hint_y=None, height=58)
    top_line = BoxLayout(size_hint_y=None, height=1)
    with top_line.canvas.before:
        Color(*TH.primary)
        tl_rect = Rectangle(pos=top_line.pos, size=top_line.size)
    top_line.bind(
        pos=lambda w,v: setattr(tl_rect,"pos",v),
        size=lambda w,v: setattr(tl_rect,"size",v))
    bar = BoxLayout(size_hint_y=None, height=57)
    with bar.canvas.before:
        Color(*TH.card)
        bar_rect = Rectangle(pos=bar.pos, size=bar.size)
    bar.bind(
        pos=lambda w,v: setattr(bar_rect,"pos",v),
        size=lambda w,v: setattr(bar_rect,"size",v))
    nav_items = [
        ("HOME",     "home"),
        ("FAV",      "favorites"),
        ("SCHEDULE", "schedule"),
        ("SETTINGS", "settings"),
    ]
    for label, key in nav_items:
        is_sel = (key == active)
        col    = TH.primary if is_sel else TH.grey
        btn = Button(
            text=label, font_size=9, bold=is_sel,
            background_normal="", background_color=(0,0,0,0),
            color=col)
        btn.nav_key = key
        btn.bind(on_press=lambda b, m=manager: _nav_go(b.nav_key, m))
        bar.add_widget(btn)
    outer.add_widget(top_line)
    outer.add_widget(bar)
    return outer


def _nav_go(key, manager):
    if key == "settings":
        manager.transition.direction = "left"
        manager.current = "settings"
    elif key == "schedule":
        manager.transition.direction = "left"
        manager.current = "schedule"
    elif key == "home":
        home = manager.get_screen("home")
        home.nav_mode = "home"
        manager.transition.direction = "right"
        manager.current = "home"
    elif key == "favorites":
        home = manager.get_screen("home")
        home.nav_mode = "favorites"
        manager.transition.direction = "right"
        manager.current = "home" 