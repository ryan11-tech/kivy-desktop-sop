"""Schedule screen — UI only. All data ops go through services.schedule."""
import os

from kivy.uix.screenmanager import Screen
from kivy.uix.boxlayout import BoxLayout
from kivy.uix.scrollview import ScrollView
from kivy.uix.button import Button
from kivy.uix.label import Label
from kivy.uix.textinput import TextInput
from kivy.uix.popup import Popup
from kivy.graphics import Color, Rectangle
CUR_DIR = os.path.dirname(os.path.abspath(__file__))
FA_FONT = os.path.join(os.path.dirname(CUR_DIR), "assets", "fa-solid-900.ttf")
from services import schedule as svc
from theme import TH, _hex_color
from lang import L
from utils import (
    set_bg, fill_rounded, divider, make_label, spacer,
    gold_btn, ghost_btn, danger_btn, icon_btn, chip,
    section_label, screen_header, pill_tab_row, rounded_card,
    get_mode, make_bottom_nav,
)

DAYS = svc.DAYS
DAY_FULL = {
    "Mon": "Monday", "Tue": "Tuesday", "Wed": "Wednesday",
    "Thu": "Thursday", "Fri": "Friday", "Sat": "Saturday",
    "Sun": "Sunday",
}


class ScheduleScreen(Screen):
    def __init__(self, **kw):
        super().__init__(**kw)
        self.active_day = "Mon"
        self.active_tab = "schedule"

    def on_enter(self):
        self.build_ui()

    # ── Main build ────────────────────────────────────────────────────────────

    def build_ui(self):
        self.clear_widgets()
        data = svc.all_data()

        root = BoxLayout(orientation="vertical")
        set_bg(root, TH.bg)

        # Header
        mode_chip = chip(
            "ADMIN" if get_mode() == "Admin" else "STAFF",
            fg=TH.gold_text if get_mode() == "Admin" else TH.white,
            bg=TH.primary if get_mode() == "Admin" else TH.card2,
            font_size=9)
        root.add_widget(screen_header(
            "Staff Schedule",
            on_back=self._go_back,
            right=mode_chip))

        root.add_widget(divider())

        # Tab bar
        tabs = [("schedule", "Schedule", None), ("tasks", "Tasks", None)]
        if get_mode() == "Admin":
            tabs.append(("manage", "Manage", None))
        root.add_widget(self._tab_bar(tabs))
        root.add_widget(divider())

        # Scrollable content
        scroll = ScrollView(bar_width=2)
        self.content = BoxLayout(
            orientation="vertical", spacing=12,
            padding=[14, 12, 14, 18], size_hint_y=None)
        self.content.bind(minimum_height=self.content.setter("height"))

        if self.active_tab == "schedule":
            self._render_schedule(data)
        elif self.active_tab == "tasks":
            self._render_tasks(data)
        elif self.active_tab == "manage":
            self._render_manage(data)

        scroll.add_widget(self.content)
        root.add_widget(scroll)
        root.add_widget(make_bottom_nav(self.manager, active="schedule"))
        self.add_widget(root)

    def _tab_bar(self, tabs):
        row = BoxLayout(
            size_hint_y=None, height=48,
            padding=[14, 6], spacing=8)
        set_bg(row, TH.bg)
        for key, label, _ in tabs:
            is_sel = (key == self.active_tab)
            btn = Button(
                text=label,
                font_size=TH.fs_small, bold=is_sel,
                background_normal="", background_color=(0, 0, 0, 0),
                color=TH.gold_text if is_sel else TH.grey,
                size_hint_y=None, height=36)
            btn.tab_key = key
            fill_rounded(btn,
                         TH.primary if is_sel else TH.card,
                         radius=18)
            btn.bind(on_press=lambda b, *_: self._switch_tab(b.tab_key))
            row.add_widget(btn)
        return row

    def _go_back(self):
        self.manager.transition.direction = "right"
        self.manager.current = "home"

    def _switch_tab(self, key):
        self.active_tab = key
        self.build_ui()

    # ── SCHEDULE TAB ──────────────────────────────────────────────────────────

    def _render_schedule(self, data):
        # Day pill selector
        day_row = BoxLayout(size_hint_y=None, height=44, spacing=6)
        for d in DAYS:
            is_sel = (d == self.active_day)
            btn = Button(
                text=d, font_size=9, bold=is_sel,
                background_normal="", background_color=(0, 0, 0, 0),
                color=TH.gold_text if is_sel else TH.grey,
                size_hint_y=None, height=36)
            btn.day = d
            fill_rounded(btn,
                         TH.primary if is_sel else TH.card,
                         radius=18)
            btn.bind(on_press=lambda b, *_: self._select_day(b.day))
            day_row.add_widget(btn)
        self.content.add_widget(day_row)

        # Day full name
        self.content.add_widget(make_label(
            DAY_FULL[self.active_day],
            font_size=TH.fs_large, bold=True,
            color=TH.primary, height=32))

        # Shift cards
        entries    = svc.get_day_entries(data, self.active_day)
        s_map      = svc.shifts_map(data)
        st_map     = svc.staff_map(data)

        if not entries:
            self.content.add_widget(self._empty_state(
                "No shifts assigned",
                "Tap '+ Add Shift' below to assign one."))
        else:
            for idx, entry in enumerate(entries):
                shift = s_map.get(entry.get("shift_id"))
                if shift:
                    self.content.add_widget(
                        self._shift_card(entry, idx, shift, st_map, data))

        if get_mode() == "Admin":
            self.content.add_widget(spacer(4))
            btn = gold_btn(f"+ Add Shift to {self.active_day}", height=46)
            btn.bind(on_press=lambda *_: self._popup_add_shift_to_day(data))
            self.content.add_widget(btn)

    def _shift_card(self, entry, entry_idx, shift, st_map, data):
        shift_color = _hex_color(shift.get("color", "#C9A84C"))

        card = rounded_card(padding=0, spacing=0, bg=TH.card, radius=14)

        # Color accent bar
        accent = BoxLayout(size_hint_y=None, height=4)
        def draw_accent(w, *_):
            w.canvas.before.clear()
            with w.canvas.before:
                Color(*shift_color)
                Rectangle(pos=w.pos, size=w.size)
        accent.bind(pos=draw_accent, size=draw_accent)
        card.add_widget(accent)

        # Info row
        info = BoxLayout(size_hint_y=None, height=48, padding=[14, 8], spacing=8)
        info.add_widget(Label(
            text=shift.get("name", "Shift"),
            font_size=TH.fs_normal, bold=True,
            color=shift_color, halign="left",
            size_hint_x=0.55,
            text_size=(None, None)))
        info.add_widget(Label(
            text=f"{shift.get('start_time','')} – {shift.get('end_time','')}",
            font_size=TH.fs_small, color=TH.grey,
            halign="right", size_hint_x=0.35,
            text_size=(None, None)))
        if get_mode() == "Admin":
            del_btn = icon_btn(
                "", size=(32, 32),
                font=FA_FONT,
                fg=TH.red, bg=TH.bg,
                font_size=12, radius=10,
                on_press=lambda *_, i=entry_idx: self._delete_entry(i, data))
            info.add_widget(del_btn)
        card.add_widget(info)

        card.add_widget(divider())

        # Staff rows
        assigned = entry.get("staff", [])
        if assigned:
            for sid in assigned:
                st = st_map.get(sid)
                if st:
                    card.add_widget(self._staff_row(st["name"]))
        else:
            card.add_widget(make_label(
                "  No staff assigned",
                color=TH.grey, font_size=TH.fs_small, height=32))

        if get_mode() == "Admin":
            assign_btn = Button(
                text="+ Assign Staff",
                font_size=TH.fs_small, bold=True,
                size_hint_y=None, height=34,
                background_normal="", background_color=(0, 0, 0, 0),
                color=TH.primary)
            assign_btn.bind(
                on_press=lambda *_, i=entry_idx: self._popup_assign_staff(i, data))
            card.add_widget(assign_btn)

        card.add_widget(spacer(6))
        return card

    def _staff_row(self, name):
        row = BoxLayout(size_hint_y=None, height=34, padding=[14, 4])
        fill_rounded(row, TH.card2, radius=8)
        row.add_widget(Label(
            text=f"  {name}",
            font_size=TH.fs_small, color=TH.white70,
            halign="left", valign="middle",
            text_size=(300, None)))
        return row

    def _select_day(self, day):
        self.active_day = day
        self.build_ui()

    # ── TASKS TAB ─────────────────────────────────────────────────────────────

    def _render_tasks(self, data):
        tasks  = svc.get_tasks(data)
        st_map = svc.staff_map(data)

        if not tasks:
            self.content.add_widget(self._empty_state(
                "No tasks yet",
                "Admin can add tasks from this tab."))
        else:
            for task in tasks:
                self.content.add_widget(self._task_card(task, st_map, data))

        if get_mode() == "Admin":
            self.content.add_widget(spacer(4))
            btn = gold_btn("+ Add New Task", height=46)
            btn.bind(on_press=lambda *_: self._popup_add_task(data))
            self.content.add_widget(btn)

    def _task_card(self, task, st_map, data):
        card = rounded_card(padding=0, spacing=0, bg=TH.card, radius=14)

        # Top accent
        accent = BoxLayout(size_hint_y=None, height=3)
        def draw_top(w, *_):
            w.canvas.before.clear()
            with w.canvas.before:
                Color(*TH.primary)
                Rectangle(pos=w.pos, size=w.size)
        accent.bind(pos=draw_top, size=draw_top)
        card.add_widget(accent)

        # Header row
        head = BoxLayout(size_hint_y=None, height=48, padding=[14, 8], spacing=8)
        head.add_widget(Label(
            text=task.get("name", "Task"),
            font_size=TH.fs_normal, bold=True,
            color=TH.text_main, halign="left",
            size_hint_x=0.55,
            text_size=(None, None)))

        days_txt = "  ".join(task.get("days", [])) or "Every day"
        head.add_widget(Label(
            text=days_txt, font_size=9,
            color=TH.primary, halign="right",
            size_hint_x=0.35,
            text_size=(None, None)))

        if get_mode() == "Admin":
            del_btn = icon_btn(
                "", size=(32, 32),
                font=FA_FONT,
                fg=TH.red, bg=TH.bg,
                font_size=12, radius=10, 
                on_press=lambda *_, tid=task["id"]: self._delete_task(tid))
            head.add_widget(del_btn)
        card.add_widget(head)

        card.add_widget(divider())

        # Staff rows
        assigned = task.get("assigned_staff", [])
        if assigned:
            for sid in assigned:
                st = st_map.get(sid)
                if st:
                    card.add_widget(self._staff_row(st["name"]))
        else:
            card.add_widget(make_label(
                "  No staff assigned",
                color=TH.grey, font_size=TH.fs_small, height=32))

        if get_mode() == "Admin":
            assign_btn = Button(
                text="+ Assign Staff",
                font_size=TH.fs_small, bold=True,
                size_hint_y=None, height=34,
                background_normal="", background_color=(0, 0, 0, 0),
                color=TH.primary)
            assign_btn.bind(
                on_press=lambda *_, tid=task["id"]: self._popup_assign_staff_task(tid, data))
            card.add_widget(assign_btn)

        card.add_widget(spacer(6))
        return card

    # ── MANAGE TAB ────────────────────────────────────────────────────────────

    def _render_manage(self, data):
        # Shifts section
        self.content.add_widget(section_label("SHIFT TYPES", height=26))
        self.content.add_widget(divider())

        shifts = svc.get_shifts(data)
        if not shifts:
            self.content.add_widget(make_label(
                "No shift types yet.",
                color=TH.grey, font_size=TH.fs_small, height=32))
        else:
            for shift in shifts:
                self.content.add_widget(self._shift_def_row(shift, data))

        self.content.add_widget(spacer(4))
        add_shift_btn = gold_btn("+ Add Shift Type", height=44)
        add_shift_btn.bind(on_press=lambda *_: self._popup_add_shift_def())
        self.content.add_widget(add_shift_btn)

        self.content.add_widget(spacer(16))

        # Staff section
        self.content.add_widget(section_label("STAFF MEMBERS", height=26))
        self.content.add_widget(divider())

        staff = svc.get_staff(data)
        if not staff:
            self.content.add_widget(make_label(
                "No staff members yet.",
                color=TH.grey, font_size=TH.fs_small, height=32))
        else:
            for member in staff:
                self.content.add_widget(self._staff_def_row(member))

        self.content.add_widget(spacer(4))
        add_staff_btn = gold_btn("+ Add Staff Member", height=44)
        add_staff_btn.bind(on_press=lambda *_: self._popup_add_staff())
        self.content.add_widget(add_staff_btn)

        self.content.add_widget(spacer(16))

        # Danger zone
        self.content.add_widget(section_label("DANGER ZONE", height=26))
        self.content.add_widget(divider())
        clear_btn = danger_btn("Clear This Week's Schedule", height=46)
        clear_btn.bind(on_press=lambda *_: self._popup_confirm_clear())
        self.content.add_widget(clear_btn)

    def _shift_def_row(self, shift, data):
        shift_color = _hex_color(shift.get("color", "#C9A84C"))
        row = BoxLayout(size_hint_y=None, height=52,
                        padding=[14, 8], spacing=10)
        fill_rounded(row, TH.card, radius=12)

        dot = Label(
            text="●", font_size=16,
            color=shift_color,
            size_hint=(None, None), size=(24, 36),
            halign="center", valign="middle")
        row.add_widget(dot)

        row.add_widget(Label(
            text=shift["name"],
            font_size=TH.fs_normal, bold=True,
            color=TH.text_main, halign="left",
            size_hint_x=0.5,
            text_size=(None, None)))
        row.add_widget(Label(
            text=f"{shift['start_time']} – {shift['end_time']}",
            font_size=TH.fs_small, color=TH.grey,
            halign="center",
            size_hint_x=0.3,
            text_size=(None, None)))
        del_btn = icon_btn(
            "", size=(32, 32),
                font=FA_FONT,
                fg=TH.red, bg=TH.bg,
                font_size=12, radius=10,
            on_press=lambda *_, sid=shift["id"]: self._delete_shift(sid))
        row.add_widget(del_btn)
        return row

    def _staff_def_row(self, member):
        row = BoxLayout(size_hint_y=None, height=48,
                        padding=[14, 8], spacing=10)
        fill_rounded(row, TH.card, radius=12)
        row.add_widget(Label(
            text=member["name"],
            font_size=TH.fs_normal, color=TH.text_main,
            halign="left", size_hint_x=0.85,
            text_size=(None, None)))
        del_btn = icon_btn(
            "", size=(32, 32),
                font=FA_FONT,
                fg=TH.red, bg=TH.bg,
                font_size=12, radius=10,
            on_press=lambda *_, sid=member["id"]: self._delete_staff(sid))
        row.add_widget(del_btn)
        return row

    # ── Empty state ───────────────────────────────────────────────────────────

    def _empty_state(self, title, subtitle):
        wrap = BoxLayout(
            orientation="vertical", spacing=8,
            padding=[24, 32, 24, 16],
            size_hint_y=None, height=160)
        wrap.add_widget(Label(
            text=title,
            font_size=TH.fs_large, bold=True,
            color=TH.text_main,
            size_hint_y=None, height=28,
            halign="center"))
        wrap.add_widget(Label(
            text=subtitle,
            font_size=TH.fs_small, color=TH.grey,
            size_hint_y=None, height=20,
            halign="center"))
        return wrap

    # ── Popup helpers ─────────────────────────────────────────────────────────

    def _text_input(self, hint="", text="", height=46):
        return TextInput(
            text=text, hint_text=hint,
            multiline=False,
            size_hint_y=None, height=height,
            font_size=TH.fs_normal,
            background_color=TH.input_bg,
            background_normal="",
            foreground_color=TH.text_main,
            cursor_color=TH.primary,
            padding=[14, 14])

    def _base_popup(self, title, content, size_hint=(0.92, None), height=400):
        return Popup(
            title=title, content=content,
            size_hint=size_hint,
            height=height if size_hint[1] is None else None,
            background_color=TH.card,
            separator_color=TH.primary)

    # ── Popup: Add Shift Definition ───────────────────────────────────────────

    def _popup_add_shift_def(self):
        inner = rounded_card(bg=TH.bg, radius=0)
        inner.add_widget(section_label("SHIFT NAME", height=22))
        name_in  = self._text_input("e.g. Morning Shift")
        inner.add_widget(name_in)
        inner.add_widget(section_label("START TIME  (HH:MM)", height=22))
        start_in = self._text_input("07:00")
        inner.add_widget(start_in)
        inner.add_widget(section_label("END TIME  (HH:MM)", height=22))
        end_in   = self._text_input("13:00")
        inner.add_widget(end_in)
        inner.add_widget(section_label("COLOR  (#hex)", height=22))
        color_in = self._text_input(text="#C9A84C")
        inner.add_widget(color_in)
        err = make_label("", color=TH.red, height=20, font_size=11)
        inner.add_widget(err)

        btns = BoxLayout(size_hint_y=None, height=46, spacing=8)
        save_btn   = gold_btn("Save", height=46)
        cancel_btn = ghost_btn("Cancel", height=46)
        btns.add_widget(save_btn)
        btns.add_widget(cancel_btn)
        inner.add_widget(btns)

        popup = self._base_popup("Add Shift Type", inner, height=480)

        def do_save(*_):
            if not name_in.text.strip():
                err.text = "Name required."
                return
            color = color_in.text.strip()
            if not color.startswith("#"):
                color = "#" + color
            try:
                svc.add_shift(name_in.text, start_in.text, end_in.text, color)
            except ValueError as e:
                err.text = str(e)
                return
            popup.dismiss()
            self.build_ui()

        save_btn.bind(on_press=do_save)
        cancel_btn.bind(on_press=popup.dismiss)
        popup.open()

    # ── Popup: Add Staff ──────────────────────────────────────────────────────

    def _popup_add_staff(self):
        inner = rounded_card(bg=TH.bg, radius=0)
        inner.add_widget(section_label("STAFF NAME", height=22))
        name_in = self._text_input("e.g. Mr.Jhon")
        inner.add_widget(name_in)
        err = make_label("", color=TH.red, height=20, font_size=11)
        inner.add_widget(err)

        btns = BoxLayout(size_hint_y=None, height=46, spacing=8)
        save_btn   = gold_btn("Save", height=46)
        cancel_btn = ghost_btn("Cancel", height=46)
        btns.add_widget(save_btn)
        btns.add_widget(cancel_btn)
        inner.add_widget(btns)

        popup = self._base_popup("Add Staff Member", inner, height=280)

        def do_save(*_):
            try:
                svc.add_staff(name_in.text)
            except ValueError as e:
                err.text = str(e)
                return
            popup.dismiss()
            self.build_ui()

        save_btn.bind(on_press=do_save)
        cancel_btn.bind(on_press=popup.dismiss)
        popup.open()

    # ── Popup: Add Shift to Day ───────────────────────────────────────────────

    def _popup_add_shift_to_day(self, data):
        shifts = svc.get_shifts(data)
        if not shifts:
            self._popup_msg("No shift types yet.\nGo to Manage tab to add shifts first.")
            return

        inner = rounded_card(bg=TH.bg, radius=0)
        inner.add_widget(make_label(
            f"Add shift to {DAY_FULL[self.active_day]}",
            color=TH.primary, bold=True, height=28))
        inner.add_widget(section_label("SELECT SHIFT", height=22))

        self._sel_shift_id = shifts[0]["id"]

        shift_col = BoxLayout(orientation="vertical",
                              size_hint_y=None, spacing=6)
        shift_col.bind(minimum_height=shift_col.setter("height"))

        def on_sel(b):
            self._sel_shift_id = b.shift_id
            for child in shift_col.children:
                if not hasattr(child, "shift_id"):
                    continue
                s = next((x for x in shifts if x["id"] == child.shift_id), {})
                is_s = child.shift_id == self._sel_shift_id
                child.background_color = (0, 0, 0, 0)
                fill_rounded(child,
                             _hex_color(s.get("color", "#C9A84C")) if is_s else TH.card,
                             radius=10)
                child.color = TH.gold_text if is_s else TH.text_main

        for shift in shifts:
            is_sel = shift["id"] == self._sel_shift_id
            sb = Button(
                text=f"{shift['name']}  ({shift['start_time']}–{shift['end_time']})",
                font_size=TH.fs_small, bold=True,
                size_hint_y=None, height=46,
                background_normal="", background_color=(0, 0, 0, 0),
                color=TH.gold_text if is_sel else TH.text_main)
            sb.shift_id = shift["id"]
            fill_rounded(sb,
                         _hex_color(shift.get("color", "#C9A84C")) if is_sel else TH.card,
                         radius=10)
            sb.bind(on_press=on_sel)
            shift_col.add_widget(sb)

        inner.add_widget(shift_col)

        btns = BoxLayout(size_hint_y=None, height=46, spacing=8)
        add_btn    = gold_btn("Add", height=46)
        cancel_btn = ghost_btn("Cancel", height=46)
        btns.add_widget(add_btn)
        btns.add_widget(cancel_btn)
        inner.add_widget(btns)

        popup = self._base_popup(
            "Add Shift", inner,
            height=200 + len(shifts) * 54)

        def do_add(*_):
            svc.add_day_entry(self.active_day, self._sel_shift_id)
            popup.dismiss()
            self.build_ui()

        add_btn.bind(on_press=do_add)
        cancel_btn.bind(on_press=popup.dismiss)
        popup.open()

    # ── Popup: Assign Staff to Shift Entry ────────────────────────────────────

    def _popup_assign_staff(self, entry_idx, data):
        staff = svc.get_staff(data)
        if not staff:
            self._popup_msg("No staff members yet.\nGo to Manage tab to add staff first.")
            return

        entries  = svc.get_day_entries(data, self.active_day)
        selected = list(entries[entry_idx].get("staff", []))

        inner = rounded_card(bg=TH.bg, radius=0)
        inner.add_widget(make_label(
            "Select staff for this shift:",
            color=TH.primary, bold=True, height=28))

        staff_col = BoxLayout(orientation="vertical",
                              size_hint_y=None, spacing=6)
        staff_col.bind(minimum_height=staff_col.setter("height"))

        def on_toggle(b):
            if b.staff_id in selected:
                selected.remove(b.staff_id)
                fill_rounded(b, TH.card, radius=10)
                b.color = TH.text_main
            else:
                selected.append(b.staff_id)
                fill_rounded(b, TH.primary, radius=10)
                b.color = TH.gold_text

        for member in staff:
            is_sel = member["id"] in selected
            sb = Button(
                text=f"  {member['name']}",
                font_size=TH.fs_normal, bold=is_sel,
                size_hint_y=None, height=46,
                background_normal="", background_color=(0, 0, 0, 0),
                color=TH.gold_text if is_sel else TH.text_main)
            sb.staff_id = member["id"]
            fill_rounded(sb, TH.primary if is_sel else TH.card, radius=10)
            sb.bind(on_press=on_toggle)
            staff_col.add_widget(sb)

        inner.add_widget(staff_col)

        btns = BoxLayout(size_hint_y=None, height=46, spacing=8)
        save_btn   = gold_btn("Save", height=46)
        cancel_btn = ghost_btn("Cancel", height=46)
        btns.add_widget(save_btn)
        btns.add_widget(cancel_btn)
        inner.add_widget(btns)

        popup = self._base_popup(
            "Assign Staff", inner,
            height=180 + len(staff) * 54)

        def do_save(*_):
            svc.assign_staff_to_entry(self.active_day, entry_idx, selected)
            popup.dismiss()
            self.build_ui()

        save_btn.bind(on_press=do_save)
        cancel_btn.bind(on_press=popup.dismiss)
        popup.open()

    # ── Popup: Add Task ───────────────────────────────────────────────────────

    def _popup_add_task(self, data):
        inner = rounded_card(bg=TH.bg, radius=0)
        inner.add_widget(section_label("TASK NAME", height=22))
        name_in = self._text_input("e.g. Clean equipment")
        inner.add_widget(name_in)

        inner.add_widget(section_label("DAYS  (leave blank = every day)", height=22))
        sel_days = []
        day_row  = BoxLayout(size_hint_y=None, height=42, spacing=4)

        def on_day(b):
            if b.text in sel_days:
                sel_days.remove(b.text)
                fill_rounded(b, TH.card, radius=16)
                b.color = TH.grey
            else:
                sel_days.append(b.text)
                fill_rounded(b, TH.primary, radius=16)
                b.color = TH.gold_text

        for d in DAYS:
            db = Button(
                text=d, font_size=9, bold=False,
                background_normal="", background_color=(0, 0, 0, 0),
                color=TH.grey,
                size_hint_y=None, height=34)
            fill_rounded(db, TH.card, radius=16)
            db.bind(on_press=on_day)
            day_row.add_widget(db)
        inner.add_widget(day_row)

        err = make_label("", color=TH.red, height=20, font_size=11)
        inner.add_widget(err)

        btns = BoxLayout(size_hint_y=None, height=46, spacing=8)
        save_btn   = gold_btn("Save", height=46)
        cancel_btn = ghost_btn("Cancel", height=46)
        btns.add_widget(save_btn)
        btns.add_widget(cancel_btn)
        inner.add_widget(btns)

        popup = self._base_popup("Add Task", inner, height=380)

        def do_save(*_):
            try:
                svc.add_task(name_in.text, sel_days)
            except ValueError as e:
                err.text = str(e)
                return
            popup.dismiss()
            self.build_ui()

        save_btn.bind(on_press=do_save)
        cancel_btn.bind(on_press=popup.dismiss)
        popup.open()

    # ── Popup: Assign Staff to Task ───────────────────────────────────────────

    def _popup_assign_staff_task(self, task_id, data):
        staff = svc.get_staff(data)
        if not staff:
            self._popup_msg("No staff members yet.\nGo to Manage tab to add staff first.")
            return

        task     = next((t for t in svc.get_tasks(data) if t["id"] == task_id), None)
        selected = list(task.get("assigned_staff", [])) if task else []

        inner = rounded_card(bg=TH.bg, radius=0)
        inner.add_widget(make_label(
            f"Assign staff to: {task['name']}",
            color=TH.primary, bold=True, height=28))

        staff_col = BoxLayout(orientation="vertical",
                              size_hint_y=None, spacing=6)
        staff_col.bind(minimum_height=staff_col.setter("height"))

        def on_toggle(b):
            if b.staff_id in selected:
                selected.remove(b.staff_id)
                fill_rounded(b, TH.card, radius=10)
                b.color = TH.text_main
            else:
                selected.append(b.staff_id)
                fill_rounded(b, TH.primary, radius=10)
                b.color = TH.gold_text

        for member in staff:
            is_sel = member["id"] in selected
            sb = Button(
                text=f"  {member['name']}",
                font_size=TH.fs_normal, bold=is_sel,
                size_hint_y=None, height=46,
                background_normal="", background_color=(0, 0, 0, 0),
                color=TH.gold_text if is_sel else TH.text_main)
            sb.staff_id = member["id"]
            fill_rounded(sb, TH.primary if is_sel else TH.card, radius=10)
            sb.bind(on_press=on_toggle)
            staff_col.add_widget(sb)

        inner.add_widget(staff_col)

        btns = BoxLayout(size_hint_y=None, height=46, spacing=8)
        save_btn   = gold_btn("Save", height=46)
        cancel_btn = ghost_btn("Cancel", height=46)
        btns.add_widget(save_btn)
        btns.add_widget(cancel_btn)
        inner.add_widget(btns)

        popup = self._base_popup(
            "Assign Staff to Task", inner,
            height=180 + len(staff) * 54)

        def do_save(*_):
            svc.assign_staff_to_task(task_id, selected)
            popup.dismiss()
            self.build_ui()

        save_btn.bind(on_press=do_save)
        cancel_btn.bind(on_press=popup.dismiss)
        popup.open()

    # ── Popup: Confirm Clear Week ─────────────────────────────────────────────

    def _popup_confirm_clear(self):
        inner = rounded_card(bg=TH.bg, radius=0, spacing=12)
        inner.add_widget(spacer(4))
        inner.add_widget(make_label(
            "Clear all shifts for this week?\nThis cannot be undone.",
            color=TH.text_main, halign="center",
            font_size=TH.fs_small, height=52))

        btns = BoxLayout(size_hint_y=None, height=46, spacing=8)
        yes_btn    = danger_btn("Clear Week", height=46)
        cancel_btn = ghost_btn("Cancel", height=46)
        btns.add_widget(yes_btn)
        btns.add_widget(cancel_btn)
        inner.add_widget(btns)

        popup = self._base_popup("", inner,
                                 size_hint=(0.85, None), height=220)

        def do_clear(*_):
            svc.clear_week()
            popup.dismiss()
            self.build_ui()

        yes_btn.bind(on_press=do_clear)
        cancel_btn.bind(on_press=popup.dismiss)
        popup.open()

    # ── Popup: Simple message ─────────────────────────────────────────────────

    def _popup_msg(self, msg):
        inner = rounded_card(bg=TH.bg, radius=0, spacing=12)
        inner.add_widget(spacer(4))
        inner.add_widget(make_label(
            msg, color=TH.text_main, halign="center",
            font_size=TH.fs_normal, height=56))
        ok_btn = gold_btn("OK", height=44)
        inner.add_widget(ok_btn)

        popup = self._base_popup("", inner,
                                 size_hint=(0.80, None), height=220)
        ok_btn.bind(on_press=popup.dismiss)
        popup.open()

    # ── Delete actions ────────────────────────────────────────────────────────

    def _delete_entry(self, entry_idx, data):
        svc.delete_day_entry(self.active_day, entry_idx)
        self.build_ui()

    def _delete_shift(self, shift_id):
        svc.delete_shift(shift_id)
        self.build_ui()

    def _delete_staff(self, staff_id):
        svc.delete_staff(staff_id)
        self.build_ui()

    def _delete_task(self, task_id):
        svc.delete_task(task_id)
        self.build_ui()