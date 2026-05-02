from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.label import Label
from kivy.clock import Clock
from kivy.graphics import Color, Rectangle, RoundedRectangle
from theme import TH
from utils import load_pin


class SplashScreen(Screen):
    def __init__(self, **kw):
        super().__init__(**kw)
        self._clock_event = None

    def on_enter(self):
        self._step = 0
        self.clear_widgets()
        root = BoxLayout(orientation="vertical")

        with root.canvas.before:
            Color(*TH.bg)
            self._bg = Rectangle(pos=root.pos, size=root.size)
        root.bind(pos=lambda w,v: setattr(self._bg,"pos",v),
                  size=lambda w,v: setattr(self._bg,"size",v))

        root.add_widget(BoxLayout())

        logo_box = BoxLayout(
            size_hint=(None, None), size=(110, 110),
            pos_hint={"center_x": 0.5})
        with logo_box.canvas.before:
            Color(*TH.primary)
            RoundedRectangle(pos=logo_box.pos,
                             size=logo_box.size, radius=[18])
        logo_box.bind(
            pos=lambda w,v: self._redraw_logo(w),
            size=lambda w,v: self._redraw_logo(w))
        logo_box.add_widget(Label(
            text="TEA\nSOP",
            font_size=26, bold=True,
            color=(0.05, 0.05, 0.05, 1),
            halign="center", valign="middle"))
        root.add_widget(logo_box)

        root.add_widget(BoxLayout(size_hint_y=None, height=20))
        root.add_widget(Label(
            text="Quality Control Guide",
            font_size=13, color=TH.grey,
            size_hint_y=None, height=28,
            halign="center"))
        root.add_widget(BoxLayout(size_hint_y=None, height=30))

        track = BoxLayout(
            size_hint=(None, None), size=(220, 6),
            pos_hint={"center_x": 0.5})
        with track.canvas.before:
            Color(*TH.card2)
            RoundedRectangle(pos=track.pos,
                             size=track.size, radius=[3])
        track.bind(
            pos=lambda w,v: self._redraw_track(w),
            size=lambda w,v: self._redraw_track(w))

        self._bar = BoxLayout(
            size_hint=(None, None), size=(0, 6),
            pos_hint={"center_x": 0.5})
        with self._bar.canvas.before:
            Color(*TH.primary)
            self._bar_rect = RoundedRectangle(
                pos=self._bar.pos,
                size=self._bar.size, radius=[3])
        self._bar.bind(
            pos=lambda w,v: setattr(self._bar_rect,"pos",v),
            size=lambda w,v: setattr(self._bar_rect,"size",v))

        root.add_widget(track)
        root.add_widget(BoxLayout(size_hint_y=None, height=4))
        root.add_widget(self._bar)
        root.add_widget(BoxLayout(size_hint_y=None, height=12))
        root.add_widget(Label(
            text="v2.0", font_size=10,
            color=(1,1,1,0.3),
            size_hint_y=None, height=20,
            halign="center"))

        root.add_widget(BoxLayout())
        self.add_widget(root)

        self._clock_event = Clock.schedule_interval(self._tick, 0.17)

    def _redraw_logo(self, w):
        w.canvas.before.clear()
        with w.canvas.before:
            Color(*TH.primary)
            RoundedRectangle(pos=w.pos, size=w.size, radius=[18])

    def _redraw_track(self, w):
        w.canvas.before.clear()
        with w.canvas.before:
            Color(*TH.card2)
            RoundedRectangle(pos=w.pos, size=w.size, radius=[3])

    def _tick(self, dt):
        self._step += 1
        self._bar.width = min(self._step * 9, 220)
        if self._step >= 25:
            if self._clock_event:
                self._clock_event.cancel()
                self._clock_event = None
            Clock.schedule_once(self.go_next, 0.2)

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
        except:
            self.manager.current = "home"