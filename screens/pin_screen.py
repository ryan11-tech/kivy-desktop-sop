from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.uix.button import Button
from kivy.clock import Clock
from kivy.graphics import Color, Rectangle, Line, RoundedRectangle
from theme import TH
from lang import L
from utils import set_bg, gold_line, load_pin


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
        root.add_widget(gold_line(2))
        root.add_widget(BoxLayout(size_hint_y=None, height=40))

        root.add_widget(Label(
            text=L.get("app_title", "TEA SOP"),
            font_size=32, bold=True,
            color=TH.primary,
            size_hint_y=None, height=60,
            halign="center"))
        root.add_widget(Label(
            text=L.get("pin_enter", "Enter PIN"),
            font_size=14, color=TH.grey,
            size_hint_y=None, height=30,
            halign="center"))

        root.add_widget(BoxLayout(size_hint_y=None, height=30))

        # PIN dots row
        self.dot_row = BoxLayout(
            size_hint_y=None, height=60,
            size_hint_x=None, width=250,
            pos_hint={"center_x": 0.5},
            spacing=24)
        root.add_widget(self.dot_row)

        # Create dots (iOS Style Glass)
        self.dots = []
        pin_data = load_pin()
        pin_len  = len(pin_data.get("pin", "1234"))
        for i in range(pin_len):
            dot_container = BoxLayout(size_hint=(None, None), size=(20, 20),
                                     pos_hint={"center_y": 0.5})
            with dot_container.canvas.before:
                # Glass background for inactive
                dot_container.color_instr = Color(1, 1, 1, 0.1)
                dot_container.rect_instr  = RoundedRectangle(pos=dot_container.pos, 
                                                           size=dot_container.size, radius=[10])
                # Subtle border
                Color(1, 1, 1, 0.15)
                dot_container.line_instr = Line(rounded_rectangle=(dot_container.x, dot_container.y, 
                                                                  dot_container.width, dot_container.height, 10), width=1.1)
            
            def update_dot(w, *a):
                w.rect_instr.pos = w.pos
                w.rect_instr.size = w.size
                w.line_instr.rounded_rectangle = (w.x, w.y, w.width, w.height, 10)
            dot_container.bind(pos=update_dot, size=update_dot)
            
            self.dot_row.add_widget(dot_container)
            self.dots.append(dot_container)

        self._refresh_dots()

        # Error label
        self.error_lbl = Label(
            text="", font_size=TH.fs_small,
            color=TH.red,
            size_hint_y=None, height=30,
            halign="center")
        root.add_widget(self.error_lbl)
        root.add_widget(BoxLayout(size_hint_y=None, height=20))

        # Keypad
        pad = BoxLayout(
            orientation="vertical",
            size_hint_y=None, height=280,
            size_hint_x=None, width=280,
            pos_hint={"center_x": 0.5},
            spacing=10)

        buttons = [
            ["1", "2", "3"],
            ["4", "5", "6"],
            ["7", "8", "9"],
            ["CLR", "0", "DEL"],
        ]

        def apply_glass_style(btn, glass_color=(1, 1, 1, 0.08), border_color=(1, 1, 1, 0.12)):
            with btn.canvas.before:
                # Main Glass background
                btn.glass_bg = Color(*glass_color)
                btn.glass_rect = RoundedRectangle(pos=btn.pos, size=btn.size, radius=[30])
                # Subtle highlight border
                btn.glass_border_color = Color(*border_color)
                btn.glass_border = Line(rounded_rectangle=(btn.x, btn.y, btn.width, btn.height, 30), width=1.1)
            
            def update_glass(w, *a):
                w.glass_rect.pos = w.pos
                w.glass_rect.size = w.size
                w.glass_border.rounded_rectangle = (w.x, w.y, w.width, w.height, 30)
            btn.bind(pos=update_glass, size=update_glass)

        for row_keys in buttons:
            row = BoxLayout(spacing=18, size_hint_y=None, height=65)
            for key in row_keys:
                if key == "CLR":
                    btn = Button(
                        text=L.get("pin_clr", "CLR"), font_size=14, bold=False,
                        background_normal="", background_color=(0,0,0,0),
                        color=TH.white)
                    apply_glass_style(btn, glass_color=(0.3, 0.1, 0.1, 0.25), border_color=TH.primary)
                elif key == "DEL":
                    btn = Button(
                        text=L.get("pin_del", "DEL"), font_size=14, bold=False,
                        background_normal="", background_color=(0,0,0,0),
                        color=TH.white)
                    apply_glass_style(btn, glass_color=(0.3, 0.1, 0.1, 0.25), border_color=TH.primary)
                else:
                    btn = Button(
                        text=key, font_size=24, bold=False,
                        background_normal="", background_color=(0,0,0,0),
                        color=TH.white)
                    apply_glass_style(btn)
                btn.key = key
                btn.bind(on_press=self.on_key)
                row.add_widget(btn)
            pad.add_widget(row)

        root.add_widget(pad)
        root.add_widget(BoxLayout())
        root.add_widget(gold_line(2))
        self.add_widget(root)

    def _refresh_dots(self):
        if not hasattr(self, 'dots'): return
        for i, dot in enumerate(self.dots):
            filled = i < len(self.entered)
            # Glass style but with Red (Primary) feedback
            if filled:
                dot.color_instr.rgba = TH.primary
            else:
                dot.color_instr.rgba = (1, 1, 1, 0.1)
            
    def on_key(self, btn):
        # Visual feedback on press
        old_color = btn.glass_bg.rgba[:]
        btn.glass_bg.rgba = (1, 1, 1, 0.2)
        def reset_color(*a):
            btn.glass_bg.rgba = old_color
        Clock.schedule_once(reset_color, 0.1)

        key      = btn.key
        pin_data = load_pin()
        correct  = pin_data.get("pin", "1234")

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