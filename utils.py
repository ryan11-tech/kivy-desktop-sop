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
    
def get_mode():
    return auth.get_mode()


def set_mode(mode):
    auth.set_mode(mode)


def check_admin_pin(entered):
    return auth.check_admin_pin(entered)