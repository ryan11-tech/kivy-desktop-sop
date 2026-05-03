import os

from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.spinner import Spinner
from kivy.uix.popup import Popup
from kivy.graphics import Color, Rectangle

from theme import TH, load_theme, save_theme, PRESETS, BG_PRESETS, LIGHT_BG_PRESETS
from lang import L, load_lang, save_lang, reload_lang
from utils import (set_bg, fill_rounded, divider, make_label, spacer,
                   gold_btn, ghost_btn, icon_btn, chip, _hex_color,
                   load_pin, save_pin)

CUR_DIR = os.path.dirname(os.path.abspath(__file__))
FA_FONT = os.path.join(os.path.dirname(CUR_DIR), "assets", "fa-solid-900.ttf")


class SettingsScreen(Screen):
    def on_enter(self):
        self.build_ui()

    def build_ui(self):
        self.clear_widgets()
        t = load_theme()
        pin_data = load_pin()
        pin_on = pin_data.get("enabled", True)

        root = BoxLayout(orientation="vertical")
        set_bg(root, TH.bg)

        # ── Top bar ─────────────────────────────────────────────────────
        top = BoxLayout(size_hint_y=None, height=64, padding=[14, 10], spacing=10)
        set_bg(top, TH.bg)
        back = icon_btn("<",
                        on_press=lambda *_: setattr(self.manager, "current", "home"),
                        size=(44, 40),
                        fg=TH.text_main, bg=TH.card,
                        font_size=22, radius=12)
        top.add_widget(back)
        top.add_widget(Label(
            text=L["settings"], font_size=18, bold=True,
            color=TH.text_main, halign="left", valign="middle",
            text_size=(220, None)))
        top.add_widget(BoxLayout(size_hint=(None, None), size=(40, 40)))
        root.add_widget(top)
        root.add_widget(divider())

        scroll = ScrollView(bar_width=2)
        layout = BoxLayout(orientation="vertical", spacing=14,
                           padding=[14, 14, 14, 24], size_hint_y=None)
        layout.bind(minimum_height=layout.setter("height"))

        # ── Theme section ───────────────────────────────────────────────
        layout.add_widget(self._section("THEME"))
        theme_card = self._card()

        # Primary color
        theme_card.add_widget(self._field_label(L["primary_color"]))
        pri_row = BoxLayout(size_hint_y=None, height=46, spacing=8)
        self.pri_input = self._input(t["primary"])
        self.pri_preview = BoxLayout(
            size_hint=(None, None), size=(46, 46))
        fill_rounded(self.pri_preview, _hex_color(t["primary"]), radius=10)
        self.pri_input.bind(
            text=lambda i, v: self._upd_preview(self.pri_preview, v))
        pri_row.add_widget(self.pri_input)
        pri_row.add_widget(self.pri_preview)
        theme_card.add_widget(pri_row)

        theme_card.add_widget(self._mini_label(L["quick_select"]))
        theme_card.add_widget(self._swatches(
            list(PRESETS.items()),
            on_pick=lambda hx: (
                setattr(self.pri_input, "text", hx),
                self._upd_preview(self.pri_preview, hx))))

        theme_card.add_widget(spacer(8))

        # Background color
        theme_card.add_widget(self._field_label(L["bg_color"]))
        bg_row = BoxLayout(size_hint_y=None, height=46, spacing=8)
        self.bg_input = self._input(t["bg"])
        self.bg_preview = BoxLayout(
            size_hint=(None, None), size=(46, 46))
        fill_rounded(self.bg_preview, _hex_color(t["bg"]), radius=10)
        self.bg_input.bind(
            text=lambda i, v: self._upd_preview(self.bg_preview, v))
        bg_row.add_widget(self.bg_input)
        bg_row.add_widget(self.bg_preview)
        theme_card.add_widget(bg_row)

        theme_card.add_widget(self._mini_label(L["dark_bg"]))
        theme_card.add_widget(self._swatches(
            list(BG_PRESETS.items()),
            on_pick=lambda hx: (
                setattr(self.bg_input, "text", hx),
                self._upd_preview(self.bg_preview, hx))))

        theme_card.add_widget(self._mini_label(L["light_bg"]))
        theme_card.add_widget(self._swatches(
            list(LIGHT_BG_PRESETS.items()),
            on_pick=lambda hx: (
                setattr(self.bg_input, "text", hx),
                self._upd_preview(self.bg_preview, hx))))

        layout.add_widget(theme_card)

        # ── Display section ─────────────────────────────────────────────
        layout.add_widget(self._section("DISPLAY"))
        disp_card = self._card()
        disp_card.add_widget(self._field_label(L["font_size"]))
        font_row = BoxLayout(size_hint_y=None, height=44, spacing=8)
        for fs_name, fs_key in [("Small", "small"), ("Medium", "medium"), ("Large", "large")]:
            is_sel = (t["font_size"] == fs_name)
            fb = self._segmented_btn(
                L[fs_key], is_sel,
                on_press=lambda b=fs_name: self._set_font(b))
            font_row.add_widget(fb)
        disp_card.add_widget(font_row)

        disp_card.add_widget(spacer(6))
        disp_card.add_widget(self._field_label(L["language"]))
        lang_row = BoxLayout(size_hint_y=None, height=44, spacing=8)
        cur_lang = load_lang()
        for lang_name in ["English", "Myanmar", "Thai"]:
            is_sel = (cur_lang == lang_name)
            lb = self._segmented_btn(
                lang_name, is_sel,
                on_press=lambda l=lang_name: self._set_lang(l))
            lang_row.add_widget(lb)
        disp_card.add_widget(lang_row)
        layout.add_widget(disp_card)

        # ── Security section ────────────────────────────────────────────
        layout.add_widget(self._section("SECURITY"))
        sec_card = self._card()
        # Status row
        status_row = BoxLayout(size_hint_y=None, height=44, spacing=8)
        status_row.add_widget(Label(
            text="PIN Lock", font_size=TH.fs_normal, bold=True,
            color=TH.text_main, halign="left", valign="middle",
            text_size=(160, None)))
        status_chip = chip(
            "ENABLED" if pin_on else "DISABLED",
            fg=TH.gold_text if pin_on else TH.white,
            bg=TH.green if pin_on else TH.grey,
            font_size=9)
        status_row.add_widget(BoxLayout())
        status_row.add_widget(status_chip)
        sec_card.add_widget(status_row)

        sec_card.add_widget(Label(
            text=("Required on app start" if pin_on else "App opens without PIN"),
            font_size=11, color=TH.grey, halign="left", valign="middle",
            size_hint_y=None, height=18, text_size=(320, None)))

        sec_card.add_widget(spacer(4))
        pin_row = BoxLayout(size_hint_y=None, height=44, spacing=8)
        for label, val in [("Enable", True), ("Disable", False)]:
            is_sel = (pin_on == val)
            color_active = TH.green if val else TH.red
            tb = self._segmented_btn(
                label, is_sel,
                on_press=lambda v=val: self._set_pin_enabled(v),
                active_bg=color_active)
            pin_row.add_widget(tb)
        sec_card.add_widget(pin_row)

        sec_card.add_widget(spacer(4))
        change_pin_btn = self._segmented_btn(
            L["change_pin"], False,
            on_press=self.show_change_pin if pin_on else None,
            active_bg=TH.primary)
        change_pin_btn.color = TH.text_main if pin_on else TH.grey
        if not pin_on:
            change_pin_btn.disabled = True
        sec_card.add_widget(change_pin_btn)
        layout.add_widget(sec_card)

        # ── Actions ─────────────────────────────────────────────────────
        layout.add_widget(spacer(6))
        save_btn = gold_btn(L["save_apply"], height=52)
        save_btn.bind(on_press=self.save_settings)
        layout.add_widget(save_btn)

        reset_btn = ghost_btn(L["reset_default"], height=44)
        reset_btn.bind(on_press=self.reset_settings)
        layout.add_widget(reset_btn)

        layout.add_widget(spacer(20))
        scroll.add_widget(layout)
        root.add_widget(scroll)
        self.add_widget(root)

    # ── UI helpers ───────────────────────────────────────────────────────
    def _section(self, text):
        wrap = BoxLayout(size_hint_y=None, height=22, padding=[2, 0])
        wrap.add_widget(Label(
            text=text, font_size=10, bold=True,
            color=TH.primary, halign="left", valign="middle",
            text_size=(360, None)))
        return wrap

    def _card(self):
        c = BoxLayout(
            orientation="vertical",
            size_hint_y=None, padding=[14, 12, 14, 14],
            spacing=8)
        c.bind(minimum_height=c.setter("height"))
        fill_rounded(c, TH.card, radius=14, border_color=(1, 1, 1, 0.05))
        return c

    def _field_label(self, text):
        return Label(
            text=text, font_size=11, bold=True,
            color=TH.grey, halign="left", valign="middle",
            size_hint_y=None, height=18,
            text_size=(360, None))

    def _mini_label(self, text):
        return Label(
            text=text, font_size=10,
            color=TH.grey, halign="left", valign="middle",
            size_hint_y=None, height=16,
            text_size=(360, None))

    def _input(self, text):
        ti = TextInput(
            text=text, multiline=False,
            size_hint_y=None, height=46,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            background_normal="",
            foreground_color=TH.text_main,
            cursor_color=TH.primary,
            padding=[14, 14])
        return ti

    def _swatches(self, items, on_pick):
        rows = BoxLayout(orientation="vertical", size_hint_y=None, spacing=4)
        rows.bind(minimum_height=rows.setter("height"))
        per_row = 5
        for i in range(0, len(items), per_row):
            r = BoxLayout(size_hint_y=None, height=36, spacing=6)
            for k, hx in items[i:i + per_row]:
                btn = Button(
                    text="", size_hint_y=None, height=36,
                    background_normal="", background_color=(0, 0, 0, 0))
                fill_rounded(btn, _hex_color(hx), radius=8,
                             border_color=(1, 1, 1, 0.10))
                btn.hx = hx
                btn.bind(on_press=lambda b, *_: on_pick(b.hx))
                r.add_widget(btn)
            # pad row if short
            for _ in range(per_row - len(items[i:i + per_row])):
                r.add_widget(BoxLayout())
            rows.add_widget(r)
        return rows

    def _segmented_btn(self, text, is_sel, on_press=None, active_bg=None):
        active_bg = active_bg or TH.primary
        btn = Button(
            text=text, font_size=TH.fs_normal, bold=True,
            size_hint_y=None, height=44,
            background_normal="", background_color=(0, 0, 0, 0),
            color=TH.gold_text if is_sel else TH.text_main)
        bg = active_bg if is_sel else TH.card2
        fill_rounded(btn, bg, radius=10)
        if on_press:
            btn.bind(on_press=lambda *_: on_press())
        return btn

    # ── PIN Lock toggle ───────────────────────────────────────────────────────
    def _set_pin_enabled(self, val):
        if not val:
            # Confirm before disabling
            self._confirm_disable_pin()
        else:
            pin_data          = load_pin()
            pin_data["enabled"] = True
            save_pin(pin_data)
            self.build_ui()

    def _confirm_disable_pin(self):
        """Ask user to confirm before turning PIN off."""
        content = BoxLayout(orientation="vertical", padding=16, spacing=12)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        content.add_widget(BoxLayout(size_hint_y=None, height=6))
        content.add_widget(make_label(
            "Disable PIN lock?\nAnyone can open the app without a PIN.",
            color=TH.white, halign="center",
            font_size=TH.fs_small, height=52))

        btns = BoxLayout(size_hint_y=None, height=46, spacing=8)
        yes = Button(
            text="Yes, Disable", font_size=TH.fs_normal, bold=True,
            background_normal="", background_color=TH.red,
            color=TH.white, size_hint_y=None, height=46)
        no = ghost_btn("Cancel", height=46)
        btns.add_widget(yes)
        btns.add_widget(no)
        content.add_widget(btns)

        popup = Popup(title="", content=content,
                      size_hint=(0.85, 0.36),
                      background_color=TH.card,
                      separator_height=0)
        yes.bind(on_press=lambda x: self._do_disable_pin(popup))
        no.bind(on_press=popup.dismiss)
        popup.open()

    def _do_disable_pin(self, popup):
        pin_data            = load_pin()
        pin_data["enabled"] = False
        save_pin(pin_data)
        popup.dismiss()
        self.build_ui()

    # ── Other settings helpers ────────────────────────────────────────────────
    def _upd_preview(self, box, val):
        box.canvas.before.clear()
        with box.canvas.before:
            Color(*_hex_color(val))
            Rectangle(pos=box.pos, size=box.size)

    def _set_mode(self, mode_name):
        t = load_theme()
        t["mode"] = mode_name
        save_theme(t)
        TH.reload()
        self.build_ui()

    def _set_font(self, fs_name):
        t = load_theme()
        t["font_size"] = fs_name
        save_theme(t)
        TH.reload()
        self.build_ui()

    def _set_lang(self, lang_name):
        save_lang(lang_name)
        reload_lang()
        import lang as lang_mod
        lang_mod.L = lang_mod.get_strings()
        global L
        L = lang_mod.L
        self.build_ui()

    def save_settings(self, *args):
        pri = self.pri_input.text.strip()
        bg  = self.bg_input.text.strip()
        if not pri.startswith("#"): pri = "#" + pri
        if not bg.startswith("#"):  bg  = "#" + bg
        t = load_theme()
        t["primary"] = pri
        t["bg"]      = bg
        save_theme(t)
        TH.reload()

        content = BoxLayout(orientation="vertical", padding=16, spacing=10)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        content.add_widget(BoxLayout(size_hint_y=None, height=8))
        content.add_widget(make_label(
            L["theme_saved"], color=TH.text_main,
            halign="center", font_size=TH.fs_normal, height=56))
        ok = gold_btn(L["btn_ok"], height=44)
        content.add_widget(ok)
        popup = Popup(title="", content=content,
                      size_hint=(0.78, 0.36),
                      background_color=TH.card,
                      separator_height=0)
        ok.bind(on_press=lambda x: (
            popup.dismiss(),
            setattr(self.manager, "current", "home")))
        popup.open()

    def reset_settings(self, *args):
        from theme import DEFAULT
        save_theme(DEFAULT.copy())
        TH.reload()
        self.build_ui()

    def show_change_pin(self, *args):
        content = BoxLayout(orientation="vertical", padding=16, spacing=10)
        set_bg(content, TH.bg)
        content.add_widget(gold_line(1))
        content.add_widget(BoxLayout(size_hint_y=None, height=6))
        content.add_widget(make_label(L["current_pin"],
                                      color=TH.primary, height=28))
        cur_in = TextInput(
            hint_text="****", password=True,
            multiline=False, size_hint_y=None, height=44,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.text_main,
            cursor_color=TH.primary)
        content.add_widget(cur_in)
        content.add_widget(make_label(L["new_pin"],
                                      color=TH.primary, height=28))
        new_in = TextInput(
            hint_text="****", password=True,
            multiline=False, size_hint_y=None, height=44,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.text_main,
            cursor_color=TH.primary)
        content.add_widget(new_in)
        content.add_widget(make_label(L["confirm_pin"],
                                      color=TH.primary, height=28))
        confirm_in = TextInput(
            hint_text="****", password=True,
            multiline=False, size_hint_y=None, height=44,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.text_main,
            cursor_color=TH.primary)
        content.add_widget(confirm_in)
        self.pin_error_lbl = Label(
            text="", font_size=TH.fs_small,
            color=TH.red, size_hint_y=None, height=28,
            halign="center")
        content.add_widget(self.pin_error_lbl)
        btns = BoxLayout(size_hint_y=None, height=44, spacing=8)
        s = gold_btn(L["btn_save"], height=44)
        c = ghost_btn(L["btn_cancel"], height=44)
        btns.add_widget(s)
        btns.add_widget(c)
        content.add_widget(btns)
        popup = Popup(title=L["change_pin"], content=content,
                      size_hint=(0.92, 0.72),
                      background_color=TH.card)
        s.bind(on_press=lambda x: self._do_change_pin(
            cur_in.text, new_in.text, confirm_in.text, popup))
        c.bind(on_press=popup.dismiss)
        popup.open()

    def _do_change_pin(self, cur, new, confirm, popup):
        pin_data = load_pin()
        correct  = pin_data.get("pin", "1234")
        if cur != correct:
            self.pin_error_lbl.text = L["pin_wrong_cur"]
            return
        if len(new) < 4:
            self.pin_error_lbl.text = L["pin_short"]
            return
        if new != confirm:
            self.pin_error_lbl.text = L["pin_no_match"]
            return
        pin_data["pin"] = new
        save_pin(pin_data)
        popup.dismiss()
        ok_content = BoxLayout(orientation="vertical", padding=16, spacing=10)
        set_bg(ok_content, TH.bg)
        ok_content.add_widget(gold_line(1))
        ok_content.add_widget(BoxLayout(size_hint_y=None, height=8))
        ok_content.add_widget(make_label(
            L["pin_changed"], color=TH.text_main,
            halign="center", height=40))
        ok_btn = gold_btn(L["btn_ok"], height=44)
        ok_content.add_widget(ok_btn)
        ok_popup = Popup(title="", content=ok_content,
                         size_hint=(0.78, 0.32),
                         background_color=TH.card,
                         separator_height=0)
        ok_btn.bind(on_press=ok_popup.dismiss)
        ok_popup.open()