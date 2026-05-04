import os
import traceback
from kivy.app import App
from kivy.core.text import LabelBase
from kivy.uix.screenmanager import ScreenManager, SlideTransition
from kivy.core.window import Window
from kivy.base import ExceptionHandler, ExceptionManager

Window.size = (400, 700)


def _register_lang_font():
    """Override Roboto with a font covering the active UI language."""
    try:
        from lang import load_lang
        lang = load_lang()
    except Exception:
        return
    win_fonts = r"C:\Windows\Fonts"
    pick = {
        "Myanmar": ("mmrtext.ttf", "mmrtextb.ttf"),
    }.get(lang)
    if not pick:
        return
    reg = os.path.join(win_fonts, pick[0])
    bold = os.path.join(win_fonts, pick[1])
    if not os.path.exists(reg):
        return
    LabelBase.register(
        name="Roboto",
        fn_regular=reg,
        fn_bold=bold if os.path.exists(bold) else reg)


_register_lang_font()

class CrashHandler(ExceptionHandler):
    def handle_exception(self, inst):
        print("KIVY EXCEPTION:", inst)
        traceback.print_exc()
        return ExceptionManager.PASS

ExceptionManager.add_handler(CrashHandler())

from screens.pin_screen      import PINScreen
from screens.splash_screen   import SplashScreen
from screens.home_screen     import HomeScreen
from screens.category_screen import CategoryScreen
from screens.recipe_screen   import RecipeScreen
from screens.settings_screen import SettingsScreen
class TeaSOPApp(App):
    kv_file = ""
    def build(self):
        sm = ScreenManager(transition=SlideTransition(duration=0.25))
        sm.add_widget(SplashScreen(name="splash"))
        sm.add_widget(PINScreen(name="pin"))
        sm.add_widget(HomeScreen(name="home"))
        sm.add_widget(CategoryScreen(name="category"))
        sm.add_widget(RecipeScreen(name="recipe"))
        sm.add_widget(SettingsScreen(name="settings"))
        sm.current = "splash"
        return sm

if __name__ == "__main__":
    try:
        TeaSOPApp().run()
    except Exception as e:
        print("ERROR:", e)
        traceback.print_exc()
    finally:
        input("Press Enter to exit...")