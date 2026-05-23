from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.clock import Clock
from kivy.graphics import Color, RoundedRectangle

from theme import TH
from utils import set_bg, fill_rounded, load_pin


class SplashScreen(Screen):
    def __init__(self, **kw):
        super().__init__(**kw)
        self._clock_event = None

    def on_enter(self):
        self._step = 0
        self.clear_widgets()

        root = BoxLayout(orientation="vertical")
        set_bg(root, TH.bg)

        root.add_widget(BoxLayout())  # top spacer

        logo = BoxLayout(
            size_hint=(None, None), size=(120, 120),
            pos_hint={"center_x": 0.5})
        fill_rounded(logo, TH.primary, radius=28)
        logo.add_widget(Label(
            text="TEA\nSOP",
            font_size=28, bold=True,
            color=TH.gold_text,
            halign="center", valign="middle"))
        root.add_widget(logo)

        root.add_widget(BoxLayout(size_hint_y=None, height=24))
        root.add_widget(Label(
            text="Tea SOP",
            font_size=22, bold=True,
            color=TH.text_main,
            size_hint_y=None, height=32,
            halign="center"))
        root.add_widget(Label(
            text="Quality Control Guide",
            font_size=12, color=TH.grey,
            size_hint_y=None, height=20,
            halign="center"))

        root.add_widget(BoxLayout(size_hint_y=None, height=40))

        track = BoxLayout(
            size_hint=(None, None), size=(180, 4),
            pos_hint={"center_x": 0.5})
        fill_rounded(track, (1, 1, 1, 0.10), radius=2)
        root.add_widget(track)

        bar_wrap = BoxLayout(
            size_hint=(None, None), size=(180, 4),
            pos_hint={"center_x": 0.5})
        self._bar = BoxLayout(
            size_hint=(None, None), size=(0, 4))
        with self._bar.canvas.before:
            Color(*TH.primary)
            self._bar_rect = RoundedRectangle(
                pos=self._bar.pos, size=self._bar.size, radius=[2])
        self._bar.bind(
            pos=lambda w, v: setattr(self._bar_rect, "pos", v),
            size=lambda w, v: setattr(self._bar_rect, "size", v))
        bar_wrap.add_widget(self._bar)
        root.add_widget(BoxLayout(size_hint_y=None, height=2))
        root.add_widget(bar_wrap)

        root.add_widget(BoxLayout())  # bottom spacer
        root.add_widget(Label(
            text="v2.0",
            font_size=10, color=(1, 1, 1, 0.3),
            size_hint_y=None, height=24,
            halign="center"))
        root.add_widget(BoxLayout(size_hint_y=None, height=12))

        self.add_widget(root)
        self._clock_event = Clock.schedule_interval(self._tick, 0.05)

    def _tick(self, dt):
        self._step += 1
        self._bar.width = min(self._step * 9, 180)
        if self._bar.width >= 180:
            if self._clock_event:
                self._clock_event.cancel()
                self._clock_event = None
            Clock.schedule_once(self.go_next, 0.15)

    def on_leave(self):
        if self._clock_event:
            self._clock_event.cancel()
            self._clock_event = None

    def go_next(self, *args):
        try:
            from utils import set_mode
            set_mode("Staff")
            pin_data = load_pin()
            if pin_data.get("enabled", True):
                self.manager.current = "pin"
            else:
                self.manager.current = "home"
        except Exception:
            self.manager.current = "home"
