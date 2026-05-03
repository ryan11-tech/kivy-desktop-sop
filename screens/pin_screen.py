from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.clock import Clock
from kivy.graphics import Color, Line, RoundedRectangle

from theme import TH
from lang import L
from utils import set_bg, fill_rounded, load_pin


class PINScreen(Screen):
    def __init__(self, **kw):
        super().__init__(**kw)
        self.entered = ""

    def on_enter(self):
        try:
            self.entered = ""
            self.build_ui()
        except Exception as e:
            import traceback
            print("PIN on_enter ERROR:", e)
            traceback.print_exc()

    def build_ui(self):
        self.clear_widgets()
        root = BoxLayout(orientation="vertical")
        set_bg(root, TH.bg)

        root.add_widget(BoxLayout(size_hint_y=None, height=60))

        # Brand
        logo = BoxLayout(
            size_hint=(None, None), size=(72, 72),
            pos_hint={"center_x": 0.5})
        fill_rounded(logo, TH.primary, radius=18)
        logo.add_widget(Label(
            text="T", font_size=32, bold=True,
            color=TH.gold_text,
            halign="center", valign="middle"))
        root.add_widget(logo)

        root.add_widget(BoxLayout(size_hint_y=None, height=18))
        root.add_widget(Label(
            text=L.get("app_title", "Tea SOP"),
            font_size=22, bold=True,
            color=TH.text_main,
            size_hint_y=None, height=30,
            halign="center"))
        root.add_widget(Label(
            text=L.get("pin_enter", "Enter PIN to continue"),
            font_size=12, color=TH.grey,
            size_hint_y=None, height=22,
            halign="center"))

        root.add_widget(BoxLayout(size_hint_y=None, height=28))

        # PIN dots
        pin_data = load_pin()
        pin_len = len(pin_data.get("pin", "1234"))
        dot_wrap = BoxLayout(
            size_hint=(None, None), height=32,
            width=pin_len * 32 + (pin_len - 1) * 18,
            pos_hint={"center_x": 0.5},
            spacing=18)
        self.dots = []
        for _ in range(pin_len):
            dot = BoxLayout(
                size_hint=(None, None), size=(16, 16),
                pos_hint={"center_y": 0.5})
            with dot.canvas.before:
                dot.color_instr = Color(1, 1, 1, 0.18)
                dot.rect_instr = RoundedRectangle(
                    pos=dot.pos, size=dot.size, radius=[8])
            dot.bind(
                pos=lambda w, v: setattr(w.rect_instr, "pos", v),
                size=lambda w, v: setattr(w.rect_instr, "size", v))
            dot_wrap.add_widget(dot)
            self.dots.append(dot)
        root.add_widget(dot_wrap)
        self._refresh_dots()

        # Error
        self.error_lbl = Label(
            text="", font_size=12, color=TH.red,
            size_hint_y=None, height=28,
            halign="center")
        root.add_widget(BoxLayout(size_hint_y=None, height=8))
        root.add_widget(self.error_lbl)

        root.add_widget(BoxLayout(size_hint_y=None, height=12))

        # Keypad
        pad = BoxLayout(
            orientation="vertical",
            size_hint=(None, None), size=(300, 320),
            pos_hint={"center_x": 0.5},
            spacing=12)

        keypad = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["CLR", "0", "DEL"],
        ]
        for row_keys in keypad:
            row = BoxLayout(spacing=12, size_hint_y=None, height=72)
            for key in row_keys:
                btn = self._key_btn(key)
                row.add_widget(btn)
            pad.add_widget(row)

        root.add_widget(pad)
        root.add_widget(BoxLayout())
        self.add_widget(root)

    def _key_btn(self, key):
        if key == "CLR":
            text = L.get("pin_clr", "CLR")
            font_size = 13
            fg = TH.red
            bg = TH.card
        elif key == "DEL":
            text = L.get("pin_del", "DEL")
            font_size = 13
            fg = TH.red
            bg = TH.card
        else:
            text = key
            font_size = 26
            fg = TH.text_main
            bg = TH.card

        btn = Button(
            text=text, font_size=font_size, bold=True,
            background_normal="", background_color=(0, 0, 0, 0),
            color=fg)
        fill_rounded(btn, bg, radius=36, border_color=(1, 1, 1, 0.06))
        btn.key = key
        btn.bind(on_press=self.on_key)
        return btn

    def _refresh_dots(self):
        if not hasattr(self, "dots"):
            return
        for i, dot in enumerate(self.dots):
            filled = i < len(self.entered)
            dot.color_instr.rgba = TH.primary if filled else (1, 1, 1, 0.18)

    def on_key(self, btn):
        # Tap feedback
        old = btn._fill_color.rgba[:]
        btn._fill_color.rgba = (TH.primary[0], TH.primary[1], TH.primary[2], 0.25)
        Clock.schedule_once(lambda *_: setattr(btn._fill_color, "rgba", old), 0.08)

        key = btn.key
        pin_data = load_pin()
        correct = pin_data.get("pin", "1234")

        if key == "CLR":
            self.entered = ""
            self.error_lbl.text = ""
        elif key == "DEL":
            self.entered = self.entered[:-1]
            self.error_lbl.text = ""
        else:
            if len(self.entered) < len(correct):
                self.entered += key

        self._refresh_dots()

        if len(self.entered) == len(correct):
            if self.entered == correct:
                self.entered = ""
                self.manager.current = "home"
            else:
                self.error_lbl.text = L.get("pin_wrong", "Wrong PIN. Try again.")
                self.entered = ""
                self._refresh_dots()
