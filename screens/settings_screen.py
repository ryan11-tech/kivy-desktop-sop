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
from utils import (set_bg, gold_line, divider, make_label,
                   gold_btn, ghost_btn, _hex_color,
                   load_pin, save_pin)


class SettingsScreen(Screen):
    def on_enter(self):
        self.build_ui()

    def build_ui(self):
        self.clear_widgets()
        t        = load_theme()
        pin_data = load_pin()
        pin_on   = pin_data.get("enabled", True)

        root = BoxLayout(orientation="vertical")
        set_bg(root, TH.bg)
        root.add_widget(gold_line(2))

        # ── Header ──────────────────────────────────────────────────────────
        header = BoxLayout(size_hint_y=None, height=60, padding=[12, 8])
        set_bg(header, TH.header_bg)
        back = ghost_btn(L["btn_back"], height=44)
        back.size_hint_x = None
        back.width = 90
        back.bind(on_press=lambda x: setattr(self.manager, "current", "home"))
        header.add_widget(back)
        header.add_widget(make_label(
            L["settings"], font_size=16,
            color=TH.primary, bold=True,
            halign="center", height=44))
        header.add_widget(BoxLayout(size_hint_x=None, width=90))
        root.add_widget(header)
        root.add_widget(gold_line(1))

        scroll = ScrollView()
        layout = BoxLayout(orientation="vertical", spacing=16,
                           padding=[16, 16], size_hint_y=None)
        layout.bind(minimum_height=layout.setter("height"))
        
        # ── Primary Color ─────────────────────────────────────────────────────
        layout.add_widget(make_label(
            L["primary_color"], font_size=TH.fs_small,
            color=TH.grey, bold=True, height=24))
        pri_row = BoxLayout(size_hint_y=None, height=52, spacing=8)
        self.pri_input = TextInput(
            text=t["primary"], multiline=False,
            size_hint_y=None, height=52,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.text_main,
            cursor_color=TH.primary)
        self.pri_preview = BoxLayout(
            size_hint_x=None, width=52,
            size_hint_y=None, height=52)
        set_bg(self.pri_preview, _hex_color(t["primary"]))
        self.pri_input.bind(
            text=lambda i, v: self._upd_preview(self.pri_preview, v))
        pri_row.add_widget(self.pri_input)
        pri_row.add_widget(self.pri_preview)
        layout.add_widget(pri_row)

        layout.add_widget(make_label(
            L["quick_select"], font_size=TH.fs_small,
            color=TH.grey, height=22))
        keys = list(PRESETS.keys())
        for i in range(0, len(keys), 5):
            row_keys = keys[i:i+5]
            prow = BoxLayout(size_hint_y=None, height=44, spacing=4)
            for k in row_keys:
                hx = PRESETS[k]
                pb = Button(
                    text=k, font_size=10, bold=True,
                    size_hint_y=None, height=44,
                    background_normal="",
                    background_color=_hex_color(hx),
                    color=(1, 1, 1, 1))
                pb.hx = hx
                pb.bind(on_press=lambda b, *a: (
                    setattr(self.pri_input, "text", b.hx),
                    self._upd_preview(self.pri_preview, b.hx)))
                prow.add_widget(pb)
            layout.add_widget(prow)
        layout.add_widget(divider())

        # ── Background Color ──────────────────────────────────────────────────
        layout.add_widget(make_label(
            L["bg_color"], font_size=TH.fs_small,
            color=TH.grey, bold=True, height=24))
        bg_row = BoxLayout(size_hint_y=None, height=52, spacing=8)
        self.bg_input = TextInput(
            text=t["bg"], multiline=False,
            size_hint_y=None, height=52,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            foreground_color=TH.text_main,
            cursor_color=TH.primary)
        self.bg_preview = BoxLayout(
            size_hint_x=None, width=52,
            size_hint_y=None, height=52)
        set_bg(self.bg_preview, _hex_color(t["bg"]))
        self.bg_input.bind(
            text=lambda i, v: self._upd_preview(self.bg_preview, v))
        bg_row.add_widget(self.bg_input)
        bg_row.add_widget(self.bg_preview)
        layout.add_widget(bg_row)

        layout.add_widget(make_label(
            L["dark_bg"], font_size=TH.fs_small,
            color=TH.grey, height=22))
        bg_keys = list(BG_PRESETS.keys())
        for i in range(0, len(bg_keys), 4):
            row_keys = bg_keys[i:i+4]
            brow = BoxLayout(size_hint_y=None, height=44, spacing=4)
            for k in row_keys:
                hx = BG_PRESETS[k]
                pb = Button(
                    text=k, font_size=10, bold=True,
                    size_hint_y=None, height=44,
                    background_normal="",
                    background_color=_hex_color(hx),
                    color=(1, 1, 1, 1))
                pb.hx = hx
                pb.bind(on_press=lambda b, *a: (
                    setattr(self.bg_input, "text", b.hx),
                    self._upd_preview(self.bg_preview, b.hx)))
                brow.add_widget(pb)
            layout.add_widget(brow)

        layout.add_widget(make_label(
            L["light_bg"], font_size=TH.fs_small,
            color=TH.grey, height=22))
        lbg_keys = list(LIGHT_BG_PRESETS.keys())
        for i in range(0, len(lbg_keys), 4):
            row_keys = lbg_keys[i:i+4]
            lrow = BoxLayout(size_hint_y=None, height=44, spacing=4)
            for k in row_keys:
                hx = LIGHT_BG_PRESETS[k]
                pb = Button(
                    text=k, font_size=10, bold=True,
                    size_hint_y=None, height=44,
                    background_normal="",
                    background_color=_hex_color(hx),
                    color=(0.1, 0.1, 0.1, 1))
                pb.hx = hx
                pb.bind(on_press=lambda b, *a: (
                    setattr(self.bg_input, "text", b.hx),
                    self._upd_preview(self.bg_preview, b.hx)))
                lrow.add_widget(pb)
            layout.add_widget(lrow)
        layout.add_widget(divider())

        # ── Font Size ─────────────────────────────────────────────────────────
        layout.add_widget(make_label(
            L["font_size"], font_size=TH.fs_small,
            color=TH.grey, bold=True, height=24))
        font_row = BoxLayout(size_hint_y=None, height=52, spacing=8)
        for fs_name, fs_key in [("Small","small"),("Medium","medium"),("Large","large")]:
            is_sel = (t["font_size"] == fs_name)
            fb = Button(
                text=L[fs_key], font_size=TH.fs_normal, bold=True,
                background_normal="",
                background_color=TH.primary if is_sel else TH.card,
                color=TH.gold_text if is_sel else TH.grey,
                size_hint_y=None, height=52)
            fb.fs_name = fs_name
            fb.bind(on_press=lambda b, *a: self._set_font(b.fs_name))
            font_row.add_widget(fb)
        layout.add_widget(font_row)
        layout.add_widget(divider())

        # ── Language ──────────────────────────────────────────────────────────
        layout.add_widget(make_label(
            L["language"], font_size=TH.fs_small,
            color=TH.grey, bold=True, height=24))
        lang_row = BoxLayout(size_hint_y=None, height=52, spacing=8)
        cur_lang = load_lang()
        for lang_name in ["English", "Myanmar", "Thai"]:
            is_sel = (cur_lang == lang_name)
            lb = Button(
                text=lang_name, font_size=TH.fs_normal, bold=True,
                background_normal="",
                background_color=TH.primary if is_sel else TH.card,
                color=TH.gold_text if is_sel else TH.grey,
                size_hint_y=None, height=52)
            lb.lang_name = lang_name
            lb.bind(on_press=lambda b, *a: self._set_lang(b.lang_name))
            lang_row.add_widget(lb)
        layout.add_widget(lang_row)
        layout.add_widget(divider())

        # ── PIN LOCK toggle ───────────────────────────────────────────────────
        layout.add_widget(make_label(
            "PIN LOCK", font_size=TH.fs_small,
            color=TH.grey, bold=True, height=24))

        # Status indicator
        status_text = ("Enabled  —  PIN required on startup"
                       if pin_on else
                       "Disabled  —  app opens without PIN")
        status_col = TH.green if pin_on else TH.grey
        layout.add_widget(make_label(
            status_text, font_size=TH.fs_small,
            color=status_col, height=22))

        # Enable / Disable buttons
        pin_toggle_row = BoxLayout(size_hint_y=None, height=52, spacing=8)
        for label, val in [("Enable", True), ("Disable", False)]:
            is_sel = (pin_on == val)
            bg_col = TH.primary if is_sel else TH.card
            if val is False and is_sel:
                bg_col = TH.red
            txt_col = TH.gold_text if (is_sel and val) else (TH.white if (is_sel and not val) else TH.grey)
            tb = Button(
                text=label, font_size=TH.fs_normal, bold=True,
                background_normal="",
                background_color=bg_col,
                color=txt_col,
                size_hint_y=None, height=52)
            tb.pin_val = val
            tb.bind(on_press=lambda b, *a: self._set_pin_enabled(b.pin_val))
            pin_toggle_row.add_widget(tb)
        layout.add_widget(pin_toggle_row)
        layout.add_widget(divider())
           
        # ── Change PIN ────────────────────────────────────────────────────────
        layout.add_widget(make_label(
            L["change_pin"], font_size=TH.fs_small,
            color=TH.grey if not pin_on else TH.grey,
            bold=True, height=24))

        change_pin_btn = gold_btn(L["change_pin"], height=46)
        if not pin_on:
            # Grayed out when PIN is disabled
            change_pin_btn.background_color = TH.card
            change_pin_btn.color            = TH.grey
            change_pin_btn.disabled         = True
        else:
            change_pin_btn.bind(on_press=self.show_change_pin)
        layout.add_widget(change_pin_btn)
        layout.add_widget(divider())

        # ── Save / Reset ──────────────────────────────────────────────────────
        save_btn = gold_btn(L["save_apply"], height=54)
        save_btn.bind(on_press=self.save_settings)
        layout.add_widget(save_btn)

        reset_btn = ghost_btn(L["reset_default"], height=44)
        reset_btn.bind(on_press=self.reset_settings)
        layout.add_widget(reset_btn)

        layout.add_widget(BoxLayout(size_hint_y=None, height=24))
        scroll.add_widget(layout)
        root.add_widget(scroll)
        self.add_widget(root)

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